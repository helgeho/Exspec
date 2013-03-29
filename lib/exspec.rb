require "active_support/core_ext"

require_relative "exspec/context_manager"
require_relative "exspec/executor"
require_relative "exspec/spec_manager"
require_relative "exspec/logger"
require_relative "exspec/spec_runner"
require_relative "exspec/reporter"
require_relative "exspec/regression_test_reporter"
require_relative "exspec/helpers/helpers"
require_relative "exspec/extensions/extension"
require_relative "exspec/extensions/mocking"
require_relative "exspec/extensions/rails"
require_relative "exspec/extensions/capybara"
parent_dirs do |parent_dir|
  configured = false
  ["exspec.rb", "config/exspec.rb", "exspec/config.rb", "exspec/exspec.rb"].each do |file|
    file = File.expand_path file, parent_dir
    require file and configured = true and break if File.file?(file)
  end
  break if configured
end

module Exspec
  def self.config
    config = {
      :test_dir => "test/exspec",
      :command_prefix => "!",
      :comment_sign => "!# ",
      :spec_separator => ".",
      :spec_extension => ".rb",
      :regression_test_reporter => RegressionTestReporter
    }
    Extension.config config
    @@config = config
  end

  TEST_DIR = File.expand_path(config[:test_dir])
  COMMAND_PREFIX = config[:command_prefix]
  COMMENT_SIGN = config[:comment_sign]
  SPEC_SEPARATOR = config[:spec_separator]
  SPEC_EXTENSION = config[:spec_extension]
  REGRESSION_TEST_REPORTER = config[:regression_test_reporter]

  SkipSignal = Class.new(StandardError)

  class Exspec
    def initialize(components={})
      Extension.initialize_exspec self, components
      @context_manager = components[:context_manager] || ContextManager.new(self)
      @executor = components[:executor] || Executor.new(self)
      @spec_manager = components[:spec_manager] || SpecManager.new(self)
      @logger = components[:logger] || Logger.new
      @runner = components[:runner] || SpecRunner.new(self)
      @reporter = components[:reporter] || Reporter.new
      @execute_stack = []
      Extension.initialized_exspec self
    end

    delegate :without_logging, :last_instruction, :erase_last_instruction, :log, :to => :@logger
    delegate :eval, :raw_eval, :exspec_eval, :last_value, :last_value=, :last_exspec_value, :to => :@context_manager
    delegate :spec, :specs, :current_spec, :to => :@spec_manager
    delegate :spec_failed, :spec_succeeded, :puts, :print, :show_comment, :to => :@reporter
    delegate :run, :run_specs, :run_stack, :to => :@runner

    attr_reader :logger, :context_manager, :reporter, :spec_manager, :runner, :executor
    alias_method :context, :context_manager

    def module
      ::Exspec
    end

    def execute(instruction)
      @execute_stack << false
      executor.eval instruction do |callbacks|
        callbacks.after do |command, params, value|
          context.last_exspec_value = value
          if command.nil?
            commit instruction, value
          end
          if @execute_stack.length == 1 && (last_exspec_value != last_value || command == "_" || command == "")
            puts "#{COMMAND_PREFIX}_: #{last_exspec_value.inspect}"
          end
        end
      end
      @execute_stack.pop
    end

    def report_to(reporter=reporter)
      reporter = reporter.new if reporter.is_a? Class
      reporter_backup = @reporter
      @reporter = reporter
      if block_given?
        begin
          yield if block_given?
        ensure
          @reporter = reporter_backup if block_given?
        end
      end
    end

    def save(description, comment=nil)
      comment(comment) unless comment.nil?
      spec = spec_manager.save logger, description
      Extension.test_hook(:after, spec)
      Extension.test_hook(:before, nil)
      spec
    end

    def load(description)
      Extension.test_hook(:after, nil)
      Extension.test_hook(:after_stack, nil)
      reset
      spec = spec(description)
      Extension.test_hook(:before_stack, nil)
      unless spec.nil?
        without_logging { runner.run_stack spec }
        spec_manager.current_spec = spec
      end
      Extension.test_hook(:before, nil)
      spec
    end

    def include(description)
      spec = spec(description)
      without_logging do
        run spec
      end
      commit "#{COMMAND_PREFIX}include #{spec.full_name}"
    end

    def retry
      instructions = logger.instructions
      load current_spec
      Extension.test_hook(:before, nil)
      instructions.each do |instruction|
        execute instruction rescue nil
      end
      last_value
    end

    def reset
      context_manager.start_new_context
      logger.clear
      spec_manager.current_spec = nil
      return_spec nil
    end

    def comment(text)
      show_comment text
      commit "#{COMMAND_PREFIX}comment #{text}", last_value
    end

    def redo
      last = last_instruction
      return nil if last.nil?
      execute last
    end

    def assert(statement=nil, comment=nil)
      begin
        val = without_logging { raw_eval statement }
        if val
          spec_succeeded "Successful: #{comment || statement}"
        else
          spec_failed "Failed: #{comment || statement}"
        end
      rescue Exception => e
        val = e
        spec_failed "Failed due to an exception: #{comment || statement} (#{e})"
      end
      commit "#{COMMAND_PREFIX}assert #{statement.strip}" + (comment ? " #{COMMENT_SIGN}#{comment}" : "")
      val
    end

    def expect(statement=nil, comment=nil)
      return expect_inspect nil, comment if statement.nil?
      actual = last_value
      expect = value_or_exception { without_logging { raw_eval statement } }
      if expect == actual
        spec_succeeded "Successful: #{comment || "value is #{prepare_output(expect)}"}"
      else
        spec_failed "Failed: #{comment || "expected #{prepare_output(expect)}"}, but got #{prepare_output(actual)}"
      end
      commit "#{COMMAND_PREFIX}expect #{statement.strip}" + (comment ? " #{COMMENT_SIGN}#{comment}" : ""), expect
    end

    def expect_inspect(expect=nil, comment=nil)
      actual = inspect_last_value
      expect = actual if expect.nil?
      successful = actual.to_s == expect.to_s
      if successful
        spec_succeeded "Successful: #{comment || "inspecting last value has yielded #{prepare_output(actual)}"}"
      else
        actual_pos = 0
        successful = true
        expect.each_char do |char|
          successful = false
          for actual_pos in actual_pos..actual.length
            successful = (actual[actual_pos] == char)
            break if successful
          end
          break if actual_pos == actual.length
        end
        spec_succeeded "Successful (fuzzy): #{comment || "inspecting last value has yielded #{prepare_output(actual)}"}" if successful
      end
      unless successful
        spec_failed "Failed: #{comment || "expected inspecting last value to yield #{prepare_output(expect)}, but was #{prepare_output(actual)}"}"
      end
      commit "#{COMMAND_PREFIX}expect_inspect #{expect}" + (comment ? " #{COMMENT_SIGN}#{comment}" : "")
      actual
    end

    def inspect_last_value
      last_value.is_a?(String) ? last_value : last_value.inspect
    end

    def commited?
      @execute_stack.last
    end

    def commit(instruction, value=last_value)
      @execute_stack[@execute_stack.length - 1] = true unless @execute_stack.empty?
      logger.log instruction, value
      return_spec value
    end

    def return_spec(value)
      self.last_value = value
    end

    def prepare_output(value)
      return "nil" if value.nil?
      return "\"#{value}\"" if value.is_a? String
      value
    end

    def value_or_exception
      begin
        val = yield
      rescue Exception => e
        val = e
      end
      val
    end
  end
end

require_relative "exspec/irb/irb_exspec"

Exspec::Extension.loaded