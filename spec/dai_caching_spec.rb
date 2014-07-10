require_relative './spec_helper'
require_relative '../lib/merkle-hash-tree'

describe "DAI caching" do
	let(:dai) do
		%w{a b c d e f g}
	end

	let(:mht) { MerkleHashTree.new(dai, IdentityDigest) }

	it "tries to get cache values, but is OK with nil" do
		dai.
		  should_receive(:mht_cache_get).
		  with(any_args).
		  at_least(:once).
		  and_return(nil)

		mht.head
	end

	it "respects cache values" do
		dai.
		  should_receive(:mht_cache_get).
		  with('1..5').
		  and_return('xyzzy')

		expect(mht.head(1..5)).to eq('xyzzy')
	end

	it "tries to cache calculated values" do
		dai.
		  should_receive(:mht_cache_get).
		  with(any_args).
		  at_least(:once).
		  and_return(nil)
		dai.
		  should_receive(:mht_cache_set).
		  with('2..2', 'c')

		mht.head(2..2)
	end
end
