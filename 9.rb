Vert = Struct.new(:x, :y)

def area(a, b)
  ((a.x - b.x).abs + 1) * ((a.y - b.y).abs + 1)
end

verts = ARGF.readlines.map { Vert.new(*it.split(?,).map(&:to_i)) }
puts verts.combination(2).lazy.map { |c| area(*c) }.max
