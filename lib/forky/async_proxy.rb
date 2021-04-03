# frozen_string_literal: true

module Forky
  class AsyncProxy
    def initialize(obj)
      @obj = obj
    end

    def method_missing(sym, *args, &block)
      Forky.global_pool.run do
        @obj.public_send(sym, *args, &block)
      end
    end
  end
end
