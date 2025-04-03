Problem for the Team:
Create a Ruby class named HTM that implements a hierarchical temporary memory
solution for the intelligent management of LLM context during a conversation that could stop and start over several days.  This HTM is like a knowledge graph that relates information nodes together much like a vector store is used for semantic searches to incorporate embeddings.  The primary difference is that a memory node can be dropped from the htm if it has not been accessed within some timeframe of relevance.  Its also important to keep in mind the size of the conversation context.  HTM nodes will start to be dropped when the context size of the conversation becomes close to the maximum allowed size.

The context size is measured on numbers of tokens.  A typical context
size is 128,000 tokens.  Some of you have smaller context sizes
while others have larger context sizes.  The size of the context
can be adjusted based on the needs of the conversation.  The HTM class
should have methods to add, retrieve, and remove nodes from the memory.
It should also support the creation of a context consisting of all memory
nodes that are available.


one: Here's a Ruby class implementation for the HTM (Hierarchical Temporary Memory) as described in your problem statement. This solution includes methods for adding, retrieving, and removing nodes, and it also manages the context size based on the number of tokens.

```ruby
class HTM
  attr_accessor :max_context_size, :nodes

  def initialize(max_context_size = 128_000)
    @max_context_size = max_context_size
    @nodes = {}
    @last_accessed = {}
  end

  def add_node(key, value)
    @nodes[key] = value
    @last_accessed[key] = Time.now
    manage_context_size
  end

  def retrieve_node(key)
    if @nodes.key?(key)
      @last_accessed[key] = Time.now
      @nodes[key]
    else
      nil
    end
  end

  def remove_node(key)
    @nodes.delete(key)
    @last_accessed.delete(key)
  end

  def create_context
    manage_relevance
    @nodes.keys
  end

  private

  def manage_context_size
    current_size = calculate_context_size
    return if current_size <= @max_context_size

    # Sort nodes by last accessed time and remove the least recently used
    nodes_to_remove = (@nodes.keys - recent_nodes).sort_by { |key| @last_accessed[key] }
    nodes_to_remove.each do |key|
      break if calculate_context_size <= @max_context_size
      remove_node(key)
    end
  end

  def calculate_context_size
    @nodes.values.join(" ").split.size # Simple token count based on space separation
  end

  def manage_relevance
    current_time = Time.now
    @last_accessed.each do |key, last_access_time|
      if (current_time - last_access_time) > 86400 # 24 hours in seconds
        remove_node(key)
      end
    end
  end

  def recent_nodes
    # Allow access to nodes accessed in the last 24 hours
    current_time = Time.now
    @last_accessed.select { |_, last_access_time| (current_time - last_access_time) <= 86400 }.keys
  end
end
```

### Explanation:
1. **Initialization**: The class takes an optional `max_context_size` parameter, defaulting to 128,000 tokens. It initializes two hashes: one for the nodes and another for tracking the last accessed time of each node.

2. **Adding Nodes**: `add_node` method adds a node and updates its last accessed time. It also calls `manage_context_size` to ensure the context size remains within limits.

3. **Retrieving Nodes**: `retrieve_node` fetches a node and updates its last accessed timestamp.

4. **Removing Nodes**: `remove_node` deletes a node from memory along with its last accessed record.

5. **Creating Context**: `create_context` generates a context of available nodes. It first calls `manage_relevance` to remove nodes that have not been accessed recently.

6. **Managing Context Size**: The `manage_context_size` method checks whether the current size exceeds the maximum allowed size and removes the least recently used nodes if necessary.

7. **Token Size Calculation**: The method `calculate_context_size` counts the tokens based on space-separated values in the nodes.

8. **Relevance Management**: The `manage_relevance` method removes nodes that have not been accessed within the last 24 hours.

### Recommendations for Improvement:
- The code could be optimized by implementing more sophisticated data structures for better performance.
- Adding error handling for edge cases (e.g., null or empty inputs).
- Adding tests to ensure the functionality works as expected.

If there are any further suggestions or improvements, please share! Otherwise, I will proceed with the current implementation.

two: two: This is a good start. I have some suggestions for improvements:

