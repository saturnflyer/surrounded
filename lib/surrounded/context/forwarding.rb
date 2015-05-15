module Surrounded
  module Context
    module Forwarding
      def forward_trigger(receiver, message, alternate=message)
        raise(ArgumentError, %{you may not forward '%{m}`} % {m: message}) if ['__id__','__send__'].include?(message.to_s)
        trigger alternate do |*args, &block|
          self.send(receiver).public_send(message,*args, &block)
        end
      end
      
      def forward_triggers(receiver, *messages)
        messages.each do |message|
          forward_trigger(receiver, message)
        end
      end
      
      def forwarding(hash)
        hash.each { |messages, receiver|
          forward_triggers(receiver, *messages)
        }
      end
      
      alias forward forward_trigger
      alias forwards forward_triggers
    end
  end
end