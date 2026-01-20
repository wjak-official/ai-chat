import React, { useState, useEffect } from 'react';
import { useChat } from '../contexts/ChatContext';
import { ollamaConfig } from '../config/ollama';
import ollamaService from '../services/ollama';

const Settings = ({ isOpen, onClose }) => {
  const { model, changeModel, clearMessages, checkConnection, isConnected } = useChat();
  const [availableModels, setAvailableModels] = useState([]);
  const [showConfirm, setShowConfirm] = useState(false);

  useEffect(() => {
    if (isOpen) {
      loadModels();
      checkConnection();
    }
  }, [isOpen]);

  const loadModels = async () => {
    const models = await ollamaService.listModels();
    setAvailableModels(models);
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

          {/* Connection Status */}
          <div className="mb-6">
            <h3 className="text-sm font-semibold text-gray-700 mb-2">Connection Status</h3>
            <div className={`flex items-center gap-2 px-4 py-3 rounded-lg ${
              isConnected ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'
            }`}>
              <div className={`w-2 h-2 rounded-full ${isConnected ? 'bg-green-500' : 'bg-red-500'}`} />
              <span className="text-sm font-medium">
                {isConnected ? 'Connected to Ollama' : 'Not connected to Ollama'}
              </span>
            </div>
            {!isConnected && (
              <p className="text-xs text-gray-600 mt-2">
                Make sure Ollama is running on {ollamaConfig.apiEndpoint}
              </p>
            )}
          </div>

          {/* Model Selection */}
          <div className="mb-6">
            <h3 className="text-sm font-semibold text-gray-700 mb-2">AI Model</h3>
            <div className="space-y-2">
              {ollamaConfig.models.map((m) => (
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
                      <div className="text-xs text-gray-500 mt-1">Size: {m.size}</div>
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

          {/* Available Models */}
          {availableModels.length > 0 && (
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
              AI Chat Tool powered by Ollama. All conversations are processed locally on your machine.
            </p>
          </div>
        </div>
      </div>
    </>
  );
};

export default Settings;
