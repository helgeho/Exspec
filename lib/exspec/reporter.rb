module Exspec
  class Reporter
    def start_stack(spec); end
    def finish_stack(spec); end
    def start_spec(spec); end
    def finish_spec(spec); end
    def execute_instruction(instruction, index, line); end
    def executed_instruction(instruction, index, line); end
    def exception(exception); end
    def skip_signal(breaking); end
    def show_comment(text); end

    def puts(text)
      Kernel.puts text
    end

    def print(text)
      Kernel.print text
    end

    def spec_failed(message)
      puts message
    end

    def spec_succeeded(message)
      puts message
    end
  end
end