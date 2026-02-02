import React from 'react';
import { ChatProvider } from './contexts/ChatContext';
import ChatContainer from './components/ChatContainer';

function App() {
  // Parse URL parameters for embedded mode
  const urlParams = new URLSearchParams(window.location.search);
  const isEmbedded = urlParams.get('embedded') === 'true';
  const initialPersonality = urlParams.get('personality');

  return (
    <ChatProvider initialPersonality={initialPersonality}>
      <div className="h-screen flex flex-col">
        <ChatContainer embedded={isEmbedded} />
      </div>
    </ChatProvider>
  );
}

export default App;
