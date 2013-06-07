require 'minitest/autorun'
require 'simplecov'
require 'coveralls'

if ENV['COVERALLS']
  Coveralls.wear!
else
  SimpleCov.start do
    add_filter 'test'
  end
end

require 'surrounded'
require 'surrounded/context'