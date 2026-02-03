import { GoogleGenerativeAI } from '@google/generative-ai';
import { geminiConfig } from '../config/gemini';

class GeminiService {
  constructor() {
    this.apiKey = null;
    this.genAI = null;
  }

  initialize(apiKey) {
    this.apiKey = apiKey || geminiConfig.apiKey;
    if (this.apiKey) {
      this.genAI = new GoogleGenerativeAI(this.apiKey);
    }
  }

  isEnabled() {
    return !!this.apiKey && this.apiKey.trim() !== '';
  }

  /**
   * Convert chat messages to Gemini format
   */
  convertMessages(messages) {
    const history = [];
    let systemInstruction = '';

    for (const msg of messages) {
      if (msg.role === 'system') {
        systemInstruction = msg.content;
      } else if (msg.role === 'user') {
        history.push({
          role: 'user',
          parts: [{ text: msg.content }],
        });
      } else if (msg.role === 'assistant') {
        history.push({
          role: 'model',
          parts: [{ text: msg.content }],
        });
      }
    }

    return { history, systemInstruction };
  }

  async chat(messages, model = geminiConfig.defaultModel, options = {}) {
    if (!this.isEnabled()) {
      throw new Error('Gemini API key not configured');
    }

    try {
      const { history, systemInstruction } = this.convertMessages(messages);
      const lastMessage = history.pop(); // Remove last user message to send separately

      const generativeModel = this.genAI.getGenerativeModel({ 
        model,
        systemInstruction: systemInstruction || undefined,
        generationConfig: {
          temperature: options.temperature || geminiConfig.options.temperature,
          topP: options.topP || geminiConfig.options.topP,
          topK: options.topK || geminiConfig.options.topK,
          maxOutputTokens: options.maxOutputTokens || geminiConfig.options.maxOutputTokens,
        },
        safetySettings: geminiConfig.safetySettings,
      });

      const chat = generativeModel.startChat({
        history: history.length > 0 ? history : undefined,
      });

      const result = await chat.sendMessage(lastMessage.parts[0].text);
      const response = result.response;
      return response.text();
    } catch (error) {
      console.error('Gemini chat error:', error);
      if (error.message?.includes('API_KEY')) {
        throw new Error('Invalid Gemini API key. Please check your configuration.');
      }
      throw error;
    }
  }

  async *chatStream(messages, model = geminiConfig.defaultModel, options = {}) {
    if (!this.isEnabled()) {
      throw new Error('Gemini API key not configured');
    }

    try {
      const { history, systemInstruction } = this.convertMessages(messages);
      const lastMessage = history.pop(); // Remove last user message to send separately

      const generativeModel = this.genAI.getGenerativeModel({ 
        model,
        systemInstruction: systemInstruction || undefined,
        generationConfig: {
          temperature: options.temperature || geminiConfig.options.temperature,
          topP: options.topP || geminiConfig.options.topP,
          topK: options.topK || geminiConfig.options.topK,
          maxOutputTokens: options.maxOutputTokens || geminiConfig.options.maxOutputTokens,
        },
        safetySettings: geminiConfig.safetySettings,
      });

      const chat = generativeModel.startChat({
        history: history.length > 0 ? history : undefined,
      });

      const result = await chat.sendMessageStream(lastMessage.parts[0].text);

      for await (const chunk of result.stream) {
        const chunkText = chunk.text();
        if (chunkText) {
          yield chunkText;
        }
      }
    } catch (error) {
      console.error('Gemini stream error:', error);
      if (error.message?.includes('API_KEY')) {
        throw new Error('Invalid Gemini API key. Please check your configuration.');
      }
      throw error;
    }
  }

  async listModels() {
    if (!this.isEnabled()) {
      return [];
    }

    // Return configured models since Gemini doesn't have a model listing API
    return geminiConfig.models;
  }

  async checkHealth() {
    if (!this.isEnabled()) {
      return false;
    }

    try {
      // Simple test to verify API key is valid
      const model = this.genAI.getGenerativeModel({ model: 'gemini-pro' });
      const result = await model.generateContent('Hi');
      return !!result.response;
    } catch (error) {
      console.error('Gemini health check failed:', error);
      return false;
    }
  }

  async validateApiKey(apiKey) {
    try {
      const testGenAI = new GoogleGenerativeAI(apiKey);
      const model = testGenAI.getGenerativeModel({ model: 'gemini-pro' });
      const result = await model.generateContent('test');
      return !!result.response;
    } catch (error) {
      return false;
    }
  }
}

export default new GeminiService();
