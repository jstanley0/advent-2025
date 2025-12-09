Vert = Struct.new(:x, :y)
verts = ARGF.readlines.map { Vert.new(*it.split(?,).map(&:to_i)) }

def area(a, b)
  ((a.x - b.x).abs + 1) * ((a.y - b.y).abs + 1)
end

SCALE=100.0

def draw_rect(corners)
  x = corners.map(&:x).min
  y = corners.map(&:y).min
  w = (corners[1].x - corners[0].x).abs + 1
  h = (corners[1].y - corners[0].y).abs + 1
  <<~SVG
  <rect width="#{w/SCALE}" height="#{h/SCALE}" x="#{x/SCALE}" y="#{y/SCALE}" style="fill:blue;" />
  SVG
end

def write_svg(verts, rects)
  w = verts.map(&:x).max
  h = verts.map(&:y).max
  File.write('9.svg', <<~SVG)
  <svg height="#{h/SCALE}" width="#{w/SCALE}" xmlns="http://www.w3.org/2000/svg">
  <polygon points="#{verts.map {"#{it.x/SCALE},#{it.y/SCALE}"}.join(" ")}" style="fill:green;stroke:red;" />
  #{rects.map { draw_rect(it) }.join}
  </svg>
  SVG
end

# visually examinging that thing^, it is obvious that the solution must include
# one of two vertices
# 94865,50110 + an opposite corner from earlier in the polygon, or
# 94865,48656 + an opposite corner from later in the polygon
# these vertices are smack-dab in the middle of the list

# bottom half
i0 = verts.size / 2
i = verts.find_index { it.x < verts[i0].x }
ymax = verts[i].y
i += 1
i += 1 while verts[i].y > ymax
i += 1
v0 = verts[i]
a0 = area(verts[i0], v0)

# top half
i1 = i0 + 1
i = verts.size - 1
i -= 1 while verts[i].x > verts[i1].x
ymin = verts[i].y
i -= 1
i -= 1 while verts[i].y < ymin
i -= 1
v1 = verts[i]
a1 = area(verts[i1], v1)

# visualize and report
write_svg(verts, [[verts[i0], v0], [verts[i1], v1]])
puts [a0, a1].max
