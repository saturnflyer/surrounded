require 'minitest/autorun'
require 'simplecov'
require 'coveralls'

if ENV['COVERALLS']
  Coveralls.wear!
else
  SimpleCov.start
end