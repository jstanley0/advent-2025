require_relative "skim"

Vert = Struct.new(:x, :y)
verts = ARGF.readlines.map { Vert.new(*it.split(?,).map(&:to_i)) }

# return a list of ranges that encompass discrete values and empty space
# and a map from real coordinate to deflated coordinate
def deflate_axis(values)
  values.sort!
  ranges = []
  map = {}
  values.uniq.sort.each do |v|
    ranges << ((ranges.last&.last || -1) + 1...v)
    map[v] = ranges.size
    ranges << (v..v)
  end
  vl = values.last + 1
  ranges << (vl..vl) # make sure an empty row/col exists, for flood fill
  [ranges, map]
end

xr, xm = deflate_axis(verts.map(&:x))
yr, ym = deflate_axis(verts.map(&:y))
dverts = verts.map { |v| Vert.new(xm[v.x], ym[v.y]) }

map = Skim.new(xr.size, yr.size, '.')
dverts.each_with_index do |v, i|
  nv = dverts[(i + 1) % dverts.size]
  map.draw_line(v.x, v.y, nv.x, nv.y, 'X')
  map[v.x, v.y] = '#'
  map[nv.x, nv.y] = '#'
end
map.flood_fill!(0, 0, ' ')

area = ->(dv0, dv1) do
  a = 0
  x0, y0, w, h = Skim.transform_corners(dv0.x, dv0.y, dv1.x, dv1.y)
  (x0...x0+w).each do |x|
    (y0...y0+h).each do |y|
      return 0 if map[x, y] == ' '

      a += xr[x].size * yr[y].size
    end
  end

  a
end

pair = dverts.combination(2).max_by { |c| area.(*c) }
map.draw_rect_from_corners(pair[0].x, pair[0].y, pair[1].x, pair[1].y, '@')
map.print

puts area.(*pair)
