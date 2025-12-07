class Ranger
  # (this class is designed around closed ranges)
  class << self
    # if integral is true, the union if 1..2, 3..4 is 1..4
    def union(*ranges, integral: true)
      ranges = ranges.sort_by(&:first)
      merged = []
      r0 = ranges.shift
      while (r1 = ranges.shift)
        if r0.last >= r1.first - (integral ? 1 : 0)
          r0 = [r0.first, r1.first].min .. [r0.last, r1.last].max
        else
          merged << r0
          r0 = r1
        end
      end
      merged << r0

      merged
    end

    def intersection(*ranges)
      ranges = ranges.sort_by(&:first)
      r0 = ranges.shift
      while (r1 = ranges.shift)
        return nil if r0.last < r1.first
        r0 = r1.first .. [r0.last, r1.last].min
      end
      r0
    end
  end
end
