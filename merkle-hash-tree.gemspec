require 'git-version-bump'

Gem::Specification.new do |s|
	s.name = "merkle-hash-tree"

	s.version = GVB.version
	s.date    = GVB.date

	s.platform = Gem::Platform::RUBY

	s.homepage = "http://theshed.hezmatt.org/merkle-hash-tree"
	s.summary = "An RFC6962-compliant implementation of Merkle Hash Trees"
	s.authors = ["Matt Palmer"]

	s.extra_rdoc_files = ["README.md"]
	s.files = `git ls-files`.split("\n")

	s.add_runtime_dependency "git-version-bump"

	s.add_development_dependency 'bundler'
	s.add_development_dependency 'guard-spork'
	s.add_development_dependency 'guard-rspec'
	s.add_development_dependency 'plymouth'
	s.add_development_dependency 'pry-debugger'
	s.add_development_dependency 'rake'
	# Needed for guard
	s.add_development_dependency 'rb-inotify', '~> 0.9'
	s.add_development_dependency 'rdoc'
	s.add_development_dependency 'rspec', '~> 2.11'
	s.add_development_dependency 'rspec-mocks'
end
