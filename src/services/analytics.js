class AnalyticsService {
  constructor() {
    this.events = [];
    this.sessionId = this.generateSessionId();
    this.startTime = Date.now();
  }

  generateSessionId() {
    return `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  trackEvent(eventType, data = {}) {
    const event = {
      sessionId: this.sessionId,
      timestamp: Date.now(),
      eventType,
      ...data
    };
    
    this.events.push(event);
    
    // Limit stored events to prevent memory issues
    if (this.events.length > 1000) {
      this.events = this.events.slice(-500);
    }

    return event;
  }

  trackPageView(page) {
    return this.trackEvent('page_view', { page });
  }

  trackMessageSent(message, personality) {
    return this.trackEvent('message_sent', {
      messageLength: message.length,
      personality: personality?.id || 'unknown'
    });
  }

  trackMessageReceived(message, personality, responseTime) {
    return this.trackEvent('message_received', {
      messageLength: message.length,
      personality: personality?.id || 'unknown',
      responseTime
    });
  }

  trackPersonalityChange(fromPersonality, toPersonality) {
    return this.trackEvent('personality_change', {
      from: fromPersonality?.id || 'none',
      to: toPersonality?.id || 'unknown'
    });
  }

  trackModelChange(fromModel, toModel) {
    return this.trackEvent('model_change', {
      from: fromModel || 'none',
      to: toModel || 'unknown'
    });
  }

  trackError(error, context = {}) {
    return this.trackEvent('error', {
      error: error.message || String(error),
      context
    });
  }

  trackUserInteraction(interactionType, details = {}) {
    return this.trackEvent('user_interaction', {
      interactionType,
      ...details
    });
  }

  getSessionSummary() {
    const now = Date.now();
    const duration = now - this.startTime;
    
    const summary = {
      sessionId: this.sessionId,
      startTime: this.startTime,
      duration,
      eventCount: this.events.length,
      eventTypes: {},
      messagesSent: 0,
      messagesReceived: 0,
      personalityChanges: 0,
      errors: 0
    };

    this.events.forEach(event => {
      summary.eventTypes[event.eventType] = (summary.eventTypes[event.eventType] || 0) + 1;
      
      if (event.eventType === 'message_sent') summary.messagesSent++;
      if (event.eventType === 'message_received') summary.messagesReceived++;
      if (event.eventType === 'personality_change') summary.personalityChanges++;
      if (event.eventType === 'error') summary.errors++;
    });

    return summary;
  }

  getEvents(filter = {}) {
    let filteredEvents = this.events;

    if (filter.eventType) {
      filteredEvents = filteredEvents.filter(e => e.eventType === filter.eventType);
    }

    if (filter.startTime) {
      filteredEvents = filteredEvents.filter(e => e.timestamp >= filter.startTime);
    }

    if (filter.endTime) {
      filteredEvents = filteredEvents.filter(e => e.timestamp <= filter.endTime);
    }

    return filteredEvents;
  }

  exportData() {
    return {
      sessionId: this.sessionId,
      startTime: this.startTime,
      events: this.events,
      summary: this.getSessionSummary()
    };
  }

  clearEvents() {
    this.events = [];
  }

  resetSession() {
    this.events = [];
    this.sessionId = this.generateSessionId();
    this.startTime = Date.now();
  }
}

export default new AnalyticsService();
