puts ARGF.gets.split(',').map { Range.new(*it.split('-').map(&:to_i)) }.sum { |range|
  range.sum { |i| s = i.to_s; (s.length.even? && s[0...s.length/2] == s[s.length/2..]) ? i : 0 }
}
