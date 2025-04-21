# examples/fast_mcp_server/tools/knowledge_retriever.rb

require 'fast-mcp'
require 'open3'

class KnowledgeRetriever < FastMcp::Tool
  description "Retrieve relevant knowledge from the knowledge base to augment prompts"
  
  arguments do
    required(:query).filled(:string).description("Search query to find relevant knowledge")
    optional(:knowledge_dir).filled(:string).default("knowledge_base").description("Subdirectory of knowledge base to search in")
    optional(:max_files).filled(:integer).default(1).description("Maximum number of files to include in context")
    optional(:expand_query).filled(:bool).default(true).description("Whether to expand query with synonyms")
    optional(:require_all_terms).filled(:bool).default(false).description("If true, requires all terms to be present (AND logic); if false, any term can match (OR logic)")
  end
  
  def call(query:, knowledge_dir: "knowledge_base", max_files: 1, expand_query: true, require_all_terms: false)
    expanded_terms = expand_query ? expand_terms(query) : [query]
    
    # Get the full path to the knowledge directory
    knowledge_path = File.join(File.dirname(__FILE__), "..", knowledge_dir)
    
    # Run the search command
    results = search_files(knowledge_path, expanded_terms, require_all_terms: require_all_terms)
    
    # Select top files
    top_files = results.sort_by { |file, hits| -hits }.first(max_files)
    
    # Read and return content of entire files
    knowledge_content = top_files.map do |file_path, hits|
      {
        source: File.basename(file_path),
        hits: hits,
        content: File.read(file_path)
      }
    end
    
    return knowledge_content
  end
  
  private
  
  def expand_terms(query)
    # Split the query into individual terms
    terms = query.downcase.split.uniq
    
    # Expand each term with synonyms
    expanded = terms.flat_map do |term|
      synonyms = get_synonyms(term)
      [term] + synonyms
    end
    
    expanded.uniq
  end
  
  def get_synonyms(word)
    # Basic synonym map
    # In a production environment, this could be replaced with a more comprehensive
    # synonym database or an API call to a thesaurus service
    synonyms = {
      "search" => ["find", "lookup", "query"],
      "file" => ["document", "text"],
      "code" => ["program", "script", "implementation"],
      "problem" => ["issue", "bug", "error"],
      "solution" => ["answer", "fix", "resolution"],
      # Add more as needed
    }
    
    synonyms[word] || []
  end
  
  def search_files(directory, terms, require_all_terms: false)
    results = {}
    
    if require_all_terms
      # AND logic - all terms must be present in the file
      matching_files = find_files_with_all_terms(directory, terms)
      
      # Then count total matches in each file
      matching_files.each do |file|
        count = count_matches_in_file(file, terms)
        results[file] = count if count > 0
      end
    else
      # OR logic - any term can match
      pattern = terms.join('\\|')
      
      cmd = ["grep", "-r", "--include=*.{txt,md}", "-i", "--count", pattern, directory]
      stdout, stderr, status = Open3.capture3(*cmd)
      
      stdout.each_line do |line|
        if line =~ /(.+):(\d+)/
          results[$1] = $2.to_i
        end
      end
    end
    
    # Return the file paths with their match counts
    results
  end
  
  # Helper for AND logic
  def find_files_with_all_terms(directory, terms)
    files = nil
    
    terms.each do |term|
      cmd = ["grep", "-r", "--include=*.{txt,md}", "-i", "-l", term, directory]
      stdout, stderr, status = Open3.capture3(*cmd)
      term_files = stdout.split("\n")
      
      if files.nil?
        files = term_files
      else
        files &= term_files # Set intersection
      end
      
      # Early exit if no files match all terms so far
      return [] if files.empty?
    end
    
    files || []
  end
  
  # Count matches for all terms in a specific file
  def count_matches_in_file(file, terms)
    pattern = terms.join('\\|')
    cmd = ["grep", "-i", "--count", pattern, file]
    stdout, stderr, status = Open3.capture3(*cmd)
    stdout.to_i
  end
end
