export const supabaseConfig = {
  url: import.meta.env.VITE_SUPABASE_URL || '',
  anonKey: import.meta.env.VITE_SUPABASE_ANON_KEY || '',
  enabled: Boolean(import.meta.env.VITE_SUPABASE_URL && import.meta.env.VITE_SUPABASE_ANON_KEY),
};

export const ragConfig = {
  // Table names
  documentsTable: 'website_documents',
  embeddingsTable: 'website_embeddings',
  
  // Embedding settings
  embeddingModel: 'all-minilm',
  embeddingDimension: 384,
  
  // Search settings
  similarityThreshold: 0.7,
  maxResults: 5,
  
  // Chunk settings
  chunkSize: 500,
  chunkOverlap: 50,
};
