#### Using PG Vector for Embeddings

**Source:** https://gist.github.com/bricolage/24b472975556d955c84d9c7c58b7f34c#file-vector_search_models_and_service_class-rb

**Via:** Discord Ruby AI Builders group

> For anyone using Pgvector — how do you store your embeddings: 1️⃣) in a separate column on a table where the data lives or 2️⃣) separate table with a foreign key back to the table that contains the data that the embeddings where generated from?
>
> <@507918523671248896> same table but I use it in an abstract hierarchical data structure.
>
> What do you mean by “abstract hierarchical”? I understand the “hierarchical” part but what kind of abstraction?
>
> I have a ContentIndex model that has a tree of ContentNodes using the ancestry gem
>
> The ContentNodes have different types (source, summary) and different levels (document, chapter, paragraph, etc)
>
> So using pgvector and neighbor gem and active record queries I can scope vector queries with high precision


---


2023-10-20 - Matt Pelletier (bricolage on github)
MIT License

These AR models and service class are a simple but powerful way to organize and search data. You get all the power of pgvector plus the power of AR queries to scope them.

This part of my code does not leverage langchainrb (which I use), because a) this work preceded that gem and b) I wanted to use AR for scoping queries, and not just the namespace options with pgvector

I store a tree of content nodes, which represent a processed document (pdf, webpage, etc.). The tree stores both "big" chunks and small chunks. There was a paper about doing RAG using small chunk embeddings to retrieve results, but then returning the big chunks they came from for building the context for the LLM. This is not implemented yet but would be handled in GenerateContextUsingContentIndex#generate_context

ContentIndex - basically a top level concept of a "document". If you implement an ACL, this is the record that would have access assigned to it. Contains a root ContentNode, which then has children.

ContentNode - The nodes of the tree. Uses vanilla ancestry gem approach. Has various attributes and named scopes for traversing to find the right kind of thing. This gist is showing a vector search, so we're looking for source content chunks. If we were looking for summaries we'd use different AR query chaining.

**UserQuery** - Just an embeddings table to store the user's queries.

**GenerateContextUsingContentIndex** - Service class. Performs the vector search. Could be modified in all kinds of ways. Basically creates the embedding for the user query, then searches against source chunks in the tree. e.g. I have a variant service class where I pass in an array of content index ids so I can search across documents.

This uses the neighbor and ancestry gems.
