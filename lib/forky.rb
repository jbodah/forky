require 'forky/version'
require 'socket'

module Forky
  module Mixin
    def async
      AsyncProxy.new(self)
    end
  end

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
      sleep 1 until self.resolved?
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
  end

  class Future::ThenProxy
    def initialize(future)
      @future = future
    end

    def method_missing(sym, *args, &block)
      @future.then do |value|
        value.public_send(sym, *args, &block)
      end
    end
  end

  class Worker
    include MonitorMixin

    def initialize
      super
      self.state = :ready
    end

    def run(future = nil, &block)
      future ||= Future.new
      state = :running
      Thread.new do
        value = ForkedProcess.new.run(&block).value
        future.resolve(value)
        state = :ready
      end
      future
    end

    def ready?
      state == :ready
    end

    def state
      synchronize { @state }
    end

    def state=(s)
      synchronize { @state = s }
    end
  end

  # A poor man's set wrapped in thread-safety
  module ThreadSafe
    class Set
      include MonitorMixin

      def initialize(arr = [])
        @set = ::Set.new(arr)
        super()
      end

      def method_missing(sym, *args, &block)
        synchronize { @set.public_send(sym, *args, &block) }
      end
    end
  end

  # Used to limit the number of workers allowed
  class Pool
    def initialize(size: 10)
      @ready_workers = Queue.new
      @commissioned_workers = ThreadSafe::Set.new
      @size = size
      @size.times { add_worker }
      @queue = Queue.new
      start!
    end

    # The main thread loop
    def start!
      # TODO: @jbodah 2016-08-02: put the thread to sleep when there is no more work
      @thread = Thread.new do
        loop { tick }
      end
    end

    def shutdown!
      @thread.kill
    end

    # A single tick of the thread loop
    def tick
      return if @queue.empty?

      worker = @ready_workers.deq

      future, block = @queue.deq
      future.then do
        if @commissioned_workers.include? worker
          @ready_workers.enq worker
        end
      end

      worker.run(future, &block)
    end

    # def size
    #   @size
    # end

    # Modifies the size of the pool
    # def size=(s)
    #   old_size = s
    #   @size = s
    #   difference = @size - old_size
    #   if difference > 0
    #     difference.times { add_worker }
    #   elsif size < 0
    #     difference.abs.times { decommission_worker }
    #   end
    # end

    # Adds a new worker to the pool
    def add_worker
      worker = Worker.new
      @commissioned_workers << worker
      @ready_workers.enq worker
    end

    # Gracefully removes a random worker from the pool
    def decommission_worker
      @commissioned_workers.delete(@commissioned_workers.first)
    end

    # Interface for adding work to the pool
    def run(&block)
      future = Future.new
      work = [future, block]
      @queue.enq work
      future
    end
  end

  # A one-time use abstraction around a forked process which
  # encapsulates IPC and status
  class ForkedProcess
    module IPC
      class UNIXSocket
        def initialize
          @serializer = -> (n) { Marshal.dump(n) }
          @deserializer = -> (n) { Marshal.load(n) }
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
