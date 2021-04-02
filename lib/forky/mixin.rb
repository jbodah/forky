module Forky
  module Mixin
    def async
      AsyncProxy.new(self)
    end
  end
end
