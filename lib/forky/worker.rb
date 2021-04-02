require 'concurrent/set'

module Forky
  class Worker
    include MonitorMixin

    def initialize
      super
      self.state = :ready
    end

    def run(future = nil, &block)
      future ||= Future.new
      self.state = :running
      Thread.new do
        value = ForkedProcess.new.run(&block).value
        future.resolve(value)
        self.state = :ready
      end
      future
    end

    def ready?
      state == :ready
    end

    def state
      synchronize { @state }
    end

    def state=(value)
      synchronize { @state = value }
    end
  end
end
