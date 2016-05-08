require 'byebug'
# Rugraph class representing a Directed graph.
class Rugraph
  # @return [Rugraph] an empty graph.
  def initialize
    @structure = {}
  end

  # Creates graph from describing hash. See {#load_from_vertices_hash}
  #
  # @param (see #load_from_vertices_hash)
  # @return [Rugraph] the generated graph
  def self.new_from_vertices_hash(vertices_hash)
    new.load_from_vertices_hash(vertices_hash)
  end

  # Creates graph from describing array. See {#load_from_edges_array}
  #
  # @param (see #load_from_edges_array)
  # @return [Rugraph] the generated graph
  def self.new_from_edges_array(edges_array)
    new.load_from_edges_array(edges_array)
  end

  # Adds vertices and edges to the graph from a hash [Hash] formatted
  # as such
  #  { node1 => neighboring_nodes_array, node2 => ... }
  #
  # @param vertices_hash [Hash] a hash describing the Rugraph
  # @return [Rugraph] the graph
  def load_from_vertices_hash(vertices_hash)
    @structure = vertices_hash
    self
  end

  # Adds vertices and edges to the graph from an array [Array] formatted
  # as such
  #   [[source_node, destination] [source_node2, destination2], ...]
  #
  # @param edges_array [Array] an array describing the Rugraph
  # @return [Rugraph] the graph
  def load_from_edges_array(edges_array)
    @structure = edges_array
                 .each_with_object({}) do |edge, nodes|
                   nodes[edge[0]] = [] unless nodes.keys.include? edge[0]
                   nodes[edge[0]] << edge[1]
                 end
    self
  end

  # Adds a vertex to the graph. If the vertex already exists, do nothing.
  #
  # @param node [Object] the value of the node to add to the graph
  # @return [Rugraph] the graph
  def add_vertex(node)
    @structure[node] ||= []
  end

  # (see #add_vertex)
  def add_node(node)
    add_vertex(node)
  end

  # Adds an edge to the graph. If the vertex already exists, do nothing.
  #
  # @param edge [Array] an array formatted as such [source, dest]
  # @return [Rugraph] the graph
  def add_edge(edge)
    edge.each { |node| add_vertex(node) }
    @structure[edge[0]] << edge[1]
  end

  # Method returning the neighbors of a node.
  #
  # @param node [Object] the value corresponding to a node in the graph
  # @return [Array, nil] an array of its neighbors if the node exists,
  #   nil otherwise
  def neighbors_of(node)
    return nil unless nodes.include?(node)
    @structure[node] || []
  end

  # Computes the shortest path lengths from a node to all other
  # accessible nodes.
  #
  # @param source [Object] the value of the source node.
  # @return [Hash] a hash of the lengths of shortest path to each other node.
  def shortest_path_lengths(source)
    seen = {}
    level = 0
    nextlevel = { source => 1 }
    until nextlevel.empty?
      thislevel = nextlevel
      nextlevel = {}
      thislevel.each do |v, _|
        if seen[v].nil?
          seen[v] = level
          nextlevel.update(neighbors_of(v).map { |w| [w, nil] }.to_h)
        end
      end
      level += 1
    end
    seen
  end

  # Computes the shortest path a node.
  #
  # @param source [Object] the value of the source node.
  # @return [Array] an array [pred, seen] containing two hashes :
  #   - pred [Hash] a hash of the shortest path to each node
  #   - seen [Hash] a hash of the lengths of the shortest path to each node
  def shortest_paths(source)
    level = 0
    nextlevel = [source]
    seen = { source => level }
    pred = { source => [] }
    until nextlevel.empty?
      level += 1
      thislevel = nextlevel
      nextlevel = []
      thislevel.each do |v|
        neighbors_of(v).each do |w|
          next if (seen.keys.include? w) && (seen[w] != level)
          unless seen.keys.include? w
            pred[w] = []
            seen[w] = level
            nextlevel << w
          end
          pred[w] << v
        end
      end
    end
    [pred, seen]
  end

  # Returns the edges around a node.
  #
  # @params node [Object]
  # @return [Array] an array of the edges.
  def edges_of(node)
    edges_from(node) | edges_to(node)
  end

  # Returns the edges coming out of a node.
  #
  # @params node [Object]
  # @return [Array] an array of the edges.
  def edges_from(node)
    self[node].map { |n| [node, n] }
  end

  # Returns the edges coming from a node.
  #
  # @params node [Object]
  # @return [Array] an array of the edges.
  def edges_to(node)
    edges.select { |edge| edge.last == node }
  end

  # Computes the degree of each node.
  #
  # @return [Enumerator] an enumerator of the degrees of all nodes
  def degrees
    Enumerator.new(@structure.length) do |y|
      nodes.each do |node|
        y << [node, degree(node)]
      end
    end
  end

  # Computes the degree of a node.
  #
  # @param node [Object] the value of a node.
  # @return [Integer] the degree of the node.
  def degree(node)
    in_degree(node) + out_degree(node)
  end

  # Computes the incoming degree of a node.
  #
  # @param (see #degree)
  # @return (see #degree)
  def in_degree(node)
    self[node].length
  end

  # Computes the outcoming degree of a node.
  #
  # @param (see #degree)
  # @return (see #degree)
  def out_degree(node)
    @structure.count { |_source, dest| dest.include? node }
  end

  # Computes the order (number of nodes) of the graph.
  #
  # @return [Integer] the order of the graph.
  def order
    nodes.length
  end

  # Returns the nodes in the graph
  #
  # @return [Array] the values of all the nodes in the graph.
  def vertices
    (@structure.keys | @structure.values).flatten.uniq
  end

  # (see #vertices)
  def nodes
    vertices
  end

  # Returns the list of all the edges in the graph.
  #
  # @return [Array] an array of pairs of nodes.
  def edges
    @structure.reduce([]) do |acc, node|
      acc + node[1].map { |dest| [node[0], dest] }
    end
  end

  # Equivalent to {#neighbors_of}
  #
  # @return (see #neighbors_of)
  def [](node)
    neighbors_of(node)
  end

  # Sets the edges coming out of a node.
  #
  # @params node_array [Array] an array of nodes
  # @params node [node] the concerned node
  # @return the new neighbors of the node
  def []=(node, node_array)
    @structure[node] = node_array
  end

  # Equivalent to #{add_vertex}.
  #
  # @params (see #add_vertex)
  # @return (see #add_vertex)
  def <<(node)
    add_vertex(node)
  end


  # Calculates the betweenness centrality for each node.
  #
  # Based on Brandes algorithm :
  # http://algo.uni-konstanz.de/publications/b-fabc-01.pdf
  #
  # @param graph [Rugraph] a graph
  # @return [Hash] a hash with the nodes as keys and their centrality as values
  def self.betweenness_centrality(graph)
    cb = graph.vertices.map { |v| [v, 0] }.to_h
    graph.vertices.each do |source|
      stack = []
      path = Hash.new { [] }
      sig = Hash.new(0)
      sig[source] = 1.0
      distance = {}
      distance[source] = 0
      queue = []
      queue << source

      until queue.empty?
        v = queue.shift
        stack << v

        graph.neighbors_of(v).each do |w|
          unless distance.keys.include? w
            queue << w
            distance[w] = distance[v] + 1
          end
          if distance[w] == distance[v] + 1
            sig[w] += sig[v]
            path[w] += [v]
          end
        end
      end

      delta = Hash.new(0)
      until stack.empty?
        w = stack.pop
        coeff = (1.0 + delta[w]) / sig[w].to_f
        path[w].each do |n|
          delta[n] += sig[n] * coeff
        end
        cb[w] += delta[w] if w != source
      end
    end

    cb
  end

  # Calculate the closeness centrality for each node.
  #
  # @param (see #betweenness_centrality)
  # @return (see #betweenness_centrality)
  def self.closeness_centrality(graph)
    closeness_centrality = {}

    graph.vertices.each do |n|
      shortest_paths = graph.shortest_path_lengths(n)
      sum = shortest_paths.values.reduce(&:+)
      closeness_centrality[n] = 0.0
      next unless (sum > 0) && (graph.order > 1)
      closeness_centrality[n] = (shortest_paths.length - 1) / sum.to_f
      s = (shortest_paths.length - 1).to_f / (graph.order - 1)
      closeness_centrality[n] *= s
    end

    closeness_centrality
  end

  # Calculate the degree centrality for each node.
  #
  # @param (see #betweenness_centrality)
  # @return (see #betweenness_centrality)
  def self.degree_centrality(graph)
    s = 1.0 / (graph.order - 1)
    graph.degrees
         .map { |n, d| [n, d * s] }
         .to_h
  end

  # Calculate the load centrality for each node.
  #
  # Based on NetworkX's Python implementation.
  #
  # @param (see #betweenness_centrality)
  # @return (see #betweenness_centrality)
  def self.load_centrality(graph)
    betweenness = graph.vertices
                       .map { |n| [n, 0.0] }
                       .to_h
    betweenness.each do |source, _|
      ubetween = _node_betweenness(graph, source)
      betweenness.merge(ubetween) do |key, v1, v2|
        betweenness[key] = v1 + v2
      end
    end
  end

  def self._node_betweenness(graph, source)
    (pred, between) = graph.shortest_paths(source)

    ordered = _ordered_nodes_from_paths(between)
    between.each { |k, _| between[k] = 1.0 }

    until ordered.empty?
      v = ordered.pop
      next unless pred.include? v
      pred[v].each do |x|
        break if x == source
        between[x] += between[v] / pred[v].size.to_f
      end
    end

    between.each { |n, _| between[n] -= 1 }
  end

  def self._ordered_nodes_from_paths(paths)
    paths.to_a
         .sort { |a, b| a.last <=> b.last }
         .map(&:first)
         .flatten
  end
  private_class_method :_node_betweenness
  private_class_method :_ordered_nodes_from_paths
end
