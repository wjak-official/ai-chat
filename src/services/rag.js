import { createClient } from '@supabase/supabase-js';
import { supabaseConfig, ragConfig } from '../config/supabase';
import { ollamaConfig } from '../config/ollama';

class RAGService {
  constructor() {
    this.supabase = null;
    this.enabled = supabaseConfig.enabled;
    
    if (this.enabled) {
      this.supabase = createClient(supabaseConfig.url, supabaseConfig.anonKey);
    }
  }

  isEnabled() {
    return this.enabled && this.supabase !== null;
  }

  async generateEmbedding(text) {
    try {
      const response = await fetch(`${ollamaConfig.apiEndpoint}/api/embeddings`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: ragConfig.embeddingModel,
          prompt: text,
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to generate embedding');
      }

      const data = await response.json();
      return data.embedding;
    } catch (error) {
      console.error('Error generating embedding:', error);
      throw error;
    }
  }

  async searchSimilarDocuments(query, limit = ragConfig.maxResults) {
    if (!this.isEnabled()) {
      return [];
    }

    try {
      const embedding = await this.generateEmbedding(query);

      const { data, error } = await this.supabase.rpc('match_documents', {
        query_embedding: embedding,
        match_threshold: ragConfig.similarityThreshold,
        match_count: limit,
      });

      if (error) {
        throw error;
      }

      return data || [];
    } catch (error) {
      console.error('Error searching documents:', error);
      return [];
    }
  }

  async addDocument(content, metadata = {}) {
    if (!this.isEnabled()) {
      return null;
    }

    try {
      const chunks = this.chunkText(content);
      const documents = [];

      for (const chunk of chunks) {
        const embedding = await this.generateEmbedding(chunk);

        const { data, error } = await this.supabase
          .from(ragConfig.documentsTable)
          .insert({
            content: chunk,
            embedding,
            metadata,
          })
          .select()
          .single();

        if (error) {
          throw error;
        }

        documents.push(data);
      }

      return documents;
    } catch (error) {
      console.error('Error adding document:', error);
      throw error;
    }
  }

  chunkText(text, chunkSize = ragConfig.chunkSize, overlap = ragConfig.chunkOverlap) {
    // Validate to prevent infinite loop
    if (overlap >= chunkSize) {
      console.warn(`chunkOverlap (${overlap}) must be less than chunkSize (${chunkSize}). Using overlap = max(0, chunkSize - 1).`);
      overlap = Math.max(0, chunkSize - 1);
    }
    
    const chunks = [];
    let start = 0;

    while (start < text.length) {
      const end = Math.min(start + chunkSize, text.length);
      chunks.push(text.slice(start, end));
      start += chunkSize - overlap;
    }

    return chunks;
  }

  async indexWebsiteContent(url, content, metadata = {}) {
    if (!this.isEnabled()) {
      return null;
    }

    const documentMetadata = {
      url,
      indexed_at: new Date().toISOString(),
      ...metadata,
    };

    return await this.addDocument(content, documentMetadata);
  }

  async getRelevantContext(query) {
    if (!this.isEnabled()) {
      return '';
    }

    const documents = await this.searchSimilarDocuments(query);
    
    if (documents.length === 0) {
      return '';
    }

    return documents
      .map(doc => doc.content)
      .join('\n\n');
  }

  async buildContextualPrompt(query, systemPrompt) {
    const relevantContext = await this.getRelevantContext(query);

    if (!relevantContext) {
      return systemPrompt;
    }

    return `${systemPrompt}

You have access to the following information about this website:

${relevantContext}

Use this information to provide helpful and accurate responses about the website.`;
  }
}

export default new RAGService();
