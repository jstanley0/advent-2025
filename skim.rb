# short for "ASCII Map"
# since this is a common pattern in AoC and I often screw it up

require 'byebug'
require 'digest'
require 'stringio'
require 'set'
require 'colorize'
require_relative 'search'

class Skim
  include Enumerable

  # cardinal directions, starting right, rotating clockwise modulo 4
  DX = [1, 0, -1, 0]
  DY = [0, 1, 0, -1]

  # yeah, this isn't very Encapsulated, but I need an escape hatch when time is of the essence
  attr_accessor :data, :sep

  # build an empty skim of the given size with the given value
  # optional separator will be used only for output
  def initialize(width = 0, height = 0, default = nil, sep: nil)
    @sep = sep
    @data = height.times.map { [default] * width }
  end

  # read a skim from src, stopping when an empty line or EOF is reached
  # kwargs:
  #  sep: if given, split input line on this separator. otherwise each character is an entry
  #  rec: require the skim to be rectangular (all rows are the same width)
  #  square: require the skim to be square (same width and height)
  #  num: treat the values as numeric
  # block:
  #  if given, transform each string on the way in
  def self.read(src = ARGF, sep: nil, rec: true, square: false, num: false, &)
    skim = Skim.new(sep:)
    data = []
    loop do
      line = src.gets
      break if line.nil?

      line.chomp!
      break if line.empty?

      ld = if sep.nil?
        line.chars
      else
        line.split(sep)
      end

      ld = ld.map(&:to_i) if num

      if block_given?
        ld = ld.map(&)
      end

      data << ld
    end

    skim.data = data
    raise "data not rectangular" if (rec || square) && !skim.rectangular?
    raise "data not square" if square && !skim.square?

    skim
  end

  # like #read, but returns an array of Skims separated by blank lines
  # if count is nil, read until EOF, otherwise read that many
  def self.read_many(src = ARGF, count: nil, sep: nil, rec: true, square: false, num: false, &)
    src = StringIO.new(src) if src.is_a?(String)
    skims = []
    loop do
      skim = Skim.read(src, sep:, rec:, square:, num:, &)
      break if skim.empty?
      skims << skim
      break if skims.size == count
    end
    raise "wrong number of Skims. expected #{count}, got #{skims.size}" if count && skims.size != count
    skims
  end

  def self.from_concise_string(str, sep: '/')
    Skim.new.tap { |s| s.data = str.split(sep).map(&:chars) }
    
    s
  end

  # width of the given row (if initialized with +rec+ then all rows are the same width)
  def width(row = 0)
    data[row].size
  end

  def height
    @height ||= data.size
  end

  def empty?
    data.empty?
  end

  def rectangular?
    data.empty? || data[1..].all? { |row| row.size == data[0].size }
  end

  def square?
    width == height
  end

  def flatten
    data.flatten
  end

  def rows
    data.map(&:dup)
  end

  def cols
    data[0].zip(*data[1..])
  end

  def in_bounds?(x, y)
    x >= 0 && y >= 0 && y < height && x < width(y)
  end

  def check_bounds!(x, y)
    raise "(#{x}, #{y}) is out of bounds" unless in_bounds?(x, y)
  end

  def subset(x, y, w, h)
    sub_data = []
    data[y...y+h].each do |row|
      sub_data << row[x...x+w]
    end
    dup_with_data(sub_data)
  end

  def paste(x, y, skim)
    skim.each do |val, a, b|
      self[x + a, y + b] = val
    end
    self
  end

  # accepts a block with |src, dst| chars and sets the destination to the return value
  # if a target cell is out of range, dst is nil and the return value is discarded
  def overlay(x, y, src)
    src.each do |val, a, b|
      if in_bounds?(x + a, y + b)
        dst = self[x + a, y + b]
        self[x + a, y + b] = yield(val, dst)
      else
        yield val, nil
      end
    end
    self
  end

  # chunk: number or pair of numbers; if given, add an extra space around chunks of this size
  # highlights: list of elements to highlight if present (will color other elements grey)
  def print(stream = $stdout, chunk: nil, highlights: [])
    delim = sep.to_s
    rec_width = flatten.map { |el| el.to_s.size }.max
    delim = ' ' if delim.empty? && rec_width > 1
    hchunk, vchunk = chunk
    vchunk ||= hchunk # chunk can be array (or single value for square chunking)

    data.each_with_index do |row, i|
      stream.puts row.map { |val| "%*s" % [rec_width, val] }.map.with_index { |val, i| post_process(val, i, hchunk, highlights) }.join(delim)
      stream.puts if vchunk && ((i + 1) % vchunk == 0)
    end
    stream.puts
  end

  HIGHLIGHT_COLORS = %i[light_cyan light_magenta light_white light_green light_red light_yellow light_blue]
  def post_process(val, i, hchunk, highlights)
    unless highlights.empty?
      color_index = highlights.index(val)
      val = val.colorize(color_index ? HIGHLIGHT_COLORS[color_index % HIGHLIGHT_COLORS.size] : :grey)
    end
    val += " " if hchunk && ((i + 1) % hchunk) == 0
    val
  end

  def pad(border_size, pad_value)
    n = Skim.new(width + 2 * border_size, height + 2 * border_size, pad_value, sep:)
    each do |val, x, y|
      n[x + border_size, y + border_size] = val
    end
    n
  end

  def rectangularize(default = nil)
    max_w = data.map(&:size).max
    n = Skim.new(max_w, height, default)
    n.paste(0, 0, self)
    n
  end

  def insert_rows!(row_count, default = nil, pos: nil, width: self.width)
    new_rows = row_count.times.map { [default] * width }
    if pos
      data[pos, 0] = new_rows
    else
      data.concat new_rows
    end
    self
  end

  def [](x, y)
    check_bounds!(x, y)
    data[y][x]
  end

  def []=(x, y, val)
    check_bounds!(x, y)
    data[y][x] = val
  end

  def dup
    dup_with_data(rows)
  end

  def each(&)
    return to_enum { size } unless block_given?

    data.each do |row|
      row.each(&)
    end
    self
  end

  def each_with_coords
    return to_enum(:each_with_coords) { size } unless block_given?

    data.each_with_index do |row, y|
      row.each_with_index do |val, x|
        yield val, x, y
      end
    end
    self
  end

  def size
    # since it may not be #rectangular?
    data.sum { |row| row.size }
  end

  def ==(rhs)
    data == rhs.data
  end

  def count_window(x, y, w, h, c)
    check_bounds!(x, y)
    check_bounds!(x + w - 1, y + h - 1)
    data[y...y+h].sum do |row|
      row[x...x+w].count(c)
    end
  end

  def find_coords(value)
    data.each_with_index do |row, y|
      x = row.find_index(value)
      return x, y if x
    end
    nil
  end

  def all_coords(value)
    return to_enum(:all_coords, value) unless block_given?

    data.each_with_index do |row, y|
      row.each_with_index do |v, x|
        yield x, y if value == v
      end
    end
    nil
  end

  # yield each value+coords and replace with block
  def transform!
    data.each_with_index do |row, y|
      row.each_with_index do |val, x|
        self[x, y] = yield val, x, y
      end
    end
    self
  end

  def draw_line(x0, y0, x1, y1, v)
    raise ArgumentError, "diagonal lines not supported" unless x0 == x1 || y0 == y1
    draw_rect_from_corners(x0, y0, x1, y1, v)
  end

  def draw_rect_from_corners(x0, y0, x1, y1, v)
    draw_rect(*self.class.transform_corners(x0, y0, x1, y1), v)
  end

  def self.transform_corners(x0, y0, x1, y1)
    xv = [x0, x1].sort
    yv = [y0, y1].sort
    [xv.first, yv.first, xv.last - xv.first + 1, yv.last - yv.first + 1]
  end

  def draw_rect(x0, y0, w, h, v)
    (x0...x0+w).each do |x|
      (y0...y0+h).each do |y|
        self[x, y] = v
      end
    end
  end

  def flood_fill!(x, y, val)
    rv = self[x, y]
    cq = Set.new
    cq << [x, y]
    until cq.empty?
      x, y = cq.first
      cq.delete cq.first
      self[x, y] = val
      cq << [x - 1, y] if x > 0 && self[x - 1, y] == rv
      cq << [x + 1, y] if x < width - 1 && self[x + 1, y] == rv
      cq << [x, y - 1] if y > 0 && self[x, y - 1] == rv
      cq << [x, y + 1] if y < height - 1 && self[x, y + 1] == rv
    end
    self
  end

  # yield neighbors (val, x, y) of the given element
  # if `diag` is false, only yield orthogonal ones (not diagonals)
  def nabes(x, y, diag: true, &)
    return to_enum(:nabes, x, y, diag:) unless block_given?

    check_nabe(x - 1, y, &)
    check_nabe(x + 1, y, &)
    check_nabe(x, y - 1, &)
    check_nabe(x, y + 1, &)
    if diag
      check_nabe(x - 1, y - 1, &)
      check_nabe(x - 1, y + 1, &)
      check_nabe(x + 1, y - 1, &)
      check_nabe(x + 1, y + 1, &)
    end
  end

  private def check_nabe(x, y)
    yield self[x, y], x, y if in_bounds?(x, y)
  end

  # return a flat array of the values of the neighbors
  def nv(x, y, diag: true)
    vals = []
    nabes(x, y, diag:) do |val|
      vals << val
    end
    vals
  end

  private def dup_with_data(data)
    other = Skim.new(sep:)
    other.data = data
    other
  end

  def match_rotation_of?(other)
    4.times do
      return true if other == self
      other = other.rotate_ccw
    end
    false
  end

  def rotate_cw
    dup_with_data(cols.map(&:reverse))
  end

  def rotate_ccw
    dup_with_data(cols.reverse)
  end

  def flip_v
    dup_with_data(rows.reverse)
  end

  def flip_h
    dup_with_data(data.map(&:reverse))
  end

  def hash
    digest = Digest::MD5.new
    data.each { digest << _1.join }
    digest.hexdigest
  end

  SearchContext = Struct.new(:skim, :diag, :path_proc, :goal_or_proc, :est_dist_proc)

  class SearchNode < Search::Node
    attr_accessor :context, :x, :y

    def initialize(context, x, y)
      self.context = context
      self.x = x
      self.y = y
    end

    def enum_edges
      c = context.skim[x, y]
      context.skim.nabes(x, y, diag: context.diag) do |v, a, b|
        cost = context.path_proc.call(c, v, x, y, a, b)
        cost = 1 if cost == true
        yield cost, SearchNode.new(context, a, b) if cost
      end
    end

    def goal?
      if context.goal_or_proc.respond_to?(:call)
        context.goal_or_proc.call(context.skim[x, y], x, y)
      else
        context.skim[x, y] == context.goal_or_proc
      end
    end

    def est_cost(other)
      context.est_dist_proc.call(x, y, other.x, other.y)
    end

    def hash
      y * context.skim.width + x
    end

    def to_s
      "(#{x},#{y})"
    end
  end

  # do a breadth-first search from x, y to a closest cell that satisfies a given goal
  # diag: can move diagonally
  # accepts block (source_char, dest_char, x0, y0, x1, y1) -> move cost (or nil if invalid)
  # goal = character to match or (char, x, y) -> bool
  # returns [cost, path]
  def bfs(x, y, diag: false, goal:, &block)
    context = SearchContext.new(self, diag, block, goal)
    Search::bfs(SearchNode.new(context, x, y))
  end

  # find a shortest path from x0, y0 to x1, y1
  # using the same block as above
  # est_dist_proc (x0, y0, x1, y1) -> est distance (defaults to manhattan distance)
  # returns [cost, path]
  def a_star(x0, y0, x1, y1, diag: false, est_dist_proc: nil, &block)
    est_dist_proc ||= ->(x0, y0, x1, y1) { (x1 - x0).abs + (y1 - y0).abs }
    context = SearchContext.new(self, diag, block, nil, est_dist_proc)
    Search::a_star(SearchNode.new(context, x0, y0), SearchNode.new(context, x1, y1))
  end
end
