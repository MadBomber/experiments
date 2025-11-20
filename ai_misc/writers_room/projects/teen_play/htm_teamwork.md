Problem for the Team:
Create a Ruby class named HTM that implements a hierarchical temporary memory
solution for the intelligent management of LLM context during a conversation that could stop and start over an extended period of time.  This HTM is like a knowledge graph that relates information nodes together much like a vector store is used for semantic searches to incorporate embeddings.  The primary difference is that a memory node can be dropped from the htm if it has not been accessed within some timeframe of relevance.  Its also important to keep in mind the size of the conversation context.  HTM nodes will start to be dropped when the context size of the conversation becomes close to the maximum allowed size.

The context size is measured on numbers of tokens.  A typical context
size is 128,000 tokens.  Some LLMs have a smaller context sizes
while others have larger context sizes.  The size of the context
can be adjusted based on the needs of the conversation and the LLM that is being used.
The HTM class
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

================================================================
# Brainstorming Session: Future Capabilities for HTM
**Date**: 2025-10-24
**Participants**: Dewayne (user), Claude Code

## Review of Current Implementation

### Strengths
1. Iterative refinement through team collaboration
2. Practical token counting using `tiktoken_ruby`
3. Multi-factor scoring (recency, importance, relationships)
4. Persistence via save/load functionality
5. Bidirectional relationship tracking for knowledge graph structure

### Identified Issues
1. **Recursive removal risk** (lines 605-607): Infinite loop potential if nodes are protected by `@min_recency_protection` but context still exceeds limits
2. **Performance concerns**:
   - Token counts recalculated repeatedly for same content
   - Should cache token sizes and invalidate on change
3. **Relationship graph integrity**: Retrieving a node updates ALL related nodes' `last_accessed`, potentially preventing necessary cleanup
4. **Importance score guidance**: No documentation on what different scores mean (0.1 vs 1.0 vs 10.0)
5. **Thread safety**: Shared state could cause race conditions in concurrent contexts
6. **Missing validation**: No checks that `related_to` keys are valid or relationships form valid structures

## Proposed Enhanced Capabilities

### 1. Memory Types & Classification
Enable categorization of different kinds of memory:

```ruby
add_node(key, value, type: :fact, category: 'user_preference', ...)
```

**Memory Types:**
- **Facts**: Immutable information ("user's name is Dewayne")
- **Context**: Conversation state ("currently debugging HTM class")
- **Code**: Snippets, patterns, solutions discovered during coding
- **Preferences**: User settings, coding style preferences
- **Decisions**: "We decided to use tiktoken_ruby because..."
- **Questions**: Unresolved items to revisit later

**Benefits:**
- Different retention policies per type
- Facts can have longer relevance_time than context
- Questions can trigger reminders if unresolved

### 2. Smart Search & Retrieval
Beyond simple key-based retrieval:

```ruby
htm.search(query: "debugging patterns", type: :code, min_importance: 5.0)
htm.find_related(key, depth: 2)  # Traverse relationship graph
htm.recall_by_timeframe(days_ago: 7)
htm.semantic_search(text)  # If embeddings are enabled
```

**Use cases:**
- "What debugging techniques did we discuss last week?"
- "Find all code snippets related to token counting"
- "Show me all unresolved questions"

### 3. Automatic Memory Compression
Intelligently compress aging memories:

```ruby
htm.compress_old_memories(older_than: 7.days)
```

**Strategies:**
- Summarize aging nodes while preserving key facts
- Merge redundant related nodes
- Create "summary nodes" from clusters of old memories
- Keep relationships intact during compression

**Example:**
- 5 nodes about "choosing tiktoken_ruby" → 1 summary node
- Original detail available if needed
- Saves tokens while preserving knowledge

### 4. Conflict Detection & Resolution
Track contradictions and changes:

```ruby
htm.add_node(key, "User prefers tabs", conflicts_with: ["User prefers spaces"])
htm.get_conflicts
htm.resolve_conflict(key, resolution: :keep_newer)
```

**Features:**
- Detect when new nodes contradict existing ones
- Track node versions/revision history
- Flag conflicts for user review
- Auto-resolution strategies (keep newer, keep higher importance, ask user)

### 5. Context Assembly Strategies
Different context building approaches for different tasks:

```ruby
htm.create_context(strategy: :recent)           # Just recent stuff
htm.create_context(strategy: :important)        # High importance only
htm.create_context(strategy: :related, seed: key) # Related to specific node
htm.create_context(strategy: :balanced)         # Mix of all factors
htm.create_context(strategy: :type, types: [:fact, :decision]) # Specific types
```

**Use cases:**
- `:recent` - Quick updates, current task focus
- `:important` - Critical information only, minimize tokens
- `:related` - Deep dive into specific topic area
- `:balanced` - Full context for complex reasoning

### 6. Conversation Threading
Manage multiple parallel conversation contexts:

```ruby
htm.start_thread(topic: "HTM implementation")
htm.switch_thread("debugging session")
htm.merge_threads("HTM implementation", "debugging session")
htm.archive_thread("completed feature X")
```

**Benefits:**
- Work on multiple tasks without context pollution
- Resume previous threads without losing context
- Merge related threads when topics converge
- Archive completed work but keep it searchable

### 7. Automatic Importance Scoring
Learn importance from usage patterns:

```ruby
htm.learn_importance  # Adjust scores based on usage patterns
```

**Factors to consider:**
- Retrieval frequency
- Number of relationships
- Edit/update history
- Explicit user feedback
- Role in successful outcomes

**Learning approach:**
- Track which nodes are accessed together
- Identify "hub" nodes that connect many others
- Boost importance of frequently retrieved nodes
- Decay importance of nodes that are never accessed

### 8. Memory Statistics & Introspection
Visibility into HTM's internal state:

```ruby
htm.stats  # Token usage, node counts, relationship density
htm.health_check  # Orphaned nodes, broken relationships, etc.
htm.visualize_graph  # Export to GraphViz/D3.js format
htm.memory_report  # What's taking up space? What's underutilized?
```

**Metrics to track:**
- Token utilization (current/max)
- Node count by type/category
- Relationship density and patterns
- Average node age
- Removal rate and reasons
- Cache hit rates (if caching implemented)

**Visualizations:**
- Graph structure (nodes and relationships)
- Timeline of memory additions/removals
- Token usage over time
- Importance distribution

### 9. Smart Decay & Forgetting
More sophisticated memory decay:

```ruby
htm.pin_node(key)  # Never remove this
htm.set_decay_rate(key, rate: 0.5)  # Slower decay
htm.configure_decay(type: :fact, strategy: :linear, rate: 0.1)
htm.configure_decay(type: :context, strategy: :exponential, half_life: 3600)
```

**Features:**
- Different decay rates for different node types
- "Rehearsal" - frequently accessed nodes stay fresh
- Exponential vs linear decay options
- Pin critical nodes to never forget
- Decay based on importance score

**Biological inspiration:**
- Short-term vs long-term memory
- Spaced repetition strengthens memories
- Unused memories fade naturally

### 10. Integration Points
Connect HTM with external systems:

```ruby
htm.export_for_llm(format: :markdown)  # Format for Claude
htm.export_for_llm(format: :json)      # Format for function calls
htm.integrate_embeddings(service: :openai)  # Add semantic search
htm.sync_to_vector_store(store)  # Backup to vector DB
htm.import_from_conversation(messages)  # Extract nodes from chat history
```

**Integrations:**
- Vector stores (Chroma, Pinecone, Weaviate)
- Embedding services (OpenAI, Cohere)
- LLM providers (OpenAI, Anthropic, etc.)
- Graph databases (Neo4j)
- Traditional databases (PostgreSQL, SQLite)

### 11. Hooks & Events
React to memory operations:

```ruby
htm.on(:node_added) { |node| log_event(node) }
htm.on(:node_removed) { |node| archive_to_long_term_storage(node) }
htm.on(:node_updated) { |old, new| track_changes(old, new) }
htm.on(:context_overflow) { |size| alert_user }
htm.on(:conflict_detected) { |node1, node2| notify_user }
```

