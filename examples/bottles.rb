require 'surrounded'

class Song
  extend Surrounded::Context
  
  initialize :chorus, :bottle_count, :container, :location
  
  trigger :sing do
    chorus.sing
  end
  
  role :bottle_count, :wrap
  
  role :chorus do
    def sing
      bottle_count.downto(0).map {|count|
        output Verse.new(count, container, location).sing
      }
    end
  end
  
  class Verse
    extend Surrounded::Context
    
    def initialize(number, container, location)
      map_role_count(number)
      map_role_next_count(next_count_or_reset)
      map_roles([ [:container, container], [:location, location] ])
    end
    private_attr_reader :count, :next_count, :container, :location
    
    def next_count_or_reset
      count.zero? ? 99 : count.pred
    end
    
    trigger :sing do
      count.to_s
    end
    
    def map_role_next_count(obj)
      role_class = case obj
      when 0
        Count0
      when 1
        Count1
      else
        Count
      end
      map_role(:next_count, role_module_basename(role_class), obj)
    end
    
    def map_role_count(obj)
      role_class = case obj
      when 0
        Count0
      when 1
        Count1
      else
        Count
      end
      map_role(:count, role_module_basename(role_class), obj)
    end
    
    role :count, :wrap do
      def to_s
        %{
#{what.capitalize} #{where}, #{what},
#{action}
#{next_count.what.capitalize} #{next_count.where}
}
      end
      
      def what
        %{#{container.contents(__getobj__)}}
      end
      
      def action
        "Take #{pronoun} down, pass it around"
      end
      
      def pronoun
        'one'
      end
      
      def where
        %{#{location.placement} the #{location.name}}
      end
    end
    
    class Count0 < Count
      def action
        "Go to the store and get some more"
      end
      
      def what
        "no more #{container.plural_name} of #{container.ingredients}"
      end
    end
    
    class Count1 < Count
      def pronoun
        "it"
      end
    end
  end
end

class Collection
  include Surrounded
  
  def initialize(ingredients)
    @ingredients = ingredients
  end
  attr_reader :ingredients
  
  def plural_name
    self.class.to_s.downcase
  end
  
  def singular_name
    raise 'unimplemented!'
  end
  
  def contents(amount)
    name = (amount == 1 ? singular_name : plural_name)
    %{#{amount} #{name} of #@ingredients}
  end
end

class Bottles < Collection
  def singular_name
    'bottle'
  end
end

class Jars < Collection
  def singular_name
    'jar'
  end
end


class Container
  include Surrounded
  
  def placement
    'on'
  end
  
  def name
    "the " + self.class.to_s.downcase
  end
end

class Wall < Container; end

class Box < Container
  def placement
    'in'
  end
end

class Chorus
  include Surrounded
  def output(value)
    STDOUT.puts(value)
  end
end

# context = Song.new(Chorus.new, 3, Jars.new('jam'), Box.new)
context = Song.new(Chorus.new, 3, Bottles.new('beer'), Wall.new)
context.sing