module Exspec
  class SpecRunner
    def initialize(exspec)
      @exspec = exspec
      @break_on_skip_signal = false
    end

    delegate :reporter, :commit, :without_logging, :to => :@exspec

    attr_accessor :break_on_skip_signal

    def run(specs)
      return run_specs specs if specs.is_a? Enumerable
      spec = @exspec.spec(specs)
      val = nil
      reporter.start_spec spec
      spec.for_instructions do |instruction, index, line|
        reporter.execute_instruction instruction, index, line
        begin
          val = without_logging { @exspec.execute instruction }
          commit instruction, val
        rescue SkipSignal
          reporter.skip_signal break_on_skip_signal
          break if break_on_skip_signal
        rescue Exception => e
          reporter.exception e
          commit instruction, e
        ensure
          reporter.executed_instruction instruction, index, line
        end
      end
      val
    ensure
      reporter.finish_spec spec
    end

    def run_stack(spec)
      spec = @exspec.spec(spec)
      reporter.start_stack spec
      spec.stack.each do |spec|
        begin
          Extension.test_hook(:before, spec)
          run spec
        rescue
          break
        ensure
          Extension.test_hook(:after, spec)
        end
      end
    ensure
      reporter.finish_stack spec
    end

    def run_specs(specs)
      specs.each do |spec|
        @exspec.reset
        Extension.test_hook(:before_stack, spec)
        run_stack(spec)
        Extension.test_hook(:after_stack, spec)
      end
    end
  end
end