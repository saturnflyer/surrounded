# Here's an example of how you might use this in rails.

# First, be guarded against changes in third-party libraries
module Awareness
  def self.included(base)
    base.class_eval {
      include Surrounded
      include Casting::Client
      delegate_missing_methods
    }
  end
end

class User
  include Awareness
end

class ApplicationController
  include Awareness
end

class SomeUseCase
  extend Surrounded::Context

  initialize(:admin, :other_user, :listener)

  trigger :do_something do
    admin.something
  end

  module Admin
    def something
      puts "Hello, #{other_user}"
      listener.redirect_to('/')
    end
  end
end

class SomethingController < ApplicationController
  def create
    surround(current_user, User.last).do_something
  end

  def surround(admin, other)
    SomeUseCase.new(admin, other, self)
  end
end