**Use cases:**
- Logging and auditing
- Archiving removed nodes to cold storage
- Triggering alerts on important events
- Syncing to external systems
- Debug tracing

### 12. Multi-Context Management (Namespaces)
Separate memory spaces for different purposes:

```ruby
htm.create_namespace(:work)
htm.create_namespace(:personal)
htm.use_namespace(:work)
htm.merge_namespaces(:work, :personal, into: :combined)
htm.share_nodes_between(:work, :personal, keys: [...])
```

**Use cases:**
- Separate work and personal conversations
- Project-specific contexts
- Shared vs private memory
- Team collaboration (shared namespace)

### 13. Learning & Adaptation
Improve over time based on outcomes:

```ruby
htm.feedback(node: key, helpful: true)
htm.optimize_relationships  # Prune unhelpful connections
htm.suggest_relationships   # Recommend new connections
htm.auto_importance        # Learn importance from feedback
```

**Learning approaches:**
- Track which nodes lead to successful outcomes
- Learn which relationship types are most useful
- Optimize context assembly based on LLM performance
- A/B test different strategies

### 14. Debugging & Development Tools
Support for development and troubleshooting:

```ruby
htm.explain_removal(key)  # Why was this node removed?
htm.simulate_add(key, value)  # What would happen if I add this?
htm.replay_session(date)  # Reconstruct HTM state from a specific date
htm.diff_states(state1, state2)  # What changed?
htm.validate_integrity  # Check for inconsistencies
htm.benchmark_operations  # Performance testing
```

**Features:**
- Transaction log of all operations
- Time-travel debugging
- "What-if" analysis
- Performance profiling
- Integrity checks

### 15. Conversation Continuity
Maintain coherent memory across sessions:

```ruby
htm.checkpoint  # Save current state as named checkpoint
htm.restore_checkpoint(name)
htm.diff_checkpoints(a, b)  # What changed between sessions?
htm.session_summary  # Summarize what happened this session
htm.auto_checkpoint(interval: 5.minutes)
```

**Benefits:**
- Undo/redo for conversations
- Branch conversations (try different approaches)
- Review what was learned in a session
- Safe experimentation

## Architecture Considerations

### Storage Backends
Should HTM support pluggable storage?

**Options:**
- **JSON files** (current): Simple, portable, human-readable
- **SQLite**: Better performance, transactions, queries
- **Redis**: Fast, distributed, pub/sub for events
- **PostgreSQL**: Full SQL, JSONB for flexibility
- **Neo4j**: Native graph database, powerful queries
- **Hybrid**: Hot storage (Redis) + Cold storage (PostgreSQL)

**Decision factors:**
- Scale (thousands vs millions of nodes)
- Concurrency needs
- Query complexity
- Deployment constraints

### Distributed/Shared Memory
Should multiple users/agents share HTM?

**Use cases:**
- Team collaboration on shared codebase
- Multiple AI agents coordinating
- User + assistant shared understanding
- Collective knowledge building

**Challenges:**
- Conflict resolution
- Access control (who can read/write what?)
- Synchronization
- Consistency guarantees

### Vector Store Integration
Should embeddings be first-class?

**Pros:**
- Semantic search is powerful
- Find related content without explicit relationships
- Discover unexpected connections

**Cons:**
- Embedding costs (API calls, compute)
- Storage overhead
- Complexity

**Hybrid approach:**
- Optional embedding support
- Use for semantic search supplement
- Cache embeddings to reduce costs

### Query Language
Should HTM have a DSL for complex queries?

```ruby
htm.query("type:fact AND importance:>5 AND age:<7d")
htm.query("related_to:xyz DEPTH 2")
```

**Benefits:**
- Powerful, flexible queries
- Composable filters
- Natural for complex use cases

**Alternatives:**
- Method chaining: `htm.filter(type: :fact).where { importance > 5 }`
- Simple methods for common cases

## Key Use Cases to Design For

### 1. Multi-day Coding Project
**Scenario:** Working on HTM implementation over a week

**Memory needs:**
- Remember architectural decisions
- Track bugs found and fixed
- Recall code patterns that work
- Remember what didn't work (avoid repeating)
- Track todos and open questions

**HTM features:**
- Decision nodes with high importance
- Bug/fix pairs as related nodes
- Code pattern nodes with examples
- Thread per major feature
- Checkpoints at end of each day

### 2. Research Assistant
**Scenario:** Literature review over weeks/months

**Memory needs:**
- Track sources and citations
- Remember key findings
- Link related research
- Track hypotheses and evidence
- Remember questions to explore

**HTM features:**
- Source nodes (facts, permanent)
- Finding nodes (linked to sources)
- Hypothesis nodes (updated as evidence grows)
- Question nodes (high importance, trigger reminders)
- Semantic search to find related research

### 3. Personal Assistant
**Scenario:** Long-term personal AI assistant

**Memory needs:**
- Learn preferences (tabs vs spaces, coding style)
- Remember habits and patterns
- Track recurring tasks
- Remember people, projects, contexts
- Adapt to changing preferences

**HTM features:**
- Preference nodes (persistent, high importance)
- Habit tracking (pattern detection)
- Template nodes for recurring tasks
- Person/project namespaces
- Conflict detection for changed preferences

### 4. Debugging Sessions
**Scenario:** Troubleshooting complex bug over days

**Memory needs:**
- What was tried and results
- Current hypotheses
- Code locations involved
- Reproduction steps
- Related bugs/solutions

**HTM features:**
- Experiment nodes (action + result)
- Hypothesis nodes (updated based on experiments)
- Code reference nodes
- Thread for this debugging session
- Relationship tracking (this affects that)

### 5. Learning Companion
**Scenario:** Teaching programming over time

**Memory needs:**
- What user already knows
- Identified knowledge gaps
- Learning progress
- Misconceptions to correct
- Personalized examples

**HTM features:**
- Knowledge nodes (track understanding level)
- Gap nodes (importance based on prerequisite needs)
- Progress tracking (update over time)
- Example nodes (tailored to user context)
- Spaced repetition for reinforcement

## Next Steps

### Immediate Priorities
1. Fix identified issues in current implementation
2. Add token caching for performance
3. Implement node types/categories
4. Add basic search capabilities
5. Improve documentation (especially importance scoring)

### Short-term Goals (Weeks 1-4)
1. Add memory compression
2. Implement context assembly strategies
3. Add statistics and introspection
4. Create comprehensive test suite
5. Add hooks/events system

### Medium-term Goals (Months 1-3)
1. Conversation threading
2. Conflict detection
3. Automatic importance learning
4. Pluggable storage backends
5. Vector store integration

### Long-term Vision (3-6 Months)
1. Distributed/shared memory
2. Advanced learning and adaptation
3. Query language
4. Multi-agent coordination
5. Production-ready with full docs

## Questions for Discussion

1. **Scope**: Should HTM focus on single-user or support multi-user from the start?
2. **Storage**: Start with JSON or go straight to SQLite for performance?
3. **Embeddings**: Core feature or optional plugin?
4. **API design**: Prioritize simplicity or power?
5. **Testing**: What test coverage level do we need?
6. **Documentation**: Auto-generate from code or write separately?
7. **Versioning**: How to handle backwards compatibility as HTM evolves?

## Ideas for Further Exploration

- **Temporal reasoning**: "What did I know on Tuesday?" vs "What do I know now?"
- **Confidence scores**: Track how certain we are about each node
- **Source attribution**: Where did this knowledge come from?
- **Privacy controls**: Mark nodes as sensitive/private
- **Export formats**: Markdown, JSON, GraphML, RDF
- **Collaboration**: Share memory graphs between users
- **Visualization**: Real-time graph browser
- **Natural language queries**: "What did we decide about caching?"
- **Automatic summarization**: Daily/weekly memory summaries
- **Integration with external tools**: IDE plugins, browser extensions

---

## Dewayne's Core Vision & Goals
**Date**: 2025-10-24

### Terminology
**Robot**: Any application that facilitates interaction between a user and an LLM.

### Core Principles

1. **Never Forget Unless Told**: The robot should NEVER forget anything unless explicitly instructed to do so by the user.

