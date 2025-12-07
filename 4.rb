require_relative 'skim'

n = 0
map = Skim.read
map.each_with_coords do |val, x, y|
  n += 1 if val == '@' && map.nv(x, y).count('@') < 4
end
puts n

n = 0
loop do
  pn = n
  map.each_with_coords do |val, x, y|
    if val == '@' && map.nv(x, y).count('@') < 4
      n += 1
      map[x, y] = 'x'
    end
  end
  break if pn == n
end
puts n
