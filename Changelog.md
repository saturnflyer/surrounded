# Change Log

All notable changes to this project will be documented in this file.

## [0.9.11]

- Rely on the standard library Forwardable to setup how the RoleMap forwards messages to the container.
- Update RoleMap role_player? method to rescue from StandardError, a non-implementation-specific exception.

## [0.9.10]

- Do something with name collisions when a role player has an existing method of another role in the context.
- Move InvalidRoleType exception under the host context class namespace. This allows you to rescue from your own namespace.