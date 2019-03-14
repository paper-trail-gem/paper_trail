# frozen_string_literal: true

require "memory_profiler"

RSpec::Matchers.define :allocate_less_than do |expected|
  supports_block_expectations

  chain :bytes do
    @scale = :bs
  end

  chain :kilobytes do
    @scale = :kbs
  end

  chain :and_print_report do
    @report = true
  end

  match do |actual|
    @scale ||= :bs

    benchmark = MemoryProfiler.report(ignore_files: /rspec/) { actual.call }

    if @report
      benchmark.pretty_print(detailed_report: true, scale_bytes: true)
    end

    @allocated = benchmark.total_allocated_memsize
    @allocated /= 1024 if @scale == :kbs
    @allocated <= expected
  end

  failure_message do
    "expected that example will allocate less than #{expected}#{@scale},"\
    " but allocated #{@allocated}#{@scale}"
  end
end
