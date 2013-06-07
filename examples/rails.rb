# Here's an example of how you might use this in rails.

# First, be guarded against changes in third-party libraries
module Awareness
  include Surrounded
  include Casting::Client
  delegate_missing_methods
end

class User
  include Awareness
end

class ApplicationController
  include Awareness
end

class SomeUseCase
  extend Surrounded::Context

  setup(:user, :other_user, :listener)

  trigger :do_something do
    user.something
  end

  module User
    def something
      puts "Hello, #{other_user}"
      listener.redirect_to('/')
    end
  end
end

class SomethingController < ApplicationController
  def create
    SomeUseCase.new(current_user, User.last, self).do_something
  end
end