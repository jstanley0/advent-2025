puts ARGF.readlines.map { it.strip.chars.map(&:to_i) }.sum { |batts|
  indexes = []
  11.downto(0) do |n|
    f = (indexes.last || -1) + 1
    indexes << f + batts[f...batts.size - n].each_index.max_by { batts[f + it] }
  end
  indexes.inject(0) { |m, i| m * 10 + batts[i] }
}
