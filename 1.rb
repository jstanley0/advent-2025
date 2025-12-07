pos = 50
zeroes = 0
clicks = 0
ARGF.each_line do |line|
  dir, dist = line.split('', 2)
  dir = (dir == 'R') ? 1 : -1
  dist = dist.to_i
  while dist.positive?
    dist -= 1
    pos = (pos + dir) % 100
    clicks += 1 if pos.zero?
  end
  zeroes += 1 if pos.zero?
end
puts zeroes
puts clicks
