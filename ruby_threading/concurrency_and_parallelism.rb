#!/usr/bin/env ruby -wKU
# experiments/ruby_threading/concurrency_and_parallelism.rb
#
#
# See: https://www.visuality.pl/posts/concurrency-and-parallelism-in-ruby-processes-threads-fibers-and-ractors
#

require 'benchmark'
require 'digest'

=begin

Concurrency and parallelism in Ruby (Processes, Threads, Fibers and Ractors)
Jan Grela
Software engineer
03 Apr 23

Concurrency and parallelism in Ruby (Processes, Threads, Fibers, and Ractors)

How to achieve concurrency and parallelism in Ruby? There are a couple of 
ways and I will describe these in the following article. It only covers the 
usage of Ruby core and standard library modules.

Modern CPUs consist of multiple cores, so software developers can benefit. 
Nowadays programming languages with concurrency features support the usage of 
multi-cores. Ruby is no exception, let's see how this it could be done.

Concurrency vs parallelism
==========================

When something is executed concurrently it doesn’t necessarily mean that it 
is parallel. Concurrent tasks are started, executed, and finished at different 
(sometimes overlapping) periods of time, switching execution context from one 
to another, whereas parallel tasks are literally running at the same time on 
multiple cores.

Prerequisites
=============

For the purpose of benchmarking, we will use some demanding calculations 
function:

=end

def factorial(n)
  n == 0 ? 1 : n * factorial(n - 1)
end

# And blocking operations function, which is using the sleep method to 
simulate a long operation:

def digest(word)
  sleep 1
  Digest::SHA256.hexdigest word
end

puts <<~TEXT

Processes
=========

TEXT

=begin

Probably the easiest way to run concurrent tasks is to use the Kernel 
module method fork. It runs a given block in the subprocess.

Let's write a simple benchmark using the calculation function.

=end

Benchmark.bmbm(10) do |x|
  x.report('sequential:') do
    4.times do
      1000.times { factorial(1000) }
    end
  end

  x.report('processes:') do
    pids = []
    4.times do
      pids << fork do
        1000.times { factorial(1000) }
      end
    end
    # wait for child procceses to exit
    pids.each { |pid| Process.wait(pid) }
  end
end

=begin
                  user     system      total        real
sequential:   1.439956   0.005165   1.445121 (  1.445128)
processes:    0.000758   0.007042   1.683600 (  0.428644)

It shows clearly that running the same task in subprocesses reduces 
calculation time. These are in fact executed in parallel.

Using processes looks easy, but there are drawbacks. Memory usage is high, 
as the new process needs its own memory allocation, creating and switching 
process context is more expensive, and communication is more complex.

=end

puts <<~TEXT

Threads
=======

TEXT

=begin

Another option for concurrency in Ruby is multithreading. Compared to using 
multiple processes, threads are lightweight, and use less memory (threads in 
the same process share memory), because of that switching thread context is 
faster. A drawback of shared memory is that threads’ communication is more 
complex and thread safety (making sure that implementation allows only one 
thread at a time to access shared data) has to be considered.

In Ruby new thread could be created with the Thread class by giving an 
execution block to a new method - Thread.new { run }.

In MRI (CRuby) implementation, the Global Interpreter Lock (GIL) is used, 
which synchronizes the execution of threads, so that only one thread in a 
process runs at a time. It is a thread-safety, mutual-exclusion mechanism, 
but prevents the Ruby programs to run in parallel. To support real parallelism 
in Ruby, other implementations of interpreters (like JRuby) may be used or use 
Ractor (more about that later in the article).

Let's illustrate threads’ behavior with the same benchmark as above.

=end

Benchmark.bm do |x|
  x.report('sequential:') do
    4.times do
      1000.times { factorial(1000) }
    end
  end

  x.report('threads:') do
    threads = []
    4.times do
      threads << Thread.new do
        1000.times { factorial(1000) }
      end
    end
    # wait for all thread to finish using join method
    threads.each(&:join)
  end
end

=begin

                  user     system      total        real
sequential:   1.441784   0.006109   1.447893 (  1.447912)
threads:      1.468147   0.008806   1.476953 (  1.476755)

It proves that because of the GIL, execution time is similar.

Are Ruby threads good for anything then? Yes, for blocking operations (like 
sleep, IO). Another thread could be executed (acquires lock) while the other 
is waiting for results (releases lock).

