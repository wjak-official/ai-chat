param(
  [string]$OutputRoot = (Join-Path $PSScriptRoot "installer-validation")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Ensure-Directory([string]$Path) {
  if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path | Out-Null }
}

function New-Scenario([string]$Name, [string[]]$Answers) {
  return @{
    Name = $Name
    Answers = $Answers
  }
}

$installerPath = Join-Path $PSScriptRoot "aio-installer_V2.ps1"
if (-not (Test-Path $installerPath)) { throw "Installer not found: $installerPath" }

Ensure-Directory $OutputRoot
$runsRoot = Join-Path $OutputRoot "runs"
Ensure-Directory $runsRoot

$dummyGgufPath = Join-Path $OutputRoot "dummy-model.gguf"
Set-Content -Path $dummyGgufPath -Value "validation gguf placeholder" -Encoding UTF8

$scenarios = @(
  (New-Scenario "openrouter-native-localtls-ragoff" @(
    "__ROOT__", "laravel-admin", "free-claude-code", "0", "0", "0",
    "local-openrouter.example.test", "8081", "8444", "8001", "8083",
    "n",
    "dummy-openrouter-key", "open_router/test-model",
    "opus-openrouter", "sonnet-openrouter", "haiku-openrouter",
    "y", "dummy-auth-openrouter",
    "2"
  )),
  (New-Scenario "nvidia-docker-publictls-redis-discord" @(
    "__ROOT__", "laravel-admin", "nim-proxy", "1", "1", "1",
    "public-nim.example.test", "8082", "8445", "8002", "8084",
    "y", "y", "n",
    "dummy-nim-key", "nvidia_nim/test-model",
    "opus-nvidia", "sonnet-nvidia", "haiku-nvidia",
    "y", "dummy-auth-nvidia",
    "0", "dummy-discord-token", "12345,67890",
    "admin-nim@example.test"
  )),
  (New-Scenario "lmstudio-docker-publictls-postgres" @(
    "__ROOT__", "laravel-admin", "lmstudio-proxy", "2", "1", "1",
    "public-lmstudio.example.test", "8083", "8446", "8003", "8085",
    "y", "n", "y",
    "http://localhost:1234/v1", "lmstudio/local-model",
    "opus-lmstudio", "sonnet-lmstudio", "haiku-lmstudio",
    "y", "dummy-auth-lmstudio",
    "2",
    "admin-lmstudio@example.test"
  )),
  (New-Scenario "llamacpp-existing-native-publictls-both-telegram-authoff" @(
    "__ROOT__", "laravel-admin", "llama-existing-proxy", "3", "0", "1",
    "public-llama-existing.example.test", "8084", "8447", "8004", "8086",
    "y", "y", "y",
    "0", "http://localhost:8080/v1", "llamacpp/existing-model",
    "opus-llama-existing", "sonnet-llama-existing", "haiku-llama-existing",
    "n",
    "1", "dummy-telegram-token", "424242",
    "admin-llama-existing@example.test"
  )),
  (New-Scenario "llamacpp-docker-localfile-localtls" @(
    "__ROOT__", "laravel-admin", "llama-docker-localfile-proxy", "3", "1", "0",
    "local-llama-file.example.test", "8085", "8448", "8005", "8087",
    "y", "n", "n",
    "1", "8090", "0", "__GGUF__", "4096", "0", "llamacpp/docker-file-model",
    "opus-llama-file", "sonnet-llama-file", "haiku-llama-file",
    "y", "dummy-auth-llama-file",
    "2"
  )),
  (New-Scenario "llamacpp-docker-download-localtls" @(
    "__ROOT__", "laravel-admin", "llama-docker-download-proxy", "3", "1", "0",
    "local-llama-download.example.test", "8086", "8449", "8006", "8088",
    "n",
    "1", "8091", "1", "https://example.com/models/test-model.gguf", "8192", "4", "llamacpp/docker-download-model",
    "opus-llama-download", "sonnet-llama-download", "haiku-llama-download",
    "y", "dummy-auth-llama-download",
    "2"
  )),
  (New-Scenario "llamacpp-docker-skip-localtls" @(
    "__ROOT__", "laravel-admin", "llama-docker-skip-proxy", "3", "1", "0",
    "local-llama-skip.example.test", "8087", "8450", "8007", "8089",
    "n",
    "1", "8092", "2", "16384", "8", "llamacpp/docker-skip-model",
    "opus-llama-skip", "sonnet-llama-skip", "haiku-llama-skip",
    "y", "dummy-auth-llama-skip",
    "2"
  ))
)

$results = New-Object System.Collections.Generic.List[object]

foreach ($scenario in $scenarios) {
  $scenarioDir = Join-Path $runsRoot $scenario.Name
  if (Test-Path $scenarioDir) { Remove-Item -Path $scenarioDir -Recurse -Force }
  Ensure-Directory $scenarioDir

  $rootDir = Join-Path $scenarioDir "stack-root"
  $answers = @($scenario.Answers | ForEach-Object {
    $_.Replace("__ROOT__", $rootDir).Replace("__GGUF__", $dummyGgufPath)
  })

  $answersPath = Join-Path $scenarioDir "answers.json"
  $logPath = Join-Path $scenarioDir "run.log"
  $answers | ConvertTo-Json | Set-Content -Path $answersPath -Encoding UTF8

  Write-Host "=== Running $($scenario.Name) ===" -ForegroundColor Cyan
  $output = & pwsh -NoProfile -File $installerPath -ValidationMode -PromptAnswersPath $answersPath 2>&1
  $output | Tee-Object -FilePath $logPath | Out-Host
  $exitCode = $LASTEXITCODE

  $generatedFiles = @()
  if (Test-Path $rootDir) {
    $generatedFiles = @(Get-ChildItem -Path $rootDir -Recurse -File -Force | ForEach-Object {
      $_.FullName.Replace($rootDir, "<root>")
    } | Sort-Object)
  }

  $result = [pscustomobject]@{
    Name = $scenario.Name
    ExitCode = $exitCode
    RootDir = $rootDir
    LogPath = $logPath
    GeneratedFiles = $generatedFiles
  }
  $results.Add($result) | Out-Null

  if ($exitCode -ne 0) {
    Write-Host "Scenario failed: $($scenario.Name)" -ForegroundColor Red
  } else {
    Write-Host "Scenario passed: $($scenario.Name)" -ForegroundColor Green
  }
}

$summaryPath = Join-Path $OutputRoot "summary.json"
$results | ConvertTo-Json -Depth 6 | Set-Content -Path $summaryPath -Encoding UTF8

$failed = @($results | Where-Object { $_.ExitCode -ne 0 })
if ($failed.Count -gt 0) {
  throw ("Installer validation failed for: " + ($failed.Name -join ", "))
}

Write-Host "Validation summary written to $summaryPath" -ForegroundColor Green
