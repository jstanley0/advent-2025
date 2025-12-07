require_relative 'ranger'

ranges, ingredients = ARGF.read.split("\n\n")
ranges = ranges.split("\n").map { Range.new(*it.split('-').map(&:to_i)) }
ingredients = ingredients.split.map(&:to_i)

puts ingredients.count { |ingredient| ranges.any? { it.cover?(ingredient) } }

puts Ranger.union(*ranges).sum(&:size)
