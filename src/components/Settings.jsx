import React, { useState, useEffect, useCallback } from 'react';
import { useChat } from '../contexts/ChatContext';
import { ollamaConfig } from '../config/ollama';
import { geminiConfig } from '../config/gemini';
import aiService from '../services/ai';

const Settings = ({ isOpen, onClose }) => {
  const { 
    model, 
    provider, 
    geminiApiKey, 
    changeModel, 
    changeProvider, 
    updateGeminiApiKey, 
    clearMessages, 
    checkConnection, 
    isConnected 
  } = useChat();
  const [availableModels, setAvailableModels] = useState([]);
  const [showConfirm, setShowConfirm] = useState(false);
  const [apiKeyInput, setApiKeyInput] = useState(geminiApiKey);
  const [isValidating, setIsValidating] = useState(false);
  const [apiKeyValid, setApiKeyValid] = useState(null);
  const [showApiKey, setShowApiKey] = useState(false);

  useEffect(() => {
    if (isOpen) {
      checkConnection();
      setApiKeyInput(geminiApiKey);
    }
  }, [isOpen, geminiApiKey, checkConnection]);

  const loadModels = useCallback(async () => {
    const models = await aiService.listModels();
    setAvailableModels(models);
  }, []);

  const handleProviderChange = (newProvider) => {
    changeProvider(newProvider);
    setAvailableModels([]);
    // loadModels is triggered by the useEffect below once the provider state settles
  };

  // Reload models whenever provider changes
  useEffect(() => {
    if (isOpen) {
      loadModels();
    }
  }, [provider, isOpen, loadModels]);

  const handleApiKeyChange = async () => {
    if (!apiKeyInput || apiKeyInput.trim() === '') {
      return;
    }

    setIsValidating(true);
    setApiKeyValid(null);

    try {
      const isValid = await aiService.validateGeminiApiKey(apiKeyInput.trim());
      setApiKeyValid(isValid);
      
      if (isValid) {
        updateGeminiApiKey(apiKeyInput.trim());
        checkConnection();
      }
    } catch (error) {
      setApiKeyValid(false);
    } finally {
      setIsValidating(false);
    }
  };

  const handleClearMessages = () => {
    clearMessages();
    setShowConfirm(false);
  };

  if (!isOpen) return null;

  return (
    <>
      <div className="fixed inset-0 bg-black bg-opacity-50 z-40" onClick={onClose} />
      <div className="fixed inset-y-0 right-0 w-full sm:w-96 bg-white shadow-xl z-50 overflow-y-auto">
        <div className="p-6">
          {/* Header */}
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-2xl font-bold text-gray-900">Settings</h2>
            <button
              onClick={onClose}
              className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          {/* Provider Selection */}
          <div className="mb-6">
            <h3 className="text-sm font-semibold text-gray-700 mb-2">AI Provider</h3>
            <div className="grid grid-cols-2 gap-2">
              <button
                onClick={() => handleProviderChange('ollama')}
                className={`px-4 py-3 rounded-lg border font-medium transition-colors ${
                  provider === 'ollama'
                    ? 'border-primary-500 bg-primary-50 text-primary-700'
                    : 'border-gray-200 hover:bg-gray-50 text-gray-700'
                }`}
              >
                <div className="text-sm">Ollama</div>
                <div className="text-xs opacity-75">Local AI</div>
              </button>
              <button
                onClick={() => handleProviderChange('gemini')}
                className={`px-4 py-3 rounded-lg border font-medium transition-colors ${
                  provider === 'gemini'
                    ? 'border-primary-500 bg-primary-50 text-primary-700'
                    : 'border-gray-200 hover:bg-gray-50 text-gray-700'
                }`}
              >
                <div className="text-sm">Gemini</div>
                <div className="text-xs opacity-75">Google AI</div>
              </button>
            </div>
          </div>

          {/* Gemini API Key Input */}
          {provider === 'gemini' && (
            <div className="mb-6">
              <h3 className="text-sm font-semibold text-gray-700 mb-2">Gemini API Key</h3>
              <p className="text-xs text-gray-500 mb-2">
                Each user configures their own API key, which is stored locally in their browser.
              </p>
              <div className="space-y-2">
                <div className="flex gap-2">
                  <div className="flex-1 relative">
                    <input
                      type={showApiKey ? "text" : "password"}
                      value={apiKeyInput}
                      onChange={(e) => {
                        setApiKeyInput(e.target.value);
                        setApiKeyValid(null);
                      }}
                      placeholder="Enter your Gemini API key"
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 text-sm font-mono"
                    />
                    <button
                      onClick={() => setShowApiKey(!showApiKey)}
                      className="absolute right-2 top-1/2 -translate-y-1/2 p-1 hover:bg-gray-100 rounded"
                    >
                      <svg className="w-4 h-4 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        {showApiKey ? (
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                        ) : (
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                        )}
                      </svg>
                    </button>
                  </div>
                  <button
                    onClick={handleApiKeyChange}
                    disabled={isValidating || !apiKeyInput}
                    className="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium"
                  >
                    {isValidating ? 'Validating...' : 'Save'}
                  </button>
                </div>
                {apiKeyValid === true && (
                  <div className="flex items-center gap-2 text-green-700 text-sm">
                    <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                    </svg>
                    API key is valid
                  </div>
                )}
                {apiKeyValid === false && (
                  <div className="flex items-center gap-2 text-red-700 text-sm">
                    <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                    </svg>
                    Invalid API key
                  </div>
                )}
                <p className="text-xs text-gray-600">
                  Get your API key from <a href="https://makersuite.google.com/app/apikey" target="_blank" rel="noopener noreferrer" className="text-primary-600 hover:underline">Google AI Studio</a>
                </p>
              </div>
            </div>
          )}

          {/* Connection Status */}
          <div className="mb-6">
            <h3 className="text-sm font-semibold text-gray-700 mb-2">Connection Status</h3>
            <div className={`flex items-center gap-2 px-4 py-3 rounded-lg ${
              isConnected ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'
            }`}>
              <div className={`w-2 h-2 rounded-full ${isConnected ? 'bg-green-500' : 'bg-red-500'}`} />
              <span className="text-sm font-medium">
                {isConnected 
                  ? `Connected to ${provider === 'gemini' ? 'Gemini' : 'Ollama'}` 
                  : `Not connected to ${provider === 'gemini' ? 'Gemini' : 'Ollama'}`
                }
              </span>
            </div>
            {!isConnected && provider === 'ollama' && (
              <p className="text-xs text-gray-600 mt-2">
                Make sure Ollama is running on {ollamaConfig.apiEndpoint}
              </p>
            )}
            {!isConnected && provider === 'gemini' && (
              <p className="text-xs text-gray-600 mt-2">
                Please enter a valid Gemini API key
              </p>
            )}
          </div>

          {/* Model Selection */}
          <div className="mb-6">
            <h3 className="text-sm font-semibold text-gray-700 mb-2">AI Model</h3>
            <div className="space-y-2">
              {(provider === 'ollama' ? ollamaConfig.models : geminiConfig.models).map((m) => (
                <button
                  key={m.id}
                  onClick={() => changeModel(m.id)}
                  className={`w-full text-left px-4 py-3 rounded-lg border transition-colors ${
                    model === m.id
                      ? 'border-primary-500 bg-primary-50'
                      : 'border-gray-200 hover:bg-gray-50'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="font-medium text-gray-900">{m.name}</div>
                      <div className="text-xs text-gray-600">{m.description}</div>
                      <div className="text-xs text-gray-500 mt-1">
                        {provider === 'ollama' ? `Size: ${m.size}` : m.size}
                      </div>
                    </div>
                    {m.recommended && (
                      <span className="text-xs bg-primary-100 text-primary-700 px-2 py-1 rounded">
                        Recommended
                      </span>
                    )}
                  </div>
                </button>
              ))}
            </div>
          </div>

          {/* Available Models (Ollama only) */}
          {provider === 'ollama' && availableModels.length > 0 && (
            <div className="mb-6">
              <h3 className="text-sm font-semibold text-gray-700 mb-2">
                Installed Models ({availableModels.length})
              </h3>
              <div className="bg-gray-50 rounded-lg p-3">
                <ul className="text-xs text-gray-600 space-y-1">
                  {availableModels.slice(0, 5).map((m, i) => (
                    <li key={i} className="truncate">• {m.name}</li>
                  ))}
                </ul>
              </div>
            </div>
          )}

          {/* Clear Messages */}
          <div className="mb-6">
            <h3 className="text-sm font-semibold text-gray-700 mb-2">Clear Chat</h3>
            {!showConfirm ? (
              <button
                onClick={() => setShowConfirm(true)}
                className="w-full px-4 py-3 bg-red-50 text-red-700 rounded-lg hover:bg-red-100 transition-colors font-medium"
              >
                Clear All Messages
              </button>
            ) : (
              <div className="space-y-2">
                <p className="text-sm text-gray-600">Are you sure? This cannot be undone.</p>
                <div className="flex gap-2">
                  <button
                    onClick={handleClearMessages}
                    className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
                  >
                    Yes, Clear
                  </button>
                  <button
                    onClick={() => setShowConfirm(false)}
                    className="flex-1 px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            )}
          </div>

          {/* Info */}
          <div className="pt-6 border-t border-gray-200">
            <p className="text-xs text-gray-500">
              {provider === 'ollama' 
                ? 'AI Chat Tool powered by Ollama. All conversations are processed locally on your machine.'
                : 'AI Chat Tool powered by Google Gemini. Conversations are processed via Google AI API.'
              }
            </p>
          </div>
        </div>
      </div>
    </>
  );
};

export default Settings;
