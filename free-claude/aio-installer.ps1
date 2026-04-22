<#
.SYNOPSIS
  Interactive Windows installer for Alishahryar1/free-claude-code with:
    - Provider selection wizard (NVIDIA NIM / OpenRouter / LM Studio / llama.cpp)
    - Two runtime paths for prerequisites:
        (A) Native Windows Python + pip + uv (repo-recommended)
        (B) Dockerized runtime (keeps Python/uv off host) + optional Dockerized Git
    - HTTPS for team sharing:
        - "Local/LAN" mode: local CA + certs (OpenSSL) for localhost + domain
        - "Public exposure" mode: Traefik + Let's Encrypt (ACME) (secure defaults)
    - No-IP domain support: myvipsb.sytes.net

.NOTES / LIMITATIONS
  - This script configures the proxy stack; your *model/provider* is external:
      - NIM/OpenRouter need API keys
      - LM Studio or llama.cpp need a local server endpoint
  - For "Public exposure" ACME HTTP-01 requires inbound TCP 80/443 reachable.
    For dynamic DNS/No-IP behind NAT, you must configure router port-forwarding.

USAGE
  powershell -ExecutionPolicy Bypass -File .\install.ps1

#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ----------------------------
# UI helpers
# ----------------------------
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

# ----------------------------
# Command helpers
# ----------------------------
function Test-Command([string]$Name) {
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}
function Ensure-Directory([string]$Path) {
  if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path | Out-Null }
}
function Can-UseWinget { Test-Command "winget" }

function Install-WithWinget([string]$Id, [string]$Name) {
  if (-not (Can-UseWinget)) {
    Write-Warn "winget not found; cannot auto-install $Name."
    return $false
  }
  if (-not (Prompt-YesNo "Install $Name using winget now?" $true)) { return $false }

  Write-Info "Running: winget install -e --id $Id"
  winget install -e --id $Id
  return $true
}

# ----------------------------
# Prereq checkers (native path)
# ----------------------------
function Ensure-Git-Native {
  if (Test-Command "git") { return $true }
  Write-Warn "Git not found."
  $ok = Install-WithWinget -Id "Git.Git" -Name "Git"
  if ($ok -and (Test-Command "git")) { return $true }
  Write-Info "Manual Git install: https://git-scm.com/download/win"
  return $false
}
function Ensure-Python-Native {
  if (Test-Command "python") { return $true }
  Write-Warn "Python not found."
  $ok = Install-WithWinget -Id "Python.Python.3.12" -Name "Python 3"
  if ($ok -and (Test-Command "python")) { return $true }
  Write-Info "Manual Python install: https://www.python.org/downloads/windows/"
  return $false
}
function Ensure-Pip-Native {
  try { python -m pip --version | Out-Null; return $true } catch { return $false }
}
function Ensure-Uv-Native {
  if (Test-Command "uv") { return $true }
  if (-not (Prompt-YesNo "Install uv on Windows using pip now? (pip install uv)" $true)) { return $false }
  python -m pip install --upgrade pip
  python -m pip install --upgrade uv
  return (Test-Command "uv")
}

# ----------------------------
# Docker checks
# ----------------------------
function Ensure-DockerDesktop {
  if (-not (Test-Command "docker")) { return $false }
  try { docker version | Out-Null; return $true } catch { return $false }
}

# ----------------------------
# OpenSSL + certs (local CA path)
# ----------------------------
function Ensure-OpenSSL {
  if (Test-Command "openssl") { return $true }
  Write-Warn "OpenSSL not found in PATH."
  Write-Info "Recommended: winget install -e --id ShiningLight.OpenSSL"
  if (Prompt-YesNo "Install OpenSSL using winget now?" $true) {
    if (Can-UseWinget) { winget install -e --id ShiningLight.OpenSSL }
  }
  return (Test-Command "openssl")
}

