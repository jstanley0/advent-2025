p ARGF.readlines.map(&:split).transpose.sum{o=it.pop.to_sym;it.map(&:to_i).inject(o)}