2. **Temporal Context Retrieval**: The user should be able to say:
   - "Remember that class we were discussing last week about HTM - here is something else I thought of"
   - The robot uses HTM capabilities to retrieve the topic context from the specified timeframe
   - That historical context gets added to the current conversation context

3. **Durability is Non-Negotiable**: HTM content must be durable and persist across sessions, restarts, and time.

### Architectural Implications

This vision requires a fundamental rethinking of the current HTM design:

#### Current Implementation Issues
- **Automatic forgetting by time**: The `relevance_time` parameter (24 hours) contradicts the "never forget" principle
- **Single-tier memory**: Treats all memory the same way
- **Token limits force deletion**: Current design deletes nodes when context is full
- **No long-term storage**: JSON files are a start but not sufficient for durability

#### Required Architecture: Two-Tier Memory System

```
┌─────────────────────────────────────────────────────────┐
│                    USER REQUEST                         │
│  "Remember that HTM class discussion from last week?"   │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              WORKING MEMORY (Active Context)            │
│  - Token-limited (e.g., 128K tokens)                    │
│  - Currently relevant to conversation                   │
│  - Actively managed for LLM context window              │
│  - Nodes can be evicted to Long-term Memory             │
└────────────────────┬────────────────────────────────────┘
                     │
                     │ Smart Retrieval
                     │ (time-based, topic-based, semantic)
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│           LONG-TERM MEMORY (Permanent Storage)          │
│  - Unlimited size (or very large)                       │
│  - All historical conversations and context             │
│  - Indexed by: time, topic, relationships, embeddings   │
│  - Never deleted (unless explicit user command)         │
│  - Durable storage (database, not just JSON)            │
└─────────────────────────────────────────────────────────┘
```

#### Key Design Changes

1. **Separation of Concerns**
   - **Long-term Memory**: Permanent storage, everything persists
   - **Working Memory**: Active context, token-limited, optimized for LLM consumption
   - **Smart Retrieval**: Bridge between the two, pulls relevant content from long-term into working memory

2. **No Automatic Time-Based Deletion**
   - Remove `relevance_time` concept for long-term memory
   - Working memory can evict nodes back to long-term storage (not deletion)
   - Only explicit `forget` commands truly delete

3. **Temporal and Topic Indexing**
   - Index all nodes by timestamp
   - Index by topic/category/tags
   - Support queries like:
     - "last week"
     - "when we discussed HTM"
     - "that class about memory management"

4. **Smart Context Assembly**
   ```ruby
   # User says: "Remember that HTM discussion from last week?"
   robot.recall(timeframe: "last week", topic: "HTM")
   # HTM retrieves relevant nodes from long-term storage
   # Adds them to working memory
   # Creates context for LLM
   ```

5. **Durable Storage Requirements**
   - **SQLite**: Good for single-user, embedded, ACID guarantees
   - **PostgreSQL**: Better for multi-user, scalability, advanced queries
   - **Hybrid**: SQLite for working memory + PostgreSQL for long-term
   - Must survive: crashes, restarts, system failures

#### New HTM Operations

```ruby
# Initialize with two-tier architecture
robot = Robot.new(
  working_memory_size: 128_000,  # tokens
  long_term_storage: :sqlite     # or :postgresql, :redis, etc.
)

# User interaction
robot.chat("Let's discuss the HTM class")
# HTM automatically stores conversation in long-term memory

# ... one week later ...

# User references past conversation
robot.chat("Remember that HTM class we discussed last week? I have more ideas")
# HTM retrieves relevant context from long-term memory
# Adds to working memory
# LLM has access to both current and historical context

# Explicit forget (only way to truly delete)
robot.forget(topic: "HTM", confirm: true)
# Removes from both working and long-term memory
```

#### Working Memory Management Strategies

When working memory is full but we need to add new content:

1. **Eviction to Long-term** (not deletion):
   ```ruby
   # Instead of deleting old nodes, move them to long-term storage
   evicted_nodes = working_memory.evict_least_important
   long_term_memory.store(evicted_nodes)
   ```

2. **Smart Retrieval**:
   ```ruby
   # When user references old context
   relevant_nodes = long_term_memory.search(
     timeframe: "last week",
     topic: "HTM",
     limit: 50  # Don't overload working memory
   )
   working_memory.add(relevant_nodes)
   ```

3. **Context Summarization**:
   ```ruby
   # For very old or large contexts, summarize before adding to working memory
   old_context = long_term_memory.get(timeframe: "3 months ago", topic: "HTM")
   summary = llm.summarize(old_context)
   working_memory.add(summary_node)
   ```

#### Search and Retrieval Requirements

To support "Remember that class we discussed last week":

1. **Temporal Search**:
   - "last week" → Time.now - 7.days
   - "yesterday" → Time.now - 1.day
   - "in March" → Specific date range
   - "recent" → Last N days

2. **Topic/Semantic Search**:
   - "HTM class" → Find nodes tagged/related to HTM
   - Keyword matching in node content
   - Semantic similarity (if embeddings enabled)

3. **Combined Search**:
   ```ruby
   htm.search(
     timeframe: 1.week.ago..Time.now,
     topic: "HTM",
     keywords: ["class", "discussion"],
     importance: :high,
     limit: 20
   )
   ```

#### Durability Implementation

1. **SQLite Approach** (recommended for single-user robot):
   ```ruby
   class HTM
     def initialize(db_path: "~/.robot/memory.db")
       @db = SQLite3::Database.new(db_path)
       setup_schema
       @working_memory = WorkingMemory.new(max_tokens: 128_000)
       @long_term = LongTermMemory.new(@db)
     end
   end
   ```

2. **Schema Design**:
   ```sql
   CREATE TABLE nodes (
     id INTEGER PRIMARY KEY,
     key TEXT UNIQUE NOT NULL,
     value TEXT NOT NULL,
     type TEXT,  -- fact, context, code, preference, decision, question
     category TEXT,
     importance REAL DEFAULT 1.0,
     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
     last_accessed TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
     token_count INTEGER,
     in_working_memory BOOLEAN DEFAULT 0
   );

   CREATE TABLE relationships (
     from_node_id INTEGER,
     to_node_id INTEGER,
     relationship_type TEXT,
     strength REAL DEFAULT 1.0,
     FOREIGN KEY (from_node_id) REFERENCES nodes(id),
     FOREIGN KEY (to_node_id) REFERENCES nodes(id)
   );

   CREATE TABLE tags (
     node_id INTEGER,
     tag TEXT,
     FOREIGN KEY (node_id) REFERENCES nodes(id)
   );

   CREATE INDEX idx_nodes_created_at ON nodes(created_at);
   CREATE INDEX idx_nodes_type ON nodes(type);
   CREATE INDEX idx_nodes_category ON nodes(category);
   CREATE INDEX idx_tags_tag ON tags(tag);
   ```

3. **Transaction Log** (for debugging and replay):
   ```sql
   CREATE TABLE operations_log (
     id INTEGER PRIMARY KEY,
     timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
     operation TEXT,  -- add, retrieve, remove, evict, recall
     node_key TEXT,
     details TEXT  -- JSON with additional info
   );
   ```

#### Example User Interaction Flow

```
User: "Let's design a memory system for robots"

Robot HTM:
1. Creates nodes for this conversation
2. Stores in both working memory and long-term storage
3. Tags with: topic="memory system", topic="robots", date=2025-10-24

User: [7 days later] "Remember that memory system we discussed last week?"

Robot HTM:
1. Parses query: timeframe="last week", topic="memory system"
2. Searches long-term storage:
   SELECT * FROM nodes
   WHERE created_at BETWEEN '2025-10-17' AND '2025-10-24'
   AND (value LIKE '%memory system%' OR key IN (
     SELECT node_id FROM tags WHERE tag = 'memory system'
   ))
3. Retrieves relevant nodes (HTM class discussion)
4. Checks working memory capacity
5. If needed, evicts less relevant nodes to make room
6. Adds retrieved nodes to working memory
7. Assembles context for LLM including both current and retrieved context

Robot: "Yes, we were designing the HTM class for hierarchical
       temporary memory management. You had concerns about
       durability and never forgetting. What new ideas do you have?"
```

