# AI Chat - Quick Start Guide

## Prerequisites Setup

### 1. Install Ollama

**macOS / Linux:**
```bash
curl https://ollama.ai/install.sh | sh
```

**Windows:**
Download from https://ollama.ai/download

### 2. Pull AI Models

```bash
# Recommended models
ollama pull llama3.1:8b
ollama pull mistral:7b

# Optional lighter models
ollama pull phi3:mini
ollama pull gemma:2b

# For RAG embeddings
ollama pull all-minilm
```

### 3. Verify Ollama is Running

```bash
ollama list
# Should show your installed models

curl http://localhost:11434/api/tags
# Should return JSON with models
```

## Quick Start

### 1. Clone and Install

```bash
git clone https://github.com/wjak-official/ai-chat.git
cd ai-chat
npm install
```

### 2. Run Development Server

```bash
npm run dev
```

Open http://localhost:5173 in your browser!

## Optional: Enable RAG (Website Knowledge)

### 1. Create Supabase Project

1. Go to https://supabase.com and create a free account
2. Create a new project
3. Wait for the project to be ready (~2 minutes)

### 2. Set Up Database

1. Go to SQL Editor in Supabase dashboard
2. Copy the contents of `supabase-setup.sql`
3. Paste and run the SQL

### 3. Configure Environment Variables

Create a `.env` file:

```env
VITE_OLLAMA_API_URL=http://localhost:11434
VITE_SUPABASE_URL=your-supabase-project-url
VITE_SUPABASE_ANON_KEY=your-supabase-anon-key
```

Get your Supabase credentials from:
- Project Settings → API → Project URL
- Project Settings → API → anon/public key

### 4. Test RAG

The application will automatically use RAG if configured. You can index website content programmatically.

## Deploy to Vercel

### 1. Install Vercel CLI

```bash
npm install -g vercel
```

### 2. Deploy

```bash
npm run build  # Test build locally first
vercel          # Deploy to Vercel
```

### 3. Configure Environment Variables

In Vercel Dashboard → Settings → Environment Variables:

```
VITE_OLLAMA_API_URL=your-ollama-server-url
VITE_SUPABASE_URL=your-supabase-url
VITE_SUPABASE_ANON_KEY=your-supabase-key
```

**Note:** For production, you'll need to host Ollama on a server accessible from Vercel.

## Embed the Widget

Add to any website:

```html
<script src="https://your-domain.vercel.app/widget/ai-chat-widget.js"></script>
<ai-chat-widget 
  api-url="https://your-domain.vercel.app"
  personality="customer-support"
  position="bottom-right"
></ai-chat-widget>
```

## Troubleshooting

### "Not connected to Ollama"

1. Ensure Ollama is running: `ollama list`
2. Check the API endpoint: `curl http://localhost:11434/api/tags`
3. Verify CORS if accessing from browser

### Models not appearing

1. Pull models: `ollama pull llama3.1:8b`
2. Restart Ollama
3. Refresh the application

### Build errors

1. Clear node_modules: `rm -rf node_modules package-lock.json`
2. Reinstall: `npm install`
3. Try building: `npm run build`

## Learn More

- [Full Documentation](README.md)
- [Ollama Documentation](https://ollama.ai)
- [Supabase Documentation](https://supabase.com/docs)
- [Vercel Documentation](https://vercel.com/docs)

## Support

- Open an issue on GitHub
- Check the documentation
- Review example files in `/public`
