<#
AIO INSTALLER (Windows) — Laravel + Filament + Free-Claude + Provider + optional llama.cpp + RAG + TLS gateway

Creates this layout under a chosen RootDir:

RootDir/
  laravel-admin/               (Laravel app + Filament)
  free-claude-code/            (proxy repo)
  stack/
    docker-compose.gateway.yml (Traefik TLS gateway)
    docker-compose.rag.yml     (Qdrant + optional Redis/Postgres)
    docker-compose.llamacpp.yml(optional llama.cpp)
    traefik/
    certs/ or acme/
    models/                    (GGUF models for llama.cpp)
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ======================
# UI helpers
# ======================
function Write-Title([string]$Text) {
  Write-Host ""
  Write-Host "===================================================================" -ForegroundColor DarkCyan
  Write-Host $Text -ForegroundColor Cyan
  Write-Host "===================================================================" -ForegroundColor DarkCyan
}
function Write-Info([string]$Text) { Write-Host "[INFO] $Text" -ForegroundColor Gray }
function Write-Warn([string]$Text) { Write-Host "[WARN] $Text" -ForegroundColor Yellow }
function Write-Err ([string]$Text) { Write-Host "[ERR ] $Text" -ForegroundColor Red }

function Prompt-YesNo([string]$Question, [bool]$Default = $true) {
  $suffix = if ($Default) { "[Y/n]" } else { "[y/N]" }
  while ($true) {
    $raw = Read-Host "$Question $suffix"
    if ([string]::IsNullOrWhiteSpace($raw)) { return $Default }
    switch ($raw.Trim().ToLowerInvariant()) {
      "y" { return $true }
      "yes" { return $true }
      "n" { return $false }
      "no" { return $false }
      default { Write-Warn "Please answer y or n." }
    }
  }
}
function Prompt-Text([string]$Question, [string]$Default = "") {
  $raw = Read-Host "$Question$(if($Default){ " (default: $Default)" } else { "" })"
  if ([string]::IsNullOrWhiteSpace($raw)) { return $Default }
  return $raw
}
function Prompt-Int([string]$Question, [int]$Default) {
  while ($true) {
    $raw = Read-Host "$Question (default: $Default)"
    if ([string]::IsNullOrWhiteSpace($raw)) { return $Default }
    $n = 0
    if ([int]::TryParse($raw, [ref]$n)) { return $n }
    Write-Warn "Please enter a valid number."
  }
}
function Prompt-Choice([string]$Question, [string[]]$Options, [int]$DefaultIndex = 0) {
  Write-Host ""
  Write-Host $Question -ForegroundColor Cyan
  for ($i=0; $i -lt $Options.Count; $i++) {
    $mark = if ($i -eq $DefaultIndex) { "*" } else { " " }
    Write-Host ("  [{0}] {1} {2}" -f $i, $Options[$i], $mark) -ForegroundColor Gray
  }
  while ($true) {
    $raw = Read-Host ("Choose 0-{0} (default: {1})" -f ($Options.Count-1), $DefaultIndex)
    if ([string]::IsNullOrWhiteSpace($raw)) { return $DefaultIndex }
    $n = 0
    if ([int]::TryParse($raw, [ref]$n) -and $n -ge 0 -and $n -lt $Options.Count) { return $n }
    Write-Warn "Invalid choice."
  }
}
function Read-Secret([string]$Prompt) {
  $secure = Read-Host $Prompt -AsSecureString
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
  finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

# ======================
# Helpers
# ======================
function Test-Command([string]$Name) { return [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
function Ensure-Directory([string]$Path) { if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path | Out-Null } }
function Ensure-File([string]$Path) {
  $parent = Split-Path -Parent $Path
  if ($parent) { Ensure-Directory $parent }
  if (-not (Test-Path $Path)) { New-Item -ItemType File -Path $Path | Out-Null }
}
function Write-Utf8File([string]$Path, [string]$Content) {
  $parent = Split-Path -Parent $Path
  if ($parent) { Ensure-Directory $parent }
  Set-Content -Path $Path -Value $Content -Encoding UTF8
}
function Assert([bool]$Condition, [string]$Message) { if (-not $Condition) { throw $Message } }

function Install-WithWinget([string]$Id, [string]$Name) {
  if (-not (Test-Command "winget")) {
    Write-Warn "winget not found; cannot auto-install $Name."
    return $false
  }
  if (-not (Prompt-YesNo "Install $Name using winget now?" $true)) { return $false }
  Write-Info "winget install -e --id $Id"
  winget install -e --id $Id
  return $true
}

function Ensure-Git { if (Test-Command "git") { return $true }; Write-Warn "Git not found."; return (Install-WithWinget "Git.Git" "Git") }
function Ensure-Node { if (Test-Command "node") { return $true }; Write-Warn "Node not found."; return (Install-WithWinget "OpenJS.NodeJS.LTS" "Node.js LTS") }
function Ensure-Composer { if (Test-Command "composer") { return $true }; Write-Warn "Composer not found."; return (Install-WithWinget "Composer.Composer" "Composer") }
function Ensure-Python { if (Test-Command "python") { return $true }; Write-Warn "Python not found."; return (Install-WithWinget "Python.Python.3.12" "Python 3.12") }
function Ensure-OpenSSL { if (Test-Command "openssl") { return $true }; Write-Warn "OpenSSL not found."; return (Install-WithWinget "ShiningLight.OpenSSL" "OpenSSL") }
function Ensure-DockerDesktop {
  if (-not (Test-Command "docker")) { return $false }
  try { docker version | Out-Null; return $true } catch { return $false }
}
function Ensure-PHP {
  if (Test-Command "php") { return $true }
  Write-Warn "PHP not found. Install PHP (recommended: Laravel Herd) then re-run."
  return $false
}
function Ensure-Pip {
  try { python -m pip --version | Out-Null; return $true } catch { return $false }
}
function Ensure-Uv {
  if (Test-Command "uv") { return $true }
  if (-not (Prompt-YesNo "Install uv using pip now? (pip install uv)" $true)) { return $false }
  python -m pip install --upgrade pip
  python -m pip install --upgrade uv
  return (Test-Command "uv")
}

function Ensure-LineInEnv([string]$EnvPath, [string]$Key, [string]$Value) {
  Ensure-File $EnvPath
  $raw = Get-Content $EnvPath -Raw
  $pattern = "(?m)^\s*{0}\s*=" -f [regex]::Escape($Key)
  if ($raw -match $pattern) {
    $lines = Get-Content $EnvPath
    $out = foreach ($l in $lines) {
      if ($l -match ("^\s*{0}\s*=" -f [regex]::Escape($Key))) { "$Key=$Value" } else { $l }
    }
    Set-Content -Path $EnvPath -Value $out -Encoding UTF8
  } else {
    Add-Content -Path $EnvPath -Value "`n$Key=$Value" -Encoding UTF8
  }
}

function Copy-EnvExampleIfMissing([string]$Example, [string]$Target) {
  if ((Test-Path $Example) -and -not (Test-Path $Target)) { Copy-Item $Example $Target }
}

# ======================
# TLS local certs
# ======================
function New-LocalDevCertificates([string]$CertDir, [string[]]$SANs, [int]$DaysValid = 825, [string]$CommonName = "ai-chat-local") {
  Ensure-Directory $CertDir

  $caKey   = Join-Path $CertDir "ca.key"
  $caCrt   = Join-Path $CertDir "ca.crt"
  $leafKey = Join-Path $CertDir "tls.key"
  $leafCrt = Join-Path $CertDir "tls.crt"
  $leafCsr = Join-Path $CertDir "tls.csr"
  $extFile = Join-Path $CertDir "tls.ext"

  if ((Test-Path $caKey) -and (Test-Path $caCrt) -and (Test-Path $leafKey) -and (Test-Path $leafCrt)) {
    Write-Info "Local certs already exist: $CertDir"
    return
  }

  $sanParts = @()
  foreach ($s in $SANs) {
    if ($s -match '^\d{1,3}(\.\d{1,3}){3}$') { $sanParts += "IP:$s" } else { $sanParts += "DNS:$s" }
  }
  $sanLine = "subjectAltName = " + ($sanParts -join ",")

@"
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
$sanLine
"@ | Set-Content -Path $extFile -Encoding ascii

  & openssl genrsa -out $caKey 4096 | Out-Null
  & openssl req -x509 -new -nodes -key $caKey -sha256 -days $DaysValid -subj "/CN=$CommonName Local CA" -out $caCrt | Out-Null
  & openssl genrsa -out $leafKey 2048 | Out-Null
  & openssl req -new -key $leafKey -subj "/CN=$($SANs[0])" -out $leafCsr | Out-Null
  & openssl x509 -req -in $leafCsr -CA $caCrt -CAkey $caKey -CAcreateserial -out $leafCrt -days $DaysValid -sha256 -extfile $extFile | Out-Null
}

# ======================
# Main wizard
# ======================
Write-Title "AIO Installer: Laravel + Filament + Free-Claude + Provider + RAG + TLS"

$rootDir = Prompt-Text "Root install folder" (Join-Path (Get-Location) "laravel-free-claude-stack")
$laravelName = Prompt-Text "Laravel app folder name" "laravel-admin"
$proxyName = Prompt-Text "free-claude-code folder name" "free-claude-code"

$stackDir = Join-Path $rootDir "stack"
$modelsDir = Join-Path $stackDir "models"

$providerIdx = Prompt-Choice "Choose provider" @(
  "OpenRouter",
  "NVIDIA NIM",
  "LM Studio",
  "llama.cpp"
) 0

$freeClaudeRuntimeIdx = Prompt-Choice "free-claude runtime" @(
  "Native on Windows (python + uv on host)",
  "Dockerized (no host python/uv; runs in container)"
) 1

$tlsIdx = Prompt-Choice "TLS exposure mode" @(
  "Local/LAN TLS (OpenSSL local CA) — for team/VPN/LAN",
  "Public TLS (Let's Encrypt) — requires inbound 80/443"
) 0

$domain = Prompt-Text "Primary domain" "myvipsb.sytes.net"
$httpPort = Prompt-Int "Gateway HTTP port" 80
$httpsPort = Prompt-Int "Gateway HTTPS port" 443

$laravelPort = Prompt-Int "Laravel local port (php artisan serve)" 8000
$proxyPort = Prompt-Int "free-claude proxy port" 8082

$enableRag = Prompt-YesNo "Enable RAG stack (Qdrant)?" $true
$enableRedis = $false
$enablePostgres = $false
if ($enableRag) {
  $enableRedis = Prompt-YesNo "Enable Redis?" $false
  $enablePostgres = Prompt-YesNo "Enable Postgres?" $false
}

Write-Title "Prerequisites"
Assert (Ensure-Git) "Git is required."
Assert (Ensure-Node) "Node.js is required."
Assert (Ensure-Composer) "Composer is required."
Assert (Ensure-DockerDesktop) "Docker Desktop is required and must be running."
Assert (Ensure-PHP) "PHP is required (install Laravel Herd or PHP)."

if ($freeClaudeRuntimeIdx -eq 0) {
  Assert (Ensure-Python) "Python is required for native free-claude runtime."
  Assert (Ensure-Pip) "pip is required."
  Assert (Ensure-Uv) "uv is required."
}
if ($tlsIdx -eq 0) {
  Assert (Ensure-OpenSSL) "OpenSSL is required for local TLS mode."
}

Ensure-Directory $rootDir
Ensure-Directory $stackDir
Ensure-Directory $modelsDir

# ======================
# Laravel + Filament
# ======================
Write-Title "Installing Laravel + Filament"
$laravelPath = Join-Path $rootDir $laravelName
if (-not (Test-Path $laravelPath)) {
  Push-Location $rootDir
  try {
    composer create-project laravel/laravel $laravelName
  } finally { Pop-Location }
} else {
  Write-Info "Laravel exists: $laravelPath"
}

Push-Location $laravelPath
try {
  if ((Test-Path ".env.example") -and -not (Test-Path ".env")) { Copy-Item ".env.example" ".env" }
  php artisan key:generate

  composer require filament/filament:"^3.0" -W
  php artisan filament:install --panels

  Ensure-Directory (Join-Path $laravelPath "database")
  $sqliteFile = Join-Path $laravelPath "database\database.sqlite"
  Ensure-File $sqliteFile

  $laravelEnv = Join-Path $laravelPath ".env"
  Ensure-LineInEnv $laravelEnv "DB_CONNECTION" '"sqlite"'
  Ensure-LineInEnv $laravelEnv "DB_DATABASE" '"database/database.sqlite"'

  npm install
  npm run build
} finally { Pop-Location }

# ======================
# free-claude-code
# ======================
Write-Title "Installing free-claude-code"
$proxyPath = Join-Path $rootDir $proxyName
if (-not (Test-Path $proxyPath)) {
  git clone https://github.com/Alishahryar1/free-claude-code.git $proxyPath
} else {
  Write-Info "Proxy exists: $proxyPath"
}

$proxyEnv = Join-Path $proxyPath ".env"
Copy-EnvExampleIfMissing (Join-Path $proxyPath ".env.example") $proxyEnv

# Enforce correct env keys baseline
# (These are the keys you provided; we set them explicitly so the file always has them.)
Ensure-LineInEnv $proxyEnv "NVIDIA_NIM_API_KEY" '""'
Ensure-LineInEnv $proxyEnv "OPENROUTER_API_KEY" '""'
Ensure-LineInEnv $proxyEnv "LM_STUDIO_BASE_URL" '"http://localhost:1234/v1"'
Ensure-LineInEnv $proxyEnv "LLAMACPP_BASE_URL" '"http://localhost:8080/v1"'

# Provider-specific setup + model mapping
Write-Title "Provider setup + models"
switch ($providerIdx) {
  0 {
    $orKey = Read-Secret "OPENROUTER_API_KEY"
    Ensure-LineInEnv $proxyEnv "OPENROUTER_API_KEY" ('"' + $orKey + '"')
    $modelDefault = Prompt-Text "MODEL (default mapping)" "open_router/arcee-ai/trinity-large-preview:free"
    Ensure-LineInEnv $proxyEnv "MODEL" ('"' + $modelDefault + '"')
  }
  1 {
    $nimKey = Read-Secret "NVIDIA_NIM_API_KEY"
    Ensure-LineInEnv $proxyEnv "NVIDIA_NIM_API_KEY" ('"' + $nimKey + '"')
    $modelDefault = Prompt-Text "MODEL (default mapping)" "nvidia_nim/z-ai/glm4.7"
    Ensure-LineInEnv $proxyEnv "MODEL" ('"' + $modelDefault + '"')
  }
  2 {
    $lmUrl = Prompt-Text "LM_STUDIO_BASE_URL" "http://localhost:1234/v1"
    Ensure-LineInEnv $proxyEnv "LM_STUDIO_BASE_URL" ('"' + $lmUrl + '"')
    $modelDefault = Prompt-Text "MODEL (label used by your code/mapping)" "lmstudio/local-model"
    Ensure-LineInEnv $proxyEnv "MODEL" ('"' + $modelDefault + '"')
    Write-Warn "LM Studio must be installed separately and its server enabled."
  }
  3 {
    $llMode = Prompt-Choice "llama.cpp setup" @(
      "Use existing llama.cpp endpoint",
      "Install and run llama.cpp SERVER in Docker (recommended)"
    ) 1

    if ($llMode -eq 0) {
      $llUrl = Prompt-Text "LLAMACPP_BASE_URL" "http://localhost:8080/v1"
      Ensure-LineInEnv $proxyEnv "LLAMACPP_BASE_URL" ('"' + $llUrl + '"')
    } else {
      $llHostPort = Prompt-Int "llama.cpp host port" 8080

      $modelSource = Prompt-Choice "Model install for llama.cpp" @(
        "Use existing local GGUF file path (copy into stack/models)",
        "Download GGUF from URL (into stack/models)",
        "Skip model install (you will add later)"
      ) 0

      $modelMount = ""
      if ($modelSource -eq 0) {
        $localPath = Prompt-Text "Local GGUF path" ""
        Assert (Test-Path $localPath) "GGUF file not found."
        $dest = Join-Path $modelsDir (Split-Path $localPath -Leaf)
        Copy-Item $localPath $dest -Force
        $modelMount = "/models/" + (Split-Path $dest -Leaf)
      } elseif ($modelSource -eq 1) {
        $url = Prompt-Text "GGUF download URL" ""
        Assert (-not [string]::IsNullOrWhiteSpace($url)) "Model URL is required."
        $file = Split-Path $url -Leaf
        $dest = Join-Path $modelsDir $file
        Invoke-WebRequest -Uri $url -OutFile $dest
        $modelMount = "/models/$file"
      } else {
        $modelMount = "/models/CHANGE_ME.gguf"
      }

      $ctx = Prompt-Int "Context size (-c)" 4096
      $ngl = Prompt-Int "GPU layers (-ngl) (0 for CPU)" 0

      $llCompose = Join-Path $stackDir "docker-compose.llamacpp.yml"
@"
services:
  llamacpp:
    image: ghcr.io/ggerganov/llama.cpp:server
    command:
      - -m
      - $modelMount
      - --host
      - 0.0.0.0
      - --port
      - "8080"
      - -c
      - "$ctx"
      - -ngl
      - "$ngl"
    ports:
      - "${llHostPort}:8080"
    volumes:
      - "./models:/models"
    restart: unless-stopped
"@ | Set-Content -Path $llCompose -Encoding UTF8

      Ensure-LineInEnv $proxyEnv "LLAMACPP_BASE_URL" ('"' + "http://host.docker.internal:$llHostPort/v1" + '"')
    }

    $modelDefault = Prompt-Text "MODEL (label used by your code/mapping)" "llamacpp/local-model"
    Ensure-LineInEnv $proxyEnv "MODEL" ('"' + $modelDefault + '"')
  }
}

$modelOpus   = Prompt-Text "MODEL_OPUS"   "nvidia_nim/z-ai/glm4.7"
$modelSonnet = Prompt-Text "MODEL_SONNET" "open_router/arcee-ai/trinity-large-preview:free"
$modelHaiku  = Prompt-Text "MODEL_HAIKU"  "open_router/stepfun/step-3.5-flash:free"
Ensure-LineInEnv $proxyEnv "MODEL_OPUS"   ('"' + $modelOpus + '"')
Ensure-LineInEnv $proxyEnv "MODEL_SONNET" ('"' + $modelSonnet + '"')
Ensure-LineInEnv $proxyEnv "MODEL_HAIKU"  ('"' + $modelHaiku + '"')

# Auth token enforcement
Write-Title "Proxy auth"
$enableAuth = Prompt-YesNo "Require ANTHROPIC_AUTH_TOKEN?" $true
$proxyToken = ""
if ($enableAuth) {
  $proxyToken = Read-Secret "ANTHROPIC_AUTH_TOKEN"
  Ensure-LineInEnv $proxyEnv "ANTHROPIC_AUTH_TOKEN" ('"' + $proxyToken + '"')
} else {
  Ensure-LineInEnv $proxyEnv "ANTHROPIC_AUTH_TOKEN" '""'
  if ($tlsIdx -eq 1) { Write-Warn "Public mode without auth token is NOT recommended." }
}

# Optional messaging config
Write-Title "Messaging (optional)"
$msgIdx = Prompt-Choice "MESSAGING_PLATFORM" @("discord","telegram","skip") 2
if ($msgIdx -eq 0) {
  Ensure-LineInEnv $proxyEnv "MESSAGING_PLATFORM" '"discord"'
  $dcToken = Read-Secret "DISCORD_BOT_TOKEN"
  $dcAllowed = Prompt-Text "ALLOWED_DISCORD_CHANNELS (comma-separated; blank=all)" ""
  Ensure-LineInEnv $proxyEnv "DISCORD_BOT_TOKEN" ('"' + $dcToken + '"')
  Ensure-LineInEnv $proxyEnv "ALLOWED_DISCORD_CHANNELS" ('"' + $dcAllowed + '"')
} elseif ($msgIdx -eq 1) {
  Ensure-LineInEnv $proxyEnv "MESSAGING_PLATFORM" '"telegram"'
  $tgToken = Read-Secret "TELEGRAM_BOT_TOKEN"
  $tgUser = Prompt-Text "ALLOWED_TELEGRAM_USER_ID" ""
  Ensure-LineInEnv $proxyEnv "TELEGRAM_BOT_TOKEN" ('"' + $tgToken + '"')
  Ensure-LineInEnv $proxyEnv "ALLOWED_TELEGRAM_USER_ID" ('"' + $tgUser + '"')
}

# ======================
# free-claude runtime (Dockerized option)
# ======================
if ($freeClaudeRuntimeIdx -eq 1) {
  Write-Title "Writing Dockerized free-claude runtime files"
  $dockerfile = Join-Path $proxyPath "Dockerfile.runtime"
@"
FROM python:3.12-slim
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
RUN python -m pip install --upgrade pip && pip install --no-cache-dir uv
COPY . /app
EXPOSE ${proxyPort}
CMD ["uv", "run", "uvicorn", "server:app", "--host", "0.0.0.0", "--port", "${proxyPort}"]
"@ | Set-Content -Path $dockerfile -Encoding UTF8

  $compose = Join-Path $proxyPath "docker-compose.app.yml"
@"
services:
  free-claude:
    build:
      context: .
      dockerfile: Dockerfile.runtime
    env_file:
      - ./.env
    ports:
      - "${proxyPort}:${proxyPort}"
    restart: unless-stopped
"@ | Set-Content -Path $compose -Encoding UTF8
}

# ======================
# RAG stack
# ======================
if ($enableRag) {
  Write-Title "Writing RAG stack (Docker)"
  $ragCompose = Join-Path $stackDir "docker-compose.rag.yml"

  $rag = @"
services:
  qdrant:
    image: qdrant/qdrant:latest
    ports:
      - "6333:6333"
      - "6334:6334"
    volumes:
      - "./qdrant_storage:/qdrant/storage"
    restart: unless-stopped
"@

  if ($enableRedis) {
    $rag += @"

  redis:
    image: redis:7
    ports:
      - "6379:6379"
    restart: unless-stopped
"@
  }

  if ($enablePostgres) {
    $rag += @"

  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: app
      POSTGRES_USER: app
      POSTGRES_PASSWORD: app_password_change_me
    ports:
      - "5432:5432"
    volumes:
      - "./postgres_data:/var/lib/postgresql/data"
    restart: unless-stopped
"@
  }

  Set-Content -Path $ragCompose -Value $rag -Encoding UTF8
}

# ======================
# TLS gateway (Traefik)
# ======================
Write-Title "Writing TLS gateway (Traefik)"
$traefikDir = Join-Path $stackDir "traefik"
Ensure-Directory $traefikDir

$traefikStatic = Join-Path $traefikDir "traefik.yml"
$traefikDynamic = Join-Path $traefikDir "dynamic.yml"
$gatewayCompose = Join-Path $stackDir "docker-compose.gateway.yml"

if ($tlsIdx -eq 0) {
  New-LocalDevCertificates -CertDir (Join-Path $stackDir "certs") -SANs @($domain,"localhost","127.0.0.1") -CommonName $domain

@"
log:
  level: INFO
api:
  dashboard: true
entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"
providers:
  file:
    filename: /etc/traefik/dynamic.yml
    watch: true
"@ | Set-Content -Path $traefikStatic -Encoding UTF8

@"
tls:
  certificates:
    - certFile: /certs/tls.crt
      keyFile: /certs/tls.key

http:
  routers:
    laravel-http:
      rule: "Host(`${domain}`) || Host(`localhost`)"
      entryPoints: [ "web" ]
      middlewares: [ "redirect-to-https" ]
      service: laravel-svc

    laravel-https:
      rule: "Host(`${domain}`) || Host(`localhost`)"
      entryPoints: [ "websecure" ]
      tls: {}
      middlewares: [ "security-headers" ]
      service: laravel-svc

    proxy-http:
      rule: "Host(`proxy.${domain}`)"
      entryPoints: [ "web" ]
      middlewares: [ "redirect-to-https" ]
      service: proxy-svc

    proxy-https:
      rule: "Host(`proxy.${domain}`)"
      entryPoints: [ "websecure" ]
      tls: {}
      middlewares: [ "security-headers" ]
      service: proxy-svc

  middlewares:
    redirect-to-https:
      redirectScheme:
        scheme: https
        permanent: false

    security-headers:
      headers:
        contentTypeNosniff: true
        frameDeny: true
        referrerPolicy: "no-referrer"

  services:
    laravel-svc:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:${laravelPort}"
    proxy-svc:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:${proxyPort}"
"@ | Set-Content -Path $traefikDynamic -Encoding UTF8

@"
services:
  traefik:
    image: traefik:v3.0
    command:
      - "--configFile=/etc/traefik/traefik.yml"
    ports:
      - "${httpPort}:80"
      - "${httpsPort}:443"
      - "127.0.0.1:8080:8080"
    volumes:
      - "./traefik/traefik.yml:/etc/traefik/traefik.yml:ro"
      - "./traefik/dynamic.yml:/etc/traefik/dynamic.yml:ro"
      - "./certs:/certs:ro"
    restart: unless-stopped
"@ | Set-Content -Path $gatewayCompose -Encoding UTF8
}
else {
  $acmeEmail = Prompt-Text "Let's Encrypt ACME email" ""
  Assert (-not [string]::IsNullOrWhiteSpace($acmeEmail)) "ACME email is required for public mode."

  Ensure-Directory (Join-Path $stackDir "acme")
  Ensure-File (Join-Path $stackDir "acme\acme.json")

@"
log:
  level: INFO
api:
  dashboard: true
entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"
providers:
  file:
    filename: /etc/traefik/dynamic.yml
    watch: true
certificatesResolvers:
  le:
    acme:
      email: "$acmeEmail"
      storage: /acme/acme.json
      httpChallenge:
        entryPoint: web
"@ | Set-Content -Path $traefikStatic -Encoding UTF8

@"
http:
  routers:
    laravel-http:
      rule: "Host(`${domain}`)"
      entryPoints: [ "web" ]
      middlewares: [ "redirect-to-https" ]
      service: laravel-svc

    laravel-https:
      rule: "Host(`${domain}`)"
      entryPoints: [ "websecure" ]
      tls:
        certResolver: le
      middlewares: [ "security-headers" ]
      service: laravel-svc

    proxy-http:
      rule: "Host(`proxy.${domain}`)"
      entryPoints: [ "web" ]
      middlewares: [ "redirect-to-https" ]
      service: proxy-svc

    proxy-https:
      rule: "Host(`proxy.${domain}`)"
      entryPoints: [ "websecure" ]
      tls:
        certResolver: le
      middlewares: [ "security-headers" ]
      service: proxy-svc

  middlewares:
    redirect-to-https:
      redirectScheme:
        scheme: https
        permanent: true

    security-headers:
      headers:
        sslRedirect: true
        stsSeconds: 31536000
        stsIncludeSubdomains: true
        contentTypeNosniff: true
        frameDeny: true
        referrerPolicy: "no-referrer"

  services:
    laravel-svc:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:${laravelPort}"
    proxy-svc:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:${proxyPort}"
"@ | Set-Content -Path $traefikDynamic -Encoding UTF8

@"
services:
  traefik:
    image: traefik:v3.0
    command:
      - "--configFile=/etc/traefik/traefik.yml"
    ports:
      - "${httpPort}:80"
      - "${httpsPort}:443"
      - "127.0.0.1:8080:8080"
    volumes:
      - "./traefik/traefik.yml:/etc/traefik/traefik.yml:ro"
      - "./traefik/dynamic.yml:/etc/traefik/dynamic.yml:ro"
      - "./acme:/acme"
    restart: unless-stopped
"@ | Set-Content -Path $gatewayCompose -Encoding UTF8
}

# ======================
# App integration layer (Laravel .env)
# ======================
Write-Title "Linking Laravel to free-claude + RAG"
$laravelEnvPath = Join-Path $laravelPath ".env"
Ensure-LineInEnv $laravelEnvPath "FREE_CLAUDE_BASE_URL" ('"' + "http://127.0.0.1:$proxyPort" + '"')
Ensure-LineInEnv $laravelEnvPath "FREE_CLAUDE_AUTH_TOKEN" ('"' + $proxyToken + '"')
Ensure-LineInEnv $laravelEnvPath "QDRANT_URL" '"http://127.0.0.1:6333"'
if ($enableRedis) { Ensure-LineInEnv $laravelEnvPath "REDIS_HOST" '"127.0.0.1"' }
if ($enablePostgres) { Ensure-LineInEnv $laravelEnvPath "PG_HOST" '"127.0.0.1"' }

# ======================
# DONE
# ======================
Write-Title "DONE"

Write-Info "Root:      $rootDir"
Write-Info "Laravel:   $laravelPath"
Write-Info "Proxy:     $proxyPath"
Write-Info "Stack:     $stackDir"
Write-Info ""

Write-Info "START (in 2-4 terminals):"
Write-Host ("1) Laravel:   cd `"{0}`" ; php artisan serve --host 0.0.0.0 --port {1}" -f $laravelPath, $laravelPort) -ForegroundColor White

if ($freeClaudeRuntimeIdx -eq 0) {
  Write-Host ("2) Proxy:     cd `"{0}`" ; uv run uvicorn server:app --host 0.0.0.0 --port {1}" -f $proxyPath, $proxyPort) -ForegroundColor White
} else {
  Write-Host ("2) Proxy:     cd `"{0}`" ; docker compose -f docker-compose.app.yml up -d --build" -f $proxyPath) -ForegroundColor White
}

$llComposePath = Join-Path $stackDir "docker-compose.llamacpp.yml"
if (Test-Path $llComposePath) {
  Write-Host ("3) llama.cpp: cd `"{0}`" ; docker compose -f docker-compose.llamacpp.yml up -d" -f $stackDir) -ForegroundColor White
}

$ragComposePath = Join-Path $stackDir "docker-compose.rag.yml"
if (Test-Path $ragComposePath) {
  Write-Host ("4) RAG:       cd `"{0}`" ; docker compose -f docker-compose.rag.yml up -d" -f $stackDir) -ForegroundColor White
}

Write-Host ("5) Gateway:   cd `"{0}`" ; docker compose -f docker-compose.gateway.yml up -d" -f $stackDir) -ForegroundColor White

Write-Info ""
Write-Info ("URLs:")
Write-Info ("  Laravel UI : https://{0}:{1}" -f $domain, $httpsPort)
Write-Info ("  Proxy API  : https://proxy.{0}:{1}" -f $domain, $httpsPort)
Write-Info ("  Traefik    : http://localhost:8080")
Write-Info ""

if ($tlsIdx -eq 1) {
  Write-Warn "PUBLIC MODE CHECKLIST:"
  Write-Warn "  - No-IP: set $domain to your public IP"
  Write-Warn "  - Router: forward TCP 80 and 443 -> this PC"
  Write-Warn "  - Firewall: allow inbound 80/443"
  Write-Warn "  - Keep ANTHROPIC_AUTH_TOKEN enabled"
} else {
  Write-Warn "LOCAL/LAN TLS:"
  Write-Warn ("  - Share/Trust this CA cert on each teammate machine: {0}" -f (Join-Path $stackDir "certs\ca.crt"))
}
