import React, { useEffect, useRef } from 'react';
import { useChat } from '../contexts/ChatContext';
import ChatMessage from './ChatMessage';

const ChatWindow = () => {
  const { messages, personality, isLoading } = useChat();
  const messagesEndRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  return (
    <div className="flex-1 overflow-y-auto px-4 py-6 bg-gray-50">
      {messages.length === 0 ? (
        <div className="flex flex-col items-center justify-center h-full text-center px-4">
          <div 
            className="w-20 h-20 rounded-full flex items-center justify-center text-4xl mb-4"
            style={{ backgroundColor: personality.color + '20' }}
          >
            {personality.avatar}
          </div>
          <h2 className="text-2xl font-bold text-gray-800 mb-2">
            {personality.name}
          </h2>
          <p className="text-gray-600 mb-6 max-w-md">
            {personality.description}
          </p>
          <div className="bg-white rounded-lg p-4 shadow-sm max-w-md">
            <p className="text-sm text-gray-700">
              💡 Start a conversation by typing a message below!
            </p>
          </div>
        </div>
      ) : (
        <>
          {messages.map((message) => (
            <ChatMessage 
              key={message.id} 
              message={message} 
              personality={personality}
            />
          ))}
          {isLoading && messages[messages.length - 1]?.role !== 'assistant' && (
            <div className="flex justify-start mb-4">
              <div className="flex items-end gap-2">
                <div 
                  className="flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center text-lg"
                  style={{ backgroundColor: personality.color + '20' }}
                >
                  {personality.avatar}
                </div>
                <div className="bg-gray-100 px-4 py-3 rounded-2xl rounded-bl-md">
                  <div className="flex gap-1">
                    <span className="w-2 h-2 bg-gray-400 rounded-full animate-bounce"></span>
                    <span className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0.2s' }}></span>
                    <span className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0.4s' }}></span>
                  </div>
                </div>
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </>
      )}
    </div>
  );
};

export default ChatWindow;
