module NameCollisionDetector
  attr_reader :handler

  def self.extended(base)
    base.include NameCollisionHandler
  end
  
  def on_name_collision(method_name)
    @handler = method_name
  end

  module NameCollisionHandler
    def detect_collisions(role_object_map)
      collision_map = Hash.new do |map, role|
        map[role] = []
      end
      
      collisions = check_for_collisions role_object_map, collision_map
      handle_collisions(collisions)
    end
    
    def handle_collisions(collisions)
      collisions.each_pair do |role, colliders|
        self.send(self.class.handler, role, colliders) if self.class.handler
      end
    end

    def check_for_collisions(role_map, collisions, index=0)
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
      check_for_collisions role_map, collisions, index
    end
    
    
    def nothing(role, array); end;
      
    def raise_exception(role, array)
      raise Surrounded::Context::NameCollisionError.new(role, array)
    end
    
    def warn(role, array)
      puts "#{role} has name collisions with #{array}" if array.length > 0
    end
  end
end
