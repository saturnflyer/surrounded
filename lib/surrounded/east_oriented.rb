module Surrounded
  module EastOriented
    # Always return the context object to ensure that a context may
    # not be asked for information.
    def trigger_return_content(name)
      %{
        self.send("__trigger_#{name}")
        
        self
      }
    end
  end
end