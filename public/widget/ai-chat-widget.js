// AI Chat Widget - Embeddable Web Component
// Usage: <script src="https://your-domain.vercel.app/widget/ai-chat-widget.js"></script>
//        <ai-chat-widget></ai-chat-widget>

(function() {
  'use strict';

  class AIChatWidget extends HTMLElement {
    constructor() {
      super();
      this.attachShadow({ mode: 'open' });
      this.isOpen = false;
      this.isMinimized = false;
      this.analytics = [];
      this.sessionId = `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      this.eventListeners = []; // Track event listeners for cleanup
    }

    connectedCallback() {
      const config = this.getConfig();
      this.render();
      this.attachEventListeners();
      this.trackPageView();
      this.loadIframe(config);
    }

    disconnectedCallback() {
      // Clean up all event listeners
      this.eventListeners.forEach(({ target, type, handler }) => {
        target.removeEventListener(type, handler);
      });
      this.eventListeners = [];
    }

    getConfig() {
      return {
        apiUrl: this.getAttribute('api-url') || 'http://localhost:5173',
        personality: this.getAttribute('personality') || 'customer-support',
        position: this.getAttribute('position') || 'bottom-right',
        theme: this.getAttribute('theme') || 'purple',
        autoOpen: this.getAttribute('auto-open') === 'true',
        tracking: this.getAttribute('tracking') !== 'false',
      };
    }

    getThemeColors(theme) {
      const themes = {
        purple: { primary: '#667eea', secondary: '#764ba2' },
        blue: { primary: '#4299e1', secondary: '#3182ce' },
        green: { primary: '#48bb78', secondary: '#38a169' },
        red: { primary: '#f56565', secondary: '#e53e3e' },
        orange: { primary: '#ed8936', secondary: '#dd6b20' },
        pink: { primary: '#ed64a6', secondary: '#d53f8c' },
      };
      return themes[theme] || themes.purple;
    }

    render() {
      const config = this.getConfig();
      const position = this.getPositionStyles(config.position);
      const colors = this.getThemeColors(config.theme);

      this.shadowRoot.innerHTML = `
        <style>
          :host {
            position: fixed;
            ${position}
            z-index: 999999;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
          }

          .widget-button {
            width: 60px;
            height: 60px;
            border-radius: 30px;
            background: linear-gradient(135deg, ${colors.primary} 0%, ${colors.secondary} 100%);
            border: none;
            cursor: pointer;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.3s ease;
          }

          .widget-button:hover {
            transform: scale(1.1);
            box-shadow: 0 6px 20px rgba(0, 0, 0, 0.2);
          }

          .widget-button svg {
            width: 28px;
            height: 28px;
            fill: white;
          }

          .widget-container {
            position: fixed;
            ${position}
            width: 400px;
            height: 600px;
            max-width: calc(100vw - 40px);
            max-height: calc(100vh - 40px);
            border-radius: 12px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
            overflow: hidden;
            transform: scale(0.9);
            opacity: 0;
            transition: all 0.3s ease;
            display: none;
          }

          .widget-container.open {
            transform: scale(1);
            opacity: 1;
            display: block;
          }

          .widget-container.minimized {
            height: 60px;
          }

          .widget-header {
            background: linear-gradient(135deg, ${colors.primary} 0%, ${colors.secondary} 100%);
            color: white;
            padding: 15px;
            display: flex;
            justify-content: space-between;
            align-items: center;
          }

          .widget-header h3 {
            margin: 0;
            font-size: 16px;
            font-weight: 600;
          }

          .widget-controls {
            display: flex;
            gap: 8px;
          }

          .widget-control-btn {
            background: rgba(255, 255, 255, 0.2);
            border: none;
            width: 28px;
            height: 28px;
            border-radius: 4px;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: background 0.2s;
          }

          .widget-control-btn:hover {
            background: rgba(255, 255, 255, 0.3);
          }

          .widget-control-btn svg {
            width: 16px;
            height: 16px;
            fill: white;
          }

          .widget-iframe {
            width: 100%;
            height: calc(100% - 60px);
            border: none;
          }

          @media (max-width: 480px) {
            .widget-container {
              width: 100vw;
              height: 100vh;
              max-width: 100vw;
              max-height: 100vh;
              border-radius: 0;
              top: 0 !important;
              left: 0 !important;
              right: 0 !important;
              bottom: 0 !important;
            }

            .widget-iframe {
              height: calc(100% - 60px);
            }
          }
        </style>

        <div class="widget-wrapper">
          <button class="widget-button" id="widget-toggle">
            <svg viewBox="0 0 24 24">
              <path d="M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2z"/>
            </svg>
          </button>

          <div class="widget-container" id="widget-container">
            <div class="widget-header">
              <h3>AI Chat Assistant</h3>
              <div class="widget-controls">
                <button class="widget-control-btn" id="minimize-btn" title="Minimize">
                  <svg viewBox="0 0 24 24">
                    <path d="M19 13H5v-2h14v2z"/>
                  </svg>
                </button>
                <button class="widget-control-btn" id="close-btn" title="Close">
                  <svg viewBox="0 0 24 24">
                    <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/>
                  </svg>
                </button>
              </div>
            </div>
            <iframe 
              class="widget-iframe" 
              id="chat-iframe"
              title="AI Chat"
              allow="microphone; camera"
            ></iframe>
          </div>
        </div>
      `;
    }

    getPositionStyles(position) {
      const positions = {
        'bottom-right': 'bottom: 20px; right: 20px;',
        'bottom-left': 'bottom: 20px; left: 20px;',
        'top-right': 'top: 20px; right: 20px;',
        'top-left': 'top: 20px; left: 20px;',
      };
      return positions[position] || positions['bottom-right'];
    }

    loadIframe(config) {
      const iframe = this.shadowRoot.getElementById('chat-iframe');
      const params = new URLSearchParams({
        embedded: 'true',
        personality: config.personality,
        sessionId: this.sessionId,
      });
      iframe.src = `${config.apiUrl}?${params.toString()}`;
    }

    attachEventListeners() {
      const toggleBtn = this.shadowRoot.getElementById('widget-toggle');
      const closeBtn = this.shadowRoot.getElementById('close-btn');
      const minimizeBtn = this.shadowRoot.getElementById('minimize-btn');

      const toggleHandler = () => this.toggleWidget();
      const closeHandler = () => this.closeWidget();
      const minimizeHandler = () => this.minimizeWidget();

      toggleBtn.addEventListener('click', toggleHandler);
      closeBtn.addEventListener('click', closeHandler);
      minimizeBtn.addEventListener('click', minimizeHandler);

      // Listen for messages from iframe
      const messageHandler = (event) => {
        if (event.data.type === 'chat-event') {
          this.trackEvent(event.data.event, event.data.data);
        }
      };
      window.addEventListener('message', messageHandler);
      this.eventListeners.push({ target: window, type: 'message', handler: messageHandler });

      // Track user interactions on host page
      if (this.getConfig().tracking) {
        this.trackUserBehavior();
      }

      // Auto-open if configured
      if (this.getConfig().autoOpen) {
        setTimeout(() => this.openWidget(), 2000);
      }
    }

    toggleWidget() {
      if (this.isOpen) {
        this.closeWidget();
      } else {
        this.openWidget();
      }
    }

    openWidget() {
      const container = this.shadowRoot.getElementById('widget-container');
      const toggleBtn = this.shadowRoot.getElementById('widget-toggle');
      
      container.classList.add('open');
      container.classList.remove('minimized');
      toggleBtn.style.display = 'none';
      this.isOpen = true;
      this.isMinimized = false;
      
      this.trackEvent('widget_opened');
    }

    closeWidget() {
      const container = this.shadowRoot.getElementById('widget-container');
      const toggleBtn = this.shadowRoot.getElementById('widget-toggle');
      
      container.classList.remove('open');
      container.classList.remove('minimized');
      toggleBtn.style.display = 'flex';
      this.isOpen = false;
      this.isMinimized = false;
      
      this.trackEvent('widget_closed');
    }

    minimizeWidget() {
      const container = this.shadowRoot.getElementById('widget-container');
      
      if (this.isMinimized) {
        container.classList.remove('minimized');
        this.isMinimized = false;
        this.trackEvent('widget_expanded');
      } else {
        container.classList.add('minimized');
        this.isMinimized = true;
        this.trackEvent('widget_minimized');
      }
    }

    trackPageView() {
      this.trackEvent('page_view', {
        url: window.location.href,
        title: document.title,
        referrer: document.referrer,
      });
    }

    trackEvent(eventType, data = {}) {
      const event = {
        sessionId: this.sessionId,
        timestamp: Date.now(),
        eventType,
        url: window.location.href,
        ...data
      };
      
      this.analytics.push(event);
      
      // Send to parent application or analytics endpoint
      this.sendAnalytics(event);
    }

    trackUserBehavior() {
      // Track clicks
      const clickHandler = (e) => {
        this.trackEvent('click', {
          element: e.target.tagName,
          text: e.target.innerText?.substring(0, 50),
          x: e.clientX,
          y: e.clientY,
        });
      };
      document.addEventListener('click', clickHandler);
      this.eventListeners.push({ target: document, type: 'click', handler: clickHandler });

      // Track scrolling
      let scrollTimeout;
      const scrollHandler = () => {
        clearTimeout(scrollTimeout);
        scrollTimeout = setTimeout(() => {
          this.trackEvent('scroll', {
            scrollY: window.scrollY,
            scrollX: window.scrollX,
            scrollPercent: Math.round((window.scrollY / (document.documentElement.scrollHeight - window.innerHeight)) * 100),
          });
        }, 500);
      };
      window.addEventListener('scroll', scrollHandler);
      this.eventListeners.push({ target: window, type: 'scroll', handler: scrollHandler });

      // Track time on page
      let pageLoadTime = Date.now();
      const beforeUnloadHandler = () => {
        this.trackEvent('page_exit', {
          timeOnPage: Date.now() - pageLoadTime,
        });
      };
      window.addEventListener('beforeunload', beforeUnloadHandler);
      this.eventListeners.push({ target: window, type: 'beforeunload', handler: beforeUnloadHandler });

      // Track form interactions
      const submitHandler = (e) => {
        this.trackEvent('form_submit', {
          formId: e.target.id,
          formAction: e.target.action,
        });
      };
      document.addEventListener('submit', submitHandler);
      this.eventListeners.push({ target: document, type: 'submit', handler: submitHandler });
    }

    sendAnalytics(event) {
      // Send analytics data to your backend or analytics service
      // This can be customized based on your needs
      console.log('Analytics Event:', event);
      
      // Example: Send to analytics endpoint
      /*
      fetch('your-analytics-endpoint', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(event),
      });
      */
    }

    getAnalytics() {
      return {
        sessionId: this.sessionId,
        events: this.analytics,
        summary: this.getAnalyticsSummary(),
      };
    }

    getAnalyticsSummary() {
      return {
        totalEvents: this.analytics.length,
        clicks: this.analytics.filter(e => e.eventType === 'click').length,
        scrolls: this.analytics.filter(e => e.eventType === 'scroll').length,
        widgetOpened: this.analytics.some(e => e.eventType === 'widget_opened'),
      };
    }
  }

  // Register the custom element
  if (!customElements.get('ai-chat-widget')) {
    customElements.define('ai-chat-widget', AIChatWidget);
  }

  // Expose analytics API
  window.AIChatWidget = {
    getAnalytics: function() {
      const widget = document.querySelector('ai-chat-widget');
      return widget ? widget.getAnalytics() : null;
    }
  };
})();
