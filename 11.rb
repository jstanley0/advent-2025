$network = ARGF.readlines.map { it.split(':') }.to_h.transform_values(&:split)

def count_paths(from, to)
  return 1 if $network[from].include?(to)

  $network[from].sum { |link| count_paths(link, to) }
end

puts count_paths("you", "out")
