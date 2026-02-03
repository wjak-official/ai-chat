# AI Chat Tool 💬

> An AI-powered chat application with customizable personalities, embeddable widget, and visitor behavior tracking. Built with React, Vite, Tailwind CSS, and powered by **Ollama** (local AI) or **Google Gemini** (cloud AI) - you choose!

![AI Chat Interface](https://github.com/user-attachments/assets/68a57367-a5c3-445c-8ca3-390f04bf5a93)

## 🌟 Features

### Core Capabilities
- **Dual AI Provider Support** - Choose between Ollama (local/free) or Google Gemini (cloud-based)
- **8 Customizable AI Personalities** - Friendly Assistant, Professional Advisor, Creative Writer, Tech Expert, Life Coach, Data Analyst, Customer Support, Educator
- **Multiple AI Models** 
  - **Ollama**: Llama 3.1, Mistral 7B, Phi-3 Mini, Gemma 2B
  - **Gemini**: Gemini 1.5 Flash, Gemini 1.5 Pro, Gemini Pro
- **RAG-Powered Knowledge** - Optional Supabase integration for vector embeddings and contextual responses
- **Responsive Design** - Inspired by iMessage and WhatsApp, works beautifully on all devices
- **Embeddable Widget** - Easy-to-embed Web Component for any website
- **Visitor Analytics** - Track user behavior, interactions, and engagement
- **Flexible Deployment** - 100% free with Ollama, or use Gemini with your API key

### UI Features
- Streaming responses with real-time updates
- Message history with timestamps
- Multiple personality selection
- AI Provider switching (Ollama ↔ Gemini)
- Model switching
- Connection status monitoring
- Keyboard shortcuts (Enter to send, Shift+Enter for newline)
- Smooth animations and transitions
- Mobile-responsive design

![Personality Selection](https://github.com/user-attachments/assets/04d1b51a-15ff-4ecf-8824-9db3371bbf04)

## 🚀 Quick Start

### Option 1: Ollama (Local AI - 100% Free)

#### Prerequisites

1. **Node.js** (v18 or higher)
2. **Ollama** installed and running locally

```bash
# Install Ollama (macOS/Linux)
curl https://ollama.ai/install.sh | sh

# Pull a model
ollama pull llama3.1:8b
```

### Option 2: Google Gemini (Cloud AI)

#### Prerequisites

1. **Node.js** (v18 or higher)
2. **Gemini API Key** from [Google AI Studio](https://makersuite.google.com/app/apikey)

### Installation

```bash
# Clone the repository
git clone https://github.com/wjak-official/ai-chat.git
cd ai-chat

# Install dependencies
npm install

# Start development server
npm run dev
```

Open http://localhost:5173 in your browser!

📖 For detailed setup instructions, see [QUICKSTART.md](QUICKSTART.md)

## 🎨 Usage

### Configuring AI Provider

The application supports two AI providers that you can switch between:

#### Using Ollama (Local AI)
1. Ensure Ollama is running on your machine
2. Open Settings
3. Select "Ollama" as your AI Provider
4. Choose your preferred model (Llama 3.1, Mistral, etc.)
5. Start chatting!

![Provider Selection](https://github.com/user-attachments/assets/0fbe1ef8-8e4d-4726-abda-7dca765aa57c)

#### Using Google Gemini (Cloud AI)
1. Get your API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Open Settings
3. Select "Gemini" as your AI Provider
4. Enter and save your API key
5. Choose your preferred Gemini model
6. Start chatting!

![Gemini Configuration](https://github.com/user-attachments/assets/74543ac1-34d2-424b-9abe-7f0465de0a1a)

### Standalone Application

The application provides a full-featured chat interface:

1. **Select a Personality** - Choose from 8 different AI personalities
2. **Configure AI Provider** - Choose between Ollama or Gemini
3. **Start Chatting** - Type your message and press Enter
4. **Switch Models** - Choose between different AI models
5. **Clear Chat** - Reset conversation history anytime

![Settings Panel](https://github.com/user-attachments/assets/14c760f5-034a-4265-88af-e20fd73c4384)

### Embeddable Widget

Add the chat widget to any website:

```html
<!-- Add to your HTML -->
<script src="https://your-domain.vercel.app/widget/ai-chat-widget.js"></script>
<ai-chat-widget 
  api-url="https://your-domain.vercel.app"
  personality="customer-support"
  position="bottom-right"
  auto-open="false"
  tracking="true"
></ai-chat-widget>
```

![Widget Demo](https://github.com/user-attachments/assets/70436ddd-7ec2-4af4-a036-bc677dca9cc7)

#### Widget Configuration

| Attribute | Options | Description |
|-----------|---------|-------------|
| `api-url` | URL | Your deployed chat application URL |
| `personality` | friendly-assistant, professional-advisor, tech-expert, customer-support, creative-writer, life-coach, data-analyst, educator | AI personality to use |
| `position` | bottom-right, bottom-left, top-right, top-left | Widget position on screen |
| `auto-open` | true, false | Automatically open widget after 2 seconds |
| `tracking` | true, false | Enable visitor behavior tracking |

## 📊 Analytics

The widget tracks visitor behavior and provides detailed analytics:

```javascript
// Access analytics data
const analytics = window.AIChatWidget.getAnalytics();
console.log(analytics);

// Returns:
// {
//   sessionId: "session_...",
//   events: [...],
//   summary: {
//     totalEvents: 45,
//     clicks: 12,
//     scrolls: 8,
//     widgetOpened: true
//   }
// }
```

### Tracked Events
- Page views and navigation
- User clicks and interactions
- Scroll behavior and depth
- Form submissions
- Widget open/close/minimize
- Chat messages sent/received
- Time spent on page

## 🤖 AI Models

### Ollama Models (Local AI)

| Model | Size | Description | Recommended |
|-------|------|-------------|-------------|
| **Llama 3.1 8B** | 4.7GB | Meta's powerful language model | ✅ Yes |
| **Mistral 7B** | 4.1GB | Fast and efficient model | ✅ Yes |
| **Phi-3 Mini** | 2.3GB | Microsoft's compact model | - |
| **Gemma 2B** | 1.4GB | Google's lightweight model | - |

#### Install Ollama Models

```bash
# Recommended models
ollama pull llama3.1:8b
ollama pull mistral:7b

# Lighter alternatives
ollama pull phi3:mini
ollama pull gemma:2b

# For RAG embeddings
ollama pull all-minilm
```

### Google Gemini Models (Cloud AI)

| Model | Context Window | Description | Recommended |
|-------|----------------|-------------|-------------|
| **Gemini 1.5 Flash** | 1M tokens | Fast and efficient multimodal model | ✅ Yes |
| **Gemini 1.5 Pro** | 2M tokens | Most capable multimodal model | ✅ Yes |
| **Gemini Pro** | 30K tokens | Best for text-based tasks | - |

#### Using Gemini

1. Get your API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Open Settings in the app
3. Select "Gemini" as AI Provider
4. Enter your API key
5. Choose a model and start chatting!

**Note**: Gemini API is free for up to 60 requests per minute. See [pricing](https://ai.google.dev/pricing) for details.

## 🗄️ RAG (Retrieval-Augmented Generation)

Enable website knowledge using Supabase for vector embeddings:

### 1. Create Supabase Project

1. Sign up at https://supabase.com (free tier)
2. Create a new project
3. Wait for initialization (~2 minutes)

### 2. Set Up Database

Run the SQL from `supabase-setup.sql` in Supabase SQL Editor:

```sql
-- Enables vector extension, creates tables, and sets up search functions
-- See supabase-setup.sql for full SQL
```

### 3. Configure Environment

Add to `.env`:

```env
VITE_SUPABASE_URL=your-supabase-project-url
VITE_SUPABASE_ANON_KEY=your-supabase-anon-key
```

### 4. Index Website Content

```javascript
import ragService from './src/services/rag';

// Index webpage content
await ragService.indexWebsiteContent(
  'https://yoursite.com/page',
  'Your page content here...',
  { title: 'Page Title', category: 'docs' }
);
```

The AI will now use this knowledge to provide contextual responses!

## 🎯 Personalities

### Available Personalities

1. **Friendly Assistant** 😊
   - Warm, approachable, and helpful
   - Great for general conversations

2. **Professional Advisor** 💼
   - Formal and strategic
   - Best for business inquiries

3. **Creative Writer** ✍️
   - Imaginative and expressive
   - Perfect for storytelling and creative tasks

4. **Tech Expert** 💻
   - Technical and detailed
   - Ideal for coding and technical questions

5. **Life Coach** 🌟
   - Supportive and motivational
   - Great for personal development

6. **Data Analyst** 📊
   - Analytical and data-driven
   - Best for insights and analysis

7. **Customer Support** 🎧
   - Patient and empathetic
   - Perfect for customer service

8. **Educator** 🎓
   - Teaching-focused and explanatory
   - Ideal for learning and education

### Create Custom Personalities

Edit `src/config/personalities.js`:

```javascript
{
  id: 'custom-personality',
  name: 'Custom Name',
  avatar: '🎭',
  description: 'A brief description',
  systemPrompt: 'Your detailed system prompt...',
  color: '#ff6b6b'
}
```

## 🚀 Deployment

### Deploy to Vercel

1. **Build the project**
   ```bash
   npm run build
   ```

2. **Deploy with Vercel CLI**
   ```bash
   npm install -g vercel
   vercel
   ```

3. **Set environment variables** in Vercel Dashboard:
   - `VITE_OLLAMA_API_URL` - Your Ollama server URL (if using Ollama)
   - `VITE_GEMINI_API_KEY` - Your Gemini API key (if using Gemini)
   - `VITE_SUPABASE_URL` - (Optional) Supabase project URL
   - `VITE_SUPABASE_ANON_KEY` - (Optional) Supabase anon key

### Alternative: Deploy via GitHub

1. Push to GitHub
2. Import project in Vercel dashboard
3. Configure environment variables
4. Deploy!

**Note:** With Gemini, you don't need to host any AI infrastructure - just configure your API key! For Ollama, host it on a server accessible from Vercel (e.g., Railway, Render, or your own VPS).

## 🏗️ Architecture

```
ai-chat/
├── src/
│   ├── components/         # React components
│   │   ├── ChatContainer.jsx
│   │   ├── ChatWindow.jsx
│   │   ├── ChatMessage.jsx
│   │   ├── ChatInput.jsx
│   │   ├── PersonalitySelector.jsx
│   │   └── Settings.jsx
│   ├── contexts/          # React contexts
│   │   └── ChatContext.jsx
│   ├── services/          # API services
│   │   ├── ai.js          # Unified AI service
│   │   ├── ollama.js      # Ollama API integration
│   │   ├── gemini.js      # Gemini API integration
│   │   ├── analytics.js   # Analytics tracking
│   │   └── rag.js         # RAG with Supabase
│   ├── config/            # Configuration
│   │   ├── personalities.js
│   │   ├── ollama.js
│   │   ├── gemini.js
│   │   └── supabase.js
│   └── utils/             # Utility functions
├── public/
│   ├── widget/            # Embeddable widget
│   │   └── ai-chat-widget.js
│   └── widget-demo.html   # Widget demo
└── dist/                  # Production build
```

## 🔧 Configuration

### Environment Variables

Create `.env` file:

```env
# Ollama API (for local AI)
VITE_OLLAMA_API_URL=http://localhost:11434

# Google Gemini API (for cloud AI)
VITE_GEMINI_API_KEY=your-gemini-api-key-here

# Supabase (optional - for RAG)
VITE_SUPABASE_URL=your-supabase-url
VITE_SUPABASE_ANON_KEY=your-supabase-anon-key

# Analytics (optional)
VITE_ANALYTICS_ENABLED=true
```

### Ollama Configuration

Edit `src/config/ollama.js` to customize:
- API endpoint
- Default model
- Generation parameters (temperature, top_p, etc.)

### Gemini Configuration

Edit `src/config/gemini.js` to customize:
- Default model
- Generation parameters
- Safety settings
- Context window limits

### Personality Configuration

Edit `src/config/personalities.js` to:
- Add new personalities
- Modify system prompts
- Change avatars and colors

## 🔒 Security

- ✅ Local AI processing with Ollama (no external data transfer)
- ✅ Cloud AI with Google Gemini (enterprise-grade security)
- ✅ API keys stored in environment variables
- ✅ Supabase RLS (Row Level Security) enabled
- ✅ HTTPS recommended for production
- ✅ CSP headers in production recommended

**Note**: When using Gemini, data is sent to Google's servers for processing. Review [Google's privacy policy](https://policies.google.com/privacy) for details.

## 📱 Browser Support

- Chrome/Edge (latest)
- Firefox (latest)
- Safari (latest)
- Mobile browsers (iOS Safari, Chrome Mobile)

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

MIT License - free to use for personal or commercial purposes.

## 🆘 Troubleshooting

### "Not connected to Ollama"
- Ensure Ollama is running: `ollama list`
- Check API endpoint in `.env`
- Verify CORS settings
- Try switching to Gemini provider if available

### "Not connected to Gemini"
- Verify your API key is correct
- Check you have credits/quota remaining
- Ensure API key has proper permissions
- Try regenerating your API key

### Models not loading
**Ollama:**
- Pull models: `ollama pull llama3.1:8b`
- Restart Ollama service
- Check Ollama logs

**Gemini:**
- Verify internet connection
- Check API key is valid
- Ensure you've accepted Google's terms

### Build errors
```bash
rm -rf node_modules package-lock.json
npm install
npm run build
```

### Widget not showing
- Check script URL is correct
- Verify CORS headers
- Check browser console for errors

## 📚 Resources

- [Ollama Documentation](https://ollama.ai)
- [Google AI Studio](https://makersuite.google.com/app/apikey) - Get Gemini API keys
- [Gemini API Documentation](https://ai.google.dev/docs)
- [Supabase Documentation](https://supabase.com/docs)
- [Vercel Documentation](https://vercel.com/docs)
- [React Documentation](https://react.dev)
- [Tailwind CSS](https://tailwindcss.com)

## 🎉 Credits

Built with:
- **React 19** - UI framework
- **Vite 7** - Build tool
- **Tailwind CSS 4** - Styling
- **Ollama** - Local AI inference
- **Google Gemini** - Cloud AI inference
- **@google/generative-ai** - Gemini SDK
- **Supabase** - Vector database (optional)
- **Vercel** - Hosting platform

---

**Made with ❤️ for the open-source community**

Star ⭐ this repository if you find it useful!
