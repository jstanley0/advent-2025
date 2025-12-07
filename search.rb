require 'rb_heap'

class Search
  # to use Search, derive from Search::Node and implement `enum_edges`
  # and probably one or the other of `goal?` and `est_dist`
  class Node
    # expected to yield cost, node pairs
    def enum_edges
    end

    # helper for iteration
    def edges(&)
      return to_enum(:edges) unless block_given?
      enum_edges(&)
    end

    # for bfs, indicate whether a goal state has been reached
    def goal?
    end

    # for a_star, estimate cost to another node
    # (this method must not underestimate it)
    def est_cost(other)
    end

    # something that compares equal if the search states are equivalent
    def hash
    end

    def eql?(other)
      hash == other.hash
    end

    # in case there are attributes such as time that aren't part of the A* heuristic
    def fuzzy_equal?(other)
      eql?(other)
    end

    # used by the underlying implementation; Search users don't need to touch this
    attr_accessor :cost_heuristic
  end

  # finds a least-cost path from start_node to a goal node
  # and returns [cost, [search_node, search_node...]]
  def self.bfs(start_node, find_all_paths: false)
    search_impl(start_node,
                ->(node) { node.goal? },
                ->(_node, cost_so_far) { cost_so_far },
                find_all_paths:)
  end

  # finds a least-cost path from start_node to end_node
  # and returns [cost, [search_node, search_node...]]
  def self.a_star(start_node, end_node)
    search_impl(start_node,
                ->(node) { node.fuzzy_equal?(end_node) },
                ->(node, cost_so_far) { cost_so_far + node.est_cost(end_node) })
  end

  private

  def self.search_impl(start_node, goal_proc, cost_heuristic_proc, find_all_paths: false)
    path_links = {}
    best_cost_to = { start_node => 0 }
    fringe = Heap.new { |a, b| a.cost_heuristic < b.cost_heuristic }
    start_node.cost_heuristic = cost_heuristic_proc.call(start_node, 0)
    fringe << start_node

    until fringe.empty?
      node = fringe.pop
      cost_so_far = best_cost_to[node]
      # puts "searching from #{node} at cost #{cost_so_far}"
      goal = goal_proc.call(node)
      if goal
        if find_all_paths
          goal_node = node
          best_path_cost = cost_so_far
        else
          return cost_so_far, build_path(path_links, node)
        end
      end
      break if find_all_paths && best_path_cost && cost_so_far > best_path_cost

      unless goal
        node.edges do |cost, neighbor|
          cost_to_neighbor = cost_so_far + cost
          if best_cost_to[neighbor].nil? || (find_all_paths ? (cost_to_neighbor <= best_cost_to[neighbor]) : (cost_to_neighbor < best_cost_to[neighbor]))
            best_cost_to[neighbor] = cost_to_neighbor
            if find_all_paths
              path_links[neighbor] ||= Set.new
              path_links[neighbor] << node
            else
              path_links[neighbor] = node
            end
            neighbor.cost_heuristic = cost_heuristic_proc.call(neighbor, cost_to_neighbor)
            fringe << neighbor
          end
        end
      end
    end

    if find_all_paths && goal_node
      [best_path_cost] + build_all_paths(path_links, [goal_node], best_path_cost)
    end
  end

  def self.build_path(path_links, target_point)
    path = [target_point]
    while (target_point = path_links[target_point])
      path.unshift target_point
    end
    path
  end

  def self.build_all_paths(path_links, end_path, best_cost, cost_so_far = 0)
    return [] if cost_so_far > best_cost
    return [end_path] if path_links[end_path.first].nil?

    paths = []
    path_links[end_path.first].each do |link|
      link_cost = cost_so_far + link.edges.find { |_cost, node| node.fuzzy_equal?(end_path.first) }.first
      paths.concat build_all_paths(path_links, [link] + end_path, best_cost, link_cost) if link_cost <= best_cost
    end
    paths
  end
end
