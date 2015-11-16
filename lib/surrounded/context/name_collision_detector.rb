module NameCollisionDetector


  def on_name_collision(handler)
    case handler
    when :nothing
      @handler = lambda {|role, array| }
    when :raise_exception
      @handler = lambda {|role, array| raise Surrounded::Context::NameCollisionError.new "#{role} has name collisions with #{array}"}
    when :warn
      @handler = lambda {|role, array| puts "#{role} has name collisions with #{array}" if array.length > 0}
    else
      @handler = handler
    end
  end


  def detect_collisions(role_object_map)
    collision_map = Hash.new do |map, role|
      map[role] = []
    end
    collisions = check_for_collisions role_object_map, 0, collision_map
    collisions.each_pair do |role, array|
      @handler.call(role, array) if @handler
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
