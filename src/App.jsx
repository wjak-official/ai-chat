import React from 'react';
import { ChatProvider } from './contexts/ChatContext';
import ChatContainer from './components/ChatContainer';

function App() {
  return (
    <ChatProvider>
      <div className="h-screen flex flex-col">
        <ChatContainer />
      </div>
    </ChatProvider>
  );
}

export default App;

