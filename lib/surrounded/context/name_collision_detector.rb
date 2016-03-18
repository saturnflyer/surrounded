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
      collisions = check_for_collisions role_object_map, create_collision_map
      handle_collisions(collisions)
    end
    
    def handle_collisions(collisions)
      handler = self.class.handler
      collisions.each_pair do |role, colliders|
        send(handler, role, colliders) if handler
      end
    end

    def check_for_collisions(role_map, collisions, index=0)
      role_names = list_role_names(role_map)
      if all_roles_checked?(role_names, index)
        return collisions 
      else
        expand_collision_map(collisions, next_role(role_names, index), role_names, role_map)
        check_for_collisions role_map, collisions, (index += 1)
      end
    end
    
    def expand_collision_map(collisions, candidate, role_names, role_map)
      actor = role_map[candidate]
      collisions_found = check_role_for_collisions(role_names, actor)
      collisions[candidate] = collisions_found unless collisions_found.empty?
    end
    
    def next_role(names, index)
      names.delete_at index
    end
    
    def check_role_for_collisions(role_names, actor)
      role_names.each_with_object([]) do |role, collisions|
        collisions << role if actor.respond_to? role
      end
    end
    
    def list_role_names(role_map)
      role_map.keys.dup
    end
    
    def all_roles_checked?(names, index)
      index.eql? names.length
    end
    
    def nothing(role, array); end;
      
    def raise_exception(role, array)
      raise Surrounded::Context::NameCollisionError.new(role, array)
    end
    
    def warn(role, array)
      puts "#{role} has name collisions with #{array}" if array.length > 0
    end
    
    def handler
      self.class.handler
    end
    
    def create_collision_map
      Hash.new do |map, role|
        map[role] = []
      end
    end
  end
end
