require_relative 'skim'

def fire_tachyon(skim, x, y)
  while y < skim.height
    case skim[x, y]
    when '.'
      skim[x, y] = '|'
      y += 1
    when '|'
      return 0
    when '^'
      return 1 + fire_tachyon(skim, x - 1, y) + fire_tachyon(skim, x + 1, y)
    end
  end
  0
end

skim = Skim.read
x, y = skim.find_coords('S')
puts fire_tachyon(skim, x, y + 1)
