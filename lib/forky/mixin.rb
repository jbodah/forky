# frozen_string_literal: true

module Forky
  module Mixin
    def async
      AsyncProxy.new(self)
    end
  end
end
