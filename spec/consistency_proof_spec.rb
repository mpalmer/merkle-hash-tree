require_relative './spec_helper'
require_relative '../lib/merkle-hash-tree'

describe "MerkleHashTree#consistency_proof" do
	let(:mht) { MerkleHashTree.new(data, IdentityDigest) }

	context "with a seven-node tree" do
		# Taken from RFC6962, s2.1.3
		let(:data) { %w{a b c d e f g} }

		it "is empty for 0->7" do
			expect(mht.consistency_proof(0, 7)).to eq([])
		end

		it "is empty for 7->7" do
			expect(mht.consistency_proof(7, 7)).to eq([])
		end

		it "works for 3->7" do
			expect(mht.consistency_proof(3, 7)).to eq(%w{c d ab efg})
		end

		it "works for 4->7" do
			expect(mht.consistency_proof(4, 7)).to eq(%w{efg})
		end

		it "works for 6->7" do
			expect(mht.consistency_proof(6, 7)).to eq(%w{ef g abcd})
		end
	end

	context "with a full three-level tree" do
		# Taken from www.certificate-transparency.org's "How Log Proofs Work"
		# page
		let(:data) { %w{a b c d e f g h} }

		it "works for 6->8" do
			expect(mht.consistency_proof(6, 8)).to eq(%w{ef gh abcd})
		end
	end
end