#### Updated Priority List

Given this new understanding, priorities shift:

**Immediate (Week 1-2):**
1. ✅ Document the two-tier architecture
2. Design SQLite schema for long-term storage
3. Implement basic long-term storage with SQLite
4. Implement working memory with eviction (not deletion)
5. Add time-based search capability

**Short-term (Weeks 3-6):**
1. Implement smart retrieval between tiers
2. Add topic/keyword search
3. Implement explicit `forget` command
4. Add transaction logging
5. Create comprehensive tests

**Medium-term (Months 2-3):**
1. Add semantic search with embeddings (optional)
2. Implement context summarization for old/large contexts
3. Add visualization of memory graph
4. Performance optimization for large long-term storage
5. Add memory statistics and health monitoring

**Long-term (Months 3-6):**
1. Support for multiple robots sharing long-term memory
2. Advanced query language
3. Memory compression and archiving
4. Integration with vector stores
5. Production-ready documentation

### Architectural Decisions Made
**Date**: 2025-10-24

1. **Storage location**: ✅ **GLOBAL**
   - Single database at `~/.robot/memory.db`
   - All conversations across all robots in one place
   - Benefits: Unified memory, cross-robot learning, simpler architecture

2. **Retrieval strategy**: ✅ **RAG-LIKE TOPIC SEARCH**
   - Query for topic within timeframe
   - Use RAG (Retrieval-Augmented Generation) approach
   - Combine temporal filtering + semantic/topic search
   - Implementation: Embeddings for semantic search within time-bounded results

3. **Multi-robot memory**: ✅ **HIVE MIND**
   - All robots share the same global memory
   - Any robot can access any conversation/context
   - Benefits: Continuity across robots, shared learning, unified knowledge base
   - Track which robot created each node for debugging/attribution

4. **Database choice**: ✅ **TIMESCALEDB (PostgreSQL)**
   - Write-heavy workload (every conversation turn creates nodes)
   - Better concurrency than SQLite
   - Native pgvector extension for vector similarity search
   - Excellent full-text search capabilities
   - Better performance at scale
   - ACID compliance with better multi-client support
   - **TimescaleDB benefits**:
     - Optimized for time-series data (perfect for temporal queries)
     - Hypertables for automatic partitioning by time
     - Excellent compression for historical data
     - Fast time-range queries (our primary use case)
     - Built on PostgreSQL, all pgvector features work

5. **Database Connection**: ✅ **TIMESCALE CLOUD**
   - Hosted TimescaleDB instance
   - Connection URL: `postgres://tsdbadmin:***@cw7rxj91bm.srbbwwxn56.tsdb.cloud.timescale.com:37807/tsdb?sslmode=require`
   - SSL required (secure)
   - Cloud-hosted, accessible from anywhere
   - **Verified Extensions**:
     - ✅ PostgreSQL 17.6
     - ✅ TimescaleDB 2.22.1
     - ✅ pgvector 0.8.1 (for vector similarity search)
     - ✅ pg_trgm 1.6 (for fuzzy text matching)
     - ✅ ai 0.11.2 (AI/ML helpers - bonus)
     - ✅ vectorscale 0.8.0 (enhanced vector search - bonus)

### Implementation Implications

#### RAG-Based Retrieval Architecture

```
User: "Remember that HTM class we discussed last week?"

┌─────────────────────────────────────────────┐
│  1. Parse User Query                        │
│     - Timeframe: "last week"                │
│     - Topic: "HTM class"                    │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  2. Temporal Filter (SQL)                   │
│     WHERE created_at BETWEEN                │
│           2025-10-17 AND 2025-10-24         │
│     → Returns: 500 candidate nodes          │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  3. Topic/Semantic Search (RAG)             │
│     - Generate embedding for "HTM class"    │
│     - Compare with embeddings of 500 nodes  │
│     - Rank by semantic similarity           │
│     → Returns: Top 20 most relevant         │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  4. Load into Working Memory                │
│     - Check token budget                    │
│     - Evict if needed                       │
│     - Add retrieved nodes                   │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  5. Assemble Context for LLM                │
│     - Format nodes as markdown/text         │
│     - Include metadata (when, which robot)  │
│     - Send to LLM                           │
└─────────────────────────────────────────────┘
```

#### PostgreSQL Schema with pgvector

```sql
-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pgvector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;  -- For fuzzy text matching

-- Main nodes table
CREATE TABLE nodes (
  id BIGSERIAL PRIMARY KEY,
  key TEXT UNIQUE NOT NULL,
  value TEXT NOT NULL,
  type TEXT,  -- fact, context, code, preference, decision, question
  category TEXT,
  importance REAL DEFAULT 1.0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  last_accessed TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  token_count INTEGER,
  in_working_memory BOOLEAN DEFAULT FALSE,
  robot_id TEXT NOT NULL,
  embedding vector(1536)  -- OpenAI ada-002 uses 1536 dimensions
);

-- Relationships between nodes
CREATE TABLE relationships (
  id BIGSERIAL PRIMARY KEY,
  from_node_id BIGINT NOT NULL REFERENCES nodes(id) ON DELETE CASCADE,
  to_node_id BIGINT NOT NULL REFERENCES nodes(id) ON DELETE CASCADE,
  relationship_type TEXT,
  strength REAL DEFAULT 1.0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(from_node_id, to_node_id, relationship_type)
);

-- Tags for flexible categorization
CREATE TABLE tags (
  id BIGSERIAL PRIMARY KEY,
  node_id BIGINT NOT NULL REFERENCES nodes(id) ON DELETE CASCADE,
  tag TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(node_id, tag)
);

-- Operation log for debugging and replay
CREATE TABLE operations_log (
  id BIGSERIAL PRIMARY KEY,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  operation TEXT NOT NULL,  -- add, retrieve, remove, evict, recall
  node_id BIGINT REFERENCES nodes(id) ON DELETE SET NULL,
  robot_id TEXT NOT NULL,
  details JSONB  -- Flexible storage for additional metadata
);

-- Robots registry (track all robots using the system)
CREATE TABLE robots (
  id TEXT PRIMARY KEY,
  name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  last_active TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  metadata JSONB  -- Store robot-specific configuration
);

-- Indexes for performance
CREATE INDEX idx_nodes_created_at ON nodes(created_at);
CREATE INDEX idx_nodes_updated_at ON nodes(updated_at);
CREATE INDEX idx_nodes_last_accessed ON nodes(last_accessed);
CREATE INDEX idx_nodes_type ON nodes(type);
CREATE INDEX idx_nodes_category ON nodes(category);
CREATE INDEX idx_nodes_robot_id ON nodes(robot_id);
CREATE INDEX idx_nodes_in_working_memory ON nodes(in_working_memory);

-- Vector similarity search index (HNSW for better performance)
CREATE INDEX idx_nodes_embedding ON nodes
  USING hnsw (embedding vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);

-- Full-text search
CREATE INDEX idx_nodes_value_gin ON nodes USING gin(to_tsvector('english', value));
CREATE INDEX idx_nodes_key_gin ON nodes USING gin(to_tsvector('english', key));

-- Trigram indexes for fuzzy matching
CREATE INDEX idx_nodes_value_trgm ON nodes USING gin(value gin_trgm_ops);

-- Relationship indexes
CREATE INDEX idx_relationships_from ON relationships(from_node_id);
CREATE INDEX idx_relationships_to ON relationships(to_node_id);

-- Tags indexes
CREATE INDEX idx_tags_node_id ON tags(node_id);
CREATE INDEX idx_tags_tag ON tags(tag);

-- Operation log indexes
CREATE INDEX idx_operations_log_timestamp ON operations_log(timestamp);
CREATE INDEX idx_operations_log_robot_id ON operations_log(robot_id);
CREATE INDEX idx_operations_log_operation ON operations_log(operation);

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_nodes_updated_at
  BEFORE UPDATE ON nodes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- View for node statistics
CREATE VIEW node_stats AS
SELECT
  type,
  COUNT(*) as count,
  AVG(importance) as avg_importance,
  SUM(token_count) as total_tokens,
  MIN(created_at) as oldest,
  MAX(created_at) as newest
FROM nodes
GROUP BY type;

-- View for robot activity
CREATE VIEW robot_activity AS
SELECT
  r.id,
  r.name,
  COUNT(n.id) as total_nodes,
  MAX(n.created_at) as last_node_created
FROM robots r
LEFT JOIN nodes n ON n.robot_id = r.id
GROUP BY r.id, r.name;
```