function New-LocalDevCertificates(
  [string]$CertDir,
  [string[]]$SANs,
  [int]$DaysValid = 825,
  [string]$CommonName = "free-claude-code"
) {
  Ensure-Directory $CertDir

  $caKey   = Join-Path $CertDir "ca.key"
  $caCrt   = Join-Path $CertDir "ca.crt"
  $leafKey = Join-Path $CertDir "tls.key"
  $leafCrt = Join-Path $CertDir "tls.crt"
  $leafCsr = Join-Path $CertDir "tls.csr"
  $extFile = Join-Path $CertDir "tls.ext"

  if ((Test-Path $caKey) -and (Test-Path $caCrt) -and (Test-Path $leafKey) -and (Test-Path $leafCrt)) {
    Write-Info "Existing certs found in $CertDir. Skipping generation."
    return @{ CaCrt=$caCrt; LeafCrt=$leafCrt; LeafKey=$leafKey }
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

  Write-Info "Generating local CA..."
  & openssl genrsa -out $caKey 4096 | Out-Null
  & openssl req -x509 -new -nodes -key $caKey -sha256 -days $DaysValid -subj "/CN=$CommonName Local CA" -out $caCrt | Out-Null

  Write-Info "Generating leaf cert..."
  & openssl genrsa -out $leafKey 2048 | Out-Null
  & openssl req -new -key $leafKey -subj "/CN=$($SANs[0])" -out $leafCsr | Out-Null
  & openssl x509 -req -in $leafCsr -CA $caCrt -CAkey $caKey -CAcreateserial -out $leafCrt -days $DaysValid -sha256 -extfile $extFile | Out-Null

  Write-Info "Generated certs under $CertDir"
  return @{ CaCrt=$caCrt; LeafCrt=$leafCrt; LeafKey=$leafKey }
}

function Offer-Trust-CA([string]$CaCertPath) {
  Write-Info "Optional: import CA cert into CurrentUser Trusted Root store (recommended for team usage on each machine)."
  if (-not (Prompt-YesNo "Trust the local CA certificate on THIS Windows user account now?" $true)) { return }
  try {
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CaCertPath)
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root","CurrentUser")
    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    $store.Add($cert)
    $store.Close()
    Write-Info "CA imported successfully."
  } catch {
    Write-Warn "Automatic import failed. You can manually import: $CaCertPath"
    Write-Warn $_.Exception.Message
  }
}

