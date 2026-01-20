import { ollamaConfig } from '../config/ollama';

class OllamaService {
  constructor() {
    this.apiEndpoint = ollamaConfig.apiEndpoint;
  }

  async chat(messages, model = ollamaConfig.defaultModel, options = {}) {
    try {
      const response = await fetch(`${this.apiEndpoint}/api/chat`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model,
          messages,
          stream: false,
          options: { ...ollamaConfig.options, ...options },
        }),
      });

      if (!response.ok) {
        throw new Error(`Ollama API error: ${response.statusText}`);
      }

      const data = await response.json();
      return data.message.content;
    } catch (error) {
      console.error('Ollama chat error:', error);
      throw error;
    }
  }

  async *chatStream(messages, model = ollamaConfig.defaultModel, options = {}) {
    try {
      const response = await fetch(`${this.apiEndpoint}/api/chat`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model,
          messages,
          stream: true,
          options: { ...ollamaConfig.options, ...options },
        }),
      });

      if (!response.ok) {
        throw new Error(`Ollama API error: ${response.statusText}`);
      }

      const reader = response.body.getReader();
      const decoder = new TextDecoder();

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        const chunk = decoder.decode(value);
        const lines = chunk.split('\n').filter(line => line.trim());

        for (const line of lines) {
          try {
            const data = JSON.parse(line);
            if (data.message?.content) {
              yield data.message.content;
            }
          } catch (e) {
            // Skip invalid JSON lines
          }
        }
      }
    } catch (error) {
      console.error('Ollama stream error:', error);
      throw error;
    }
  }

  async listModels() {
    try {
      const response = await fetch(`${this.apiEndpoint}/api/tags`);
      if (!response.ok) {
        throw new Error(`Ollama API error: ${response.statusText}`);
      }
      const data = await response.json();
      return data.models || [];
    } catch (error) {
      console.error('Ollama list models error:', error);
      return [];
    }
  }

  async checkHealth() {
    try {
      const response = await fetch(`${this.apiEndpoint}/api/tags`);
      return response.ok;
    } catch (error) {
      return false;
    }
  }
}

export default new OllamaService();
