require_relative './spec_helper'
require_relative '../lib/merkle-hash-tree'
require 'digest/sha2'

describe "MerkleHashTree#head" do
	let(:data) do
		["", "\0", "\x10", "\x20\x21", "\x30\x31", "\x40\x41\x42\x43",
	    "\x50\x51\x52\x53\x54\x55\x56\x57",
	    "\x60\x61\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f"
	   ]
	end
	let(:mht) { MerkleHashTree.new(data, Digest::SHA256) }

	hashes = ["6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d",
	          "fac54203e7cc696cf0dfcb42c92a1d9dbaf70ad9e621f4bd8d98662f00e3c125",
	          "aeb6bcfe274b70a14fb067a5e5578264db0fa9b51af5e0ba159158f329e06e77",
	          "d37ee418976dd95753c1c73862b9398fa2a2cf9b4ff0fdfe8b30cd95209614b7",
	          "4e3bbb1f7b478dcfe71fb631631519a3bca12c9aefca1612bfce4c13a86264d4",
	          "76e67dadbcdf1e10e1b74ddc608abd2f98dfb16fbce75277b5232a127f2087ef",
	          "ddb89be403809e325750d3d263cd78929c2942b7942a34b77e122c9594a74c8c",
	          "5dc9da79a70659a9ad559cb701ded9a2ab9d823aad2f4960cfe370eff4604328"
	         ]


	def hexstring(s)
		s.scan(/./m).map { |c| sprintf("%02x", c.ord) }.join
	end

	8.times do |i|
		context "head(#{i})" do
			it "gives a specific hash" do
				expect(hexstring(mht.head(0..i))).to eq(hashes[i])
			end
		end
	end
end
