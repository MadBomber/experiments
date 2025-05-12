# Fast MCP Knowledge Server

This is an example implementation of a Model Context Protocol (MCP) server using the fast-mcp Ruby gem. The server provides knowledge retrieval capabilities to augment AI prompts with relevant context from a knowledge base.

## Features

- Knowledge retrieval from text files using grep-based search
- Query expansion with synonyms
- Support for both AND and OR search logic
- Returns complete file content for context augmentation

## Setup

1. Install dependencies:

```bash
bundle install
```

2. Add knowledge files to the `knowledge_base` directory. Files can be in plain text or markdown format.

3. Start the server:

```bash
ruby server.rb
```

## Usage with AIA

This server can be used with the AIA gem's MCPClientAdapter. Configure the server in your AIA configuration:

1. Create a server definition JSON file:

```json
{
  "id": "knowledge",
  "name": "AIA Knowledge Server",
  "url": "http://localhost:3000",
  "authentication": false
}
```

2. Add the server definition to your AIA config.

3. Use the MCPClientAdapter to submit requests:

```ruby
client = AIA::MCPClientAdapter.new
response = client.submit_request("knowledge", prompt_text, {
  tools: [{
    name: "KnowledgeRetriever",
    arguments: {
      query: "your search query",
      max_files: 2,
      expand_query: true
    }
  }]
})
```

## Tool Parameters

- `query` (required): The search query to find relevant knowledge
- `knowledge_dir` (optional): Subdirectory within knowledge_base to search (default: "knowledge_base")
- `max_files` (optional): Maximum number of files to include (default: 1)
- `expand_query` (optional): Whether to expand query with synonyms (default: true)
- `require_all_terms` (optional): Use AND logic instead of OR (default: false)

## Roadmap

### Near-term improvements
- Add support for more file formats (PDF, DOCX, etc.)
- Improve synonym expansion with a more comprehensive dictionary
- Add caching for frequently accessed knowledge

### Future enhancements

1. **SQLite-vec Integration**
   - Implement vector storage using sqlite-vec extension
   - Convert text to embeddings for semantic search
   - Enable similarity-based retrieval rather than keyword matching

2. **Knowledge Management**
   - Add tools for adding/updating knowledge base
   - Create a simple web UI for knowledge management
   - Implement version control for knowledge base entries

3. **Advanced Retrieval**
   - Implement chunking for more precise context retrieval
   - Add support for different retrieval algorithms
   - Enable hybrid search (keyword + semantic)

4. **Performance Optimization**
   - Add indexing for faster search
   - Implement caching strategies
   - Support for concurrent requests
