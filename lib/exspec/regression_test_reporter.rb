module Exspec
  class RegressionTestReporter < Reporter
    SpecFailedError = Class.new(StandardError)

    def initialize
      @indent = 0
      @specs = []
      @failed = []
      super
    end

    alias_method :_puts, :puts
    alias_method :_print, :print

    attr_reader :specs, :failed

    def indent
      " " * (@indent * 4)
    end

    def puts(text); end
    def print(text); end

    def puts_indented(text)
      _puts "" if !@on_new_line
      _puts indent + text
      @on_new_line = true
      $stdout.flush
    end

    def print_indented(text)
      _print indent if @on_new_line
      _print text
      @on_new_line = false
      $stdout.flush
    end

    def start_stack(spec)
      puts_indented "Start spec stack #{spec.full_name}"
      @indent += 1
    end

    def finish_stack(spec)
      @indent -= 1
      puts_indented "Finished spec stack #{spec.full_name}"
      puts_indented "---------------------------------" if @indent == 0
    end

    def start_spec(spec)
      @spec = spec
      @specs << spec unless @specs.include?(spec)
      puts_indented "Start test #{spec.full_name}"
      @indent += 1
    end

    def finish_spec(spec)
      @indent -= 1
      puts_indented "Finished test #{spec.full_name}"
    end

    def execute_instruction(instruction, index, line)
      @line = line
      @instruction = instruction
      print_indented "."
    end

    def skip_signal(breaking)
      raise SkipSignal
    end

    def spec_failed(message)
      failed << @spec unless failed.include?(@spec)
      puts_indented "==> #{message}"
      _print "XXXX"
      puts_indented "(line: #{@line}, instruction: \"#{@instruction}\")"
      raise SpecFailedError.new message
    end

    def spec_succeeded(message)
      puts_indented "==> #{message}"
    end

    def exception(exception)
      raise exception if exception.is_a? SpecFailedError
    end

    def show_comment(text)
      puts_indented("#" + text)
    end
  end
end