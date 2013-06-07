# Surrounded

[![Build Status](https://travis-ci.org/saturnflyer/surrounded.png?branch=master)](https://travis-ci.org/saturnflyer/surrounded)
[![Code Climate](https://codeclimate.com/github/saturnflyer/surrounded.png)](https://codeclimate.com/github/saturnflyer/surrounded)
[![Coverage Status](https://coveralls.io/repos/saturnflyer/surrounded/badge.png)](https://coveralls.io/r/saturnflyer/surrounded)

## Create encapsulated environments for your objects.

Keep the distraction of other features out of your way. Write use cases and focus on just the business logic

## Usage

Add `Surrounded` to your objects to give them awareness of other objects.

```ruby
class User
  include Surrounded
end
```

Now your user instances will be able to get objects in their environment.

_What environment!? I don't get it._

I didn't explain that yet.

You can make an object which contains other objects. It acts as an environment
and objects inside should have knowledge of the other objects in the environment.
Take a breath, because there's a lot going on.

First, you extend a class with the appropriate module to turn it into an object environment:

```ruby
class MyEnvironment
  extend Surrounded::Context
end
```

Typical initialization of this environment has a lot of code. For example:

```ruby
class MyEnvironment
  extend Surrounded::Context

  attr_reader :employee, :boss
  private :employee, :boss
  def initialize(employee, boss)
    @employee = employee.extend(Exmployee)
    @boss = boss
  end

  module Employee
    # extra behavior here...
  end
end
```

_WTF was all that!?_

Relax. I'll explain.

When you create an instance of `MyEnvironment` it has certain objects inside.
Here we see that it has an `employee` and a `boss`. Inside the methods of the environment it's simpler and easier to write `employee` instead of `@employee` so we make them `attr_reader`s. But we don't need these methods to be externally accessible so we set them to private.

Next, we want to add environment-specific behavior to the `employee` so we extend the object with the module `Employee`.

If you're going to be doing this a lot, it's painful. Here's what `Surrounded` does for you:

```ruby
class MyEnvironment
  extend Surrounded::Context

  setup(:employee, :boss)

  module Employee
    # extra behavior here...
  end
end
```

There! All that boilerplate code is cleaned up.

Notice that there's no `Boss` module. If a module of that name does not exist, the object passed into initialize simply won't gain any new behavior.

_OK. I think I get it, but what about the objects? How are they aware of their environment? Isn't that what this is supposed to do?_

Yup. Ruby doesn't have a notion of a local environment, so we lean on `method_missing` to do the work for us.

```ruby
class User
  include Surrounded
end
```

With that, all instances of `User` have implicit access to their surroundings.

_Yeah... How?_

Via `method_missing` those `User` instances can access a `context` object stored in `Thread.current`. I didn't mention how the context is set, however.

Your environment will have methods of it's own that will trigger actions on the objects inside, but we need those trigger methods to set the environment instance as the current context so that the objects it contains can access them.

Here's an example of what we want:

```ruby
class MyEnvironment
  # other stuff from above is still here...

  def shove_it
    Thread.current[:context] = self
    employee.quit
    Thread.current[:context] = nil
  end

  module Employee
    def quit
      say("I'm sick of this place, #{boss.name}!")
      stomp
      throw_papers
      say("I quit!")
    end
  end
end
```

What's happening in there is that when the `shove_it` method is called, the current environment object is stored as the context.

The behavior defined in the `Employee` module assumes that it may access other objects in it's local environment. The `boss` object, for example, is never explicitly passed in as an argument.

_WTF!? That's insane!_

I thought so too, at first. But continually passing references assumes there's no relationship between objects in that method. What `Surrounded` does for us is to make the relationship between objects and gives them the ability to access each other.

This simple example may seem trivial, but the more contextual code you have the more cumbersome passing references becomes. By moving knowledge to the local environment, you're free to make changes to the procedures without the need to alter method signatures with new refrences or the removal of unused ones.

By using `Surrounded::Context` you are declaring a relationship between the objects inside.

Because all the behavior is defined internally and only relevant internally, those relationships don't exist outside of the environment.

_OK. I think I understand. So I can change business logic just by changing the procedures and the objects. I don't need to adjust arguments for a new requirement. That's kind of cool!_

Damn right.

But you don't want to continually set those `Thread` variables, do you?

_No. That's annoying._

Yeah. Instead, it would be easier to have this library do the work for us.
Here's what you can do:

```ruby
class MyEnvironment
  # the other code from above...

  trigger :shove_it do
    employee.quit
  end
end
```

By using this `trigger` keyword, our block is the code we care about, but internally the method is written to set the `Thread` variables.

_Hmm. I don't like having to do that._

Me either. I'd rather just use `def` but getting automatic code for setting the context is really convenient.
It also allows us to store the triggers so that you can, for example, provide details outside of the environment about what triggers exist.

```ruby
context = MyEnvironment.new(current_user, the_boss)
context.triggers #=> [:shove_it]
```

You might find that useful for dynamically defining user interfaces.

## Dependencies

The dependencies are minimal. The plan is to keep it that way but allow you to configure things as you need.

If you're using [Casting](http://github.com/saturnflyer/casting), for example, Surrounded will attempt to use that before extending an object, but it will still work without it.

## To Do

Casting provides a way to remove features outside of a block. For now, the code doesn't attempt to `uncast` an object. It will in the future though.

## Installation

Add this line to your application's Gemfile:

    gem 'surrounded'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install surrounded

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