#### PostgreSQL + pgvector Implementation

**Primary Approach: Native PostgreSQL with pgvector**

```ruby
require 'pg'
require 'pgvector'

class LongTermMemory
  def initialize(connection_config)
    @conn = PG.connect(connection_config)
    @conn.type_map_for_results = PG::BasicTypeMapForResults.new(@conn)
    # Register pgvector type
    PGVector.register(@conn)
  end

  def search(timeframe:, query:, limit: 20, embedding_service:)
    # 1. Generate query embedding
    query_embedding = embedding_service.embed(query)

    # 2. Combined temporal filter + vector similarity search
    # Uses cosine similarity (1 - cosine distance)
    results = @conn.exec_params(
      <<~SQL,
        SELECT
          id, key, value, type, category,
          importance, created_at, robot_id,
          token_count,
          1 - (embedding <=> $1::vector) as similarity
        FROM nodes
        WHERE created_at BETWEEN $2 AND $3
        ORDER BY embedding <=> $1::vector  -- cosine distance
        LIMIT $4
      SQL
      [
        query_embedding.to_s,  # pgvector expects string representation
        timeframe.begin,
        timeframe.end,
        limit
      ]
    )

    results.to_a
  end

  # Alternative: Full-text search (faster, no embedding cost)
  def search_fulltext(timeframe:, query:, limit: 20)
    @conn.exec_params(
      <<~SQL,
        SELECT
          id, key, value, type, category,
          importance, created_at, robot_id,
          token_count,
          ts_rank(to_tsvector('english', value), plainto_tsquery('english', $1)) as rank
        FROM nodes
        WHERE created_at BETWEEN $2 AND $3
        AND to_tsvector('english', value) @@ plainto_tsquery('english', $1)
        ORDER BY rank DESC
        LIMIT $4
      SQL
      [query, timeframe.begin, timeframe.end, limit]
    )
  end

  # Hybrid: Combine full-text pre-filter with vector search
  def search_hybrid(timeframe:, query:, limit: 20, embedding_service:, prefilter_limit: 100)
    query_embedding = embedding_service.embed(query)

    # First, use full-text search to get candidates (cheaper)
    # Then, re-rank with vector similarity (more accurate)
    @conn.exec_params(
      <<~SQL,
        WITH candidates AS (
          SELECT id, key, value, type, category,
                 importance, created_at, robot_id, token_count, embedding
          FROM nodes
          WHERE created_at BETWEEN $2 AND $3
          AND to_tsvector('english', value) @@ plainto_tsquery('english', $1)
          LIMIT $5
        )
        SELECT
          id, key, value, type, category,
          importance, created_at, robot_id, token_count,
          1 - (embedding <=> $4::vector) as similarity
        FROM candidates
        ORDER BY embedding <=> $4::vector
        LIMIT $6
      SQL
      [query, timeframe.begin, timeframe.end, query_embedding.to_s, prefilter_limit, limit]
    )
  end

  # Find related nodes through relationship graph
  def find_related(node_id, depth: 1, limit: 20)
    @conn.exec_params(
      <<~SQL,
        WITH RECURSIVE related_nodes AS (
          -- Base case: direct relationships
          SELECT
            to_node_id as node_id,
            relationship_type,
            1 as depth
          FROM relationships
          WHERE from_node_id = $1

          UNION

          -- Recursive case: follow relationships
          SELECT
            r.to_node_id as node_id,
            r.relationship_type,
            rn.depth + 1 as depth
          FROM relationships r
          JOIN related_nodes rn ON r.from_node_id = rn.node_id
          WHERE rn.depth < $2
        )
        SELECT DISTINCT n.*
        FROM nodes n
        JOIN related_nodes rn ON n.id = rn.node_id
        LIMIT $3
      SQL
      [node_id, depth, limit]
    )
  end

  # Search by tags
  def search_by_tags(tags:, timeframe: nil, limit: 20)
    if timeframe
      @conn.exec_params(
        <<~SQL,
          SELECT DISTINCT n.*
          FROM nodes n
          JOIN tags t ON n.id = t.node_id
          WHERE t.tag = ANY($1::text[])
          AND n.created_at BETWEEN $2 AND $3
          LIMIT $4
        SQL
        [tags, timeframe.begin, timeframe.end, limit]
      )
    else
      @conn.exec_params(
        <<~SQL,
          SELECT DISTINCT n.*
          FROM nodes n
          JOIN tags t ON n.id = t.node_id
          WHERE t.tag = ANY($1::text[])
          LIMIT $2
        SQL
        [tags, limit]
      )
    end
  end
end
```

**Performance Optimization: Prepared Statements**

```ruby
class LongTermMemory
  def initialize(connection_config)
    @conn = PG.connect(connection_config)
    PGVector.register(@conn)
    prepare_statements
  end

  private

  def prepare_statements
    # Prepare frequently used queries
    @conn.prepare('search_vector',
      <<~SQL
        SELECT id, key, value, type, category,
               importance, created_at, robot_id, token_count,
               1 - (embedding <=> $1::vector) as similarity
        FROM nodes
        WHERE created_at BETWEEN $2 AND $3
        ORDER BY embedding <=> $1::vector
        LIMIT $4
      SQL
    )

    @conn.prepare('search_fulltext',
      <<~SQL
        SELECT id, key, value, type, category,
               importance, created_at, robot_id, token_count,
               ts_rank(to_tsvector('english', value), plainto_tsquery('english', $1)) as rank
        FROM nodes
        WHERE created_at BETWEEN $2 AND $3
        AND to_tsvector('english', value) @@ plainto_tsquery('english', $1)
        ORDER BY rank DESC
        LIMIT $4
      SQL
    )

    @conn.prepare('add_node',
      <<~SQL
        INSERT INTO nodes (key, value, type, category, importance,
                          token_count, robot_id, embedding)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8::vector)
        RETURNING id
      SQL
    )
  end

  public

  def search(timeframe:, query:, limit: 20, embedding_service:)
    query_embedding = embedding_service.embed(query)
    @conn.exec_prepared('search_vector',
      [query_embedding.to_s, timeframe.begin, timeframe.end, limit]
    ).to_a
  end
end
```

#### TimescaleDB Setup and Configuration

**Database Connection via Environment Variables**

Database credentials are managed via environment variables in `~/.bashrc__tiger`:

```bash
# Source the Tiger database environment variables
source ~/.bashrc__tiger

# This loads:
# TIGER_SERVICE_NAME - Service identifier
# TIGER_DBNAME       - Database name
# TIGER_DBUSER       - Database user
# TIGER_DBPASS       - Database password
# TIGER_DBURL        - Full connection URL (preferred)
# TIGER_DBPORT       - Database port
```

**Database Initialization**

