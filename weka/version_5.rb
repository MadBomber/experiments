require 'csv'
require 'matrix'
require 'set'

# Attribute class (unchanged)
class Attribute
  attr_reader :name, :type, :values

  def initialize(name, type = :numeric, values = nil)
    @name = name
    @type = type # :numeric, :nominal, :string
    @values = values
  end

  def numeric?; @type == :numeric; end
  def nominal?; @type == :nominal; end
  def to_s; "#{@name} (#{@type})"; end
end

# Dataset class (unchanged)
class Dataset
  attr_reader :attributes, :data, :class_index, :relation_name
  attr_accessor :data

  def initialize(relation_name = "Unnamed")
    @relation_name = relation_name
    @attributes = []
    @data = []
    @class_index = -1
  end

  def add_attribute(attribute); @attributes << attribute; end

  def add_instance(values)
    raise "Instance size mismatch" unless values.size == @attributes.size || values.is_a?(Hash)
    @data << (values.is_a?(Hash) ? values : values.dup)
  end

  def set_class_index(index); raise "Invalid index" unless index.between?(-1, @attributes.size - 1); @class_index = index; end

  def num_instances; @data.size; end
  def num_attributes; @attributes.size; end
  def class_attribute; @class_index >= 0 ? @attributes[@class_index] : nil; end

  def clone
    new_dataset = Dataset.new(@relation_name)
    @attributes.each { |attr| new_dataset.add_attribute(attr.dup) }
    @data.each { |inst| new_dataset.add_instance(inst.dup) }
    new_dataset.set_class_index(@class_index)
    new_dataset
  end

  def get_value(instance, idx)
    instance.is_a?(Hash) ? instance[idx] : instance[idx]
  end

  def to_s; "Dataset '#{@relation_name}' with #{num_instances} instances and #{num_attributes} attributes"; end

  def self.from_arff(file_path)
    dataset = Dataset.new
    data_section = false

    File.foreach(file_path) do |line|
      line = line.strip
      next if line.empty? || line.start_with?('%')

      if line.downcase.start_with?('@relation')
        dataset.instance_variable_set(:@relation_name, line.split[1].gsub(/['"]/, ''))
      elsif line.downcase.start_with?('@attribute')
        parts = line.split
        name = parts[1].gsub(/['"]/, '')
        type = parts[2..-1].join(' ')
        if type.start_with?('{')
          values = type[1..-2].split(',').map(&:strip)
          dataset.add_attribute(Attribute.new(name, :nominal, values))
        elsif type.downcase == 'numeric' || type.downcase == 'real'
          dataset.add_attribute(Attribute.new(name, :numeric))
        else
          dataset.add_attribute(Attribute.new(name, :string))
        end
      elsif line.downcase == '@data'
        data_section = true
      elsif data_section
        if line.start_with?('{')
          sparse = {}
          line[1..-2].split(',').each do |pair|
            idx, val = pair.strip.split
            sparse[idx.to_i] = val
          end
          dataset.add_instance(sparse)
        else
          dataset.add_instance(line.split(',').map(&:strip))
        end
      end
    end
    dataset
  end

  def to_arff(file_path)
    File.open(file_path, 'w') do |f|
      f.puts "@relation '#{@relation_name}'"
      @attributes.each do |attr|
        f.puts attr.nominal? ? "@attribute #{attr.name} {#{attr.values.join(',')}}" : "@attribute #{attr.name} #{attr.type}"
      end
      f.puts "@data"
      @data.each do |inst|
        if inst.is_a?(Hash)
          f.puts "{" + inst.map { |k, v| "#{k} #{v}" }.join(',') + "}"
        else
          f.puts inst.join(',')
        end
      end
    end
  end
end

# Base Classifier (unchanged)
class Classifier
  def build_classifier(dataset); raise NotImplementedError; end
  def classify_instance(instance); raise NotImplementedError; end
end

# KNN (unchanged)
class KNN < Classifier
  def initialize(k = 3); @k = k; end

  def build_classifier(dataset)
    raise "Class index not set" if dataset.class_index == -1
    @dataset = dataset.clone
  end

  def classify_instance(instance)
    distances = @dataset.data.map.with_index do |data_inst, idx|
      dist = euclidean_distance(instance, data_inst)
      [dist, idx]
    end
    k_nearest = distances.sort_by(&:first).take(@k)
    class_values = k_nearest.map { |_, idx| @dataset.get_value(@dataset.data[idx], @dataset.class_index) }
    class_values.tally.max_by(&:last)&.first
  end

  private

  def euclidean_distance(inst1, inst2)
    sum = 0
    @dataset.num_attributes.times do |i|
      v1 = inst1.is_a?(Hash) ? inst1[i] : inst1[i]
      v2 = inst2.is_a?(Hash) ? inst2[i] : inst2[i]
      v1 = v1.to_f rescue 0
      v2 = v2.to_f rescue 0
      sum += (v1 - v2) ** 2
    end
    sum ** 0.5
  end
end

# Naive Bayes (unchanged)
class NaiveBayes < Classifier
  def build_classifier(dataset)
    raise "Class index not set" if dataset.class_index == -1
    @dataset = dataset.clone
    @class_index = dataset.class_index
    @class_counts = dataset.data.group_by { |inst| dataset.get_value(inst, @class_index) }.transform_values(&:count)
    @priors = @class_counts.transform_values { |count| count.to_f / dataset.num_instances }
    @stats = compute_statistics
  end

  def classify_instance(instance)
    probabilities = @priors.map do |class_value, prior|
      likelihood = calculate_likelihood(instance, class_value)
      [class_value, Math.log(prior) + likelihood]
    end
    probabilities.max_by(&:last).first
  end

  private

  def compute_statistics
    stats = {}
    @class_counts.each_key do |class_value|
      instances = @dataset.data.select { |inst| @dataset.get_value(inst, @class_index) == class_value }
      stats[class_value] = @dataset.attributes.map.with_index do |attr, idx|
        next nil if idx == @class_index
        if attr.numeric?
          values = instances.map { |inst| @dataset.get_value(inst, idx).to_f rescue nil }.compact
          mean = values.sum / values.size
          variance = values.sum { |v| (v - mean) ** 2 } / [values.size - 1, 1].max
          [mean, variance]
        elsif attr.nominal?
          instances.tally { |inst| @dataset.get_value(inst, idx) }
        end
      end
    end
    stats
  end

  def calculate_likelihood(instance, class_value)
    @dataset.attributes.map.with_index do |attr, idx|
      next 0 if idx == @class_index
      value = @dataset.get_value(instance, idx)
      if attr.numeric? && value
        mean, variance = @stats[class_value][idx]
        next 0 if variance.zero?
        gaussian_probability(value.to_f, mean, variance)
      elsif attr.nominal?
        count = @stats[class_value][idx][value] || 0
        total = @class_counts[class_value]
        (count + 1).to_f / (total + @stats[class_value][idx].size)
      else
        0
      end
    end.sum
  end

  def gaussian_probability(x, mean, variance)
    exponent = -((x - mean) ** 2) / (2 * variance)
    -(Math.log(2 * Math::PI * variance) / 2) + exponent
  end
end

# Decision Tree (unchanged)
class DecisionTree < Classifier
  def build_classifier(dataset)
    raise "Class index not set" if dataset.class_index == -1
    @dataset = dataset.clone
    @tree = build_tree(dataset.data, dataset.attributes, dataset.class_index)
  end

  def classify_instance(instance)
    classify_with_tree(@tree, instance)
  end

  private

  def build_tree(data, attributes, class_index, depth = 0, max_depth = 10)
    return most_common_class(data, class_index) if depth >= max_depth || data.empty? || all_same_class?(data, class_index)

    best_attr, best_gain = find_best_attribute(data, attributes, class_index)
    return most_common_class(data, class_index) unless best_attr

    node = { attribute: best_attr, branches: {} }
    values = best_attr.nominal? ? best_attr.values : split_numeric(data, best_attr, class_index)
    values.each do |value|
      subset = data.select { |inst| match_value?(inst, best_attr, value, attributes.index(best_attr)) }
      node[:branches][value] = build_tree(subset, attributes - [best_attr], class_index, depth + 1, max_depth)
    end
    node
  end

  def match_value?(instance, attr, value, idx)
    inst_val = @dataset.get_value(instance, idx)
    attr.nominal? ? inst_val == value : (inst_val.to_f <= value rescue false)
  end

  def find_best_attribute(data, attributes, class_index)
    base_entropy = entropy(data, class_index)
    attributes.reject { |a| a == @dataset.attributes[class_index] }.map do |attr|
      gain = information_gain(data, attr, class_index, base_entropy)
      [attr, gain]
    end.max_by(&:last)
  end

  def entropy(data, class_index)
    counts = data.group_by { |inst| @dataset.get_value(inst, class_index) }.transform_values(&:count)
    counts.values.sum { |c| -c.to_f / data.size * Math.log2(c.to_f / data.size) rescue 0 }
  end

  def information_gain(data, attr, class_index, base_entropy)
    idx = @dataset.attributes.index(attr)
    if attr.nominal?
      subsets = attr.values.map { |v| data.select { |inst| @dataset.get_value(inst, idx) == v } }
    else
      threshold = split_numeric(data, attr, class_index).first
      subsets = [data.select { |inst| (@dataset.get_value(inst, idx).to_f <= threshold rescue false) },
                 data.select { |inst| (@dataset.get_value(inst, idx).to_f > threshold rescue false) }]
    end
    base_entropy - subsets.sum { |subset| subset.empty? ? 0 : (subset.size.to_f / data.size) * entropy(subset, class_index) }
  end

  def split_numeric(data, attr, class_index)
    idx = @dataset.attributes.index(attr)
    values = data.map { |inst| @dataset.get_value(inst, idx).to_f rescue nil }.compact.sort
    [values[values.size / 2]]
  end

  def all_same_class?(data, class_index)
    data.map { |inst| @dataset.get_value(inst, class_index) }.uniq.size <= 1
  end

  def most_common_class(data, class_index)
    data.group_by { |inst| @dataset.get_value(inst, class_index) }.max_by { |_, v| v.size }&.first
  end

  def classify_with_tree(tree, instance)
    return tree if tree.is_a?(String) || tree.nil?
    attr_idx = @dataset.attributes.index(tree[:attribute])
    value = @dataset.get_value(instance, attr_idx)
    branch_key = tree[:attribute].nominal? ? value : (value.to_f <= tree[:branches].keys.first ? tree[:branches].keys.first : tree[:branches].keys.last)
    classify_with_tree(tree[:branches][branch_key], instance)
  end
end

# SVM (unchanged)
class SVM < Classifier
  def initialize(learning_rate = 0.01, iterations = 1000)
    @learning_rate = learning_rate
    @iterations = iterations
  end

  def build_classifier(dataset)
    raise "Class index not set" if dataset.class_index == -1
    raise "SVM requires numeric data" unless dataset.attributes.all?(&:numeric?)
    @dataset = dataset.clone
    @weights = Vector.elements(Array.new(dataset.num_attributes - 1, 0.0))
    @bias = 0.0
    train
  end

  def classify_instance(instance)
    features = Vector.elements((0...@dataset.num_attributes).map { |i| i == @dataset.class_index ? 0 : @dataset.get_value(instance, i).to_f rescue 0 }[0...-1])
    (@weights.inner_product(features) + @bias) >= 0 ? @dataset.class_attribute.values[1] : @dataset.class_attribute.values[0]
  end

  private

  def train
    @iterations.times do
      @dataset.data.each do |instance|
        features = Vector.elements((0...@dataset.num_attributes).map { |i| i == @dataset.class_index ? 0 : @dataset.get_value(instance, i).to_f rescue 0 }[0...-1])
        y = @dataset.get_value(instance, @dataset.class_index) == @dataset.class_attribute.values[1] ? 1 : -1
        condition = y * (@weights.inner_product(features) + @bias)
        if condition < 1
          @weights += @learning_rate * (y * features - 2 * @learning_rate * @weights)
          @bias += @learning_rate * y
        end
      end
    end
  end
end

# Base Clusterer (unchanged)
class Clusterer
  def build_clusters(dataset); raise NotImplementedError; end
  def assign_instance(instance); raise NotImplementedError; end
end

# Improved K-Means Clustering with convergence checks
class KMeans < Clusterer
  def initialize(k = 3, max_iterations = 100, tolerance = 0.001)
    @k = k
    @max_iterations = max_iterations
    @tolerance = tolerance
  end

  def build_clusters(dataset)
    raise "KMeans requires numeric data" unless dataset.attributes.all?(&:numeric?)
    @dataset = dataset.clone
    @centroids = initialize_centroids
    @clusters = Array.new(@k) { [] }

    @max_iterations.times do |iteration|
      old_centroids = @centroids.map(&:dup)
      assign_to_clusters
      update_centroids
      break if converged?(old_centroids, @centroids)
      puts "Iteration #{iteration + 1}: Centroids updated"
    end

    @dataset.add_attribute(Attribute.new("cluster", :nominal, (0...@k).map { |i| "cluster#{i}" }))
    @dataset.data.each_with_index { |inst, i| inst << @clusters.find_index { |c| c.include?(inst) }.to_s }
  end

  def assign_instance(instance)
    distances = @centroids.map { |centroid| euclidean_distance(instance, centroid) }
    distances.index(distances.min)
  end

  private

  def initialize_centroids
    @dataset.data.shuffle.take(@k).map { |inst| inst.map { |v| v.to_f rescue 0 } }
  end

  def assign_to_clusters
    @clusters = Array.new(@k) { [] }
    @dataset.data.each do |inst|
      cluster_idx = assign_instance(inst)
      @clusters[cluster_idx] << inst
    end
  end

  def update_centroids
    @centroids = @clusters.map do |cluster|
      next @centroids[@clusters.index(cluster)] if cluster.empty?
      cluster.transpose.map { |vals| vals.sum { |v| v.to_f rescue 0 } / cluster.size }
    end
  end

  def converged?(old_centroids, new_centroids)
    old_centroids.zip(new_centroids).all? do |old, new|
      euclidean_distance(old, new) < @tolerance
    end
  end

  def euclidean_distance(inst1, inst2)
    inst1.zip(inst2).sum { |a, b| (a.to_f - b.to_f) ** 2 } ** 0.5
  end
end

# DBSCAN Clustering
class DBSCAN < Clusterer
  def initialize(eps = 0.5, min_pts = 4)
    @eps = eps # Maximum distance for points to be considered neighbors
    @min_pts = min_pts # Minimum points to form a cluster
  end

  def build_clusters(dataset)
    raise "DBSCAN requires numeric data" unless dataset.attributes.all?(&:numeric?)
    @dataset = dataset.clone
    @visited = Set.new
    @clusters = []
    @noise = []

    @dataset.data.each_with_index do |point, idx|
      next if @visited.include?(idx)
      @visited << idx
      neighbors = find_neighbors(idx)

      if neighbors.size >= @min_pts
        cluster = []
        expand_cluster(point, idx, neighbors, cluster)
        @clusters << cluster unless cluster.empty?
      else
        @noise << point
      end
    end

    # Add cluster assignments
    @dataset.add_attribute(Attribute.new("cluster", :nominal, (0...@clusters.size).map { |i| "cluster#{i}" } + ["noise"]))
    @dataset.data.each_with_index do |inst, i|
      cluster_idx = @clusters.find_index { |c| c.include?(inst) }
      inst << (cluster_idx ? "cluster#{cluster_idx}" : "noise")
    end
  end

  def assign_instance(instance)
    distances = @dataset.data.map.with_index { |p, i| [euclidean_distance(instance, p), i] }
    neighbors = distances.select { |dist, _| dist <= @eps }.map(&:last)
    return "noise" if neighbors.size < @min_pts

    # Find the closest cluster or noise
    cluster_counts = neighbors.group_by { |i| @dataset.get_value(@dataset.data[i], @dataset.num_attributes - 1) }
    cluster_counts.max_by { |_, v| v.size }&.first || "noise"
  end

  private

  def find_neighbors(point_idx)
    @dataset.data.each_with_index.select { |p, i| euclidean_distance(@dataset.data[point_idx], p) <= @eps && i != point_idx }.map(&:last)
  end

  def expand_cluster(point, point_idx, neighbors, cluster)
    cluster << point
    neighbors.each do |neighbor_idx|
      next if @visited.include?(neighbor_idx)
      @visited << neighbor_idx
      new_neighbors = find_neighbors(neighbor_idx)

      if new_neighbors.size >= @min_pts
        neighbors.concat(new_neighbors - neighbors)
      end
      cluster << @dataset.data[neighbor_idx] unless cluster.include?(@dataset.data[neighbor_idx])
    end
  end

  def euclidean_distance(inst1, inst2)
    inst1.zip(inst2).sum { |a, b| (a.to_f - b.to_f) ** 2 } ** 0.5
  end
end

# Base Association Rule Miner (unchanged)
class AssociationRuleMiner
  def build_rules(dataset); raise NotImplementedError; end
end

# Improved Apriori with pruning
class Apriori < AssociationRuleMiner
  def initialize(min_support = 0.1, min_confidence = 0.5)
    @min_support = min_support
    @min_confidence = min_confidence
  end

  def build_rules(dataset)
    raise "Apriori requires nominal data" unless dataset.attributes.all?(&:nominal?)
    @dataset = dataset.clone
    @itemsets = generate_frequent_itemsets
    @rules = generate_rules
  end

  def rules; @rules; end

  private

  def generate_frequent_itemsets
    items = @dataset.attributes.flat_map.with_index { |attr, i| attr.values.map { |v| [i, v] } }
    itemsets = {}
    support_counts = items.each_with_object(Hash.new(0)) do |item, counts|
      @dataset.data.each { |inst| counts[[item]] += 1 if inst.is_a?(Hash) ? inst[item[0]] == item[1] : inst[item[0]] == item[1] }
    end

    min_count = @dataset.num_instances * @min_support
    itemsets[1] = support_counts.select { |_, count| count >= min_count }.keys

    k = 2
    while !itemsets[k - 1].empty?
      candidates = generate_candidates(itemsets[k - 1], k)
      counts = candidates.each_with_object(Hash.new(0)) do |cand, h|
        @dataset.data.each { |inst| h[cand] += 1 if cand.all? { |i, v| @dataset.get_value(inst, i) == v } }
      end
      itemsets[k] = counts.select { |_, count| count >= min_count }.keys
      k += 1
    end
    itemsets
  end

  def generate_candidates(prev_itemsets, k)
    candidates = []
    prev_itemsets.combination(2) do |a, b|
      next unless a[0...-1] == b[0...-1] # Join step: ensure k-1 items are common
      cand = (a + b).uniq.sort
      next unless cand.size == k
      # Pruning step: check if all (k-1)-subsets are frequent
      next unless cand.combination(k - 1).all? { |subset| prev_itemsets.include?(subset) }
      candidates << cand
    end
    candidates.uniq
  end

  def generate_rules
    rules = []
    @itemsets.each do |k, sets|
      next if k < 2
      sets.each do |itemset|
        itemset.combination(1..itemset.size - 1) do |antecedent|
          consequent = itemset - antecedent
          support_all = support_count(itemset)
          support_ante = support_count(antecedent)
          confidence = support_all.to_f / support_ante
          rules << { antecedent: antecedent, consequent: consequent, support: support_all.to_f / @dataset.num_instances, confidence: confidence } if confidence >= @min_confidence
        end
      end
    end
    rules
  end

  def support_count(itemset)
    @dataset.data.count { |inst| itemset.all? { |i, v| @dataset.get_value(inst, i) == v } }
  end
end

# Base Filter (unchanged)
class Filter
  def set_input_format(dataset); @input_format = dataset.clone; end
  def filter(dataset); raise NotImplementedError; end
end

# Normalize (unchanged)
class Normalize < Filter
  def filter(dataset)
    raise "Input format not set" unless @input_format
    result = dataset.clone
    mins, maxs = compute_min_max(dataset)

    result.data.map! do |inst|
      if inst.is_a?(Hash)
        inst.transform_values.with_index { |v, i| dataset.attributes[i].numeric? && v ? scale(v, mins[i], maxs[i]) : v }
      else
        inst.map.with_index { |v, i| dataset.attributes[i].numeric? && v ? scale(v, mins[i], maxs[i]) : v }
      end
    end
    result
  end

  private

  def scale(value, min, max)
    (max - min).zero? ? 0 : (value.to_f - min) / (max - min)
  end

  def compute_min_max(dataset)
    mins = Array.new(dataset.num_attributes, Float::INFINITY)
    maxs = Array.new(dataset.num_attributes, -Float::INFINITY)
    dataset.data.each do |inst|
      dataset.num_attributes.times do |i|
        v = dataset.get_value(inst, i).to_f rescue next
        next unless dataset.attributes[i].numeric?
        mins[i] = [mins[i], v].min
        maxs[i] = [maxs[i], v].max
      end
    end
    [mins, maxs]
  end
end

# NominalToNumeric (unchanged)
class NominalToNumeric < Filter
  def filter(dataset)
    raise "Input format not set" unless @input_format
    new_dataset = Dataset.new(dataset.relation_name)
    mapping = {}
    new_attrs = []

    dataset.attributes.each_with_index do |attr, idx|
      if attr.nominal?
        attr.values.each_with_index do |val, val_idx|
          new_attrs << Attribute.new("#{attr.name}_#{val}", :numeric)
          mapping[idx] ||= {}
          mapping[idx][val] = val_idx
        end
      else
        new_attrs << attr.dup
        mapping[idx] = :identity
      end
    end

    new_attrs.each { |attr| new_dataset.add_attribute(attr) }
    dataset.data.each do |inst|
      new_inst = inst.is_a?(Hash) ? {} : Array.new(new_dataset.num_attributes, 0)
      inst.each_with_index do |(k, v), idx|
        next unless v
        if mapping[idx] == :identity
          new_inst.is_a?(Hash) ? new_inst[idx] = v : new_inst[idx] = v
        else
          new_idx = mapping[idx][v] + (dataset.attributes[0...idx].sum { |a| a.nominal? ? a.values.size : 1 })
          new_inst.is_a?(Hash) ? new_inst[new_idx] = 1 : new_inst[new_idx] = 1
        end
      end
      new_dataset.add_instance(new_inst)
    end
    new_dataset.set_class_index(new_attrs.size - 1) if dataset.class_index >= 0
    new_dataset
  end
end

# Discretize (unchanged)
class Discretize < Filter
  def initialize(num_bins = 5); @num_bins = num_bins; end

  def filter(dataset)
    raise "Input format not set" unless @input_format
    result = dataset.clone
    ranges = compute_ranges(dataset)

    result.data.map! do |inst|
      if inst.is_a?(Hash)
        inst.transform_values.with_index { |v, i| dataset.attributes[i].numeric? && v ? discretize_value(v, ranges[i]) : v }
      else
        inst.map.with_index { |v, i| dataset.attributes[i].numeric? && v ? discretize_value(v, ranges[i]) : v }
      end
    end
    result.attributes.map!.with_index do |attr, i|
      attr.numeric? ? Attribute.new(attr.name, :nominal, (0...@num_bins).map { |j| "bin#{j}" }) : attr
    end
    result
  end

  private

  def compute_ranges(dataset)
    dataset.attributes.map.with_index do |attr, i|
      next nil unless attr.numeric?
      values = dataset.data.map { |inst| dataset.get_value(inst, i).to_f rescue nil }.compact.sort
      min, max = values.minmax
      step = (max - min) / @num_bins.to_f
      (0...@num_bins).map { |j| [min + j * step, min + (j + 1) * step] }
    end
  end

  def discretize_value(value, ranges)
    return nil unless value && ranges
    v = value.to_f
    ranges.each_with_index { |range, i| return "bin#{i}" if v >= range[0] && v < range[1] }
    "bin#{@num_bins - 1}"
  end
end

# Attribute Selection (unchanged)
class AttributeSelection < Filter
  def filter(dataset)
    raise "Input format not set" unless @input_format
    raise "Class index not set" if dataset.class_index == -1
    ranked_attrs = rank_attributes(dataset)
    num_to_select = [dataset.num_attributes / 2, 1].max
    selected_attrs = ranked_attrs.take(num_to_select + 1)

    new_dataset = Dataset.new(dataset.relation_name)
    selected_attrs.each { |attr| new_dataset.add_attribute(attr.dup) }
    new_data = dataset.data.map do |inst|
      if inst.is_a?(Hash)
        inst.select { |k, _| selected_attrs.include?(dataset.attributes[k]) }
      else
        inst.values_at(*selected_attrs.map { |a| dataset.attributes.index(a) })
      end
    end
    new_data.each { |inst| new_dataset.add_instance(inst) }
    new_dataset.set_class_index(selected_attrs.index(dataset.class_attribute))
    new_dataset
  end

  private

  def rank_attributes(dataset)
    base_entropy = entropy(dataset.data, dataset.class_index)
    dataset.attributes.reject { |a| a == dataset.class_attribute }.map do |attr|
      gain = information_gain(dataset, attr, dataset.class_index, base_entropy)
      [attr, gain]
    end.sort_by(&:last).reverse.map(&:first) + [dataset.class_attribute]
  end

  def entropy(data, class_index)
    counts = data.group_by { |inst| dataset.get_value(inst, class_index) }.transform_values(&:count)
    counts.values.sum { |c| -c.to_f / data.size * Math.log2(c.to_f / data.size) rescue 0 }
  end

  def information_gain(dataset, attr, class_index, base_entropy)
    idx = dataset.attributes.index(attr)
    if attr.nominal?
      subsets = attr.values.map { |v| dataset.data.select { |inst| dataset.get_value(inst, idx) == v } }
    else
      threshold = dataset.data.map { |inst| dataset.get_value(inst, idx).to_f rescue nil }.compact.sort[dataset.num_instances / 2]
      subsets = [dataset.data.select { |inst| (dataset.get_value(inst, idx).to_f <= threshold rescue false) },
                 dataset.data.select { |inst| (dataset.get_value(inst, idx).to_f > threshold rescue false) }]
    end
    base_entropy - subsets.sum { |subset| subset.empty? ? 0 : (subset.size.to_f / dataset.data.size) * entropy(subset, class_index) }
  end
end

# Impute Missing (unchanged)
class ImputeMissing < Filter
  def filter(dataset)
    raise "Input format not set" unless @input_format
    result = dataset.clone
    means = compute_means(dataset)
    modes = compute_modes(dataset)

    result.data.map! do |inst|
      if inst.is_a?(Hash)
        (0...dataset.num_attributes).each { |i| inst[i] ||= dataset.attributes[i].numeric? ? means[i] : modes[i] }
        inst
      else
        inst.map.with_index { |v, i| v || (dataset.attributes[i].numeric? ? means[i] : modes[i]) }
      end
    end
    result
  end

  private

  def compute_means(dataset)
    dataset.attributes.map.with_index do |attr, i|
      next nil unless attr.numeric?
      values = dataset.data.map { |inst| dataset.get_value(inst, i).to_f rescue nil }.compact
      values.empty? ? 0 : values.sum / values.size
    end
  end

  def compute_modes(dataset)
    dataset.attributes.map.with_index do |attr, i|
      next nil unless attr.nominal?
      dataset.data.tally { |inst| dataset.get_value(inst, i) }.max_by(&:last)&.first
    end
  end
end

# Evaluation (unchanged)
class Evaluation
  def initialize(dataset); @dataset = dataset.clone; @correct = 0; @total = 0; end

  def evaluate_model(classifier)
    @dataset.data.each do |inst|
      predicted = classifier.classify_instance(inst)
      actual = @dataset.get_value(inst, @dataset.class_index)
      @correct += 1 if predicted == actual
      @total += 1
    end
  end

  def cross_validate_model(classifier, num_folds = 10)
    fold_size = @dataset.num_instances / num_folds
    shuffled = @dataset.data.shuffle

    num_folds.times do |fold|
      test_start = fold * fold_size
      test_end = [test_start + fold_size, @dataset.num_instances].min
      test_data = shuffled[test_start...test_end]
      train_data = shuffled[0...test_start] + shuffled[test_end..-1]

      train_set = @dataset.clone
      train_set.instance_variable_set(:@data, train_data)
      classifier.build_classifier(train_set)

      test_set = @dataset.clone
      test_set.instance_variable_set(:@data, test_data)
      test_set.data.each do |inst|
        predicted = classifier.classify_instance(inst)
        actual = @dataset.get_value(inst, @dataset.class_index)
        @correct += 1 if predicted == actual
        @total += 1
      end
    end
  end

  def accuracy; @total.zero? ? 0 : @correct.to_f / @total; end
end

# Visualization (unchanged)
class Visualization
  def self.confusion_matrix(dataset, classifier)
    matrix = Hash.new(0)
    dataset.data.each do |inst|
      predicted = classifier.classify_instance(inst)
      actual = dataset.get_value(inst, dataset.class_index)
      matrix[[actual, predicted]] += 1
    end

    puts "Confusion Matrix:"
    classes = dataset.class_attribute.values
    puts "  " + classes.join(" ")
    classes.each do |actual|
      row = classes.map { |pred| matrix[[actual, pred]] }
      puts "#{actual} #{row.join(' ')}"
    end
  end

  def self.scatter_plot(dataset, attr_x, attr_y)
    x_idx = dataset.attributes.index(attr_x)
    y_idx = dataset.attributes.index(attr_y)
    raise "Attributes must be numeric" unless attr_x.numeric? && attr_y.numeric?

    puts "Scatter Plot (#{attr_x.name} vs #{attr_y.name}):"
    dataset.data.each do |inst|
      x = dataset.get_value(inst, x_idx).to_f rescue 0
      y = dataset.get_value(inst, y_idx).to_f rescue 0
      cluster = dataset.get_value(inst, dataset.attributes.size - 1)
      puts "#{x},#{y},#{cluster}"
    end
  end

  def self.cluster_summary(dataset, clusterer)
    puts "Cluster Assignments:"
    dataset.data.each_with_index do |inst, i|
      cluster = clusterer.assign_instance(inst)
      puts "Instance #{i}: Cluster #{cluster}"
    end
  end
end

# Example usage
def main
  # Create a sample dataset with sparse and missing values
  dataset = Dataset.new("SampleData")
  dataset.add_attribute(Attribute.new("length", :numeric))
  dataset.add_attribute(Attribute.new("width", :numeric))
  dataset.add_attribute(Attribute.new("color", :nominal, ["red", "blue"]))
  dataset.add_attribute(Attribute.new("class", :nominal, ["positive", "negative"]))
  dataset.add_instance([1.0, nil, "red", "positive"])
  dataset.add_instance({ 0 => 2.0, 1 => 3.0, 3 => "negative" }) # Sparse
  dataset.add_instance([1.5, 2.5, "blue", "positive"])
  dataset.add_instance([nil, 3.5, "red", "negative"])
  dataset.set_class_index(3)

  # Impute missing values
  imputer = ImputeMissing.new
  imputer.set_input_format(dataset)
  imputed = imputer.filter(dataset)

  # Normalize
  normalizer = Normalize.new
  normalizer.set_input_format(imputed)
  normalized = normalizer.filter(imputed)

  # Discretize
  discretizer = Discretize.new(3)
  discretizer.set_input_format(normalized)
  discretized = discretizer.filter(normalized)

  # Attribute Selection
  selector = AttributeSelection.new
  selector.set_input_format(discretized)
  selected = selector.filter(discretized)

  # Convert nominal to numeric for SVM, KMeans, DBSCAN
  converter = NominalToNumeric.new
  converter.set_input_format(selected)
  numeric_dataset = converter.filter(selected)

  # Classifiers
  classifiers = {
    "KNN" => KNN.new(1),
    "NaiveBayes" => NaiveBayes.new,
    "DecisionTree" => DecisionTree.new,
    "SVM" => SVM.new
  }

  classifiers.each do |name, clf|
    puts "\nEvaluating #{name}:"
    clf.build_classifier(name == "SVM" ? numeric_dataset : selected)
    eval = Evaluation.new(name == "SVM" ? numeric_dataset : selected)
    eval.cross_validate_model(clf, 2)
    puts "#{name} Accuracy: #{eval.accuracy}"
    Visualization.confusion_matrix(selected, clf) unless name == "SVM"
  end

  # Improved KMeans Clustering
  puts "\nImproved K-Means Clustering:"
  kmeans = KMeans.new(2, 100, 0.001)
  kmeans.build_clusters(numeric_dataset)
  Visualization.cluster_summary(numeric_dataset, kmeans)
  Visualization.scatter_plot(numeric_dataset, numeric_dataset.attributes[0], numeric_dataset.attributes[1])

  # DBSCAN Clustering
  puts "\nDBSCAN Clustering:"
  dbscan = DBSCAN.new(0.5, 2)
  dbscan.build_clusters(numeric_dataset)
  Visualization.cluster_summary(numeric_dataset, dbscan)
  Visualization.scatter_plot(numeric_dataset, numeric_dataset.attributes[0], numeric_dataset.attributes[1])

  # Improved Apriori Association Rules
  puts "\nImproved Apriori Association Rules:"
  apriori = Apriori.new(0.25, 0.5)
  apriori.build_rules(discretized)
  apriori.rules.each do |rule|
    ante = rule[:antecedent].map { |i, v| "#{discretized.attributes[i].name}=#{v}" }.join(", ")
    cons = rule[:consequent].map { |i, v| "#{discretized.attributes[i].name}=#{v}" }.join(", ")
    puts "#{ante} => #{cons} (Support: #{rule[:support].round(2)}, Confidence: #{rule[:confidence].round(2)})"
  end
end

main if __FILE__ == $0
