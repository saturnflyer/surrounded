# Surrounded aims to make things simple and get out of your way.

Most of what you care about is defining the behavior of objects. How they interact is important.
The purpose of this library is to clear away the details of getting things setup.

You should read the [main README](../../README.md) to get the gist of what's going on, if you haven't.

When you get started, you'll probably be specifying things exactly how you want them. But you can easily make changes.

```ruby
class MoneyTransfer
  extend Surrounded::Context

  def initialize(source, destination, amount)
    @source = source.extend(Source)
    @destination = destination
    @amount = amount
  end

  attr_reader :source, :destination, :amount
  private :source, :destination, :amount

  def execute
    source.transfer
  end

  module Source
    def transfer
      self.balance -= amount
      destination.balance += amount
      self
    end
  end
end
```

That's a lot of setup just to create the `execute` and `transfer` methods.

Here's a shortened version:

```ruby
class MoneyTransfer
  extend Surrounded::Context

  initialize(:source, :destination, :amount)

  trigger :execute do
    source.transfer
  end

  module Source
    def transfer
      self.balance -= amount
      destination.balance += amount
      self
    end
  end
end
```

Now it's cleaned up a bit and is much easier to see what's important.
If you decide you want to try out wrappers, you can start making changes to use `SimpleDelegator` from the standard library, but you'll have to remember to 1) `include Surrounded` 2) to do the initialize yourself again and 3) return the correct object from your role method.

Simply by changing your mind to use `SimpleDelegator`, here's what you'll need to do:

```ruby
class MoneyTransfer
  extend Surrounded::Context

  def initialize(source, destination, amount)
    @source = Source.new(source)
    @destination = destination
    @amount = amount
  end

  attr_reader :source, :destination, :amount
  private :source, :destination, :amount

  def execute
    source.transfer
  end

  class Source < SimpleDelegator
    include Surrounded

    def transfer
      self.balance -= amount
      destination.balance += amount
      __getobj__
    end
  end
end
```
Once again, it's big and ugly. But surrounded has your back; you can istead do this:

```ruby
class MoneyTransfer
  extend Surrounded::Context

  initialize(:source, :destination, :amount)

  trigger :execute do
    source.transfer
  end

  wrap :source do
    def transfer
      self.balance -= amount
      destination.balance += amount
      __getobj__
    end
  end
end
```

That's not much different from the module and it takes care of using `SimpleDelegator` and including `Surrounded` for you. If you want to make changing your approach even easier, you can use the `role` method instead.

```ruby
class MoneyTransfer
  extend Surrounded::Context

  initialize(:source, :destination, :amount)

  trigger :execute do
    source.transfer
  end

  role :source, :wrap do
    def transfer
      self.balance -= amount
      destination.balance += amount
      __getobj__
    end
  end
end
```

This way you can swap between implementations:

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
  role :source do
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