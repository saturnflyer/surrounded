module Surrounded
  module Shortcuts
    private
    
    def shortcut(*names)
      names.each do |name|
        define_shortcut(name)
      end
    end
    
    def define_shortcut(name)
      singleton_class.send(:define_method, name) do |*args|
        instance = self.new(*args)
        instance.public_send(name)
      end
    end
    
    def store_trigger(*names)
      names.each do |name|
        define_shortcut(name)
      end
      @triggers.merge(names)
    end
  end
end