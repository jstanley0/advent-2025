require 'debug'

Point = Struct.new(:x, :y, :z, :c) do
  def distance(other)
    Math.sqrt((x - other.x) ** 2 + (y - other.y) ** 2 + (z - other.z) ** 2)
  end
end

data = File.readlines(ARGV[0]).map { Point.new(*it.split(?,).map(&:to_i)) }
n = ARGV[1].to_i
raise ArgumentError, "invalid connection count" unless n > 0

Dist = Struct.new(:dist, :a, :b)
dists = []
(0...data.size).each do |a|
  (0...a).each do |b|
    dists << Dist.new(data[a].distance(data[b]), a, b)
  end
end
dists.sort_by!(&:dist)

cid = 0
connect = ->(i) do
  dist = dists[i]
  ca = data[dist.a].c
  cb = data[dist.b].c
  if ca.nil? && cb.nil?
    data[dist.a].c = data[dist.b].c = cid
    cid += 1
  elsif ca.nil?
    data[dist.a].c = data[dist.b].c
  elsif cb.nil?
    data[dist.b].c = data[dist.a].c
  elsif ca != cb
    data.each do |point|
      point.c = cb if point.c == ca
    end
  end
end

n.times { connect.(it) }

puts data.map(&:c).compact.tally.values.sort.last(3).inject(:*)

loop do
  connect.(n)
  break if data.all? { it.c == data[0].c }

  n += 1
end

puts data[dists[n].a].x * data[dists[n].b].x