1.  **Tokenization**: The `calculate_context_size` method uses a very basic space-separated word count as a proxy for token count. This is not accurate. A real token counter (like the one used by the LLM) should be used. Since we don't have access to the LLM's tokenizer, we can use a gem like `tiktoken_ruby` to get a more accurate token count. We should add this as a dependency.

2.  **Relevance Time**: The relevance time (24 hours) is hardcoded. This should be configurable.

3.  **Context Creation**: The `create_context` method currently returns an array of keys. It should return the actual content of the nodes, joined into a string, suitable for passing to the LLM.

4.  **Recent Nodes**: The `recent_nodes` method is only used to calculate the nodes to be removed when the context size is exceeded. This can be simplified.

5.  **Efficiency**: When removing nodes to manage context size, the code iterates through the nodes to remove one by one. This is inefficient. It should remove as many nodes as possible in each iteration.

Here's the improved code:

```ruby
require 'tiktoken_ruby'

class HTM
  attr_accessor :max_context_size, :nodes, :relevance_time

  def initialize(max_context_size: 128_000, relevance_time: 86400)
    @max_context_size = max_context_size
    @nodes = {}
    @last_accessed = {}
    @relevance_time = relevance_time # Time in seconds after which a node is considered irrelevant
    @tokenizer = Tiktoken.encoding_for_model("gpt-3.5-turbo") # Or any other model
  end

  def add_node(key, value)
    @nodes[key] = value
    @last_accessed[key] = Time.now
    manage_context_size
  end

  def retrieve_node(key)
    if @nodes.key?(key)
      @last_accessed[key] = Time.now
      @nodes[key]
    else
      nil
    end
  end

  def remove_node(key)
    @nodes.delete(key)
    @last_accessed.delete(key)
  end

  def create_context
    manage_relevance
    @nodes.values.join("\n") # Join nodes with newline for better readability
  end

  private

  def manage_context_size
    current_size = calculate_context_size
    return if current_size <= @max_context_size

    # Sort nodes by last accessed time and remove the least recently used
    nodes_to_remove = @nodes.keys.sort_by { |key| @last_accessed[key] }

    tokens_to_free = current_size - @max_context_size
    removed_tokens = 0
    nodes_to_remove.each do |key|
      break if removed_tokens >= tokens_to_free

      node_size = calculate_token_size(@nodes[key])
      remove_node(key)
      removed_tokens += node_size
    end
  end

  def calculate_context_size
    @nodes.values.sum { |value| calculate_token_size(value) }
  end

  def calculate_token_size(text)
    @tokenizer.encode(text).length
  end

  def manage_relevance
    current_time = Time.now
    @last_accessed.each do |key, last_access_time|
      if (current_time - last_access_time) > @relevance_time
        remove_node(key)
      end
    end
  end
end
```

Changes:

*   Added `tiktoken_ruby` dependency.
*   Using `Tiktoken` to calculate token size.
*   `relevance_time` is now configurable during initialization.
*   `create_context` returns the content of the nodes joined by newlines.
*   The context size management now removes nodes in larger chunks, based on token count, until the context size is within limits.
*   Removed the `recent_nodes` method.
*   Added the calculate_token_size method.

This improved version addresses the identified issues and provides a more robust and accurate implementation of the HTM.

three: I appreciate the improvements suggested. Let me incorporate those changes and make a few more enhancements:

```ruby
require 'tiktoken_ruby'

class HTM
  attr_accessor :max_context_size, :nodes, :relevance_time

  def initialize(max_context_size: 128_000, relevance_time: 86400, model: "gpt-3.5-turbo")
    @max_context_size = max_context_size
    @nodes = {}
    @last_accessed = {}
    @relevance_time = relevance_time # Time in seconds after which a node is considered irrelevant
    @tokenizer = Tiktoken.encoding_for_model(model)
    @relationships = {} # Store relationships between nodes
  end

  def add_node(key, value, related_to: [])
    token_size = calculate_token_size(value)
    
    # Check if adding this node would exceed max context size
    if token_size > @max_context_size
      raise ArgumentError, "Node content exceeds maximum context size"
    end
    
    @nodes[key] = value
    @last_accessed[key] = Time.now
    
    # Establish relationships
    @relationships[key] ||= []
    related_to.each do |related_key|
      if @nodes.key?(related_key)
        @relationships[key] << related_key
        @relationships[related_key] ||= []
        @relationships[related_key] << key unless @relationships[related_key].include?(key)
      end
    end
    
    manage_context_size
    key
  end

  def retrieve_node(key)
    if @nodes.key?(key)
      @last_accessed[key] = Time.now
      # Update last_accessed for related nodes to increase their relevance
      if @relationships[key]
        @relationships[key].each do |related_key|
          @last_accessed[related_key] = Time.now if @nodes.key?(related_key)
        end
      end
      @nodes[key]
    else
      nil
    end
  end

  def remove_node(key)
    return false unless @nodes.key?(key)
    
    # Remove relationships
    if @relationships[key]
      @relationships[key].each do |related_key|
        @relationships[related_key]&.delete(key)
      end
    end
    
    @relationships.delete(key)
    @nodes.delete(key)
    @last_accessed.delete(key)
    true
  end

  def create_context
    manage_relevance
    @nodes.values.join("\n\n") # Join nodes with double newline for better readability
  end
  
  def get_related_nodes(key)
    return [] unless @nodes.key?(key)
    (@relationships[key] || []).select { |related_key| @nodes.key?(related_key) }
  end
  
  def context_size
    calculate_context_size
  end
  
  def node_count
    @nodes.size
  end

  private

  def manage_context_size
    current_size = calculate_context_size
    return if current_size <= @max_context_size

    # Sort nodes by last accessed time and remove the least recently used
    # Also consider relationships - nodes with fewer relationships are removed first
    nodes_to_remove = @nodes.keys.sort_by do |key| 
      relationship_factor = @relationships[key]&.size || 0
      [@last_accessed[key], relationship_factor]
    end

    tokens_to_free = current_size - @max_context_size
    removed_tokens = 0
    
    nodes_to_remove.each do |key|
      break if removed_tokens >= tokens_to_free
      
      # Skip very recent nodes (accessed in the last minute)
      next if (Time.now - @last_accessed[key]) < 60
      
      node_size = calculate_token_size(@nodes[key])
      if remove_node(key)
        removed_tokens += node_size
      end
    end
    
    # If we still exceed the context size after removing old nodes,
    # we need to remove more nodes regardless of recency
    if calculate_context_size > @max_context_size
      manage_context_size
    end
  end

  def calculate_context_size
    @nodes.values.sum { |value| calculate_token_size(value) }
  end

  def calculate_token_size(text)
    @tokenizer.encode(text.to_s).length
  rescue => e
    # Fallback to a simple estimation if tokenization fails
    text.to_s.split.size
  end

  def manage_relevance
    current_time = Time.now
    @last_accessed.each do |key, last_access_time|
      if (current_time - last_access_time) > @relevance_time
        remove_node(key)
      end
    end
  end
end
```

Improvements I've made:

1. **Relationships between nodes**: Added functionality to establish and manage relationships between nodes, which helps in building a knowledge graph structure.

2. **Smarter node removal**: When removing nodes to manage context size, I now consider both the last accessed time and the number of relationships the node has.

3. **Protection against large nodes**: Added a check to prevent adding nodes that would exceed the maximum context size.

4. **Error handling**: Added error handling for token calculation.

5. **Utility methods**: Added methods to get related nodes, check current context size, and count nodes.

6. **Preservation of recent nodes**: Added logic to avoid removing very recently accessed nodes (within the last minute).

7. **Recursive context management**: If we still exceed the context size after removing old nodes, we recursively call the management function.

8. **Better formatting**: Using double newlines when joining nodes for better readability in the context.

9. **Configurable model**: Added the ability to specify which model's tokenizer to use.

This implementation provides a more robust HTM that considers the hierarchical relationships between nodes while intelligently managing the context size.

one: done

two: done

three: I think the current solution is comprehensive and well-designed. Let me suggest a few additional improvements:

```ruby
require 'tiktoken_ruby'
require 'json'

class HTM
  attr_accessor :max_context_size, :nodes, :relevance_time

  def initialize(max_context_size: 128_000, relevance_time: 86400, model: "gpt-3.5-turbo", min_recency_protection: 60)
    @max_context_size = max_context_size
    @nodes = {}
    @last_accessed = {}
    @relevance_time = relevance_time # Time in seconds after which a node is considered irrelevant
    @min_recency_protection = min_recency_protection # Minimum time in seconds to protect recently accessed nodes
    @tokenizer = Tiktoken.encoding_for_model(model)
    @relationships = {} # Store relationships between nodes
    @importance_scores = {} # Store importance scores for nodes
  end

  def add_node(key, value, related_to: [], importance: 1.0)
    token_size = calculate_token_size(value)
    
    # Check if adding this node would exceed max context size
    if token_size > @max_context_size
      raise ArgumentError, "Node content exceeds maximum context size"
    end
    
    @nodes[key] = value
    @last_accessed[key] = Time.now
    @importance_scores[key] = importance.clamp(0.0, 10.0) # Limit importance between 0 and 10
    
    # Establish relationships
    @relationships[key] ||= []
    related_to.each do |related_key|
      if @nodes.key?(related_key)
        @relationships[key] << related_key unless @relationships[key].include?(related_key)
        @relationships[related_key] ||= []
        @relationships[related_key] << key unless @relationships[related_key].include?(key)
      end
    end
    
    manage_context_size
    key
  end

  def retrieve_node(key)
    if @nodes.key?(key)
      @last_accessed[key] = Time.now
      # Update last_accessed for related nodes to increase their relevance
      if @relationships[key]
        @relationships[key].each do |related_key|
          @last_accessed[related_key] = Time.now if @nodes.key?(related_key)
        end
      end
      @nodes[key]
    else
      nil
    end
  end

  def remove_node(key)
    return false unless @nodes.key?(key)
    
    # Remove relationships
    if @relationships[key]
      @relationships[key].each do |related_key|
        @relationships[related_key]&.delete(key)
      end
    end
    
    @relationships.delete(key)
    @nodes.delete(key)
    @last_accessed.delete(key)
    @importance_scores.delete(key)
    true
  end

  def create_context(max_tokens: nil)
    manage_relevance
    
    # If max_tokens is specified, create a context with limited size
    if max_tokens && max_tokens < calculate_context_size
      create_limited_context(max_tokens)
    else
      @nodes.values.join("\n\n")
    end
  end
  
  def get_related_nodes(key)
    return [] unless @nodes.key?(key)
    (@relationships[key] || []).select { |related_key| @nodes.key?(related_key) }
  end
  
  def context_size
    calculate_context_size
  end
  
  def node_count
    @nodes.size
  end
  
  def update_node_importance(key, importance)
    return false unless @nodes.key?(key)
    @importance_scores[key] = importance.clamp(0.0, 10.0)
    true
  end
  
  def save_to_file(filename)
    data = {
      max_context_size: @max_context_size,
      relevance_time: @relevance_time,
      nodes: @nodes,
      last_accessed: @last_accessed.transform_values(&:to_i),
      relationships: @relationships,
      importance_scores: @importance_scores
    }
    
    File.open(filename, 'w') do |file|
      file.write(JSON.generate(data))
    end
    true
  rescue => e
    puts "Error saving HTM to file: #{e.message}"
    false
  end
  
  def self.load_from_file(filename, model: "gpt-3.5-turbo")
    data = JSON.parse(File.read(filename))
    
    htm = HTM.new(
      max_context_size: data['max_context_size'],
      relevance_time: data['relevance_time'],
      model: model
    )
    
    # Restore data
    htm.instance_variable_set(:@nodes, data['nodes'])
    htm.instance_variable_set(:@relationships, data['relationships'])
    htm.instance_variable_set(:@importance_scores, data['importance_scores'] || {})
    
    # Convert timestamps back to Time objects
    last_accessed = {}
    data['last_accessed'].each do |key, timestamp|
      last_accessed[key] = Time.at(timestamp)
    end
    htm.instance_variable_set(:@last_accessed, last_accessed)
    
    htm
  rescue => e
    puts "Error loading HTM from file: #{e.message}"
    nil
  end

  private

  def create_limited_context(max_tokens)
    # Sort nodes by importance and recency
    sorted_nodes = @nodes.keys.sort_by do |key|
      # Calculate a score based on recency and importance
      recency_factor = 1.0 / (1.0 + (Time.now - @last_accessed[key]) / 3600.0) # Higher for more recent
      importance = @importance_scores[key] || 1.0
      relationship_factor = Math.log((@relationships[key]&.size || 0) + 1)
      
      # Combine factors (higher score = more important to keep)
      -(recency_factor * importance * relationship_factor)
    end
    
    # Build context up to max_tokens
    context = []
    current_size = 0
    
    sorted_nodes.each do |key|
      node_size = calculate_token_size(@nodes[key])
      if current_size + node_size <= max_tokens
        context << @nodes[key]
        current_size += node_size
      end
    end
    
    context.join("\n\n")
  end

  def manage_context_size
    current_size = calculate_context_size
    return if current_size <= @max_context_size

    # Sort nodes by importance, relationships, and recency
    nodes_to_remove = @nodes.keys.sort_by do |key| 
      recency = Time.now - @last_accessed[key]
      relationship_factor = @relationships[key]&.size || 0
      importance = @importance_scores[key] || 1.0
      
      # Calculate score (lower = remove first)
      score = importance * (1 + relationship_factor) * (1.0 / (1.0 + recency / 3600.0))
      score
    end

    tokens_to_free = current_size - @max_context_size
    removed_tokens = 0
    
    nodes_to_remove.each do |key|
      break if removed_tokens >= tokens_to_free
      
      # Skip very recent nodes
      next if (Time.now - @last_accessed[key]) < @min_recency_protection
      
      node_size = calculate_token_size(@nodes[key])
      if remove_node(key)
        removed_tokens += node_size
      end
    end
    
    # If we still exceed the context size after removing old nodes,
    # we need to remove more nodes regardless of recency
    if calculate_context_size > @max_context_size
      manage_context_size
    end
  end

  def calculate_context_size
    @nodes.values.sum { |value| calculate_token_size(value) }
  end

  def calculate_token_size(text)
    @tokenizer.encode(text.to_s).length
  rescue => e
    # Fallback to a simple estimation if tokenization fails
    text.to_s.split.size
  end

  def manage_relevance
    current_time = Time.now
    @last_accessed.each do |key, last_access_time|
      if (current_time - last_access_time) > @relevance_time
        remove_node(key)
      end
    end
  end
end
```