# ----------------------------
# Provider wizard -> env requirements
# ----------------------------
function Read-Secret([string]$Prompt) {
  $secure = Read-Host $Prompt -AsSecureString
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
  finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

function Ensure-LineInEnv([string]$EnvPath, [string]$Key, [string]$Value, [bool]$Overwrite = $false) {
  if (-not (Test-Path $EnvPath)) { New-Item -ItemType File -Path $EnvPath | Out-Null }
  $raw = Get-Content $EnvPath -Raw
  $pattern = "(?m)^\s*{0}\s*=" -f [regex]::Escape($Key)
  if ($raw -match $pattern) {
    if ($Overwrite) {
      $lines = Get-Content $EnvPath
      $out = foreach ($l in $lines) {
        if ($l -match "^\s*$([regex]::Escape($Key))\s*=") { "$Key=$Value" } else { $l }
      }
      Set-Content -Path $EnvPath -Value $out -Encoding UTF8
      Write-Info "Updated $Key in .env"
    } else {
      Write-Info "$Key already exists in .env (leaving as-is)."
    }
  } else {
    Add-Content -Path $EnvPath -Value "`n$Key=$Value" -Encoding UTF8
    Write-Info "Added $Key to .env"
  }
}

# ----------------------------
# Compose writer (proxy only; app can be native or container)
# ----------------------------
function Write-TraefikProxyFiles(
  [string]$RepoDir,
  [int]$HttpPort,
  [int]$HttpsPort,
  [string]$Domain,
  [string]$UpstreamUrl,
  [string]$TlsMode,   # "localca" or "letsencrypt"
  [string]$Email      # for ACME (letsencrypt)
) {
  $traefikDir = Join-Path $RepoDir "traefik"
  Ensure-Directory $traefikDir

  $staticPath = Join-Path $traefikDir "traefik.yml"
  $dynamicPath = Join-Path $traefikDir "dynamic.yml"

  if ($TlsMode -eq "letsencrypt") {
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
      email: "$Email"
      storage: /acme/acme.json
      httpChallenge:
        entryPoint: web
"@ | Set-Content -Path $staticPath -Encoding UTF8

@"
http:
  routers:
    fcc-http:
      rule: "Host(`${Domain}`) || Host(`localhost`)"
      entryPoints: [ "web" ]
      middlewares: [ "redirect-to-https" ]
      service: fcc-svc

    fcc-https:
      rule: "Host(`${Domain}`) || Host(`localhost`)"
      entryPoints: [ "websecure" ]
      tls:
        certResolver: le
      service: fcc-svc

  middlewares:
    redirect-to-https:
      redirectScheme:
        scheme: https
        permanent: true

  services:
    fcc-svc:
      loadBalancer:
        servers:
          - url: "$UpstreamUrl"
"@ | Set-Content -Path $dynamicPath -Encoding UTF8
  }
  else {
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
"@ | Set-Content -Path $staticPath -Encoding UTF8

@"
tls:
  certificates:
    - certFile: /certs/tls.crt
      keyFile: /certs/tls.key

http:
  routers:
    fcc-http:
      rule: "Host(`${Domain}`) || Host(`localhost`)"
      entryPoints: [ "web" ]
      middlewares: [ "redirect-to-https" ]
      service: fcc-svc

    fcc-https:
      rule: "Host(`${Domain}`) || Host(`localhost`)"
      entryPoints: [ "websecure" ]
      tls: {}
      service: fcc-svc

  middlewares:
    redirect-to-https:
      redirectScheme:
        scheme: https
        permanent: false

  services:
    fcc-svc:
      loadBalancer:
        servers:
          - url: "$UpstreamUrl"
"@ | Set-Content -Path $dynamicPath -Encoding UTF8
  }

  $composePath = Join-Path $RepoDir "docker-compose.proxy.yml"

  $compose = @"
services:
  traefik:
    image: traefik:v3.0
    command:
      - "--configFile=/etc/traefik/traefik.yml"
    ports:
      - "${HttpPort}:80"
      - "${HttpsPort}:443"
      - "127.0.0.1:8080:8080"
    volumes:
      - "./traefik/traefik.yml:/etc/traefik/traefik.yml:ro"
      - "./traefik/dynamic.yml:/etc/traefik/dynamic.yml:ro"
"@

  if ($TlsMode -eq "letsencrypt") {
    $compose += @"
      - "./acme:/acme"
"@
  } else {
    $compose += @"
      - "./certs:/certs:ro"
"@
  }

  $compose += @"
    restart: unless-stopped
"@

  Set-Content -Path $composePath -Value $compose -Encoding UTF8

  Write-Info "Wrote: $staticPath"
  Write-Info "Wrote: $dynamicPath"
  Write-Info "Wrote: $composePath"
}

# ----------------------------
# Main
# ----------------------------
Write-Title "Free Claude Code - Secure Setup Wizard (Windows)"

$repoUrl = "https://github.com/Alishahryar1/free-claude-code.git"
$defaultDir = Join-Path (Get-Location) "free-claude-code"

# Decide runtime approach
$runtimeChoice = Prompt-Choice `
  "How do you want to run the proxy runtime prerequisites (Git/Python/uv)?" `
  @(
    "Native on Windows (recommended by repo; simplest)",
    "Dockerized runtime (minimize host clutter; run proxy inside container)",
    "Hybrid: Native proxy, Docker only for HTTPS reverse proxy (recommended for team HTTPS)"
  ) `
  2

# Choose exposure/security mode
$exposureChoice = Prompt-Choice `
  "Where will this be used?" `
  @(
    "Local/LAN sharing (team on same network/VPN): HTTPS via local CA (self-managed)",
    "Public internet exposure (hardened): HTTPS via Let's Encrypt + strict redirects"
  ) `
  0

$domain = Prompt-Text "Primary domain (No-IP hostname) for HTTPS" "myvipsb.sytes.net"
$repoDir = Prompt-Text "Target directory for the repo" $defaultDir

# Repo uses 8082 in README
$port = Prompt-Int "Proxy port (repo default)" 8082

# Provider wizard
Write-Title "Provider selection"
$providerIdx = Prompt-Choice `
  "Pick the provider your .env will target (this script will ask the minimal required fields):" `
  @(
    "OpenRouter (cloud; requires API key)",
    "NVIDIA NIM (cloud; requires API key + base URL)",
    "LM Studio (local server; requires base URL, e.g. http://localhost:1234/v1)",
    "llama.cpp server (local; requires base URL, e.g. http://localhost:8080/v1)"
  ) `
  0

# Optional auth token used by this proxy (repo mentions optional)
Write-Title "Proxy authentication (optional)"
$enableAuth = Prompt-YesNo "Enable auth token for the proxy?" $true
$anthropicToken = ""
if ($enableAuth) {
  $anthropicToken = Read-Secret "Enter ANTHROPIC_AUTH_TOKEN to require (stored in .env; not echoed)"
}

# Prereqs (Git/Python/uv) depending on mode
Write-Title "Prerequisites"

if ($runtimeChoice -eq 0 -or $runtimeChoice -eq 2) {
  $okGit = Ensure-Git-Native
  $okPy  = Ensure-Python-Native
  if (-not ($okGit -and $okPy)) { throw "Missing prerequisites. Fix and re-run." }
  if (-not (Ensure-Pip-Native)) { throw "pip missing for python. Fix and re-run." }
  if (-not (Ensure-Uv-Native)) { throw "uv missing. Fix and re-run." }
} else {
  # Dockerized runtime path
  if (-not (Ensure-DockerDesktop)) {
    Write-Err "Docker Desktop is required for Dockerized runtime mode."
    Write-Info "Install Docker Desktop: https://www.docker.com/products/docker-desktop/"
    throw "Docker not ready."
  }
  Write-Info "Docker Desktop is available."
  # Git can be skipped if user has repo already; we still prefer to clone via git if present.
  if (-not (Test-Command "git")) {
    Write-Warn "Git not found; Dockerized runtime mode can still work if you download zip manually."
  }
}

# Clone/update repo
Write-Title "Clone / update repository"
if (-not (Test-Path $repoDir)) {
  if (Test-Command "git") {
    Write-Info "Cloning $repoUrl -> $repoDir"
    git clone $repoUrl $repoDir
  } else {
    throw "Git not available to clone. Install Git or manually download the repo to $repoDir, then re-run."
  }
} else {
  Write-Info "Repo directory exists."
  if (Test-Command "git" -and (Prompt-YesNo "Run git pull in $repoDir?" $true)) {
    Push-Location $repoDir
    try { git pull } finally { Pop-Location }
  }
}

# .env setup
Write-Title ".env configuration"
$envExample = Join-Path $repoDir ".env.example"
$envFile    = Join-Path $repoDir ".env"

if ((Test-Path $envExample) -and -not (Test-Path $envFile)) {
  Copy-Item $envExample $envFile
  Write-Info "Created .env from .env.example"
} elseif (-not (Test-Path $envFile)) {
  New-Item -ItemType File -Path $envFile | Out-Null
  Write-Warn "No .env.example found; created empty .env"
} else {
  Write-Info ".env already exists; leaving as-is."
}

# Apply provider fields (minimal + safe; do not print secrets)
switch ($providerIdx) {
  0 { # OpenRouter
    Write-Title "OpenRouter config"
    $key = Read-Secret "Enter OPENROUTER_API_KEY (stored in .env; not echoed)"
    Ensure-LineInEnv $envFile "OPENROUTER_API_KEY" $key $false
    # Some setups also use base url; we add a sensible default but don't overwrite.
    Ensure-LineInEnv $envFile "OPENROUTER_BASE_URL" "https://openrouter.ai/api/v1" $false
    Write-Info "OpenRouter fields written. Ensure any model name fields required by the repo are set in .env."
  }
  1 { # NVIDIA NIM
    Write-Title "NVIDIA NIM config"
    $nimKey = Read-Secret "Enter NIM_API_KEY (stored in .env; not echoed)"
    $nimBase = Prompt-Text "Enter NIM base URL (from your NIM endpoint docs)" "https://integrate.api.nvidia.com/v1"
    Ensure-LineInEnv $envFile "NIM_API_KEY" $nimKey $false
    Ensure-LineInEnv $envFile "NIM_BASE_URL" $nimBase $false
    Write-Info "NIM fields written. Ensure any model/deployment id fields required by the repo are set in .env."
  }
  2 { # LM Studio
    Write-Title "LM Studio config"
    $lmBase = Prompt-Text "LM Studio OpenAI-compatible base URL" "http://localhost:1234/v1"
    Ensure-LineInEnv $envFile "LMSTUDIO_BASE_URL" $lmBase $false
    Write-Info "LM Studio base URL written. Make sure LM Studio server is running."
  }
  3 { # llama.cpp
    Write-Title "llama.cpp server config"
    $llBase = Prompt-Text "llama.cpp OpenAI-compatible base URL" "http://localhost:8080/v1"
    Ensure-LineInEnv $envFile "LLAMACPP_BASE_URL" $llBase $false
    Write-Info "llama.cpp base URL written. Make sure llama.cpp server is running."
  }
}

if ($enableAuth) {
  Ensure-LineInEnv $envFile "ANTHROPIC_AUTH_TOKEN" $anthropicToken $false
}

# HTTPS decision tree
Write-Title "HTTPS (required for team sharing)"
$httpPort = Prompt-Int "HTTP port for reverse proxy (host)" 80
$httpsPort = Prompt-Int "HTTPS port for reverse proxy (host)" 443

if ($exposureChoice -eq 1) {
  Write-Title "Public exposure security checklist"
  Write-Warn "For public exposure you MUST do these outside the script:"
  Write-Info "  1) Ensure No-IP '$domain' points to your public IP"
  Write-Info "  2) Router port-forward TCP 80 and 443 -> this machine"
  Write-Info "  3) Keep Windows updated, restrict admin access, and consider running behind a VPN if possible"
  Write-Info "  4) Consider adding IP allowlists / authentication in front of the proxy"
}

# Start modes
$startNow = Prompt-YesNo "Start the stack now after configuration?" $true

# Compose proxy always (for HTTPS), upstream depends on runtime choice
# - If proxy runs native on Windows, upstream is host.docker.internal:$port
# - If proxy runs in docker, upstream is fcc:$port (service name)
$useProxyDocker = $true
if (-not (Ensure-DockerDesktop)) {
  Write-Err "Docker Desktop is required for HTTPS reverse proxy (Traefik) in this script."
  throw "Docker not ready."
}

# Prepare ACME directory if needed
if ($exposureChoice -eq 1) {
  $acmeDir = Join-Path $repoDir "acme"
  Ensure-Directory $acmeDir
  $acmeFile = Join-Path $acmeDir "acme.json"
  if (-not (Test-Path $acmeFile)) {
    New-Item -ItemType File -Path $acmeFile | Out-Null
  }
}

# Local CA certs if LAN mode
if ($exposureChoice -eq 0) {
  if (-not (Ensure-OpenSSL)) { throw "OpenSSL is required for local CA TLS mode." }
  $certDir = Join-Path $repoDir "certs"
  $certs = New-LocalDevCertificates -CertDir $certDir -SANs @($domain,"localhost","127.0.0.1") -CommonName $domain
  Offer-Trust-CA -CaCertPath $certs.CaCrt
  Write-Warn "Each teammate must trust your CA (or you must distribute a trusted cert)."
  Write-Info "CA certificate file to share (securely): $($certs.CaCrt)"
}

# If runtime is Dockerized, write a compose that runs the proxy app container too.
# Otherwise, proxy app runs native; Traefik routes to host.docker.internal.
Write-Title "Writing reverse proxy config (Traefik)"

$upstreamUrl = ""
$proxyAppComposePath = Join-Path $repoDir "docker-compose.app.yml"
if ($runtimeChoice -eq 1) {
  # Dockerized runtime: run the Python app in Docker using a small Dockerfile injected by this script.
  # This avoids installing Python/uv on host.
  Write-Title "Dockerized runtime: creating Dockerfile.runtime + compose"
  $dockerfileRuntime = Join-Path $repoDir "Dockerfile.runtime"

@"
FROM python:3.12-slim

WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# install uv + runtime deps
RUN python -m pip install --upgrade pip && pip install --no-cache-dir uv

# copy repo
COPY . /app

# expose default port
EXPOSE ${port}

# run the repo-recommended command
CMD ["uv", "run", "uvicorn", "server:app", "--host", "0.0.0.0", "--port", "${port}"]
"@ | Set-Content -Path $dockerfileRuntime -Encoding UTF8

@"
services:
  fcc:
    build:
      context: .
      dockerfile: Dockerfile.runtime
    env_file:
      - ./.env
    ports:
      - "${port}:${port}"
    restart: unless-stopped
"@ | Set-Content -Path $proxyAppComposePath -Encoding UTF8

  Write-Info "Wrote: $dockerfileRuntime"
  Write-Info "Wrote: $proxyAppComposePath"
  $upstreamUrl = "http://host.docker.internal:$port"
  # Even though container publishes port, Traefik can still go host.docker.internal reliably on Windows.
} else {
  # Native or Hybrid: app runs on Windows via uv; Traefik routes to host
  $upstreamUrl = "http://host.docker.internal:$port"
}

# TLS mode selection for Traefik config
if ($exposureChoice -eq 1) {
  $email = Prompt-Text "Email for Let's Encrypt ACME registration (required)" ""
  if ([string]::IsNullOrWhiteSpace($email)) { throw "ACME email is required for public exposure mode." }
  Write-TraefikProxyFiles -RepoDir $repoDir -HttpPort $httpPort -HttpsPort $httpsPort -Domain $domain -UpstreamUrl $upstreamUrl -TlsMode "letsencrypt" -Email $email
} else {
  Write-TraefikProxyFiles -RepoDir $repoDir -HttpPort $httpPort -HttpsPort $httpsPort -Domain $domain -UpstreamUrl $upstreamUrl -TlsMode "localca" -Email ""
}

# Start instructions / start now
Write-Title "Run instructions"

if ($runtimeChoice -eq 0 -or $runtimeChoice -eq 2) {
  Write-Info "Terminal A (Windows) - run proxy (repo recommended):"
  Write-Host ("  cd `"{0}`"" -f $repoDir) -ForegroundColor White
  Write-Host ("  uv run uvicorn server:app --host 0.0.0.0 --port {0}" -f $port) -ForegroundColor White
} else {
  Write-Info "Dockerized runtime will run the proxy app container."
}

