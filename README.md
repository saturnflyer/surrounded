# Surrounded
## Bring your own complexity

[![Build Status](https://travis-ci.org/saturnflyer/surrounded.png?branch=master)](https://travis-ci.org/saturnflyer/surrounded)
[![Code Climate](https://codeclimate.com/github/saturnflyer/surrounded.png)](https://codeclimate.com/github/saturnflyer/surrounded)
[![Coverage Status](https://coveralls.io/repos/saturnflyer/surrounded/badge.png)](https://coveralls.io/r/saturnflyer/surrounded)
[![Gem Version](https://badge.fury.io/rb/surrounded.png)](http://badge.fury.io/rb/surrounded)

# Surrounded aims to make things simple and get out of your way.

Most of what you care about is defining the behavior of objects. How they interact is important.
The purpose of this library is to clear away the details of getting things setup and to allow you to make changes to the way you handle roles.

There are two main parts to this library. 

1. `Surrounded` gives objects an implicit awareness of other objects in their environments.
2. `Surrounded::Context` helps you create objects which encapsulate other objects. These *are* the environments.

First, take a look at creating contexts. This is where you'll spend most of your time.

## Easily create encapsulated environments for your objects.

Typical initialization of an environment, or a Context in DCI, has a lot of code. For example:

```ruby
class MyEnvironment

  attr_reader :employee, :boss
  private :employee, :boss
  def initialize(employee, boss)
    @employee = employee.extend(Employee)
    @boss = boss
  end

  module Employee
    # extra behavior here...
  end
end
```

This code allows the MyEnvironment class to create instances where it will have an `employee` and a `boss` role internally. These are set to `attr_reader`s and are made private.

The `employee` is extended with behaviors defined in the `Employee` module, and in this case there's no extra stuff for the `boss` so it doesn't get extended with anything.

Most of the time you'll follow a pattern like this. Some objects will get extra behavior and some won't. The modules that you use to provide the behavior will match the names you use for the roles to which you assign objects.

By adding `Surrounded::Context` you can shortcut all this work.

```ruby
class MyEnvironment
  extend Surrounded::Context
  
  initialize(:employee, :boss)

  module Employee
    # extra behavior here...
  end
end
```

Surrounded gives you an `initialize` class method which does all the setup work for you.

## Managing Roles

_I don't want to use modules. Can't I use something like SimpleDelegator?_

Well, it just so happens that you can. This code will work just fine:

```ruby
class MyEnvironment
  extend Surrounded::Context
  
  initialize(:employee, :boss)

  class Employee < SimpleDelegator
    # extra behavior here...
  end
end
```

Instead of extending the `employee` object, Surrounded will run `Employee.new(employee)` to create the wrapper for you. You'll need to include the `Surrounded` module in your wrapper, but we'll get to that.

But the syntax can be even simpler than that if you want.

```ruby
class MyEnvironment
  extend Surrounded::Context
  
  initialize(:employee, :boss)

  role :employee do
    # extra behavior here...
  end
end
```

By default, this code will create a module for you named `Employee`. If you want to use a wrapper, you can do this:

```ruby
class MyEnvironment
  extend Surrounded::Context
  
  initialize(:employee, :boss)

  wrap :employee do
    # extra behavior here...
  end
end
```

But if you're making changes and you decide to move from a module to a wrapper or from a wrapper to a module, you'll need to change that method call. Instead, you could just tell it which type of role to use:

```ruby
class MyEnvironment
  extend Surrounded::Context
  
  initialize(:employee, :boss)

  role :employee, :wrapper do
    # extra behavior here...
  end
end
```

The default available types are `:module`, `:wrap` or `:wrapper`, and `:interface`. We'll get to `interface` below. The `:wrap` and `:wrapper` types are the same and they'll both create classes which inherit from SimpleDelegator _and_ include Surrounded for you.

These are minor little changes which highlight how simple it is to use Surrounded.

_Well... I want to use [Casting](https://github.com/saturnflyer/casting) so I get the benefit of modules without extending objects. Can I do that?_

Yup. The ability to use Casting is built-in. If the objects you provide to your context respond to `cast_as` then Surrounded will use that.

_Ok. So is that it?_

There's a lot more. Let's look at the individual objects and what they need for this to be valuable...

## Objects' access to their environments

Add `Surrounded` to your objects to give them awareness of other objects.

```ruby
class User
  include Surrounded
end
```

Now the `User` instances will be able to implicitly access objects in their environment.

Via `method_missing` those `User` instances can access a `context` object it stores in an internal collection. 

Inside of the `MyEnvironment` context we saw above, the `employee` and `boss` objects are instances of `User` for this example.

Because the `User` class includes `Surrounded`, the instances of that class will be able to access other objects in the same context implicitly.

Let's make our context look like this:

```ruby
class MyEnvironment
  # other stuff from above is still here...

  def shove_it
    employee.quit
  end

  role :employee do
    def quit
      say("I'm sick of this place, #{boss.name}!")
      stomp
      throw_papers
      say("I quit!")
    end
  end
end
```

What's happening in there is that when the `shove_it` method is called on the instance of `MyEnvironment`, the `employee` has the ability to refer to `boss` because it is in the same context, e.g. the same environment.

The behavior defined in the `Employee` module assumes that it may access other objects in it's local environment. The `boss` object, for example, is never explicitly passed in as an argument.

What `Surrounded` does for us is to make the relationship between objects and gives them the ability to access each other. Adding new or different roles to the context now only requires that we add them to the context and nothing else. No explicit references must be passed to each individual method. The objects are aware of the other objects around them and can refer to them by their role name.

I didn't mention how the context is set, however.

## Tying objects together

Your context will have methods of it's own which will trigger actions on the objects inside, but we need those trigger methods to set the accessible context for each of the contained objects.

Here's an example of what we want:

```ruby
class MyEnvironment
  # other stuff from above is still here...

  def shove_it
    employee.store_context(self)
    employee.quit
    employee.remove_context
  end

  role :employee do
    def quit
      say("I'm sick of this place, #{boss.name}!")
      stomp
      throw_papers
      say("I quit!")
    end
  end
end
```

Now that the `employee` has a reference to the context, it won't blow up when it hits `boss` inside that `quit` method.

We saw how we were able to clear up a lot of that repetitive work with the `initialize` method, so this is how we do it here:

```ruby
class MyEnvironment
  # other stuff from above is still here...

  trigger :shove_it do
    employee.quit
  end

  role :employee do
    def quit
      say("I'm sick of this place, #{boss.name}!")
      stomp
      throw_papers
      say("I quit!")
    end
  end
end
```

By using this `trigger` keyword, our block is the code we care about, but internally the method is created to first set all the objects' current contexts.

The context will also store the triggers so that you can, for example, provide details outside of the environment about what triggers exist.

```ruby
context = MyEnvironment.new(current_user, the_boss)
context.triggers #=> [:shove_it]
```

You might find that useful for dynamically defining user interfaces.

Sometimes I'd rather not use this DSL, however. I want to just write regular methods. 

We can do that too. You'll need to opt in to this by specifying `set_methods_as_triggers` for the context class.

```ruby
class MyEnvironment
  # other stuff from above is still here...
  
  set_methods_as_triggers

  def shove_it
    employee.quit
  end

  role :employee do
    def quit
      say("I'm sick of this place, #{boss.name}!")
      stomp
      throw_papers
      say("I quit!")
    end
  end
end
```

This will allow you to write methods like you normally would. They are aliased internally with a prefix and the method name that you use is rewritten to add and remove the context for the objects in this context. The public API of your class remains the same, but the extra feature of wrapping your method is handled for you.

This will treat all instance methods defined on your context the same way, so be aware of that.

## Where roles exist

By using `Surrounded::Context` you are declaring a relationship between the objects inside playing your defined roles.

Because all the behavior is defined internally and only relevant internally, those relationships don't exist outside of the environment.

Surrounded makes all of your role modules and classes private constants. It's not a good idea to try to reuse behavior defined for one context in another area.

## The role DSL

Using the `role` method to define modules and classes takes care of the setup for you. This way you can swap between implementations:

```ruby

  # this uses modules
  role :source do
    def transfer
      self.balance -= amount
      destination.balance += amount
      self
    end
  end

  # this uses SimpleDelegator and Surrounded
  role :source, :wrap do
    def transfer
      self.balance -= amount
      destination.balance += amount
      __getobj__
    end
  end

  # this uses a special interface object which pulls
  # methods from a module and applies them to your object.
  role :source, :interface do
    def transfer
      self.balance -= amount
      destination.balance += amount
      self
    end
  end
```

The `:interface` option is a special object which has all of its methods removed (excepting `__send__` and `object_id`) so that other methods will be pulled from the ones that you define, or from the object it attempts to proxy.

Notice that the `:interface` allows you to return `self` whereas the `:wrap` acts more like a wrapper and forces you to deal with that shortcoming by using it's wrapped-object-accessor method: `__getobj__`.

If you'd like to choose one and use it all the time, you can set the default:

```ruby
class MoneyTransfer
  extend Surrounded::Context

  self.default_role_type = :interface # also :wrap, :wrapper, or :module

  role :source do
    def transfer
      self.balance -= amount
      destination.balance += amount
      self
    end
  end
end
```

Or, if you like, you can choose the default for your entire project:

```ruby
Surrounded::Context.default_role_type = :interface

class MoneyTransfer
  extend Surrounded::Context

  role :source do
    def transfer
      self.balance -= amount
      destination.balance += amount
      self
    end
  end
end
```

## Policies for the application of role methods

There are 2 approaches to applying new behavior to your objects.

By default your context will add methods to an object before a trigger is run
and behaviors will be removed after the trigger is run.

Alternatively you may set the behaviors to be added during the initialize method
of your context.

Here's how it works:

```ruby
class ActiviatingAccount
  extend Surrounded::Context

  apply_roles_on(:trigger) # this is the default
  # apply_roles_on(:initialize) # set this to apply behavior from the start

  initialize(:activator, :account)

  role :activator do
    def some_behavior; end
  end

  def non_trigger_method
    activator.some_behavior # not available unless you apply roles on initialize
  end

  trigger :some_trigger_method do
    activator.some_behavior # always available
  end
end
```

_Why are those options there?_

When you initialize a context and apply behavior at the same time, you'll need
to remove that behavior. For example, if you are using Casting AND you apply roles on initialize:

```ruby
context = ActiviatingAccount.new(current_user, Account.find(123))
context.do_something
current_user.some_behavior # this method is still available
current_user.uncast # you'll have to manually cleanup
```

But if you go with the default and apply behaviors on trigger, your roles will be cleaned up automatically:

```ruby
context = ActiviatingAccount.new(current_user, Account.find(123))
context.do_something
current_user.some_behavior # NoMethodError
```

## Overview in code

Here's a view of the possibilities in code.

```ruby
# set default role type for *all* contexts in your program
Surrounded::Context.default_role_type = :module # also :wrap, :wrapper, or :interface

class ActiviatingAccount
  extend Surrounded::Context

  apply_roles_on(:trigger) # this is the default
  # apply_roles_on(:initialize) # set this to apply behavior from the start
  
  set_methods_as_triggers # allows you to skip the 'trigger' dsl
  
  # set the default role type only for this class
  self.default_role_type = :module # also :wrap, :wrapper, or :interface

  initialize(:activator, :account)

  role :activator do # module by default
    def some_behavior; end
  end

  #  role :activator, :module do
  #    def some_behavior; end
  #  end
  #
  #  role :activator, :wrap do
  #    def some_behavior; end
  #  end
  #
  #  role :activator, :interface do
  #    def some_behavior; end
  #  end
  #
  # use your own classes if you don't want SimpleDelegator
  # class MySpecialClass
  #   include Surrounded # you must remember this
  #   # Surrounded assumes MySpecialClass.new(the_role_player_here)
  #   def initialize(...);
  #     # ... your code here
  #   end
  # end

  # works as a trigger (assigning the current context) only if set_methods_as_triggers is set
  def regular_method
    activator.some_behavior # behavior not available unless you apply roles on initialize
  end

  trigger :some_trigger_method do
    activator.some_behavior # behavior always available
  end
end
```

## Dependencies

The dependencies are minimal. The plan is to keep it that way but allow you to configure things as you need. The [Triad](http://github.com/saturnflyer/triad) project was written specifically to manage the mapping of roles and objects to the modules which contain the behaviors.

If you're using [Casting](http://github.com/saturnflyer/casting), for example, Surrounded will attempt to use that before extending an object, but it will still work without it.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'surrounded'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install surrounded
    
## Installation for Rails

See [surrounded-rails](https://github.com/saturnflyer/surrounded-rails)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
