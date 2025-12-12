# programming note: this is a dead-end approach. I was kind of fooled into keeping
# the same form as part 1 despite this being a very different problem. in particular,
# the order in which buttons is pushed is completely immaterial here, so this search
# is wasting an insane amount of time exploring every possible order. it got the right
# answer on the first two of 176 problems in the real input but never completed
# any others. I'm leaving it here for curiosity's sake
#
# programming update: after perusing the AoC subreddit I realized the above note
# is absolutely wrong; the button pressing order for part 1 doesn't matter either,
# and part 1 is in fact part 2 but with modulo-2 counters!

require_relative 'search'

class Indicator
  attr_accessor :buttons, :target

  def initialize(line)
    self.buttons = []
    self.target = []
    line.split.each do |thing|
      content = thing[1..-2]
      case thing[0]
      when '('
        self.buttons << content.split(?,).map { 1 << it.to_i }.inject(:|)
      when '{'
        self.target = content.split(?,).map(&:to_i)
      end
    end
  end
end

indicators = ARGF.readlines.map { Indicator.new(it) }

class SearchNode < Search::Node
  attr_accessor :indicator, :counters

  def initialize(indicator, counters = nil)
    self.indicator = indicator
    self.counters = counters || indicator.target.map { 0 }
  end

  def hash
    counters.hash
  end

  def enum_edges
    indicator.buttons.each do |button|
      next_counters = counters.dup
      counters.each_index do |i|
        next_counters[i] += 1 if button[i] > 0
      end
      unless counters.each_index.any? { next_counters[it] > indicator.target[it] }
        yield [1, SearchNode.new(indicator, next_counters)]
      end
    end
  end

  def est_cost(other)
    other.counters.zip(counters).map { _2 - _1 }.max
  end
end

puts indicators.sum { |indicator| Search::a_star(SearchNode.new(indicator), SearchNode.new(indicator, indicator.target)).first.tap { puts it } }
