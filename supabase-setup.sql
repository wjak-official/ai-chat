-- AI Chat - Supabase Database Setup
-- Run this SQL in your Supabase SQL Editor to set up RAG functionality

-- Enable the vector extension for embeddings
create extension if not exists vector;

-- Create the website_documents table
create table if not exists website_documents (
  id bigserial primary key,
  content text not null,
  embedding vector(384),
  metadata jsonb default '{}'::jsonb,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Create an index for faster vector similarity search
create index if not exists website_documents_embedding_idx 
  on website_documents 
  using ivfflat (embedding vector_cosine_ops)
  with (lists = 100);

-- Create a function for similarity search
create or replace function match_documents (
  query_embedding vector(384),
  match_threshold float default 0.7,
  match_count int default 5
)
returns table (
  id bigint,
  content text,
  metadata jsonb,
  similarity float
)
language plpgsql
as $$
begin
  return query
  select
    website_documents.id,
    website_documents.content,
    website_documents.metadata,
    1 - (website_documents.embedding <=> query_embedding) as similarity
  from website_documents
  where 1 - (website_documents.embedding <=> query_embedding) > match_threshold
  order by website_documents.embedding <=> query_embedding
  limit match_count;
end;
$$;

-- Create a function to update the updated_at timestamp
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Create a trigger to automatically update updated_at
create trigger update_website_documents_updated_at
  before update on website_documents
  for each row
  execute function update_updated_at_column();

-- Enable Row Level Security (RLS)
alter table website_documents enable row level security;

-- Create policies for RLS (adjust based on your needs)
-- Allow public (anon) users to read documents
create policy "Allow public users to read documents"
  on website_documents for select
  to anon, authenticated
  using (true);

-- Allow authenticated users or service role to insert documents (not anon)
create policy "Allow authenticated users to insert documents"
  on website_documents for insert
  to authenticated
  with check (true);

-- Allow authenticated users to update documents
create policy "Allow authenticated users to update documents"
  on website_documents for update
  to authenticated
  using (true);

-- Allow authenticated users to delete documents
create policy "Allow authenticated users to delete documents"
  on website_documents for delete
  to authenticated
  using (true);

-- Create a view for document statistics (optional)
create or replace view document_stats as
select
  count(*) as total_documents,
  count(distinct metadata->>'url') as unique_urls,
  max(created_at) as last_indexed,
  pg_size_pretty(pg_total_relation_size('website_documents')) as table_size
from website_documents;

-- Grant access to the view
grant select on document_stats to authenticated;