```ruby
require 'pg'
require 'uri'

class HTMDatabase
  class << self
    def setup(db_url = nil)
      config = parse_connection_url(db_url || ENV['TIGER_DBURL'])

      unless config
        raise "Database configuration not found. Please source ~/.bashrc__tiger"
      end

      # Connect to the database
      conn = PG.connect(config)

      # Verify TimescaleDB is available
      version = conn.exec("SELECT extversion FROM pg_extension WHERE extname='timescaledb'").first
      if version
        puts "TimescaleDB version: #{version['extversion']}"
      else
        puts "Warning: TimescaleDB extension not found"
      end

      # Run schema
      run_schema(conn)

      # Convert tables to hypertables for time-series optimization
      setup_hypertables(conn)

      conn.close
      puts "HTM database schema created successfully"
    end

    # Parse connection URL format
    def parse_connection_url(url)
      return nil unless url

      uri = URI.parse(url)
      params = URI.decode_www_form(uri.query || '').to_h

      {
        host: uri.host,
        port: uri.port,
        dbname: uri.path[1..-1],  # Remove leading /
        user: uri.user,
        password: uri.password,
        sslmode: params['sslmode'] || 'prefer'
      }
    end

    # Alternative: Build config from individual environment variables
    def parse_connection_params
      return nil unless ENV['TIGER_DBNAME']

      {
        host: ENV['TIGER_DBHOST'] || 'cw7rxj91bm.srbbwwxn56.tsdb.cloud.timescale.com',
        port: (ENV['TIGER_DBPORT'] || 37807).to_i,
        dbname: ENV['TIGER_DBNAME'],
        user: ENV['TIGER_DBUSER'],
        password: ENV['TIGER_DBPASS'],
        sslmode: 'require'
      }
    end

    def default_config
      # Prefer TIGER_DBURL if available
      if ENV['TIGER_DBURL']
        parse_connection_url(ENV['TIGER_DBURL'])
      elsif ENV['TIGER_DBNAME']
        parse_connection_params
      else
        nil
      end
    end

    private

    def run_schema(conn)
      # Enable required extensions
      conn.exec("CREATE EXTENSION IF NOT EXISTS pgvector")
      conn.exec("CREATE EXTENSION IF NOT EXISTS pg_trgm")

      # Create tables (schema SQL from earlier)
      schema = File.read(File.expand_path('../sql/schema.sql', __FILE__))
      conn.exec(schema)
    end

    def setup_hypertables(conn)
      # Convert operations_log to hypertable for time-series optimization
      # This is perfect for our append-only log
      begin
        conn.exec(
          "SELECT create_hypertable('operations_log', 'timestamp',
           if_not_exists => TRUE,
           migrate_data => TRUE)"
        )
        puts "Created hypertable for operations_log"
      rescue PG::Error => e
        puts "Note: Could not create hypertable: #{e.message}"
      end

      # Optionally convert nodes table to hypertable partitioned by created_at
      # This can improve query performance for time-range queries
      begin
        conn.exec(
          "SELECT create_hypertable('nodes', 'created_at',
           if_not_exists => TRUE,
           migrate_data => TRUE)"
        )
        puts "Created hypertable for nodes"

        # Enable compression for older data
        conn.exec(
          "ALTER TABLE nodes SET (
           timescaledb.compress,
           timescaledb.compress_segmentby = 'robot_id,type'
          )"
        )

        # Add compression policy: compress chunks older than 30 days
        conn.exec(
          "SELECT add_compression_policy('nodes', INTERVAL '30 days', if_not_exists => TRUE)"
        )
        puts "Enabled compression for nodes older than 30 days"
      rescue PG::Error => e
        puts "Note: Could not create hypertable for nodes: #{e.message}"
      end
    end
  end
end

# Usage:
# HTMDatabase.setup
# Or with custom URL:
# HTMDatabase.setup(ENV['TIGER_DBURL'])
```

**Benefits of TimescaleDB for HTM:**

1. **Hypertables**: Automatically partition data by time for better performance
2. **Compression**: Old memories get compressed automatically, saving space
3. **Time-range queries**: Optimized for `created_at BETWEEN ...` queries (our primary use case)
4. **Continuous aggregates**: Can pre-compute statistics efficiently
5. **Retention policies**: Easy to implement if we want to archive very old data

**Connection Pooling for Multiple Robots**

```ruby
require 'connection_pool'
require 'pg'

class HTMConnectionPool
  def self.instance
    @instance ||= ConnectionPool.new(size: 10, timeout: 5) do
      PG.connect(HTMDatabase.default_config)
    end
  end

  def self.with_connection(&block)
    instance.with(&block)
  end
end
```

#### Hive Mind Implementation (PostgreSQL)

```ruby
require 'pg'
require 'pgvector'
require 'securerandom'

class HTM
  attr_reader :robot_id, :robot_name

  def initialize(
    working_memory_size: 128_000,
    robot_id: SecureRandom.uuid,
    robot_name: nil,
    db_config: nil,
    embedding_service: :openai
  )
    @robot_id = robot_id
    @robot_name = robot_name || "robot_#{robot_id[0..7]}"
    @working_memory = WorkingMemory.new(max_tokens: working_memory_size)

    # Use connection pool for better performance
    @db_config = db_config || HTMDatabase.default_config
    @long_term = LongTermMemory.new(@db_config)
    @embedding_service = EmbeddingService.new(embedding_service)

    # Register this robot in the database
    register_robot
    update_last_active
  end

  def add_node(key, value, type: nil, category: nil, importance: 1.0, related_to: [], tags: [])
    # Generate embedding
    embedding = @embedding_service.embed(value)

    # Calculate token count
    token_count = calculate_tokens(value)

    # Store in long-term (with robot attribution)
    node_id = @long_term.add(
      key: key,
      value: value,
      type: type,
      category: category,
      importance: importance,
      token_count: token_count,
      robot_id: @robot_id,
      embedding: embedding
    )

    # Add relationships
    related_to.each do |related_key|
      @long_term.add_relationship(from: key, to: related_key)
    end

    # Add tags
    tags.each do |tag|
      @long_term.add_tag(node_id: node_id, tag: tag)
    end

    # Also add to working memory
    @working_memory.add(key, value, token_count: token_count)

    # Log the operation
    log_operation('add', node_id, { key: key, type: type })

    update_last_active
    node_id
  end

  def recall(timeframe:, topic:, limit: 20, strategy: :vector)
    parsed_timeframe = parse_timeframe(timeframe)

    # RAG-based retrieval using selected strategy
    nodes = case strategy
    when :vector
      @long_term.search(
        timeframe: parsed_timeframe,
        query: topic,
        limit: limit,
        embedding_service: @embedding_service
      )
    when :fulltext
      @long_term.search_fulltext(
        timeframe: parsed_timeframe,
        query: topic,
        limit: limit
      )
    when :hybrid
      @long_term.search_hybrid(
        timeframe: parsed_timeframe,
        query: topic,
        limit: limit,
        embedding_service: @embedding_service
      )
    end

    # Add to working memory (evict if needed)
    nodes.each do |node|
      if @working_memory.has_space?(node['token_count'])
        @working_memory.add(node['key'], node['value'],
                          token_count: node['token_count'],
                          from_recall: true)
      else
        # Evict least important from working memory
        evicted = @working_memory.evict_to_make_space(node['token_count'])
        @long_term.mark_evicted(evicted.map { |n| n[:key] })

        # Now add the recalled node
        @working_memory.add(node['key'], node['value'],
                          token_count: node['token_count'],
                          from_recall: true)
      end
    end

    # Log the operation
    log_operation('recall', nil, {
      timeframe: timeframe,
      topic: topic,
      count: nodes.length
    })

    update_last_active
    nodes
  end

  def retrieve(key)
    node = @long_term.retrieve(key)
    if node
      @long_term.update_last_accessed(key)
      log_operation('retrieve', node['id'], { key: key })
    end
    node
  end

  def forget(key, confirm: true)
    if confirm
      # In real implementation, this would prompt the user
      # For now, we'll just require explicit confirmation parameter
      raise ArgumentError, "Must explicitly confirm deletion" unless confirm == :confirmed
    end

    node_id = @long_term.get_node_id(key)
    @long_term.delete(key)
    @working_memory.remove(key)

    log_operation('forget', node_id, { key: key })
    update_last_active

    true
  end

  def create_context(strategy: :balanced, max_tokens: nil)
    @working_memory.assemble_context(strategy: strategy, max_tokens: max_tokens)
  end

  # Hive mind capabilities
  def which_robot_said(topic, limit: 100)
    results = @long_term.search_fulltext(
      timeframe: (Time.at(0)..Time.now),  # All time
      query: topic,
      limit: limit
    )

    results.group_by { |n| n['robot_id'] }
           .transform_values(&:count)
  end

  def conversation_timeline(topic, limit: 50)
    # Get chronological view of conversation about topic
    results = @long_term.search_fulltext(
      timeframe: (Time.at(0)..Time.now),
      query: topic,
      limit: limit
    )

    results.sort_by { |n| n['created_at'] }
           .map { |n| {
             timestamp: n['created_at'],
             robot: @long_term.get_robot_name(n['robot_id']),
             content: n['value'],
             type: n['type']
           }}
  end

  def memory_stats
    @long_term.stats.merge({
      robot_id: @robot_id,
      robot_name: @robot_name,
      working_memory: {
        current_tokens: @working_memory.token_count,
        max_tokens: @working_memory.max_tokens,
        utilization: @working_memory.utilization_percentage,
        node_count: @working_memory.node_count
      }
    })
  end

  private

  def register_robot
    @long_term.register_robot(@robot_id, @robot_name)
  end

  def update_last_active
    @long_term.update_robot_activity(@robot_id)
  end

  def log_operation(operation, node_id, details)
    @long_term.log_operation(
      operation: operation,
      node_id: node_id,
      robot_id: @robot_id,
      details: details
    )
  end

  def calculate_tokens(text)
    # Use tiktoken or similar
    @embedding_service.count_tokens(text)
  end

  def parse_timeframe(timeframe)
    case timeframe
    when Range
      timeframe
    when String
      parse_natural_timeframe(timeframe)
    else
      raise ArgumentError, "Invalid timeframe: #{timeframe}"
    end
  end

  def parse_natural_timeframe(text)
    # Simple parser for "last week", "yesterday", etc.
    case text.downcase
    when /last week/
      (Time.now - 7.days)..Time.now
    when /yesterday/
      (Time.now - 1.day).beginning_of_day..(Time.now - 1.day).end_of_day
    when /last (\d+) days/
      days = $1.to_i
      (Time.now - days.days)..Time.now
    when /this month/
      Time.now.beginning_of_month..Time.now
    else
      # Default to last 24 hours
      (Time.now - 1.day)..Time.now
    end
  end
end
```