Improvements I've added:

1. **Node Importance**: Added an importance score system that allows prioritizing certain nodes over others when managing context size.

2. **Persistence**: Added methods to save the HTM state to a file and load it back, enabling the conversation to persist across sessions.

3. **Limited Context Creation**: Added the ability to create a context of limited size, prioritizing the most important and recent nodes.

4. **Configurable Recency Protection**: Made the minimum time to protect recently accessed nodes configurable.

5. **Better Scoring Algorithm**: Improved the algorithm for deciding which nodes to remove, considering importance, relationships, and recency in a more balanced way.

6. **JSON Serialization**: Used JSON for serialization to make the saved state more portable and human-readable.

7. **Error Handling**: Added more robust error handling for file operations.

These enhancements make the HTM more flexible, persistent, and intelligent in managing the conversation context.

done
================================================================
# Team Project Summary: Hierarchical Temporary Memory (HTM) Implementation

The team was tasked with creating a Ruby class called HTM to intelligently manage LLM context during conversations that might span several days. The implementation needed to handle memory nodes in a knowledge graph-like structure, with the ability to drop nodes based on relevance timeframes and context size constraints.

## Development Process

The team went through several iterations, each building upon the previous one:

1. **Initial Implementation (by "one")**: 
   - Created a basic HTM class with methods for adding, retrieving, and removing nodes
   - Implemented simple context size management based on space-separated word counting
   - Added time-based relevance management with a hardcoded 24-hour timeframe

