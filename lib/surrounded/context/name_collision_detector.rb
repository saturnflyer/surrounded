class NameCollisionDetector

  def initialize(role_map)
    @role_object_array = role_map
  end

  def detect_collisions
    # for each role name, we need to check that its mapped object does not
    # respond to the other role names.
    collision_map = {}
    # Map an empty array to each role
    map_roles_to_empty_arrays collision_map, @role_object_array.keys
    collisions = check_for_collisions(@role_object_array, 0, collision_map)
    collisions.each_pair do |role, array|
      yield role, array if block_given?
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

  def map_roles_to_empty_arrays(collision_map, roles)
    roles.each {|role| collision_map[role] = []}
  end
end
