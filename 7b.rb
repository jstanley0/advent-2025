require_relative 'skim'

def fire_tachyon(skim, x, y, memo={})
  res = memo[[x, y]]
  return res if res

  y0 = y
  while y < skim.height
    case skim[x, y]
    when '.'
      y += 1
    when '^'
      res = fire_tachyon(skim, x - 1, y, memo) + fire_tachyon(skim, x + 1, y, memo)
      memo[[x, y0]] = res
      return res
    end
  end
  1
end

skim = Skim.read
x, y = skim.find_coords('S')
puts fire_tachyon(skim, x, y + 1)
