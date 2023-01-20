require_relative './spec_helper'
require_relative '../lib/merkle-hash-tree'

describe "MerkleHashTree#audit_proof" do
	let(:mht) { MerkleHashTree.new(data, IdentityDigest) }

	context "with a single element" do
		let(:data) { %w{a} }

		it "returns empty" do
			expect(mht.audit_proof(0)).to eq([])
		end
	end

	context "with a one-level tree" do
		let(:data) { %w{a b} }

		it "works for 'b'" do
			expect(mht.audit_proof(1)).to eq(['a'])
		end

		it "works for 'a'" do
			expect(mht.audit_proof(0)).to eq(['b'])
		end
	end

	context "with a two-level tree" do
		let(:data) { %w{a b c d} }

		it "works for 'a'" do
			expect(mht.audit_proof(0)).to eq(['b', 'cd'])
		end

		it "works for 'b'" do
			expect(mht.audit_proof(1)).to eq(['a', 'cd'])
		end

		it "works for 'c'" do
			expect(mht.audit_proof(2)).to eq(['d', 'ab'])
		end

		it "works for 'd'" do
			expect(mht.audit_proof(3)).to eq(['c', 'ab'])
		end
	end

	context "with an unbalanced three-level tree" do
		let(:data) { %w{a b c d e} }

		it "works for 'a'" do
			expect(mht.audit_proof(0)).to eq(['b', 'cd', 'e'])
		end

		it "works for 'b'" do
			expect(mht.audit_proof(1)).to eq(['a', 'cd', 'e'])
		end

		it "works for 'c'" do
			expect(mht.audit_proof(2)).to eq(['d', 'ab', 'e'])
		end

		it "works for 'd'" do
			expect(mht.audit_proof(3)).to eq(['c', 'ab', 'e'])
		end

		it "works for 'e'" do
			# It makes sense if you drink *juuuuust* enough tequila
			expect(mht.audit_proof(4)).to eq(['abcd'])
		end
	end

	context "with a seven node tree" do
		# Taken from RFC6962, s2.1.3
		let(:data) { %w{a b c d e f g} }

		it "works for 'a'" do
			expect(mht.audit_proof(0)).to eq(%w{b cd efg})
		end

		it "works for 'd'" do
			expect(mht.audit_proof(3)).to eq(%w{c ab efg})
		end

		it "works for 'e'" do
			expect(mht.audit_proof(4)).to eq(%w{f g abcd})
		end

		it "works for 'g'" do
			expect(mht.audit_proof(6)).to eq(%w{ef abcd})
		end
	end

	context "with a large tree" do
		let(:data) { %w{a b c d e f g h} }

		it "works for 'd'" do
			expect(mht.audit_proof(3)).to eq(%w{c ab efgh})
		end
	end

	context "with a hueg tree" do
		let(:data) { %w{a b c d e f g h i j k l m n o p q r s t u v w x y z} }

		it "works for 'f'" do
			expect(mht.audit_proof(5)).to eq(%w{e gh abcd ijklmnop qrstuvwxyz})
		end

		it "works for 'q'" do
			expect(mht.audit_proof(15)).to eq(%w{o mn ijkl abcdefgh qrstuvwxyz})
		end

		it "works for 'z'" do
			expect(mht.audit_proof(25)).to eq(%w{y qrstuvwx abcdefghijklmnop})
		end
	end

	context "with data from issue #2" do
		let(:data) do
			[].tap do |mht_data|
				mht_data << {sender_id: 1, receiver_id: 5, balance_transaction_id: 101, amount: 10, fee: 0.05} #0
				mht_data << {sender_id: 2, receiver_id: 6, balance_transaction_id: 102, amount: 20, fee: 0.05} #1
				mht_data << {sender_id: 3, receiver_id: 7, balance_transaction_id: 103, amount: 30, fee: 0.05} #2
				mht_data << {sender_id: 4, receiver_id: 8, balance_transaction_id: 104, amount: 40, fee: 0.05} #3
				mht_data << {user_id: 1, balance: 1000} #4
				mht_data << {user_id: 2, balance: 2000} #5
				mht_data << {user_id: 3, balance: 3000} #6
				mht_data << {user_id: 4, balance: 4000} #7
				mht_data << {user_id: 5, balance: 5000} #8
				mht_data << {user_id: 6, balance: 6000} #9
				mht_data << {user_id: 7, balance: 7000} #10
				mht_data << {user_id: 8, balance: 8000} #11
			end
		end

		it "produces unique audit proofs" do
			expect(mht.audit_proof(6)).to_not eq(mht.audit_proof(7))
		end
	end
end
