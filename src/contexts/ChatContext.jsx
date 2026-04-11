import React, { createContext, useContext, useState, useCallback, useEffect } from 'react';
import aiService from '../services/ai';
import analyticsService from '../services/analytics';
import ragService from '../services/rag';
import { defaultPersonality, getPersonalityById } from '../config/personalities';
import { ollamaConfig, getModelById } from '../config/ollama';
import { geminiConfig, getGeminiModelById } from '../config/gemini';

const ChatContext = createContext();

export const useChat = () => {
  const context = useContext(ChatContext);
  if (!context) {
    throw new Error('useChat must be used within ChatProvider');
  }
  return context;
};

export const ChatProvider = ({ children, initialPersonality }) => {
  const [messages, setMessages] = useState([]);
  const [personality, setPersonality] = useState(() => {
    if (initialPersonality) {
      const p = getPersonalityById(initialPersonality);
      return p || defaultPersonality;
    }
    return defaultPersonality;
  });
  const [provider, setProvider] = useState('ollama'); // 'ollama' or 'gemini'
  const [model, setModel] = useState(ollamaConfig.defaultModel);
  const [geminiApiKey, setGeminiApiKey] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isConnected, setIsConnected] = useState(false);
  const [error, setError] = useState(null);
  const [useRAG, setUseRAG] = useState(ragService.isEnabled());

  // Initialize AI service provider and auto-detect on mount
  useEffect(() => {
    const detectProvider = async () => {
      const storedApiKey = localStorage.getItem('gemini_api_key');
      if (storedApiKey) {
        setGeminiApiKey(storedApiKey);
        aiService.setGeminiApiKey(storedApiKey);
        
        // Check if Gemini is working
        aiService.setProvider('gemini');
        const geminiWorking = await aiService.checkHealth();
        if (geminiWorking) {
          setProvider('gemini');
          setModel(geminiConfig.defaultModel);
        } else {
          // Fall back to Ollama
          aiService.setProvider('ollama');
        }
      }
    };
    
    detectProvider();
  }, []);

  // Update AI service when provider or API key changes
  useEffect(() => {
    aiService.setProvider(provider);
    if (provider === 'gemini' && geminiApiKey) {
      aiService.setGeminiApiKey(geminiApiKey);
      localStorage.setItem('gemini_api_key', geminiApiKey);
    }
  }, [provider, geminiApiKey]);

  const checkConnection = useCallback(async () => {
    try {
      const connected = await aiService.checkHealth();
      setIsConnected(connected);
      return connected;
    } catch (err) {
      setIsConnected(false);
      return false;
    }
  }, []);

  const changeProvider = useCallback((newProvider) => {
    setProvider(newProvider);
    
    // Switch to default model for new provider
    if (newProvider === 'gemini') {
      setModel(geminiConfig.defaultModel);
    } else {
      setModel(ollamaConfig.defaultModel);
    }
    
    analyticsService.trackUserInteraction('provider_change', { provider: newProvider });
  }, []);

  const updateGeminiApiKey = useCallback((apiKey) => {
    setGeminiApiKey(apiKey);
    aiService.setGeminiApiKey(apiKey);
  }, []);

  const changePersonality = useCallback((personalityId) => {
    const newPersonality = getPersonalityById(personalityId);
    analyticsService.trackPersonalityChange(personality, newPersonality);
    setPersonality(newPersonality);
  }, [personality]);

  const changeModel = useCallback((modelId) => {
    // Validate model exists
    let modelInfo;
    if (provider === 'gemini') {
      modelInfo = getGeminiModelById(modelId);
    } else {
      modelInfo = getModelById(modelId);
    }
    
    if (modelInfo) {
      analyticsService.trackModelChange(model, modelId);
      setModel(modelId);
    } else {
      console.warn(`Model ${modelId} not found. Keeping current model: ${model}`);
    }
  }, [model, provider]);

  const sendMessage = useCallback(async (content) => {
    if (!content.trim()) return;

    const userMessage = {
      id: Date.now(),
      role: 'user',
      content: content.trim(),
      timestamp: new Date().toISOString(),
    };

    setMessages(prev => [...prev, userMessage]);
    setIsLoading(true);
    setError(null);

    analyticsService.trackMessageSent(content, personality);

    try {
      const startTime = Date.now();
      
      // Build system prompt with RAG context if enabled
      let systemPrompt = personality.systemPrompt;
      if (useRAG && ragService.isEnabled()) {
        systemPrompt = await ragService.buildContextualPrompt(content.trim(), personality.systemPrompt);
      }
      
      // Prepare messages for Ollama
      const chatMessages = [
        { role: 'system', content: systemPrompt },
        ...messages.map(msg => ({
          role: msg.role,
          content: msg.content
        })),
        { role: 'user', content: content.trim() }
      ];

      const response = await aiService.chat(chatMessages, model);
      const responseTime = Date.now() - startTime;

      const assistantMessage = {
        id: Date.now() + 1,
        role: 'assistant',
        content: response,
        timestamp: new Date().toISOString(),
        personality: personality.id,
      };

      setMessages(prev => [...prev, assistantMessage]);
      analyticsService.trackMessageReceived(response, personality, responseTime);
    } catch (err) {
      console.error('Error sending message:', err);
      setError(err.message || 'Failed to send message');
      analyticsService.trackError(err, { context: 'sendMessage' });
    } finally {
      setIsLoading(false);
    }
  }, [messages, personality, model, useRAG]);

  const sendMessageStream = useCallback(async (content) => {
    if (!content.trim()) return;

    const userMessage = {
      id: Date.now(),
      role: 'user',
      content: content.trim(),
      timestamp: new Date().toISOString(),
    };

    setMessages(prev => [...prev, userMessage]);
    setIsLoading(true);
    setError(null);

    analyticsService.trackMessageSent(content, personality);

    try {
      const startTime = Date.now();
      
      // Build system prompt with RAG context if enabled
      let systemPrompt = personality.systemPrompt;
      if (useRAG && ragService.isEnabled()) {
        systemPrompt = await ragService.buildContextualPrompt(content.trim(), personality.systemPrompt);
      }
      
      // Prepare messages for Ollama
      const chatMessages = [
        { role: 'system', content: systemPrompt },
        ...messages.map(msg => ({
          role: msg.role,
          content: msg.content
        })),
        { role: 'user', content: content.trim() }
      ];

      const assistantMessageId = Date.now() + 1;
      let fullResponse = '';

      // Add empty assistant message
      setMessages(prev => [...prev, {
        id: assistantMessageId,
        role: 'assistant',
        content: '',
        timestamp: new Date().toISOString(),
        personality: personality.id,
        streaming: true,
      }]);

      // Stream the response
      for await (const chunk of aiService.chatStream(chatMessages, model)) {
        fullResponse += chunk;
        setMessages(prev => prev.map(msg => 
          msg.id === assistantMessageId 
            ? { ...msg, content: fullResponse }
            : msg
        ));
      }

      // Mark as complete
      const responseTime = Date.now() - startTime;
      setMessages(prev => prev.map(msg => 
        msg.id === assistantMessageId 
          ? { ...msg, streaming: false }
          : msg
      ));

      analyticsService.trackMessageReceived(fullResponse, personality, responseTime);
    } catch (err) {
      console.error('Error streaming message:', err);
      setError(err.message || 'Failed to stream message');
      analyticsService.trackError(err, { context: 'sendMessageStream' });
    } finally {
      setIsLoading(false);
    }
  }, [messages, personality, model, useRAG]);

  const clearMessages = useCallback(() => {
    setMessages([]);
    analyticsService.trackUserInteraction('clear_messages');
  }, []);

  const deleteMessage = useCallback((messageId) => {
    setMessages(prev => prev.filter(msg => msg.id !== messageId));
    analyticsService.trackUserInteraction('delete_message', { messageId });
  }, []);

  const value = {
    messages,
    personality,
    model,
    provider,
    geminiApiKey,
    isLoading,
    isConnected,
    error,
    sendMessage,
    sendMessageStream,
    clearMessages,
    deleteMessage,
    changePersonality,
    changeModel,
    changeProvider,
    updateGeminiApiKey,
    checkConnection,
    useRAG,
    setUseRAG,
  };

  return <ChatContext.Provider value={value}>{children}</ChatContext.Provider>;
};
