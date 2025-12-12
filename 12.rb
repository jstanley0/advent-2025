require_relative "skim"

data = ARGF.read.split("\n\n")
problems = data.pop.split("\n").map do |line|
  size, counts = line.split(':')
  size = size.split('x').map(&:to_i)
  counts = counts.split.map(&:to_i)
  { size:, counts: }
end

shapes = data.map { Skim.from_concise_string(it.split("\n", 1).last, sep: "\n") }
sizes = shapes.map { it.count("#") }

# ... this wasn't supposed to be the answer. it was just a sanity check, eliminating
# groups of shapes with a total area exceeding the space they need to fit in.
puts problems.count { it[:counts].each_with_index.sum { |num, shape| num * sizes[shape] } <= it[:size].inject(:*) }
