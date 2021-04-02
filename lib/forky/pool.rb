module Forky

  # Used to limit the number of workers allowed
  class Pool
    def initialize(size: 10)
      @ready_workers = Queue.new
      @commissioned_workers = Concurrent::Set.new
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
end
