require 'surrounded'

class Countdown
  extend Surrounded::Context
  
  initialize :singer, :number, :location
  
  trigger :start do
    singer.start
  end
  
  trigger :continue do
    singer.continue
  end
  
  trigger :finish do
    singer.announce_status
  end
  
  role :singer do
    def start
      announce_full_status
      take_action
    end
    
    def continue
      announce_status
      pause
      start
    end
    
    def announce_full_status
      output %{#{location.status}, #{location.inventory}}.capitalize
    end
    
    def announce_status
      output %{#{location.status}}.capitalize
    end
    
    def take_action
      if location.empty?
        output %{Go to the store and get some more}
        next_part.finish
      else
        output %{#{location.subtraction}, pass it around}.capitalize
        next_part.continue
      end
    end
    
    def pause
      output ""
    end
    
    def next_part
      context.class.new(singer, number.pred, location)
    end
  end
  
  role :number, :wrap do
    def name
      self.zero? ? 'no more' : to_i
    end
    
    def pronoun
      self == 1 ? 'it' : 'one'
    end
    
    def container
      self == 1 ? 'bottle' : 'bottles'
    end
    
    def pred
      self.zero? ? 99 : super
    end
  end
  
  role :location do
    def empty?
      number.zero?
    end
    
    def inventory
      %{#{number.name} #{number.container} of beer}
    end
    
    def status
      %{#{inventory} #{placement} #{name}}
    end
    
    def subtraction
      %{take #{number.pronoun} #{removal_strategy}}
    end
  end
end

class Location
  include Surrounded
  
  def placement
    'on'
  end
  
  def removal_strategy
    'off'
  end
  
  def name
    "the " + self.class.to_s.downcase
  end
end

class Wall < Location
  def removal_strategy
    'down'
  end
end

class Box < Location
  def placement
    'in'
  end
  
  def removal_strategy
    'out'
  end
end

class Chorus
  include Surrounded
  def output(value)
    STDOUT.puts(value)
  end
end

class Sheet
  include Surrounded
  def output(value)
    File.open('bottles.txt', 'a') do |f|
      f.puts(value)
    end
  end
end

Countdown.new(Chorus.new, 3, Wall.new).start
# Countdown.new(Sheet.new, 3, Box.new).start