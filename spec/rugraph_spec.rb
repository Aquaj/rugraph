require 'spec_helper'

describe Rugraph do
  let(:graph) { Rugraph.new_from_vertices_hash(a: [:b, :c], b: [:c], d: [:e]) }
  let(:connected_graph) { Rugraph.new_from_vertices_hash(a: [:b, :c, :d], b: [:e], d: [:a, :b], e: [:a, :c, :d]) }

  describe "Construction" do
    it "can construct a Graph from a Hash description" do
      graph = Rugraph.new_from_vertices_hash(a: [:b, :c], b: [:c], d: [:e])

      expect(graph.vertices).to match_array [:a, :b, :c, :d, :e]
      expect(graph.edges).to match_array [[:a, :b], [:a, :c], [:b, :c], [:d, :e]]
    end

    it "can construct a Graph from an Array of edges" do
      graph = Rugraph.new_from_edges_array([[:a, :b], [:a, :c], [:b, :c], [:d, :e]])

      expect(graph.vertices).to match_array [:a, :b, :c, :d, :e]
      expect(graph.edges).to match_array [[:a, :b], [:a, :c], [:b, :c], [:d, :e]]
    end

    it "can add a vertex to the graph" do
      graph.add_vertex :f
      expect(graph.nodes).to match_array [:a, :b, :c, :d, :e, :f]
    end

    it "can add an edge to the graph" do
      graph.add_edge [:f, :g]
      expect(graph.nodes).to match_array [:a, :b, :c, :d, :e, :f, :g]
      expect(graph.edges).to match_array [[:a, :b], [:a, :c], [:b, :c], [:d, :e], [:f, :g]]
    end
  end

  describe "Properties" do
    describe "Neighbors" do
      it "can give the neighbors of a node" do
        expect(graph.neighbors_of(:a)).to match_array [:b, :c]
        expect(graph.neighbors_of(:d)).to match_array [:e]
      end

      it "returns an empty array if the node doesn't have any neighbors" do
        expect(graph.neighbors_of(:c)).to match_array []
      end

      it "returns nil otherwise" do
        expect(graph.neighbors_of(:v)).to eq nil
      end
    end

    describe "Edges" do
      it "can give the edges around a node" do
        expect(graph.edges_of(:b)).to match_array [[:a, :b], [:b, :c]]
      end

      it "can give the edges coming out of a node" do
        expect(graph.edges_from(:b)).to match_array [[:b, :c]]
      end

      it "can give the edges coming to a node" do
        expect(graph.edges_to(:b)).to match_array [[:a, :b]]
      end
    end

    describe "Degree" do
      it "can give the degree of a node" do
        expect(graph.degree(:b)).to eq 2
      end

      it "can give the incoming degree of a node" do
        expect(graph.degree(:c)).to eq 2
      end

      it "can give the outgoing degree of a node" do
        expect(graph.degree(:a)).to eq 2
      end
    end

    describe "Order" do
      it "can give the order of a graph" do
        expect(graph.order).to eq 5
        expect(Rugraph.new_from_edges_array([[:a, :a]]).order).to eq 1
        expect(Rugraph.new.order).to eq 0
      end
    end

    describe "Aliases" do
      it "has the #[] alias for #neighbors_of" do
        expect(graph.neighbors_of(:a)).to match_array graph[:a]
      end

      it "has the #nodes alias for #vertices" do
        expect(graph.nodes).to match_array graph.vertices
      end

      it "has the #<< alias for #add_vertex" do
        expect(graph << :f).to eq graph.add_vertex(:f)
        expect(graph.nodes).to match_array [:a, :b, :c, :d, :e, :f]
      end

      it "has the #add_node alias for #add_vertex" do
        expect(graph.add_node(:f)).to eq graph.add_vertex(:f)
        expect(graph.nodes).to match_array [:a, :b, :c, :d, :e, :f]
      end
    end
  end

  describe "Calculations" do
    describe "Paths" do
      it "can compute the shortest paths from a node to the others" do
        expect(graph.shortest_paths(:a)).to match_array([{a: [], b: [:a], c: [:a]}, {a: 0, b: 1, c: 1}])
        expect(graph.shortest_paths(:d)).to match_array([{d: [], e: [:d]}, {d: 0, e: 1}])
        expect(graph.shortest_paths(:c)).to match_array([{c: []}, {c: 0}])
      end
      it "can compute the shortest_path_length from a node to the others" do
        expect(graph.shortest_path_lengths(:a)).to eq({a: 0, b: 1, c: 1})
        expect(graph.shortest_path_lengths(:d)).to eq({d: 0, e: 1})
        expect(graph.shortest_path_lengths(:c)).to eq({c: 0})
      end
    end

    describe "Centrality" do
    # Test values computed via Networkx for Python.

      it "can calculate betweenness centrality" do
        expect(Rugraph.betweenness_centrality(graph)).to eq({a: 0.0, b: 0.0, c: 0.0, d: 0.0, e: 0.0})
        expect(Rugraph.betweenness_centrality(connected_graph)).to eq({a: 1.5, b: 2.0, c: 0.0, d: 0.5, e: 3.0})
      end

      it "can calculate closeness centrality" do
        expect(Rugraph.closeness_centrality(graph)).to eq({a: 0.5, b: 0.25, c: 0.0, d: 0.25, e: 0.0})
        expect(Rugraph.closeness_centrality(connected_graph)).to eq({a: 0.8, b: 0.5714285714285714, c: 0.0, d: 0.6666666666666666, e: 0.8})
      end

      it "can calculate degree centrality" do
        expect(Rugraph.degree_centrality(graph)).to eq({a: 0.5, b: 0.5, c: 0.5, d: 0.25, e: 0.25})
        expect(Rugraph.degree_centrality(connected_graph)).to eq({a: 1.25, b: 0.75, c: 0.5, d: 1.0, e: 1.0})
      end

      it "can calculate load centrality" do
        expect(Rugraph.load_centrality(graph)).to eq({a: 0.0, b: 0.0, c: 0.0, d: 0.0, e: 0.0})
        expect(Rugraph.load_centrality(connected_graph)).to eq({a: 1.5, b: 2.0, c: 0.0, d: 0.5, e: 3.0})
      end
    end
  end
end
