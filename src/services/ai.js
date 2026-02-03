import ollamaService from './ollama';
import geminiService from './gemini';

/**
 * Unified AI service that routes requests to either Ollama or Gemini
 * based on provider selection
 */
class AIService {
  constructor() {
    this.provider = 'ollama'; // Default provider
    this.geminiApiKey = null;
  }

  setProvider(provider) {
    this.provider = provider;
  }

  getProvider() {
    return this.provider;
  }

  setGeminiApiKey(apiKey) {
    this.geminiApiKey = apiKey;
    geminiService.initialize(apiKey);
  }

  getGeminiApiKey() {
    return this.geminiApiKey;
  }

  isGeminiEnabled() {
    return geminiService.isEnabled();
  }

  async chat(messages, model, options = {}) {
    if (this.provider === 'gemini') {
      return await geminiService.chat(messages, model, options);
    } else {
      return await ollamaService.chat(messages, model, options);
    }
  }

  async *chatStream(messages, model, options = {}) {
    if (this.provider === 'gemini') {
      yield* geminiService.chatStream(messages, model, options);
    } else {
      yield* ollamaService.chatStream(messages, model, options);
    }
  }

  async listModels() {
    if (this.provider === 'gemini') {
      return await geminiService.listModels();
    } else {
      return await ollamaService.listModels();
    }
  }

  async checkHealth() {
    if (this.provider === 'gemini') {
      return await geminiService.checkHealth();
    } else {
      return await ollamaService.checkHealth();
    }
  }

  async validateGeminiApiKey(apiKey) {
    return await geminiService.validateApiKey(apiKey);
  }
}

export default new AIService();
