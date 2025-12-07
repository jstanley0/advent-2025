def invalid_id?(id)
  s = id.to_s
  (1..s.size/2).each do |l|
    return true if s =~ /^(#{s[0...l]})+$/
  end
  false
end

puts ARGF.gets.split(',').map { Range.new(*it.split('-').map(&:to_i)) }.sum { |range|
  range.sum { |i| invalid_id?(i) ? i : 0 }
}
