require_relative './spec_helper'
require_relative '../lib/merkle-hash-tree'
require 'digest/sha1'

describe "MerkleHashTree#power_of_2_smaller_than" do
	tests = {
		2 => 1,
		3 => 2,
		4 => 2,
		5 => 4,
		6 => 4,
		7 => 4,
		8 => 4,
		9 => 8,
		10 => 8,
		15 => 8,
		16 => 8,
		17 => 16,
		18 => 16,
		31 => 16,
		32 => 16,
		33 => 32
	}

	let(:mht) { MerkleHashTree.new([], Digest::SHA1) }

	it "bombs out for n=1" do
		expect { mht.send(:power_of_2_smaller_than, 1) }.
		  to raise_error(ArgumentError, /Too small, Jim/)
	end

	tests.each_pair do |k, v|
		it "(#{k}) => #{v}" do
			expect(mht.send(:power_of_2_smaller_than, k)).to eq(v)
		end
	end
end
