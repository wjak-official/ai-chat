import React, { useState } from 'react';
import { useChat } from '../contexts/ChatContext';
import { personalities } from '../config/personalities';

const PersonalitySelector = () => {
  const [isOpen, setIsOpen] = useState(false);
  const { personality, changePersonality } = useChat();

  const handleSelect = (personalityId) => {
    changePersonality(personalityId);
    setIsOpen(false);
  };

  return (
    <div className="relative">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 px-4 py-2 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
      >
        <span className="text-lg">{personality.avatar}</span>
        <span className="text-sm font-medium text-gray-700 hidden sm:inline">
          {personality.name}
        </span>
        <svg
          className={`w-4 h-4 transition-transform ${isOpen ? 'rotate-180' : ''}`}
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>

      {isOpen && (
        <>
          <div 
            className="fixed inset-0 z-10"
            onClick={() => setIsOpen(false)}
          />
          <div className="absolute top-full mt-2 right-0 w-72 bg-white rounded-lg shadow-lg border border-gray-200 z-20 max-h-96 overflow-y-auto">
            {personalities.map((p) => (
              <button
                key={p.id}
                onClick={() => handleSelect(p.id)}
                className={`w-full flex items-start gap-3 px-4 py-3 hover:bg-gray-50 transition-colors ${
                  p.id === personality.id ? 'bg-primary-50' : ''
                }`}
              >
                <div
                  className="flex-shrink-0 w-10 h-10 rounded-full flex items-center justify-center text-xl"
                  style={{ backgroundColor: p.color + '20' }}
                >
                  {p.avatar}
                </div>
                <div className="flex-1 text-left">
                  <div className="font-medium text-gray-900">{p.name}</div>
                  <div className="text-xs text-gray-600">{p.description}</div>
                </div>
                {p.id === personality.id && (
                  <svg className="w-5 h-5 text-primary-500" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                  </svg>
                )}
              </button>
            ))}
          </div>
        </>
      )}
    </div>
  );
};

export default PersonalitySelector;
