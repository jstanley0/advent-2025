require "z3"

class Button
  attr_accessor :wires, :count

  def initialize(index, wires)
    self.wires = wires
    self.count = Z3.Int("b#{index}")
  end
end

class Machine
  attr_accessor :buttons, :target

  def initialize(line)
    self.buttons = []
    self.target = []
    line.split.each do |thing|
      next unless thing.start_with?('(') || thing.start_with?('{')

      nums = thing[1..-2].split(?,).map(&:to_i)
      case thing[0]
      when '('
        self.buttons << Button.new(buttons.size, nums)
      when '{'
        self.target = nums
      end
    end
  end

  def solve
    z3 = Z3::Optimize.new
    buttons.each do |button|
      z3.assert button.count >= 0
    end
    target.each_with_index do |val, i|
      z3.assert buttons.select { it.wires.include?(i) }.sum(&:count) == val
    end
    total = Z3.Int("total")
    z3.assert buttons.sum(&:count) == total
    z3.minimize total
    raise "unpossible" unless z3.satisfiable?

    z3.model[total].to_i
  end
end

machines = ARGF.readlines.map { Machine.new(it) }

puts machines.sum(&:solve)
