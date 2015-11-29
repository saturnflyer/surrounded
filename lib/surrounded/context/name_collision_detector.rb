module NameCollisionDetector
  attr_reader :handler

  def on_name_collision(handler)
    case handler
    when :nothing
      @handler = nil
    when :raise_exception
      @handler = lambda {|role, array| raise Surrounded::Context::NameCollisionError.new "#{role} has name collisions with #{array}"}
    when :warn
      @handler = lambda {|role, array| puts "#{role} has name collisions with #{array}" if array.length > 0}
    else
      if handler.respond_to? :call
        @handler = handler
      else
        @handler = instance_method handler
      end
    end
  end
  
  def self.extended(base)
    base.include NameCollisionHandler
  end

  module NameCollisionHandler
    def detect_collisions(role_object_map)
      collision_map = Hash.new do |map, role|
        map[role] = []
      end
      collisions = check_for_collisions role_object_map, 0, collision_map
      collisions.each_pair do |role, colliders|
        if handler = self.class.handler
          if handler.respond_to? :call
            handler.call(role, colliders)
          else
            handler.bind(self).call(role, colliders)
          end
        end
      end
    end

    def check_for_collisions(role_map, index, collisions)
      role_names = role_map.keys.dup
      if index.eql? role_names.length
        return collisions
      end

      candidate_role_name = role_names[index]
      actor = role_map[candidate_role_name]
      role_names.delete(candidate_role_name)
      role_names.each do |role|
        collisions[candidate_role_name] << role if actor.respond_to? role
      end
      index += 1
      check_for_collisions role_map, index, collisions
    end
  end
end
