# frozen_string_literal: true

require "benchmark"
require "objspace"

# A small benchmark helper for scripts in perf/. It reports throughput,
# per-operation time, allocations, and retained heap so a change that makes
# the hot path slower or allocate more is visible.
module Perf

  # The measurements for one scenario.
  class Result
    attr_reader :label, :iterations, :seconds, :allocated_objects,
      :retained_bytes

    def initialize(label, iterations, seconds, allocated_objects,
      retained_bytes)
      @label = label
      @iterations = iterations
      @seconds = seconds
      @allocated_objects = allocated_objects
      @retained_bytes = retained_bytes
    end

    def milliseconds_per_operation
      seconds * 1_000 / iterations
    end

    def operations_per_second
      iterations / seconds
    end

    def allocations_per_operation
      allocated_objects.to_f / iterations
    end

    def retained_bytes_per_operation
      retained_bytes.to_f / iterations
    end
  end

  # Measure a block by running it a number of times.
  #
  # @param [ String ] label The scenario name.
  # @param [ Integer ] iterations The number of measured iterations.
  # @param [ Integer ] warmup The number of unmeasured iterations.
  #
  # @yield The operation to measure.
  #
  # @return [ Result ] The measurements.
  def self.measure(label, iterations, warmup: [iterations / 10, 1].max)
    warmup.times { yield }

    GC.start
    allocations_before = GC.stat(:total_allocated_objects)
    bytes_before = memsize

    seconds = Benchmark.realtime do
      iterations.times { yield }
    end

    allocated_objects = GC.stat(:total_allocated_objects) - allocations_before
    GC.start
    retained_bytes = [memsize - bytes_before, 0].max

    Result.new(label, iterations, seconds, allocated_objects, retained_bytes)
  end

  # Print results as a table.
  #
  # @param [ Array<Result> ] results The results to print.
  # @param [ IO ] io The output stream.
  #
  # @return [ void ]
  def self.report(results, io: $stdout)
    io.puts
    io.puts format(
      "%-32s %10s %12s %10s %12s %14s",
      "scenario", "iterations", "ops/sec", "ms/op", "allocs/op", "retained B/op"
    )
    io.puts "-" * 96
    results.each do |result|
      io.puts format(
        "%-32s %10d %12.1f %10.3f %12.1f %14.1f",
        result.label,
        result.iterations,
        result.operations_per_second,
        result.milliseconds_per_operation,
        result.allocations_per_operation,
        result.retained_bytes_per_operation
      )
    end
    io.puts
  end

  # The size of the Ruby heap. Returns zero when the runtime does not expose
  # ObjectSpace.memsize_of_all.
  #
  # @return [ Integer ]
  def self.memsize
    return 0 unless ObjectSpace.respond_to?(:memsize_of_all)

    ObjectSpace.memsize_of_all
  end
end
