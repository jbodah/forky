# Forky

a library for simple distributed tasks

## Installation

```
gem install forky
```

## Quick-start

Below are some quick real-life examples of how to use `Forky`:

```rb
# Parse log files in parallel
Dir.glob('log_*').map { |filename| Forky.global_pool.run { LogParser.parse(filename) }}.map(&:value)
```

## Description

See `test/integration_test.rb` for usage examples.

`Forky::ForkedProcess` is a wrapper around `fork`. In addition to raw forking it provides
an IPC mechanism, object serialization, and a consistent interface similar to that of `Thread`.

`Forky::Worker` can be used to encapsulate a `Forky::ForkedProcess`.
`Forky::Worker` however is meant to be long-lived and spawn many processes.
It wraps forked processes in an MRI thread which keeps track of the process status
and relates that to the application. The `#run` method will also create a `Forky::Future`
which can be used to trigger functionality once the process completes.
You can also optionally pass a `Forky::Future` to `#run` to have it use that future instead.

`Forky::Pool` manages a set of workers. It's primarily responsible for receiving and queuing
work as it comes in and dispatching work to the workers. It does this by keeping track of which
workers are ready for work and which are busy. The `#run` method is the main API for interacting
with the pool. It runs an MRI thread which loops and makes sure
that the state is being properly updated. `Forky.global_pool` implements a global pool for convenience.
It's primary purpose is for ad-hoc scripting so that you can quickly run some asynchronous tasks.

`Forky::Future` is our promise-style API. It represents some async operation that will
eventually return a value. You can wait for the value via `#join` or `#value`.
The `#then` method can be called to add callbacks.
If given a block then it will assign the block as the callback.
Without any arguments it will return a proxy which can be used to chain off a method.
This can be useful for chaining with `#map`.

`Forky::Mixin` allows you to mix in the `async` method into your objects.
This method will return a proxy that will execute the chained command in forked
workers from the global pool.
Like other asynchronous methods, the proxy will return a `Forky::Future` which
you can wait for by calling `#join` or `#value`
