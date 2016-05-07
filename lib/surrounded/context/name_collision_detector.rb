module NameCollisionDetector
  attr_reader :handler

  def self.extended(base)
    base.send :include, NameCollisionHandler
  end
  
  def on_name_collision(method_name)
    @handler = method_name
  end

  module NameCollisionHandler
    
    private
    
    def detect_collisions(role_object_map)
      if handler
        handle_collisions(collision_warnings(role_object_map))
      end
    end
    
    def collision_warnings(role_object_map)
      role_object_map.select{|role, object|
        ![object.methods & role_object_map.keys].flatten.empty?
      }.map{|role, object|
        role_collision_message(role,(object.methods & role_object_map.keys).sort)
      }.join("\n")
    end
    
    def handle_collisions(collisions)
      handler_args = [collisions]
      if handler == :raise
        handler_args.unshift Surrounded::Context::NameCollisionError
      end
      
      handler_method.call *handler_args
    end
    
    def role_collision_message(role, colliding_method_names)
      "#{role} has name collisions with #{colliding_method_names}"
    end
    
    def nothing(*); end

    def handler
      self.class.handler
    end
    
    def handler_method
      if handler.respond_to?(:call)
        handler
      elsif respond_to?(handler, true)
        method(handler)
      elsif self.class.respond_to?(handler, true)
        self.class.method(handler)
      else
        method(:nothing)
      end
    end
  end
end
