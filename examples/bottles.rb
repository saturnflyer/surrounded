require 'surrounded'
require "debug"
class CountdownSong
  extend Surrounded::Context

  def initialize(max:, min:)
    @max = max
    @min = min
  end
  attr_reader :max, :min

  def sing_with(verse_template)
    max.downto(min).map { |num| verse(num, verse_template) }
  end

  def verse(number, verse_template)
    verse_template.lyrics(number)
  end
end

class BottleVerse
  def self.lyrics(number)
    new(bottle_number: number).lyrics
  end

  extend Surrounded::Context

  initialize :bottle_number

  trigger :lyrics do
    "#{bottle_number} of beer on the wall, ".capitalize +
    "#{bottle_number} of beer.\n" +
    "#{bottle_number.action}, " +
    "#{bottle_number.successor} of beer on the wall.\n"
  end

  role :bottle_number, :wrapper do
    def to_s
      "#{quantity} #{container}"
    end

    def quantity
      __getobj__.to_s
    end

    def container
      "bottles"
    end

    def action
      "Take #{pronoun} down and pass it around"
    end

    def pronoun
      "one"
    end

    def successor
      context.bottle_role_player(pred)
    end
  end

  def bottle_role_player(number)
    bottle_role_for(number).new(number)
  end

  def bottle_role_for(number)
    case number
    when 0
      BottleNumber0
    when 1
      BottleNumber1
    else
      BottleNumber
    end
  end

  def map_role_bottle_number(num)
    map_role(:bottle_number, bottle_role_for(num), num)
  end

  # Inherit from existing role
  def self.bottle_role(name, &block)
    mod_name = RoleName(name)
    klass = Class.new(BottleNumber, &block)
    const_set(mod_name, klass)
  end

  role :bottle_number_0, :bottle_role do
    def quantity
      "no more"
    end

    def action
      "Go to the store and buy some more"
    end

    def successor
      context.bottle_role_player(99)
    end
  end

  role :bottle_number_1, :bottle_role do
    def container
      "bottle"
    end

    def pronoun
      "it"
    end
  end
end

class Bottles
  extend Surrounded::Context

  def song_template(upper: 99, lower: 0)
    CountdownSong.new(max: upper, min: lower)
  end

  trigger :song do
    song_template.sing_with(BottleVerse)
  end

  trigger :verses do |upper, lower|
    song_template(upper: upper, lower: lower).sing_with(BottleVerse)
  end

  trigger :verse do |number|
    song_template.verse(number, BottleVerse)
  end
end

puts Bottles.new.song
