require 'spork'

Spork.prefork do
	require 'bundler'
	Bundler.setup(:default, :test)
	require 'rspec/core'

	require 'rspec/mocks'

	require 'pry'
#	require 'plymouth'

	RSpec.configure do |config|
		config.fail_fast = true
#		config.full_backtrace = true

		config.expect_with :rspec do |c|
			c.syntax = :expect
		end
	end
	
	# Our super-special digest class to make it easier to understand WTF is
	# going on
	class IdentityDigest
		def self.digest(s)
			# Strip off the first character, it'll just be a \0 or \x1 anyway
			s[1..-1]
		end
	end
end

Spork.each_run do
	# Nothing to do here, specs will load the files they need
end
