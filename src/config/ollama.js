export const ollamaConfig = {
  // Default Ollama API endpoint (local)
  apiEndpoint: import.meta.env.VITE_OLLAMA_API_URL || 'http://localhost:11434',
  
  // Supported models
  models: [
    {
      id: 'llama3.1:8b',
      name: 'Llama 3.1 8B',
      description: 'Meta\'s powerful language model',
      size: '4.7GB',
      recommended: true
    },
    {
      id: 'mistral:7b',
      name: 'Mistral 7B',
      description: 'Fast and efficient model',
      size: '4.1GB',
      recommended: true
    },
    {
      id: 'phi3:mini',
      name: 'Phi-3 Mini',
      description: 'Microsoft\'s compact model',
      size: '2.3GB',
      recommended: false
    },
    {
      id: 'gemma:2b',
      name: 'Gemma 2B',
      description: 'Google\'s lightweight model',
      size: '1.4GB',
      recommended: false
    }
  ],
  
  // Default model
  defaultModel: 'llama3.1:8b',
  
  // Generation parameters
  options: {
    temperature: 0.7,
    top_p: 0.9,
    top_k: 40,
    num_ctx: 2048,
  }
};

export const getModelById = (id) => {
  return ollamaConfig.models.find(m => m.id === id) || ollamaConfig.models[0];
};
