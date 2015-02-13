# ![Surrounded](http://saturnflyer.github.io/surrounded/images/surrounded.png "Surrounded")
## Be in control of business logic.

[![Build Status](https://travis-ci.org/saturnflyer/surrounded.png?branch=master)](https://travis-ci.org/saturnflyer/surrounded)
[![Code Climate](https://codeclimate.com/github/saturnflyer/surrounded.png)](https://codeclimate.com/github/saturnflyer/surrounded)
[![Coverage Status](https://coveralls.io/repos/saturnflyer/surrounded/badge.png)](https://coveralls.io/r/saturnflyer/surrounded)
[![Gem Version](https://badge.fury.io/rb/surrounded.png)](http://badge.fury.io/rb/surrounded)

# Get work done with only what you need and nothing more.

Surrounded is designed to help you better manage your business logic.

## How to think about your objects

First, name the problem you're solving. Then, break down your problem into responsible roles.

Use your problem name as a class and extend it with `Surrounded::Context`

It might look like this:

```ruby
class Employment
  extend Surrounded::Context

  role :boss
  role :employee
end
```

In your application, you'll initialize this class with objects to play the roles that you've defined, so you'll need to specify which role players will use which role.

```ruby
class Employment
  extend Surrounded::Context

  initialize :employee, :boss

  role :boss
  role :employee
end
```

Here, you've specified the order when initializing so you can use it like this:

```ruby
user1 = User.find(1)
user2 = User.find(2)
context = Employment.new(user1, user2)
```

That ensures that `user1` will become (and have all the features of) the `employee` and `user2` will become (and have all the features of) the `boss`.

There are 2 things left to do:

1. define behaviors for each role and
2. define how you can trigger their actions

## Defining behaviors for roles

Behaviors for your roles are easily defined just like you define a method. Provide your role a block and define methods there.

```ruby
class Employment
  extend Surrounded::Context

  initialize :employee, :boss

  role :boss

  role :employee do
    def work_weekend
      if fed_up?
        quit
      else
        schedule_weekend_work
      end
    end

    def quit
      say("I'm sick of this place, #{boss.name}!")
      stomp
      throw_papers
      say("I quit!")
    end

    def schedule_weekend_work
      # ...
    end
  end
end
```

If any of your roles don't have special behaviors, like `boss`, you don't need to specify it. Your `initialize` setup will handle assiging who's who when this context is used.

```ruby
class Employment
  extend Surrounded::Context

  initialize :employee, :boss

  role :employee do
    #...
  end
end
```

## Triggering interactions

You'll need to define way to trigger these behaviors to occur so that you can use them.

```ruby
context = Employment.new(user1, user2)

context.plan_weekend_work
```

The method you need is defined as an instance method in your context, but before that method will work as expected you'll need to mark it as a trigger.

```ruby
class Employment
  extend Surrounded::Context

  initialize :employee, :boss

  def plan_weekend_work
    employee.work_weekend
  end
  trigger :plan_weekend_work

  role :employee do
    #...
  end
end
```

Trigger methods are different from regular instance methods in that they apply behaviors from the roles to the role players.
A regular instance method just does what you define. But a trigger will make your role players come alive with their behaviors.

There's one last thing to make this work.

## Getting your role players ready

You'll need to include `Surrounded` in the classes of objects which will be role players in your context.

It's as easy as:

```ruby
class User
  include Surrounded

  # ...
end
```

This gives each of the objects the ability to understand its context and direct access to other objects in the context.

## Why is this valuable?

By creating environments which encapsulate roles and all necessary behaviors, you will be better able to isolate the logic of your system. A `user` in your system doesn't have all possible behaviors defined in its class, it gains the behaviors only when they are necessary.

The objects that interact have their behaviors defined and available right where they are needed. Implementation is in proximity to necessity. The behaviors you need for each role player are highly cohesive and are coupled to their use rather than being coupled to the class of an object which might use them at some point.

# Deeper Dive

## Create encapsulated environments for your objects.

Typical initialization of an environment, or a Context in DCI, has a lot of code. For example:

```ruby
class Employment

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

This code allows the Employment class to create instances where it will have an `employee` and a `boss` role internally. These are set to `attr_reader`s and are made private.

The `employee` is extended with behaviors defined in the `Employee` module, and in this case there's no extra stuff for the `boss` so it doesn't get extended with anything.

Most of the time you'll follow a pattern like this. Some objects will get extra behavior and some won't. The modules that you use to provide the behavior will match the names you use for the roles to which you assign objects.

By adding `Surrounded::Context` you can shortcut all this work.

```ruby
class Employment
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
class Employment
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
class Employment
  extend Surrounded::Context
  
  initialize(:employee, :boss)

  role :employee do
    # extra behavior here...
  end
end
```

By default, this code will create a module for you named `Employee`. If you want to use a wrapper, you can do this:

```ruby
class Employment
  extend Surrounded::Context
  
  initialize(:employee, :boss)

  wrap :employee do
    # extra behavior here...
  end
end
```

But if you're making changes and you decide to move from a module to a wrapper or from a wrapper to a module, you'll need to change that method call. Instead, you could just tell it which type of role to use:

```ruby
class Employment
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

Inside of the `Employment` context we saw above, the `employee` and `boss` objects are instances of `User` for this example.

Because the `User` class includes `Surrounded`, the instances of that class will be able to access other objects in the same context implicitly.

Let's make our context look like this:

```ruby
class Employment
  # other stuff from above is still here...

  def plan_weekend_work
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

What's happening in there is that when the `plan_weekend_work` method is called on the instance of `Employment`, the `employee` has the ability to refer to `boss` because it is in the same context, e.g. the same environment.

The behavior defined in the `Employee` module assumes that it may access other objects in it's local environment. The `boss` object, for example, is never explicitly passed in as an argument.

What `Surrounded` does for us is to make the relationship between objects and gives them the ability to access each other. Adding new or different roles to the context now only requires that we add them to the context and nothing else. No explicit references must be passed to each individual method. The objects are aware of the other objects around them and can refer to them by their role name.

I didn't mention how the context is set, however.

## Tying objects together

Your context will have methods of it's own which will trigger actions on the objects inside, but we need those trigger methods to set the accessible context for each of the contained objects.

Here's an example of what we want:

```ruby
class Employment
  # other stuff from above is still here...

  def plan_weekend_work
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
class Employment
  # other stuff from above is still here...

  trigger :plan_weekend_work do
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
context = Employment.new(current_user, the_boss)
context.triggers #=> [:plan_weekend_work]
```

You might find that useful for dynamically defining user interfaces.

Sometimes I'd rather not use this DSL, however. I want to just write regular methods. 

We can do that too. You'll need to opt in to this by specifying `trigger :your_method_name` for the methods you want to use.

```ruby
class Employment
  # other stuff from above is still here...

  def plan_weekend_work
    employee.quit
  end
  trigger :plan_weekend_work
  
  # or in Ruby 2.x
  trigger def plan_weekend_work
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

This works like Ruby's `public`,`protected`, and `private` keywords in that you can send symbols of method names to it. But `trigger` does not alter the parsing of the document like those core keywords do. In other words, you can't merely type `trigger` on one line, and have methods added afterward be treated as trigger methods.

## Access Control for Triggers

If you decide to build a user interface from the available triggers, you'll find you need to know what triggers are available.

Fortunately, you can make it easy.

By running `protect_triggers` you'll be able to define when triggers may or may not be run. You can still run them, but they'll raise an error. Here's an example.

```ruby
class Employment
  extend Surrounded::Context
  protect_triggers
  
  def plan_weekend_work
    employee.quit
  end
  trigger :plan_weekend_work
  
  disallow :plan_weekend_work do
    employee.bank_balance > 1000000
  end
end
```

Then, when the employee role's `bank_balance` is greater than `1000000`, the available triggers won't include `:plan_weekend_work`.

You can compare the instance of the context by listing `all_triggers` and `triggers` to see what could be possible and what's currently possible.

Alternatively, if you just want to define your own methods without the DSL using `disallow`, you can just follow the pattern of `disallow_#{method_name}?` when creating your own protection.

In fact, that's exactly what happens with the `disallow` keyword. After using it here, we'd have a `disallow_plan_weekend_work?` method defined.

If you call the disallowed trigger directly, you'll raise an `Employment::AccessError` exception and the code in your trigger will not be run. You may rescue from that or you may rescue from `Surrounded::Context::AccessError` although you should prefer to use the error name from your own class.

## Restricting return values

_Tell, Don't Ask_ style programming can better be enforced by following East-oriented Code principles. This means that the return values from methods on your objects should not provide information about their internal state. Instead of returning values, you can enforce that triggers return the context object. This forces you to place context responsiblities inside the context and prevents leaking the details and responsiblities outside of the system.

Here's how you enforce it:

```ruby
class Employment
  extend Surrounded::Context
  east_oriented_triggers
end
```

That's it.

With that change, any trigger you define will execute the block you provide and return `self`, being the instance of the context.

## Where roles exist

By using `Surrounded::Context` you are declaring a relationship between the objects inside playing your defined roles.

Because all the behavior is defined internally and only relevant internally, those relationships don't exist outside of the environment.

Surrounded makes all of your role modules and classes private constants. It's not a good idea to try to reuse behavior defined for one context in another area.

## The role DSL

Using the `role` method to define modules and classes takes care of the setup for you. This way you can swap between implementations:

```ruby

  # this uses modules which include Surrounded
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

## Working with collections

If you want to use an Array of objects (for example) as a role player in your context,
you may do so. If you want each item in your collection to gain behavior, you merely need to
create a role for the items.

Surrounded will attempt to guess at the singular role name. For example, a role player named `members` would
be given the behaviors from a `Members` behavior module or class. Each item in your `members` collection
would be given behavior from a `Member` behavior module or class if you create one.

```ruby
class Organization
  initialize :leader, :members
  
  role :members do
    # special behavior for the collection
  end
  
  role :member do
    # special behavior to be applied to each member in the collection
  end  
end
```

## Overview in code

Here's a view of the possibilities in code.

```ruby
# set default role type for *all* contexts in your program
Surrounded::Context.default_role_type = :module # also :wrap, :wrapper, or :interface

class ActiviatingAccount
  extend Surrounded::Context
  
  # set the default role type only for this class
  self.default_role_type = :module # also :wrap, :wrapper, or :interface

  # shortcut initialization code
  initialize(:activator, :account)
  # or handle it yourself
  def initialize(activator, account)
    # this must be done to handle the mapping of roles to objects
    # pass an array of arrays with role name symbol and the object for that role
    map_roles([[:activator, activator],[:account, account]])

    # or load extra objects, perform other functions, etc. if you need and then use super
    account.perform_some_funtion
    super
  end
  # these also must be done if you create your own initialize method.
  # this is a shortcut for using attr_reader and private
  private_attr_reader :activator, :account

  role :activator do # module by default
    def some_behavior; end
  end

  #  role_methods :activator, :module do # alternatively use role_methods if you choose
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
  # class SomeSpecialRole
  #   include Surrounded # <-- you must remember this in your own classes
  #   # Surrounded assumes SomeSpecialRole.new(some_special_role)
  #   def initialize(...);
  #     # ... your code here
  #   end
  # end

  # if you use a regular method and want to use context-specific behavior, 
  # you must handle storing the context yourself:
  def regular_method
    apply_behaviors # handles the adding of all the roles and behaviors
    activator.some_behavior # behavior not available unless you apply roles on initialize
  ensure
     # Use ensure to enforce the removal of behaviors in case of exceptions.
     # This also does not affect the return value of this method.
    remove_behaviors # handles the removal of all roles and behaviors
  end

  trigger :some_trigger_method do
    activator.some_behavior # behavior always available
  end
  
  trigger def some_other_trigger
    activator.some_behavior # behavior always available
  end
  
  def regular_non_trigger
    activator.some_behavior # behavior always available with the following line
  end
  trigger :regular_non_trigger # turns the method into a trigger
  
  # create restrictions on what triggers may be used
  protect_triggers # <-- this is required if you want to protect your triggers this way.
  disallow :some_trigger_method do
    # whatever conditional code for the instance of the context
  end
  
  # or define your own method without the `disallow` keyword
  def disallow_some_trigger_method?
    # whatever conditional code for the instance of the context
  end
  
  # Create shortcuts for triggers as class methods
  # so you can do ActiviatingAccount.some_trigger_method(activator, account)
  # This will make all triggers shortcuts.
  shortcut_triggers
  # Alterantively, you could implement shortcuts individually:
  def self.some_trigger_method(activator, account)
    instance = self.new(activator, account)
    instance.some_trigger_method
  end
  
  # Set triggers to always return the context object
  # so you can enforce East-oriented style or Tell, Don't Ask
  east_oriented_triggers
  
  # Forward context instance methods as triggers to role players
  forward_trigger :role_name, :method_name
  forward_trigger :role_name, :method_name, :alternative_trigger_name_for_method_name
  forward_triggers :role_name, :list, :of, :methods, :to, :forward
  forwarding [:list, :of, :methods, :to, :forward] => :role_name
end
```

## Dependencies

The dependencies are minimal. The plan is to keep it that way but allow you to configure things as you need. The [Triad](http://github.com/saturnflyer/triad) project was written specifically to manage the mapping of roles and objects to the modules which contain the behaviors.

If you're using [Casting](http://github.com/saturnflyer/casting), for example, Surrounded will attempt to use that before extending an object, but it will still work without it.

## Support for other ways to apply behavior

Surrounded is designed to be flexible for you. If you have your own code to manage applying behaviors, you can setup your context class to use it.

### Additional libraries

Here's an example using [Behavioral](https://github.com/saturnflyer/behavioral)

```ruby
class MyCustomContext
  extend Surrounded::Context

  initialize :employee, :boss

  def module_extension_methods
    [:with_behaviors].concat(super)
  end

  def module_removal_methods
    [:without_behaviors].concat(super)
  end
end
```

If you're using your own non-SimpleDelegator wrapper you can conform to that; whatever it may be.

```ruby
class MyCustomContext
  extend Surrounded::Context

  initialize :employee, :boss

  class Employee < SuperWrapper
    include Surrounded

    # defined behaviors here...

    def wrapped_object
      # return the object that is wrapped
    end

  end

  def unwrap_methods
    [:wrapped_object]
  end
end
```

### Applying individual roles

If you'd like to use a special approach for just a single role, you may do that too.

When applying behaviors from a role to your role players, your Surrounded context will first look for a method named  `"apply_behavior_#{role}"`. Define your own method and set it to accept 2 arguments: the role constant and the role player.

```ruby
class MyCustomContext
  extend Surrounded::Context

  initialize :employee, :boss

  def apply_behavior_employee(behavior_constant, role_player)
    behavior_constant.build(role_player).apply # or whatever your need to do with your constant and object.
  end
end
```

You can also plan for special ways to remove behavior as well.

```ruby
class MyCustomContext
  extend Surrounded::Context

  initialize :employee, :boss

  def remove_behavior_employee(behavior_constant, role_player)
    role_player.cleanup # or whatever your need to do with your constant and object.
  end
end
```

You can remember the method name by the convention that `remove` or `apply` describes it's function, `behavior` refers to the first argument (thet contsant holding the behaviors), and then the name of the role which refers to the role playing object: `remove_behavior_role`.

## How to read this code

If you use this library, it's important to understand it.

As much as possible, when you use the Surrounded DSL for creating triggers, roles, initialize methods, and others you'll likely fine the actual method definitions created in a module and then find that module included in your class.

This is a design choice which allows you to override any standard behavior more easily.

### Where methods exist and why

When you define an initialize method for a Context class, Surrounded _could_ define the method on your class like this:

```ruby
def initialize(*roles)
  self.class_eval do # <=== this evaluates on _your_ class and defines it there.
    # code...
  end
end
```

If we used the above approach, you'd need to redefine initialize in its entirety:

```ruby
initialize(:role1, role2)

def initialize(role1, role2) # <=== this will completely redefine initialize on _this class_
  super # <=== this will NOT be the initialize method as provided to the Surrounded initialize above.
end
```

Surrounded uses a more flexible approach for you:

```ruby
def initialize(*roles)
  mod = Module.new
  mod.class_eval do # <=== this evaluates on the module and defines it there.
    # code...
  end
  include mod # <=== this adds it to the class ancestors
end
```

With this approach you can use the way Surrounded is setup, but make changes if you need.

```ruby
initialize(:role1, :role2) # <=== defined in a module in the class ancestors

def initialize(role1, role2)
  super # <=== run the method as defined above in the Surrounded DSL
  # ... then do additional work
end
```

### Read methods, expect modules

When you go to read the code, expect to find behavior defined in modules.

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