The following example uses a blocking function. Execution time shows that the 
thread context is changed while the other waits for the HTTP call result.

=end

animals = ['fox', 'rat', 'bat', 'owl']

Benchmark.bm do |x|
  x.report('sequential:') do
    animals.each do |word|
      digest(word)
    end
  end

  x.report('threads:') do
    threads = []
    animals.each do |word|
      threads << Thread.new do
        digest(word)
      end
    end
    threads.each(&:join)
  end
end

=begin

                                user     system      total        real
sequential:                 0.001875   0.000387   0.002262 (  4.004000)
threads:                    0.000559   0.000710   0.001269 (  1.005732)

=end

puts <<~TEXT

Mutual-exclusion
================

TEXT

=begin

As mentioned before, threads share a memory, so these can access and modify 
the state of the same objects. This could lead to race conditions - when 
threads operation on shared data interrupts each other. This matter is very 
important to consider when implementing multithreaded applications. Ruby has 
Thread::Mutex class, which is a mean to lock access to shared data.

A simple example shows that instead of the expected 15, might calculate to 25. 
This is because all threads have access to a and increment it before summing. 
Having that operation in mutex.synchronize {} block, ensures only one thread 
can run it at a time, so a and sum will be calculated sequentially.

=end

a = 0
sum = 0
calculate_sum = -> do
  a += 1
  sleep rand
  sum += a
end

threads = []
5.times do
  threads << Thread.new do
    calculate_sum.call
  end
end
threads.each(&:join)
puts "calculation without mutex - sum #{sum}"

mutex = Thread::Mutex.new
a = 0
sum = 0

5.times do
  threads << Thread.new do
    mutex.synchronize(&calculate_sum)
  end
end
threads.each(&:join)
puts "calculation with mutex - sum #{sum}"

=begin

calculation without mutex - sum 25
calculation with mutex - sum 15

=end

puts <<~TEXT

Tasks queue in Thread Pool
==========================

TEXT

=begin


Threads are easy to create and start executing, but when our application 
grows and needs to be scaled, creating a new thread for a new task might 
end up exceeding resources. To avoid that, mechanism that limits the number 
of threads running tasks could be implemented.

One possibility is a thread pool, a limited amount of threads running in a 
loop. Task data is not bounded to a specific thread. Instead of creating a 
new thread, a task with its data is enqueued for processing, then any free 
thread in a thread pool can take task data and process it.

Ruby provides a class that could be used to synchronize task execution. 
Thread::Queue - it’s a thread-safe (locks when push/pop) FIFO queue. A 
thread calls pop on a queue, which takes data and processes it or is 
suspended and waits when a queue is empty. There is also Thread::SizedQueue, 
which has one addition compared to Queue - which limits the number of objects 
in it, when the thread pushes on full queue it’s suspended.

In the general limiting the number of threads and objects in a queue saves 
resources (CPU time and memory). Thread pool and queue size have to be decided 
and can be different for every application to reach optimal performance.

The next example shows a simple implementation of a consumer and 5 producers 
(pool of 5 threads). The producer generates a random number and enqueues it. 
Consumers take a generated number, calculate the factorial, and rest.

# =end

begin
  job_queue = SizedQueue.new(3)

  producer = Thread.new do
    # In the article this is an endless loop
    counter = 0
    while counter <= 10 do
      number = rand(10)
      job_queue.push(number)
      puts "pushed #{number} to the queue"
      # sleep 1
      counter += 1
    end
  end

  consumers = []
  5.times do |i|
    consumers << Thread.new do
      loop do
        number = job_queue.pop
        puts "consumer #{i} - factorial of #{number} is #{factorial(number)}"
        sleep(rand)
      end
    end
  end

  producer.join
  consumers.each(&:join)

rescue => e
  puts "ERROR: #{e}"
end

=begin

pushed 3 to the queue
pushed 9 to the queue
pushed 2 to the queue
consumer 0 - factorial of 3 is 6
pushed 4 to the queue
consumer 2 - factorial of 9 is 362880
pushed 8 to the queue
consumer 1 - factorial of 2 is 2
consumer 3 - factorial of 4 is 24
...


=end

puts <<~TEXT

Fibers
======

TEXT

=begin

