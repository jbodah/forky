# frozen_string_literal: true

require 'socket'

module Forky
  # A one-time use abstraction around a forked process which
  # encapsulates IPC and status
  class ForkedProcess
    module IPC
      class UNIXSocket
        def initialize
          @serializer = ->(n) { Marshal.dump(n) }
          @deserializer = ->(n) { Marshal.load(n) }
          @parent, @child = ::UNIXSocket.pair
        end

        def send_to_parent(value)
          serialized = @serializer.call(value)
          @child.send(serialized, 0)
        end

        def receive_from_child
          # TODO: @jbodah 2016-08-02: optimize this
          received = @parent.recv(100_000_000)
          @deserializer.call(received)
        end
      end
    end

    def initialize
      @ipc = IPC::UNIXSocket.new
    end

    def run(&block)
      @pid = fork do
        value = block.call
        @ipc.send_to_parent(value)
      end
      self
    end

    def done?
      raise
    end

    def join
      Process.wait @pid
      self
    end

    def value
      join
      @ipc.receive_from_child
    end
  end

  def self.fork(&block)
    ForkedProcess.new.run(&block)
  end

  def self.global_pool
    @pool ||= Pool.new
  end
end
