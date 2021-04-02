# frozen_string_literal: true

module Forky
  class Future
    include MonitorMixin

    def initialize
      super
      self.resolved = false
      @thens = []
    end

    def resolve(value)
      @resolved_value = value
      @thens.each do |then_|
        then_.call(value)
      end
      self.resolved = true
    end

    def join
      sleep 1 until resolved?
      self
    end

    def value
      join
      @resolved_value
    end

    def then(&block)
      if block
        synchronize do
          if resolved?
            block.call(@resolved_value)
          else
            @thens << block
          end
        end
        self
      else
        Future::ThenProxy.new(self)
      end
    end

    def resolved?
      synchronize { @resolved }
    end

    def resolved=(r)
      synchronize { @resolved = r }
    end

    class ThenProxy
      def initialize(future)
        @future = future
      end

      def method_missing(sym, *args, &block)
        @future.then do |value|
          value.public_send(sym, *args, &block)
        end
      end
    end
  end
end
