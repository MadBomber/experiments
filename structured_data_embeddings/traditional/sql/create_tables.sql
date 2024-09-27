-- sql/create_tables.sql

-- Connect to the sd database
-- Note: You may need to run this command separately if you're not already connected to the database
-- \c sd



-- ##########################################
-- Create the embeddings table
DROP TABLE IF EXISTS public.embeddings;

CREATE TABLE IF NOT EXISTS public.embeddings (
    id SERIAL PRIMARY KEY,
    data JSON NOT NULL,
    content TEXT NOT NULL,  
    --
    -- CAUTION: The magic 768 number comes from the use of the
    --          nomic-embed-text model for the vectorization.
    --          other models may have a different dimension.
    --
    values vector(768)  -- Adjust the vector dimension as needed
);

-- Add comments to the embeddings table
COMMENT ON TABLE public.embeddings IS 'Stores embeddings for document line ranges';
COMMENT ON COLUMN public.embeddings.id IS 'Auto-generated sequential primary key';
COMMENT ON COLUMN public.embeddings.data IS 'JSON structured data';
COMMENT ON COLUMN public.embeddings.content IS 'Text representation of the structured data';
COMMENT ON COLUMN public.embeddings.values IS 'Vector representation of the embedding';