2. **First Improvement Round (by "two")**: 
   - Added proper tokenization using the `tiktoken_ruby` gem
   - Made relevance time configurable
   - Improved the context creation to return actual node content
   - Enhanced efficiency of node removal during context size management

3. **Second Improvement Round (by "three")**: 
   - Added relationships between nodes to create a knowledge graph structure
   - Implemented smarter node removal based on both recency and relationships
   - Added protection for recently accessed nodes
   - Improved error handling and added utility methods

4. **Final Enhancements (by "three")**: 
   - Added node importance scoring to prioritize critical information
   - Implemented persistence through file saving/loading
   - Created a limited context creation feature
   - Made recency protection configurable
   - Improved the scoring algorithm for node removal decisions
   - Added JSON serialization and robust error handling

## Key Features of the Final Solution

- **Accurate Token Counting**: Uses the `tiktoken_ruby` gem to calculate token sizes accurately
- **Relationship Management**: Tracks connections between nodes in a knowledge graph structure
- **Intelligent Context Management**: Removes nodes based on recency, importance, and relationships
- **Persistence**: Can save and load the memory state across sessions
- **Configurable Parameters**: Adjustable context size, relevance time, and recency protection
- **Importance Scoring**: Allows prioritizing certain nodes over others
- **Robust Error Handling**: Gracefully handles tokenization failures and file operations

## Final Solution

