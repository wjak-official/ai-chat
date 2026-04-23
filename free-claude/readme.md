
# 🚀 Free‑Claude Full Stack Installer  
### **Laravel + Filament + free‑claude‑code + RAG + TLS Gateway + Optional llama.cpp**

A **zero‑cost**, **one‑click**, **AIO Windows installer** that provisions a complete modern AI‑powered full‑stack environment:

- **Laravel (latest)** with **Filament Admin**
- **free‑claude‑code** proxy (provider‑selectable)
- **Optional llama.cpp server** (Docker‑based, with optional GGUF model download/copy)
- **Optional RAG stack** (Qdrant + optional Redis/Postgres)
- **Traefik TLS gateway**  
  - Local/LAN mode → OpenSSL local CA  
  - Public mode → Let’s Encrypt (ACME HTTP‑01)

This installer is designed for **developers**, **self‑hosters**, and **teams** who want a **secure**, **modular**, and **production‑grade** AI stack with minimal effort.

---

## 📦 Contents

```
free-claude/
 ├── aio-installer.ps1
 ├── free-claude-code/
 ├── laravel-admin/
 └── stack/
      ├── docker-compose.gateway.yml
      ├── docker-compose.rag.yml
      ├── docker-compose.llamacpp.yml
      ├── traefik/
      ├── certs/ or acme/
      └── models/
```

---

# 🧰 1. Features Overview

## **1. Laravel + Filament Admin**
- Latest Laravel version
- Pre‑configured Filament Admin Panel
- Ready for API integration with free‑claude‑code

## **2. free‑claude‑code Proxy**
- Provider‑selectable (Anthropic, OpenAI‑compatible, etc.)
- Native mode (Uvicorn) or Docker mode
- Secure reverse‑proxy routing via Traefik

## **3. Optional llama.cpp Server**
- Dockerized llama.cpp runtime
- Auto‑copy or auto‑download GGUF models into `/models`
- Exposes HTTP API for local inference

## **4. Optional RAG Stack**
- Qdrant vector DB
- Optional Redis or Postgres
- Docker‑compose modularity

## **5. Traefik TLS Gateway**
- Local CA mode (OpenSSL)
- Public mode (Let’s Encrypt)
- Automatic routing:
  - `https://<domain>` → Laravel
  - `https://proxy.<domain>` → free‑claude‑code
  - Local dashboard → `http://localhost:8080`

---

# ⚙️ 2. Installation

## **Prerequisites**
- Windows 10/11
- PowerShell (Run as Administrator)
- Docker Desktop (if using llama.cpp or RAG)
- ANTHROPIC_AUTH_TOKEN (for proxy)

---

## **Run the Installer**

From the `free-claude/` folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\aio-installer.ps1
```

The installer will:

- Ask for a **RootDir**
- Create a full stack inside it
- Generate TLS certificates (local mode)
- Prepare Docker stacks
- Clone/update required repos
- Configure environment files

---

# 📁 3. Output Structure (After Install)

Inside your chosen **RootDir**:

### **Laravel App**
```
<RootDir>/laravel-admin/
```

### **free‑claude‑code Proxy**
```
<RootDir>/free-claude-code/
```

### **Docker Stack**
```
<RootDir>/stack/
 ├── docker-compose.gateway.yml
 ├── docker-compose.rag.yml
 ├── docker-compose.llamacpp.yml
 ├── traefik/
 ├── certs/ or acme/
 └── models/
```

---

# ▶️ 4. Starting Services

## **Laravel**
```powershell
cd <RootDir>\laravel-admin
php artisan serve --host 0.0.0.0 --port 8000
```

## **free‑claude‑code Proxy**

### Native mode:
```powershell
cd <RootDir>\free-claude-code
uv run uvicorn server:app --host 0.0.0.0 --port 8082
```

### Docker mode:
```powershell
cd <RootDir>\free-claude-code
docker compose -f docker-compose.app.yml up -d --build
```

## **llama.cpp (optional)**
```powershell
cd <RootDir>\stack
docker compose -f docker-compose.llamacpp.yml up -d
```

## **RAG Stack (optional)**
```powershell
cd <RootDir>\stack
docker compose -f docker-compose.rag.yml up -d
```

## **TLS Gateway**
```powershell
cd <RootDir>\stack
docker compose -f docker-compose.gateway.yml up -d
```

---

# 🌐 5. URLs

| Service | URL |
|--------|-----|
| **Laravel UI** | `https://<domain>` |
| **free‑claude‑code Proxy** | `https://proxy.<domain>` |
| **Traefik Dashboard (local only)** | `http://localhost:8080` |

---

# 🔐 6. TLS Modes

## **Local/LAN Mode (OpenSSL CA)**

Installer generates:

```
<RootDir>\stack\certs\ca.crt
```

Each teammate must import this CA into:

- Windows Trusted Root Store  
- Browser trust store

---

## **Public Mode (Let’s Encrypt)**

### Requirements (outside the script):

- A **No‑IP** hostname pointing to your public IP
- Router forwards:
  - TCP **80 → Windows machine**
  - TCP **443 → Windows machine**
- Windows Firewall allows inbound 80/443
- Valid **ANTHROPIC_AUTH_TOKEN**

---

# 🧱 7. Architecture Diagram

```
                   ┌──────────────────────────────┐
                   │          Traefik TLS          │
                   │  (Local CA or Let's Encrypt)  │
                   └──────────────┬───────────────┘
                                  │
         ┌────────────────────────┼────────────────────────┐
         │                        │                        │
 ┌──────────────┐        ┌────────────────┐       ┌─────────────────┐
 │ Laravel App  │        │ free-claude    │       │  llama.cpp       │
 │ (Filament)   │        │ Proxy API      │       │  (optional)      │
 └──────────────┘        └────────────────┘       └─────────────────┘
                                  │
                                  │
                         ┌────────────────┐
                         │   RAG Stack    │
                         │ Qdrant + DBs   │
                         └────────────────┘
```

---

# 🧪 8. Development Notes

The installer script includes:

- Dynamic environment generation  
- Provider selection logic  
- Docker stack auto‑generation  
- Model directory provisioning  
- TLS automation  
- Error handling and rollback routines  

---

# 📝 9. Troubleshooting

### **Docker fails to start**
- Ensure Docker Desktop is running
- Enable WSL2 backend

### **TLS errors**
- Re‑import `ca.crt`
- Clear browser cache
- Ensure ports 80/443 are not used by IIS, WAMP, Skype, etc.

### **Proxy not responding**
- Check `ANTHROPIC_AUTH_TOKEN`
- Verify Traefik routing rules

---

# ❤️ 10. Contributing

PRs, issues, and enhancements are welcome.  
This project aims to make **self‑hosted AI development accessible to everyone**.

---

# 📜 License

MIT — free for personal and commercial use.
