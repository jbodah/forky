require_relative '../spec_helper'

RSpec.describe 'integration' do
  it do
    ## A cheap integration test until I can write real tests

    # IPC
    # forked = Forky.fork do |f|
    #   f.send_msg('hello!')
    #   msg = f.recv_msg
    #   puts msg
    # end
    # msg = forked.recv_msg
    # puts msg
    # forked.send_msg('world!')

    # fork/join
    10.times.map do |n|
      Forky.fork do |f|
        puts "sleeping for 1"
        sleep 1
      end
    end.map(&:join)

    # pool
    pool = Forky::Pool.new(size: 10)
    20.times.map do |n|
      pool.run do
        sleep 1
        puts n
      end
    end.map(&:join)
    pool.shutdown!

    # mixin
    Integer.class_eval do
      include Forky::Mixin

      def add_one
        sleep 1
        puts self
        self + 1
      end
    end
    (0..20).to_a.map(&:async).map(&:add_one).map(&:then).map(&:add_one).map(&:join)

    # test global pool and value
    final = 10.times.map { |n| Forky.global_pool.run { sleep 1; n + 1 } }.map(&:value)
    puts final.join(', ')
  end
end