Another Ruby mechanism to achieve concurrency is fibers - these run code 
from a given block. Fibers are similar to Threads. The main difference is 
that it is up to the programmer when to start, pause and resume fibers, 
while threads are controlled by the operating system. This makes fibers 
lightweight and more efficient when it comes to context switching. Also, 
a thread can have many fibers.

Fibers are created with block Fiber.new { run someting; Fiber.yield; run 
again }, started with resume, paused with Fiber.yield (which moves control 
to where fiber was resumed), to resume from the point when it was paused, 
and call resume again. Another way is the transfer method. It gives control 
to chosen fiber, which then gives it back to another fiber.

In this example, we can observe the behavior of switching control.

=end

fib2 = nil

fib = Fiber.new do
  puts "1 - fib started"
  fib2.transfer
  Fiber.yield
  puts "4 - fib resumed"
end

fib2 = Fiber.new do
  puts "2 - control moved to fib2"
  fib.transfer
end

fib.resume
puts "3 - fib paused execution"
fib.resume

=begin

1 - fib started
2 - control moved to fib2
3 - fib paused execution
4 - fib resumed


=end

puts <<~TEXT

Fibers scheduler
================

TEXT

=begin

Ruby 3.0 introduced the non-blocking fibers concept. Fibers are created 
by default with blocking: false option. To use that feature, the scheduler 
has to be set with Fiber.set_scheduler(CustomScheduler.new). There is no 
Fiber::Scheduler class, it only describes the implementation interface for 
the scheduler. It should implement hooks for blocking operations (like IO, 
sleep, DB queries), which call Fiber.yield to pause fiber. Fiber is resumed 
by the scheduler when the blocking operation is ready. The scheduler closes 
at the end of the current thread. Additionally Fiber.schedule runs the given 
block in a non-blocking manner.

One thread can have many fibers, executing smaller tasks. Fibers, similar to 
threads, can benefit from Mutex, Queue, and SizedQueue when used in a 
non-blocking context.

This is how fibers work with and without a scheduler. For purpose of testing, 
we are going to use scheduler implementation from the async gem.

=end

require 'async'

animals = ['fox', 'rat', 'bat', 'owl']

Benchmark.bm do |x|
   x.report('sequential:') do
    animals.each do |word|
       digest(word)
    end
  end

  x.report('fibers without scheduler:') do
    fibers = []
    animals.each do |word|
      fibers << Fiber.new do
        digest(word)
      end
    end
    fibers.each(&:resume)
  end

  x.report('fibers with scheduler:') do
    Thread.new do
      Fiber.set_scheduler(Async::Scheduler.new)
      animals.each do |word|
        Fiber.schedule do
          digest(word)
        end
      end
    end.join
  end
end

=begin

                                user     system      total        real
sequential:                 0.001794   0.000443   0.002237 (  4.004614)
fibers without scheduler:   0.000816   0.000188   0.001004 (  4.003279)
fibers with scheduler:      0.002658   0.001208   0.003866 (  1.006556)

=end

puts <<~TEXT

Ractors
=======

TEXT

=begin

It is an experimental feature in Ruby 3.0 - Actor-model pattern 
implementation. You even got a warning when using it Ractor is 
experimental, and the behavior may change in future versions of 
Ruby! Also there are many implementation issues.

Ractor takes advantage of the Global Interpreter Lock (GIL), as 
every ractor has its own lock, so given blocks can be executed 
parallelly. Ractors do not share data, so it is thread-safe. It 
uses a messaging system to send and receive objects’ states.

=end

Benchmark.bm do |x|
  x.report('sequential:') do
    4.times do
      1000.times { factorial(1000) }
    end
  end

  x.report('ractors:') do
    ractors = []
    4.times do
      ractors << Ractor.new do
        1000.times { factorial(1000) }
      end
    end
    # take response from ractor, so it will actually execute
    ractors.each(&:take)
  end
end

=begin

                  user     system      total        real
sequential:   1.431720   0.005095   1.436815 (  1.437175)
ractors:      2.226264   0.044831   2.271095 (  0.848970)


=end

puts <<~TEXT

Summary
=======

Although Ruby isn't the fastest and the best language to utilize 
the multithreaded capabilities of CPUs, it is possible to write 
programs that use it. Many gems implement concurrency and parallelism, 
but it is good to know how this could be done in pure Ruby, so a custom 
solution might fit to solve some performance and scalability problems. 
With the Ruby 3 release, language gains new features, which improve 
concurrency and even parallelism.

TEXT