export const geminiConfig = {
  // Google AI Studio API Key
  apiKey: import.meta.env.VITE_GEMINI_API_KEY || '',
  
  // Supported Gemini models
  models: [
    {
      id: 'gemini-1.5-flash',
      name: 'Gemini 1.5 Flash',
      description: 'Fast and efficient multimodal model',
      size: 'Cloud-based',
      recommended: true,
      maxTokens: 1000000
    },
    {
      id: 'gemini-1.5-pro',
      name: 'Gemini 1.5 Pro',
      description: 'Most capable multimodal model',
      size: 'Cloud-based',
      recommended: true,
      maxTokens: 2000000
    },
    {
      id: 'gemini-pro',
      name: 'Gemini Pro',
      description: 'Best for text-based tasks',
      size: 'Cloud-based',
      recommended: false,
      maxTokens: 30720
    }
  ],
  
  // Default model
  defaultModel: 'gemini-1.5-flash',
  
  // Generation parameters
  options: {
    temperature: 0.7,
    topP: 0.9,
    topK: 40,
    maxOutputTokens: 2048,
  },
  
  // Safety settings
  safetySettings: [
    {
      category: 'HARM_CATEGORY_HARASSMENT',
      threshold: 'BLOCK_MEDIUM_AND_ABOVE',
    },
    {
      category: 'HARM_CATEGORY_HATE_SPEECH',
      threshold: 'BLOCK_MEDIUM_AND_ABOVE',
    },
    {
      category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
      threshold: 'BLOCK_MEDIUM_AND_ABOVE',
    },
    {
      category: 'HARM_CATEGORY_DANGEROUS_CONTENT',
      threshold: 'BLOCK_MEDIUM_AND_ABOVE',
    },
  ]
};

export const getGeminiModelById = (id) => {
  return geminiConfig.models.find(m => m.id === id) || geminiConfig.models[0];
};

export const isGeminiEnabled = () => {
  return !!geminiConfig.apiKey && geminiConfig.apiKey.trim() !== '';
};
