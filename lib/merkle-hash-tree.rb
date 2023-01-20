require 'range_extensions'

# Implement an RFC6962-compliant Merkle Hash Tree.
#
class MerkleHashTree
	# Instantiate a new MerkleHashTree.
	#
	# Arguments:
	#
	# * `data_access` -- An object which implements the Data Access Interface
	#   specified in `doc/DAI.md`.  `Array` implements the basic interface,
	#   but for performance you'll want to implement the caching methods
	#   described in `doc/DAI.md`.
	#
	#   The MerkleHashTree gets all of its data from this object.
	#
	# * `hash_class` -- An object which provides a `.digest` method which
	#   behaves identically to `Digest::Base.digest` -- that is, it takes
	#   an arbitrary string and returns another string, with the requirement
	#   that every call with the same input will return the same output.
	#
	# Raises:
	#
	# * `ArgumentError` -- If either argument does not meet the basic
	#   requirements specified above (that is, the objects don't implement
	#   the defined interface).
	#
	def initialize(data_access, hash_class)
		@data = data_access
		unless @data.respond_to?(:[])
			raise ArgumentError,
			      "data_access (#{@data.inspect}) does not implement #[]"
		end
		unless @data.respond_to?(:length)
			raise ArgumentError,
			      "data_access (#{@data.inspect}) does not implement #length"
		end

		@digest = hash_class
		unless @digest.respond_to?(:digest)
			raise ArgumentError,
			      "hash_class (#{@digest.inspect}) does not implement #digest"
		end
	end

	# Return the hash value of a subtree.
	#
	# Arguments:
	#
	# * `subtree` -- A range of the list items over which the tree hash will
	#   be calculated.  If not specified, it defaults to the entire current
	#   list.
	#
	# Raises:
	#
	# * `ArgumentError` -- if the range doesn't consist of integers, or if the
	#   range is outside the bounds of the current list size.
	#
	def head(subtree = nil)
		# Super-special case when we're asking for the hash of an entire list
		# that...  just happens to be empty
		if subtree.nil? and @data.length == 0
			return digest("")
		end

		subtree ||= 0..(@data.length-1)

		unless subtree.min.is_a? Integer and subtree.max.is_a? Integer
			raise ArgumentError,
			      "subtree is not all integers (got #{subtree.inspect})"
		end

		if subtree.min < 0
			raise ArgumentError,
			      "subtree cannot go negative (#{subtree.inspect})"
		end

		if subtree.max >= @data.length
			raise ArgumentError,
			      "subtree extends beyond list length (subtree is #{subtree.inspect}, list has #{@data.length} items)"
		end

		if subtree.max < subtree.min
			raise ArgumentError,
			      "subtree goes backwards (#{subtree.inspect})"
		end

		if @data.respond_to?(:mht_cache_get) and h = @data.mht_cache_get(subtree.inspect)
			return h
		end

		# No caching, or not in the cache... recalculate!
		h = if subtree.size == 1
			# We're at a leaf!
			leaf_hash(subtree.min)
		else
			k = power_of_2_smaller_than(subtree.size)

			node_hash(head((0..k-1)+subtree.min), head(subtree.min+k..subtree.max))
		end

		if @data.respond_to?(:mht_cache_set)
			@data.mht_cache_set(subtree.inspect, h)
		end

		h
	end

	# Generate an "audit proof" for a list item.
	#
	# Arguments:
	#
	# * `item` -- Specifies the index in the list to retrieve the audit proof
	#   for.  Must be a non-negative integer within the bounds of the current
	#   list.
	#
	# * `subtree` -- A range which defines the subset of list items within
	#   which to generate the audit proof.  The bounds of the range must be
	#   within the bounds of the current list.
	#
	# The return value of this method is an array of node hashes which make
	# up the audit proof.  The first element of the array is the immediate
	# sibling of the item requested; the last is a child of the root.
	#
	# Raises:
	#
	# * `ArgumentError` -- if any provided argument isn't an integer, or is
	#   negative, or is out of range.
	#
	# * `RuntimeError` -- if an attempt is made to request an audit proof on
	#   an empty list.
	#
	def audit_proof(item, subtree=nil)
		if @data.length == 0
			raise RuntimeError,
			      "Cannot calculate an audit proof on an empty list"
		end

		subtree ||= (0..@data.length - 1)

		unless subtree.min.is_a? Integer and subtree.max.is_a? Integer
			raise ArgumentError,
			      "subtree must be an integer range (got #{subtree.inspect})"
		end

		unless item.is_a? Integer
			raise ArgumentError,
			      "item must be an integer (got #{item.inspect})"
		end

		if subtree.min < 0
			raise ArgumentError,
			      "subtree range must be non-negative (subtree is #{subtree.inspect})"
		end

		if subtree.max >= @data.length
			raise ArgumentError,
			      "subtree must not extend beyond the end of the list (subtree is #{subtree.inspect}, list has #{@data.length} items)"
		end

		if subtree.max < subtree.min
			raise ArgumentError,
			      "subtree must be min..max (subtree is #{subtree.inspect})"
		end

		# And finally, after all that, we can start actually *doing* something
		if subtree.size == 1
			# Audit proof for a single item is defined as being empty
			[]
		else
			k = power_of_2_smaller_than(subtree.size)

			if item < k
				audit_proof(item, (0..k-1)+subtree.min) + [head(subtree.min+k..subtree.max)]
			else
				audit_proof(item-k, subtree.min+k..subtree.max) +
				  [head((0..k-1)+subtree.min)]
			end
		end
	end

	# Generate a consistency proof.
	#
	# Arguments:
	#
	# * `m` -- The smaller list size for which you wish to generate
	#   the consistency proof.
	#
	# * `n` -- The larger list size for which you wish to generate
	#   the consistency proof.
	#
	# Raises:
	#
	# * `ArgumentError` -- If the arguments aren't integers, or if they're
	#   negative, or if `n < m`.
	#
	def consistency_proof(m, n)
		unless m.is_a? Integer
			raise ArgumentError,
			      "m is not an integer (got #{m.inspect})"
		end

		unless n.is_a? Integer
			raise ArgumentError,
			      "n is not an integer (got #{n.inspect})"
		end

		if m < 0
			raise ArgumentError,
			      "m cannot be negative (m is #{m})"
		end

		if n > @data.length
			raise ArgumentError,
			      "n cannot be larger than the list length (n is #{n}, list has #{@data.length} elements)"
		end

		if n < m
			raise ArgumentError,
			      "n cannot be less than m (m is #{m}, n is #{n})"
		end

		# This is taken from in-practice behaviour of the Google pilot/aviator
		# CT servers... when first=0, you always get an empty proof.
		return [] if m == 0

		# And now... on to the real show!
		subproof(m, 0..n-1, true)
	end

	private
	# :nodoc:

	def subproof(m, n, b)
		if n.max == m-1
			if b
				[]
			else
				[head(n)]
			end
		elsif n.min == n.max
			[head(n)]
		else
			k = power_of_2_smaller_than(n.size)

			if m <= k+n.min
				subproof(m, (0..k-1)+n.min, b) + [head((n.min+k)..n.max)]
			else
				subproof(m, ((n.min+k)..n.max), false) + [head((0..k-1)+n.min)]
			end
		end
	end

	def digest(s)
		@digest.digest(s)
	end

	def leaf_hash(n)
		if @data[n].respond_to?(:mht_leaf_hash) and h = @data[n].mht_leaf_hash
			return h
		end

		h = digest("\0" + @data[n].to_s)

		if @data[n].respond_to?(:mht_leaf_hash=)
			@data[n].mht_leaf_hash = h
		end

		h
	end

	def node_hash(h1, h2)
		digest("\x01" + h1 + h2)
	end

	def power_of_2_smaller_than(n)
		raise ArgumentError, "Too small, Jim" if n < 2
		2 << ((n-1).bit_length - 2)
	end
end
