$network = ARGF.readlines.map { it.split(':') }.to_h.transform_values(&:split)

def count_paths(from, memo = {}, dac: false, fft: false)
  return (dac && fft) ? 1 : 0 if $network[from].include?("out")

  dac = true if from == "dac"
  fft = true if from == "fft"
  memo[[from, dac, fft]] ||= $network[from].sum { |link| count_paths(link, memo, dac:, fft:) }
end

puts count_paths("svr")