#### Memory Statistics for Hive Mind (PostgreSQL)

```ruby
class LongTermMemory
  def stats
    conn = PG.connect(@config)

    {
      total_nodes: conn.exec("SELECT COUNT(*) FROM nodes").first['count'].to_i,
      nodes_by_robot: conn.exec(
        "SELECT robot_id, COUNT(*) as count
         FROM nodes
         GROUP BY robot_id"
      ).to_a.map { |r| [r['robot_id'], r['count'].to_i] }.to_h,
      nodes_by_type: conn.exec("SELECT * FROM node_stats").to_a,
      total_relationships: conn.exec("SELECT COUNT(*) FROM relationships").first['count'].to_i,
      total_tags: conn.exec("SELECT COUNT(*) FROM tags").first['count'].to_i,
      oldest_memory: conn.exec("SELECT MIN(created_at) FROM nodes").first['min'],
      newest_memory: conn.exec("SELECT MAX(created_at) FROM nodes").first['max'],
      active_robots: conn.exec("SELECT COUNT(*) FROM robots").first['count'].to_i,
      robot_activity: conn.exec("SELECT * FROM robot_activity").to_a,
      database_size: conn.exec("SELECT pg_database_size(current_database())").first['pg_database_size'].to_i,
      operations_count: conn.exec(
        "SELECT operation, COUNT(*) as count
         FROM operations_log
         GROUP BY operation"
      ).to_a.map { |r| [r['operation'], r['count'].to_i] }.to_h
    }
  ensure
    conn&.close
  end
end
```

#### Complete API Reference

**Core HTM Operations**

```ruby
# Initialize HTM
htm = HTM.new(
  working_memory_size: 128_000,    # Token limit for active context
  robot_id: "my-coding-assistant",  # Unique ID for this robot
  robot_name: "Code Helper",        # Human-readable name
  embedding_service: :openai        # or :cohere, :local
)

# Add memory nodes
htm.add_node(
  "htm_design_decision",
  "We decided to use PostgreSQL for its write performance and pgvector support",
  type: :decision,
  category: "architecture",
  importance: 8.0,
  related_to: ["database_choice", "rag_implementation"],
  tags: ["HTM", "PostgreSQL", "architecture"]
)

# Recall memories from the past
memories = htm.recall(
  timeframe: "last week",        # or Range: 7.days.ago..Time.now
  topic: "HTM architecture",     # Natural language query
  limit: 20,                     # Max nodes to retrieve
  strategy: :vector              # :vector, :fulltext, or :hybrid
)

# Retrieve specific memory
node = htm.retrieve("htm_design_decision")

# Forget (explicit deletion only)
htm.forget("old_idea", confirm: :confirmed)

# Create context for LLM
context = htm.create_context(
  strategy: :balanced,    # :recent, :important, :balanced
  max_tokens: 50_000     # Optional limit
)

# Hive mind queries
# Which robot discussed this topic?
robot_breakdown = htm.which_robot_said("PostgreSQL")
# => { "robot-123" => 15, "robot-456" => 8 }

# Get conversation timeline
timeline = htm.conversation_timeline("HTM design", limit: 50)
# => [{ timestamp: ..., robot: "...", content: "...", type: :decision }, ...]

# Memory statistics
stats = htm.memory_stats
```

**Working Memory Operations**

```ruby
class WorkingMemory
  def initialize(max_tokens:)
    @max_tokens = max_tokens
    @nodes = {}
    @access_order = []
    @importance_scores = {}
  end

  def add(key, value, token_count:, importance: 1.0, from_recall: false)
    # Add node to working memory
    @nodes[key] = {
      value: value,
      token_count: token_count,
      importance: importance,
      added_at: Time.now,
      from_recall: from_recall
    }
    update_access(key)
  end

  def has_space?(token_count)
    current_tokens + token_count <= @max_tokens
  end

  def evict_to_make_space(needed_tokens)
    evicted = []
    tokens_freed = 0

    # Sort by importance and recency
    candidates = @nodes.sort_by do |key, node|
      recency = Time.now - node[:added_at]
      [node[:importance], -recency]  # Lower importance first, then older
    end

    candidates.each do |key, node|
      break if tokens_freed >= needed_tokens

      evicted << { key: key, value: node[:value] }
      tokens_freed += node[:token_count]
      @nodes.delete(key)
      @access_order.delete(key)
    end

    evicted
  end

  def assemble_context(strategy:, max_tokens: nil)
    max = max_tokens || @max_tokens

    nodes = case strategy
    when :recent
      @access_order.reverse.map { |k| @nodes[k] }
    when :important
      @nodes.sort_by { |k, v| -v[:importance] }.map(&:last)
    when :balanced
      @nodes.sort_by { |k, v|
        recency = Time.now - v[:added_at]
        -(v[:importance] * (1.0 / (1 + recency / 3600.0)))
      }.map(&:last)
    end

    # Build context up to token limit
    context_parts = []
    current_tokens = 0

    nodes.each do |node|
      break if current_tokens + node[:token_count] > max
      context_parts << node[:value]
      current_tokens += node[:token_count]
    end

    context_parts.join("\n\n")
  end

  def token_count
    @nodes.values.sum { |n| n[:token_count] }
  end

  def utilization_percentage
    (token_count.to_f / @max_tokens * 100).round(2)
  end

  def node_count
    @nodes.size
  end

  private

  def update_access(key)
    @access_order.delete(key)
    @access_order << key
  end
end
```

### Class Hierarchy and Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         HTM                                 │
│  (Main API - coordinates all components)                   │
│  - robot_id, robot_name                                     │
│  - add_node(), recall(), retrieve(), forget()              │
│  - create_context(), memory_stats()                        │
└──────────┬──────────────────────┬────────────────┬─────────┘
           │                      │                │
           ▼                      ▼                ▼