Write-Info "Terminal B (Docker) - run HTTPS reverse proxy:"
Write-Host ("  cd `"{0}`"" -f $repoDir) -ForegroundColor White
Write-Host ("  docker compose -f docker-compose.proxy.yml up -d" ) -ForegroundColor White
if ($runtimeChoice -eq 1) {
  Write-Host ("  docker compose -f docker-compose.app.yml up -d --build") -ForegroundColor White
}

Write-Info "Access endpoints:"
Write-Info ("  - https://localhost:{0}" -f $httpsPort)
Write-Info ("  - https://{0}:{1}  (requires DNS/hosts/router setup)" -f $domain, $httpsPort)
Write-Info "Traefik dashboard (localhost only): http://localhost:8080"

Write-Title "Claude Code env vars (PowerShell)"
Write-Info "Claude Code should point to the proxy base URL."
Write-Host ('$env:ANTHROPIC_BASE_URL="https://localhost"; claude') -ForegroundColor White
if ($enableAuth) {
  Write-Host ('$env:ANTHROPIC_AUTH_TOKEN="(your token)"; $env:ANTHROPIC_BASE_URL="https://localhost"; claude') -ForegroundColor White
}

if ($startNow) {
  Write-Title "Starting services"
  Push-Location $repoDir
  try {
    if ($runtimeChoice -eq 1) {
      Write-Info "docker compose -f docker-compose.app.yml up -d --build"
      docker compose -f docker-compose.app.yml up -d --build
    }

    Write-Info "docker compose -f docker-compose.proxy.yml up -d"
    docker compose -f docker-compose.proxy.yml up -d

    Write-Info "docker compose -f docker-compose.proxy.yml ps"
    docker compose -f docker-compose.proxy.yml ps
  } finally {
    Pop-Location
  }
}

Write-Title "Security notes (high-level)"
if ($exposureChoice -eq 1) {
  Write-Warn "PUBLIC MODE ENABLED:"
  Write-Info "  - Ensure firewall rules are strict; only 80/443 needed inbound."
  Write-Info "  - Consider adding an auth layer in front of the proxy (or IP allowlists) if this exposes paid API keys."
  Write-Info "  - Treat the machine as internet-facing; keep it patched."
} else {
  Write-Info "LAN MODE:"
  Write-Info "  - Teammates must trust your CA cert (certs/ca.crt) on their devices to avoid browser warnings."
}

Write-Title "Done"
Write-Info "If you want this to be 100% exact to the repo's supported env keys, paste your .env.example here (redact secrets) and I’ll map the provider prompts to the exact variable names it uses."
