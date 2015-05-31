source 'https://rubygems.org'

group :test do
  gem 'minitest'
  # gem 'mutant', git: 'https://github.com/kbrock/mutant.git', ref: 'minitest'
  gem "simplecov"
  gem 'coveralls', :require => false
  gem 'casting'
  gem 'rubinius-coverage', :platform => :rbx
end

platforms :rbx do
  gem 'rubysl', '~> 2.0'
end

gemspec
