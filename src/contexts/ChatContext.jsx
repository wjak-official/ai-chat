import React, { createContext, useContext, useState, useCallback } from 'react';
import ollamaService from '../services/ollama';
import analyticsService from '../services/analytics';
import ragService from '../services/rag';
import { defaultPersonality, getPersonalityById } from '../config/personalities';
import { ollamaConfig, getModelById } from '../config/ollama';

const ChatContext = createContext();

export const useChat = () => {
  const context = useContext(ChatContext);
  if (!context) {
    throw new Error('useChat must be used within ChatProvider');
  }
  return context;
};

export const ChatProvider = ({ children }) => {
  const [messages, setMessages] = useState([]);
  const [personality, setPersonality] = useState(defaultPersonality);
  const [model, setModel] = useState(ollamaConfig.defaultModel);
  const [isLoading, setIsLoading] = useState(false);
  const [isConnected, setIsConnected] = useState(false);
  const [error, setError] = useState(null);
  const [useRAG, setUseRAG] = useState(ragService.isEnabled());

  const checkConnection = useCallback(async () => {
    try {
      const connected = await ollamaService.checkHealth();
      setIsConnected(connected);
      return connected;
    } catch (err) {
      setIsConnected(false);
      return false;
    }
  }, []);

  const changePersonality = useCallback((personalityId) => {
    const newPersonality = getPersonalityById(personalityId);
    analyticsService.trackPersonalityChange(personality, newPersonality);
    setPersonality(newPersonality);
  }, [personality]);

  const changeModel = useCallback((modelId) => {
    analyticsService.trackModelChange(model, modelId);
    setModel(modelId);
  }, [model]);

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
      
      // Prepare messages for Ollama
      const chatMessages = [
        { role: 'system', content: personality.systemPrompt },
        ...messages.map(msg => ({
          role: msg.role,
          content: msg.content
        })),
        { role: 'user', content: content.trim() }
      ];

      const response = await ollamaService.chat(chatMessages, model);
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
      
      // Prepare messages for Ollama
      const chatMessages = [
        { role: 'system', content: personality.systemPrompt },
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
      for await (const chunk of ollamaService.chatStream(chatMessages, model)) {
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
    isLoading,
    isConnected,
    error,
    sendMessage,
    sendMessageStream,
    clearMessages,
    deleteMessage,
    changePersonality,
    changeModel,
    checkConnection,
    useRAG,
    setUseRAG,
  };

  return <ChatContext.Provider value={value}>{children}</ChatContext.Provider>;
};