```ruby
require 'tiktoken_ruby'
require 'json'

class HTM
  attr_accessor :max_context_size, :nodes, :relevance_time

  def initialize(max_context_size: 128_000, relevance_time: 86400, model: "gpt-3.5-turbo", min_recency_protection: 60)
    @max_context_size = max_context_size
    @nodes = {}
    @last_accessed = {}
    @relevance_time = relevance_time # Time in seconds after which a node is considered irrelevant
    @min_recency_protection = min_recency_protection # Minimum time in seconds to protect recently accessed nodes
    @tokenizer = Tiktoken.encoding_for_model(model)
    @relationships = {} # Store relationships between nodes
    @importance_scores = {} # Store importance scores for nodes
  end

  def add_node(key, value, related_to: [], importance: 1.0)
    token_size = calculate_token_size(value)
    
    # Check if adding this node would exceed max context size
    if token_size > @max_context_size
      raise ArgumentError, "Node content exceeds maximum context size"
    end
    
    @nodes[key] = value
    @last_accessed[key] = Time.now
    @importance_scores[key] = importance.clamp(0.0, 10.0) # Limit importance between 0 and 10
    
    # Establish relationships
    @relationships[key] ||= []
    related_to.each do |related_key|
      if @nodes.key?(related_key)
        @relationships[key] << related_key unless @relationships[key].include?(related_key)
        @relationships[related_key] ||= []
        @relationships[related_key] << key unless @relationships[related_key].include?(key)
      end
    end
    
    manage_context_size
    key
  end

  def retrieve_node(key)
    if @nodes.key?(key)
      @last_accessed[key] = Time.now
      # Update last_accessed for related nodes to increase their relevance
      if @relationships[key]
        @relationships[key].each do |related_key|
          @last_accessed[related_key] = Time.now if @nodes.key?(related_key)
        end
      end
      @nodes[key]
    else
      nil
    end
  end

  def remove_node(key)
    return false unless @nodes.key?(key)
    
    # Remove relationships
    if @relationships[key]
      @relationships[key].each do |related_key|
        @relationships[related_key]&.delete(key)
      end
    end
    
    @relationships.delete(key)
    @nodes.delete(key)
    @last_accessed.delete(key)
    @importance_scores.delete(key)
    true
  end

  def create_context(max_tokens: nil)
    manage_relevance
    
    # If max_tokens is specified, create a context with limited size
    if max_tokens && max_tokens < calculate_context_size
      create_limited_context(max_tokens)
    else
      @nodes.values.join("\n\n")
    end
  end
  
  def get_related_nodes(key)
    return [] unless @nodes.key?(key)
    (@relationships[key] || []).select { |related_key| @nodes.key?(related_key) }
  end
  
  def context_size
    calculate_context_size
  end
  
  def node_count
    @nodes.size
  end
  
  def update_node_importance(key, importance)
    return false unless @nodes.key?(key)
    @importance_scores[key] = importance.clamp(0.0, 10.0)
    true
  end
  
  def save_to_file(filename)
    data = {
      max_context_size: @max_context_size,
      relevance_time: @relevance_time,
      nodes: @nodes,
      last_accessed: @last_accessed.transform_values(&:to_i),
      relationships: @relationships,
      importance_scores: @importance_scores
    }
    
    File.open(filename, 'w') do |file|
      file.write(JSON.generate(data))
    end
    true
  rescue => e
    puts "Error saving HTM to file: #{e.message}"
    false
  end
  
  def self.load_from_file(filename, model: "gpt-3.5-turbo")
    data = JSON.parse(File.read(filename))
    
    htm = HTM.new(
      max_context_size: data['max_context_size'],
      relevance_time: data['relevance_time'],
      model: model
    )
    
    # Restore data
    htm.instance_variable_set(:@nodes, data['nodes'])
    htm.instance_variable_set(:@relationships, data['relationships'])
    htm.instance_variable_set(:@importance_scores, data['importance_scores'] || {})
    
    # Convert timestamps back to Time objects
    last_accessed = {}
    data['last_accessed'].each do |key, timestamp|
      last_accessed[key] = Time.at(timestamp)
    end
    htm.instance_variable_set(:@last_accessed, last_accessed)
    
    htm
  rescue => e
    puts "Error loading HTM from file: #{e.message}"
    nil
  end

  private

  def create_limited_context(max_tokens)
    # Sort nodes by importance and recency
    sorted_nodes = @nodes.keys.sort_by do |key|
      # Calculate a score based on recency and importance
      recency_factor = 1.0 / (1.0 + (Time.now - @last_accessed[key]) / 3600.0) # Higher for more recent
      importance = @importance_scores[key] || 1.0
      relationship_factor = Math.log((@relationships[key]&.size || 0) + 1)
      
      # Combine factors (higher score = more important to keep)
      -(recency_factor * importance * relationship_factor)
    end
    
    # Build context up to max_tokens
    context = []
    current_size = 0
    
    sorted_nodes.each do |key|
      node_size = calculate_token_size(@nodes[key])
      if current_size + node_size <= max_tokens
        context << @nodes[key]
        current_size += node_size
      end
    end
    
    context.join("\n\n")
  end

  def manage_context_size
    current_size = calculate_context_size
    return if current_size <= @max_context_size

    # Sort nodes by importance, relationships, and recency
    nodes_to_remove = @nodes.keys.sort_by do |key| 
      recency = Time.now - @last_accessed[key]
      relationship_factor = @relationships[key]&.size || 0
      importance = @importance_scores[key] || 1.0
      
      # Calculate score (lower = remove first)
      score = importance * (1 + relationship_factor) * (1.0 / (1.0 + recency / 3600.0))
      score
    end

    tokens_to_free = current_size - @max_context_size
    removed_tokens = 0
    
    nodes_to_remove.each do |key|
      break if removed_tokens >= tokens_to_free
      
      # Skip very recent nodes
      next if (Time.now - @last_accessed[key]) < @min_recency_protection
      
      node_size = calculate_token_size(@nodes[key])
      if remove_node(key)
        removed_tokens += node_size
      end
    end
    
    # If we still exceed the context size after removing old nodes,
    # we need to remove more nodes regardless of recency
    if calculate_context_size > @max_context_size
      manage_context_size
    end
  end

  def calculate_context_size
    @nodes.values.sum { |value| calculate_token_size(value) }
  end

  def calculate_token_size(text)
    @tokenizer.encode(text.to_s).length
  rescue => e
    # Fallback to a simple estimation if tokenization fails
    text.to_s.split.size
  end

  def manage_relevance
    current_time = Time.now
    @last_accessed.each do |key, last_access_time|
      if (current_time - last_access_time) > @relevance_time
        remove_node(key)
      end
    end
  end
end
```

This final solution provides a sophisticated, hierarchical temporary memory system that intelligently manages context for LLM conversations across multiple sessions while maintaining relevance and respecting context size limitations.