┌──────────────────┐   ┌────────────────┐   ┌──────────────┐
│  WorkingMemory   │   │ LongTermMemory │   │  Embedding   │
│                  │   │                │   │   Service    │
│ - Token-limited  │   │ - PostgreSQL   │   │              │
│ - Active context │   │ - Durable      │   │ - OpenAI     │
│ - Eviction logic │   │ - RAG search   │   │ - Cohere     │
│ - Context        │   │ - Relationships│   │ - Local      │
│   assembly       │   │ - Tags         │   │              │
└──────────────────┘   └────────┬───────┘   └──────────────┘
                                │
                ┌───────────────┼───────────────┐
                ▼               ▼               ▼
        ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
        │ PostgreSQL   │ │ Connection   │ │ HTMDatabase  │
        │ + pgvector   │ │    Pool      │ │   Setup      │
        │              │ │              │ │              │
        │ - Nodes      │ │ - Thread-safe│ │ - Schema     │
        │ - Relations  │ │ - Reusable   │ │ - Migration  │
        │ - Tags       │ │   connections│ │ - Init       │
        │ - Operations │ │              │ │              │
        └──────────────┘ └──────────────┘ └──────────────┘
```

**Key Components:**

1. **HTM**: Main API surface, orchestrates all components
2. **WorkingMemory**: In-memory, token-limited active context
3. **LongTermMemory**: PostgreSQL-backed permanent storage with RAG
4. **EmbeddingService**: Pluggable embedding generation
5. **HTMDatabase**: Database setup and schema management
6. **ConnectionPool**: Efficient connection management

### Implementation Roadmap

#### Phase 1: Foundation (Weeks 1-2)
**Goal**: Basic two-tier memory system working

- [ ] PostgreSQL schema creation
- [ ] HTMDatabase setup class
- [ ] Basic LongTermMemory with CRUD operations
- [ ] Basic WorkingMemory implementation
- [ ] Simple HTM class tying them together
- [ ] EmbeddingService with OpenAI support
- [ ] Basic tests

**Deliverable**: Can add nodes, store in PostgreSQL, retrieve by key

#### Phase 2: RAG Retrieval (Weeks 3-4)
**Goal**: Temporal + semantic search working

- [ ] pgvector integration
- [ ] Embedding generation and storage
- [ ] Temporal search (timeframe filtering)
- [ ] Vector similarity search
- [ ] Full-text search fallback
- [ ] Hybrid search strategy
- [ ] Natural timeframe parsing ("last week")

**Deliverable**: Can recall memories: `htm.recall(timeframe: "last week", topic: "HTM")`

#### Phase 3: Relationships & Tags (Week 5)
**Goal**: Knowledge graph functionality

- [ ] Relationship management (add, query, traverse)
- [ ] Tag system
- [ ] Recursive relationship queries
- [ ] Related node retrieval
- [ ] Tag-based search

**Deliverable**: Memory nodes connected in knowledge graph

#### Phase 4: Working Memory Management (Week 6)
**Goal**: Intelligent eviction and context assembly

- [ ] Token counting integration
- [ ] Eviction strategies (importance, recency, hybrid)
- [ ] Context assembly strategies (recent, important, balanced)
- [ ] Working memory optimization
- [ ] Automatic eviction when full

**Deliverable**: Working memory stays under token limit, smart eviction

#### Phase 5: Hive Mind Features (Week 7)
**Goal**: Multi-robot coordination

- [ ] Robot registry
- [ ] Robot attribution for all nodes
- [ ] Cross-robot queries (which_robot_said)
- [ ] Conversation timeline
- [ ] Robot activity tracking
- [ ] Connection pooling for concurrency

**Deliverable**: Multiple robots sharing one memory, queryable by robot

#### Phase 6: Operations & Observability (Week 8)
**Goal**: Debugging, monitoring, and operations

- [ ] Operations logging
- [ ] Memory statistics
- [ ] Health checks
- [ ] Database size monitoring
- [ ] Query performance tracking
- [ ] Debugging tools (explain_removal, etc.)

**Deliverable**: Full visibility into HTM operations

#### Phase 7: Advanced Features (Weeks 9-10)
**Goal**: Production-ready features

- [ ] Backup/export functionality
- [ ] Import from conversation history
- [ ] Memory compression for old nodes
- [ ] Soft delete (vs hard delete)
- [ ] Prepared statements for performance
- [ ] Query optimization

**Deliverable**: Production-ready HTM system

#### Phase 8: Polish & Documentation (Weeks 11-12)
**Goal**: Ready for real-world use

- [ ] Comprehensive test suite (unit, integration, performance)
- [ ] API documentation
- [ ] Usage examples
- [ ] Migration guide
- [ ] Performance benchmarks
- [ ] Security review
- [ ] Gem packaging

**Deliverable**: Published gem, full documentation

### Open Questions for Next Discussion

**Answered:**
1. ✅ Storage location: Global (`~/.robot/memory.db` → PostgreSQL `robot_memory`)
2. ✅ Retrieval strategy: RAG (temporal + semantic)
3. ✅ Multi-robot: Hive mind (shared memory)
4. ✅ Database: PostgreSQL with pgvector

**Still to Decide:**

1. **Embedding service default**:
   - **Recommendation**: Start with OpenAI (text-embedding-3-small), make it configurable
   - Easy to use, good quality, 1536 dimensions
   - Add Cohere/local later as alternatives

2. **Working memory size**:
   - **Recommendation**: User-configurable, default 128K tokens
   - Auto-detect LLM context window if possible
   - Allow override per robot instance

3. **Eviction strategy**:
   - **Recommendation**: Hybrid (importance × recency)
   - Formula: `score = importance * (1 / (1 + age_in_hours))`
   - Evict lowest scoring nodes first
   - Never evict nodes added in last 60 seconds

4. **Explicit forget confirmation**:
   - **Recommendation**: Require `confirm: :confirmed` parameter
   - Prevent accidental deletions
   - Option for soft delete (mark as deleted, don't show in queries, but keep in DB)

5. **Robot identification**:
   - **Recommendation**: UUID + optional human-readable name
   - robot_id: SecureRandom.uuid (unique, never changes)
   - robot_name: "Code Helper" (optional, can change)
   - Best of both worlds

6. **Backup/export**:
   - **Recommendation**: PostgreSQL native backups (pg_dump)
   - Add export to JSON for portability
   - Cloud sync: out of scope for v1, users can handle externally

### Next Steps

**Immediate (This Week):**
1. ✅ Finalize architectural decisions (DONE)
2. Create project structure
3. Set up PostgreSQL database schema
4. Write basic LongTermMemory class with PostgreSQL
5. Write basic WorkingMemory class
6. Create HTM class skeleton

**Short Term (Weeks 1-4):**
- Follow Phase 1 and Phase 2 of roadmap
- Get basic RAG retrieval working
- Write initial tests
- Create simple example/demo

**Questions for You:**
1. Should we start implementing now, or continue planning?
2. Do you agree with the recommendations for open questions?
3. Any other concerns or requirements before we begin coding?
4. What's your preferred project structure? (Standard Ruby gem layout?)

---

## Environment Setup (COMPLETED)
**Date**: 2025-10-24

### Database Connection Configured ✅

Database credentials are managed via `~/.bashrc__tiger` environment variables:

```bash
# Load database credentials
source ~/.bashrc__tiger

# Available variables:
# - TIGER_SERVICE_NAME (db-67977)
# - TIGER_DBNAME (tsdb)
# - TIGER_DBUSER (tsdbadmin)
# - TIGER_DBPASS (password)
# - TIGER_DBURL (full connection URL - preferred)
# - TIGER_DBPORT (37807)
```

### Verified Extensions ✅

All required PostgreSQL extensions are installed and enabled:
- ✅ TimescaleDB 2.22.1 (time-series optimization)
- ✅ pgvector 0.8.1 (vector similarity search)
- ✅ pg_trgm 1.6 (fuzzy text matching)
- ✅ ai 0.11.2 (AI/ML helpers - bonus)
- ✅ vectorscale 0.8.0 (enhanced vector search - bonus)

### Test Scripts Created ✅

- `test_connection.rb` - Verify database connectivity and extensions
- `enable_extensions.rb` - Enable required PostgreSQL extensions
- `SETUP.md` - Complete setup guide and troubleshooting

### Ready to Code ✅

All prerequisites are in place:
- ✅ Database configured and accessible
- ✅ All extensions enabled
- ✅ Connection verified
- ✅ Environment variables set up
- ✅ Setup documentation complete

**We are now ready to begin Phase 1 implementation!**

---
**End of Brainstorming Session**
