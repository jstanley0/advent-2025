require_relative 'skim'

def extract_num(ws, x)
  return nil if x >= ws.width

  num = ''
  (0...ws.height - 1).each do |y|
    num << ws[x, y]
  end
  num.strip!
  return nil if num.empty?

  num.to_i
end

ws = Skim.read
y = ws.height - 1
x = 0
sum = 0
while x < ws.width
  op = ws[x, y]
  raise "oops" unless %w[+ *].include?(op)

  nums = []
  while (num = extract_num(ws, x))
    x += 1
    nums << num
  end
  x += 1

  sum += nums.inject(op.to_sym)
end

puts sum
