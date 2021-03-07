# Change Log

All notable changes to this project will be documented in this file.

## [1.0.1]

- Fix a bug where shortcut_triggers would not work with keyword initialize

## [1.0.0]

- Drop deprecations around Context initialize method. It now requires keyword arguments. Non-keyword argumennts may be used with initialize_without_keywords
- Remove code supporting exception cause it InvalidRoleType prior to ruby 2.1

## [0.9.11]

- Rely on the standard library Forwardable to setup how the RoleMap forwards messages to the container.
- Update RoleMap role_player? method to rescue from StandardError, a non-implementation-specific exception.
- Move to using triad 0.3.0 which relies on concurrent-ruby 0.9+ and moves off of thread_safe 0.3.5

## [0.9.10]

- Do something with name collisions when a role player has an existing method of another role in the context.
- Move InvalidRoleType exception under the host context class namespace. This allows you to rescue from your own namespace.
