module Surrounded
  module Shortcuts
    private

    def define_shortcut(name)
      # if keyword initialize
      if instance_method(:initialize).parameters.dig(0, 0) == :keyreq
        singleton_class.send(:define_method, name) do |**args|
          instance = new(**args)

          instance.public_send(name)
        end
      else # non-keyword initialize
        singleton_class.send(:define_method, name) do |*args|
          instance = new(*args)

          instance.public_send(name)
        end
      end
    end

    def store_trigger(*names)
      names.each do |name|
        define_shortcut(name)
      end
      super
    end
  end
end
