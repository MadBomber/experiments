-- scripts/sql/create_tables.sql

-- Connect to the dv_development database
-- Note: You may need to run this command separately if you're not already connected to the database
-- \c dv_development

-- ##########################################
-- Create the documents table
DROP TABLE IF EXISTS public.documents;

CREATE TABLE IF NOT EXISTS public.documents (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    filename TEXT NOT NULL UNIQUE
);

-- Add comments to the documents table
COMMENT ON TABLE public.documents IS 'Stores metadata for each document';
COMMENT ON COLUMN public.documents.id IS 'Auto-generated sequential primary key';
COMMENT ON COLUMN public.documents.title IS 'Title of the document';
COMMENT ON COLUMN public.documents.filename IS 'Filename of the document';

-- ##########################################
-- Create the contents table
DROP TABLE IF EXISTS public.contents;

CREATE TABLE IF NOT EXISTS public.contents (
    id SERIAL PRIMARY KEY,
    document_id INTEGER NOT NULL,
    line_number INTEGER NOT NULL,
    text TEXT NOT NULL,
    text_vector tsvector GENERATED ALWAYS AS (to_tsvector('english', text)) STORED,
    FOREIGN KEY (document_id) REFERENCES public.documents(id) ON DELETE CASCADE,
    CONSTRAINT unique_document_line UNIQUE (document_id, line_number)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_contents_document_id_line_number ON public.contents(document_id, line_number);
CREATE INDEX IF NOT EXISTS idx_contents_text_vector ON public.contents USING GIN (text_vector);

-- Add comments to the contents table
COMMENT ON TABLE public.contents IS 'Stores document content with line numbers, associated with documents';
COMMENT ON COLUMN public.contents.id IS 'Auto-generated sequential primary key';
COMMENT ON COLUMN public.contents.document_id IS 'Foreign key reference to the documents table';
COMMENT ON COLUMN public.contents.line_number IS 'Line number in the document';
COMMENT ON COLUMN public.contents.text IS 'The text content of the document line';
COMMENT ON COLUMN public.contents.text_vector IS 'tsvector representation of the text for full-text search';

-- ##########################################
-- Create the embeddings table
DROP TABLE IF EXISTS public.embeddings;

CREATE TABLE IF NOT EXISTS public.embeddings (
    id SERIAL PRIMARY KEY,
    document_id INTEGER NOT NULL,
    lines INT4RANGE NOT NULL,  -- Using the integer range type
    --
    -- CAUTION: The magic 2048 number comes from the use of the
    --          nomic-embed-text model for the vectorization.
    --          other models may have a different dimension.
    --
    values vector(2048),  -- Adjust the vector dimension as needed
    FOREIGN KEY (document_id) REFERENCES public.documents(id) ON DELETE CASCADE
);

-- Add comments to the embeddings table
COMMENT ON TABLE public.embeddings IS 'Stores embeddings for document line ranges';
COMMENT ON COLUMN public.embeddings.id IS 'Auto-generated sequential primary key';
COMMENT ON COLUMN public.embeddings.document_id IS 'Foreign key reference to the documents table';
COMMENT ON COLUMN public.embeddings.lines IS 'Integer range representing the lines covered by this embedding';
COMMENT ON COLUMN public.embeddings.values IS 'Vector representation of the embedding';

-- Create index for the embeddings table
CREATE INDEX IF NOT EXISTS idx_embeddings_document_id ON public.embeddings(document_id);
CREATE INDEX IF NOT EXISTS idx_embeddings_lines ON public.embeddings USING GIST (lines);  -- Index on lines

-- ##########################################
-- Create the pages table
DROP TABLE IF EXISTS public.pages;

CREATE TABLE IF NOT EXISTS public.pages (
    id SERIAL PRIMARY KEY,
    document_id INTEGER NOT NULL,
    page_number VARCHAR(50) NOT NULL,
    lines INT4RANGE NOT NULL,  -- Using the integer range type
    FOREIGN KEY (document_id) REFERENCES public.documents(id) ON DELETE CASCADE
);

-- Add comments to the pages table
COMMENT ON TABLE public.pages IS 'Stores information about pages in documents';
COMMENT ON COLUMN public.pages.id IS 'Auto-generated sequential primary key';
COMMENT ON COLUMN public.pages.document_id IS 'Foreign key reference to the documents table';
COMMENT ON COLUMN public.pages.page_number IS 'Page number of the document';
COMMENT ON COLUMN public.pages.lines IS 'Integer range representing the lines covered by this page';

-- Create index for the pages table
CREATE INDEX IF NOT EXISTS idx_pages_lines ON public.pages USING GIST (lines);  -- Index on lines

-- ##########################################
-- Create the structures table
DROP TABLE IF EXISTS public.structures;

CREATE TABLE IF NOT EXISTS public.structures (
    id SERIAL PRIMARY KEY,
    document_id INTEGER NOT NULL,
    block_name VARCHAR(255) NOT NULL,
    lines INT4RANGE NOT NULL,  -- Using the integer range type
    FOREIGN KEY (document_id) REFERENCES public.documents(id) ON DELETE CASCADE
);

-- Create an index on the lines field
CREATE INDEX IF NOT EXISTS idx_structures_lines ON public.structures USING GIST (lines);  -- Index on lines

-- Add comments to the structures table
COMMENT ON TABLE public.structures IS 'Stores block structures associated with documents';
COMMENT ON COLUMN public.structures.id IS 'Auto-generated sequential primary key';
COMMENT ON COLUMN public.structures.document_id IS 'Foreign key reference to the documents table';
COMMENT ON COLUMN public.structures.block_name IS 'Name of the block in the document';
COMMENT ON COLUMN public.structures.lines IS 'Integer range representing the lines covered by this block';
