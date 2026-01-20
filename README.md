# AI Chat Tool 💬

> An AI-powered chat application with customizable personalities, embeddable widget, and visitor behavior tracking. Built with React, Vite, Tailwind CSS, and powered by Ollama for 100% free local AI inference.

![AI Chat Interface](https://github.com/user-attachments/assets/68a57367-a5c3-445c-8ca3-390f04bf5a93)

## 🌟 Features

### Core Capabilities
- **8 Customizable AI Personalities** - Friendly Assistant, Professional Advisor, Creative Writer, Tech Expert, Life Coach, Data Analyst, Customer Support, Educator
- **Local AI Processing** - Powered by Ollama (Llama 3.1, Mistral 7B, Phi-3 Mini, Gemma 2B)
- **RAG-Powered Knowledge** - Optional Supabase integration for vector embeddings and contextual responses
- **Responsive Design** - Inspired by iMessage and WhatsApp, works beautifully on all devices
- **Embeddable Widget** - Easy-to-embed Web Component for any website
- **Visitor Analytics** - Track user behavior, interactions, and engagement
- **100% Free** - Vercel Free Tier hosting + local Ollama inference

### UI Features
- Streaming responses with real-time updates
- Message history with timestamps
- Multiple personality selection
- Model switching
- Connection status monitoring
- Keyboard shortcuts (Enter to send, Shift+Enter for newline)
- Smooth animations and transitions
- Mobile-responsive design

![Personality Selection](https://github.com/user-attachments/assets/04d1b51a-15ff-4ecf-8824-9db3371bbf04)

## 🚀 Quick Start

### Prerequisites

1. **Node.js** (v18 or higher)
2. **Ollama** installed and running locally

```bash
# Install Ollama (macOS/Linux)
curl https://ollama.ai/install.sh | sh

# Pull a model
ollama pull llama3.1:8b
```

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

### Standalone Application

The application provides a full-featured chat interface:

1. **Select a Personality** - Choose from 8 different AI personalities
2. **Start Chatting** - Type your message and press Enter
3. **Configure Settings** - Click the settings icon to change models or clear chat
4. **Switch Models** - Choose between different Ollama models

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

### Supported Ollama Models

| Model | Size | Description | Recommended |
|-------|------|-------------|-------------|
| **Llama 3.1 8B** | 4.7GB | Meta's powerful language model | ✅ Yes |
| **Mistral 7B** | 4.1GB | Fast and efficient model | ✅ Yes |
| **Phi-3 Mini** | 2.3GB | Microsoft's compact model | - |
| **Gemma 2B** | 1.4GB | Google's lightweight model | - |

### Install Models

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
   - `VITE_OLLAMA_API_URL` - Your Ollama server URL
   - `VITE_SUPABASE_URL` - (Optional) Supabase project URL
   - `VITE_SUPABASE_ANON_KEY` - (Optional) Supabase anon key

### Alternative: Deploy via GitHub

1. Push to GitHub
2. Import project in Vercel dashboard
3. Configure environment variables
4. Deploy!

**Note:** For production, host Ollama on a server accessible from Vercel (e.g., Railway, Render, or your own VPS).

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
│   │   ├── ollama.js     # Ollama API integration
│   │   ├── analytics.js  # Analytics tracking
│   │   └── rag.js        # RAG with Supabase
│   ├── config/           # Configuration
│   │   ├── personalities.js
│   │   ├── ollama.js
│   │   └── supabase.js
│   └── utils/            # Utility functions
├── public/
│   ├── widget/           # Embeddable widget
│   │   └── ai-chat-widget.js
│   └── widget-demo.html  # Widget demo
└── dist/                 # Production build
```

## 🔧 Configuration

### Environment Variables

Create `.env` file:

```env
# Ollama API (required)
VITE_OLLAMA_API_URL=http://localhost:11434

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

### Personality Configuration

Edit `src/config/personalities.js` to:
- Add new personalities
- Modify system prompts
- Change avatars and colors

## 🔒 Security

- ✅ All AI processing happens locally via Ollama
- ✅ No data sent to external APIs (except optional Supabase)
- ✅ Supabase RLS (Row Level Security) enabled
- ✅ Environment variables for sensitive config
- ✅ CSP headers in production recommended

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

### Models not loading
- Pull models: `ollama pull llama3.1:8b`
- Restart Ollama service
- Check Ollama logs

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
- [Supabase Documentation](https://supabase.com/docs)
- [Vercel Documentation](https://vercel.com/docs)
- [React Documentation](https://react.dev)
- [Tailwind CSS](https://tailwindcss.com)

## 🎉 Credits

Built with:
- **React** - UI framework
- **Vite** - Build tool
- **Tailwind CSS** - Styling
- **Ollama** - Local AI inference
- **Supabase** - Vector database (optional)
- **Vercel** - Hosting platform

---

**Made with ❤️ for the open-source community**

Star ⭐ this repository if you find it useful!
