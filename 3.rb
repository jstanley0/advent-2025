puts ARGF.readlines.map { it.strip.chars.map(&:to_i) }.sum { |batts|
  fi = batts[0...batts.size - 1].each_index.max_by { batts[it] }
  s = batts[fi + 1..].max
  batts[fi] * 10 + s
}
