require_relative 'search'

class Indicator
  attr_accessor :target, :buttons, :jolts

  def initialize(line)
    self.target = 0
    self.buttons = []
    line.split.each do |thing|
      content = thing[1..-2]
      case thing[0]
      when '['
        content.chars.each_with_index { |c, i| self.target |= (1 << i) if c == '#' }
      when '('
        self.buttons << content.split(?,).map { 1 << it.to_i }.inject(:|)
      end
    end
  end

end

indicators = ARGF.readlines.map { Indicator.new(it) }

class SearchNode < Search::Node
  attr_accessor :indicator, :lights

  def initialize(indicator, lights)
    self.indicator = indicator
    self.lights = lights
  end

  def hash
    lights.hash
  end

  def enum_edges
    indicator.buttons.each do |button|
      yield [1, SearchNode.new(indicator, lights ^ button)]
    end
  end

  def goal?
    lights == indicator.target
  end
end

puts indicators.sum { |indicator| Search::bfs(SearchNode.new(indicator, 0)).first }
