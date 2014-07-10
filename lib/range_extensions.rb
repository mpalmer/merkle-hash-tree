class Range
	def length
		last - first + 1
	end

	alias_method :size, :length

	def +(n)
		raise ArgumentError, "n must be integer" unless n.is_a? Integer

		(min+n)..(max+n)
	end
end
