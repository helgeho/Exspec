require_relative "execute_callbacks"

module Exspec
  class Executor
    def initialize(exspec)
      @exspec = exspec
    end

    delegate :puts, :print, :return_spec, :context, :commit, :to => :@exspec
    attr_reader :exspec

    def eval(instruction, &callback_block)
      callbacks = ExecuteCallbacks.new
      Extension.set_execute_callbacks callbacks
      callback_block.call callbacks if block_given?
      instruction.strip!
      eval = true
      val = nil
      if instruction.start_with? COMMAND_PREFIX
        parts = instruction.split " "
        command = parts[0][1..-1]
        param_string = parts[1..-1].join " "
        eval = false
        val = Extension.execute_command self, command, param_string, callbacks
        if val.nil?
          val = case command
                  when ""
                    execute(command, parameters(param_string), callbacks) do
                      exspec.exspec_eval param_string
                    end
                  when "_"
                    execute(command, parameters(param_string), callbacks) do
                      exspec.last_exspec_value
                    end
                  when "redo"
                    execute(command, callbacks) do
                      exspec.redo
                    end
                  when "retry", "rerun", "again"
                    execute(command, callbacks) do
                      exspec.retry
                    end
                  when "save"
                    execute(command, parameters(param_string, COMMENT_SIGN), callbacks) do |params|
                      exspec.save *params
                    end
                  when "include", "call", "include_segment", "call_segment"
                    execute(command, parameters(param_string), callbacks) do |params|
                      exspec.include *params
                    end
                  when "run", "run_spec", "run_segment"
                    execute(command, parameters(param_string), callbacks) do |params|
                      exspec.run *params
                    end
                  when "run_stack"
                    execute(command, parameters(param_string), callbacks) do |params|
                      exspec.run_stack *params
                    end
                  when "load"
                    execute(command, parameters(param_string), callbacks) do |params|
                      exspec.load *params
                    end
                  when "comment", "#"
                    execute(command, parameters(param_string), callbacks) do |params|
                      exspec.comment *params
                    end
                  when "assert"
                    execute(command, parameters(param_string, COMMENT_SIGN), callbacks) do |params|
                      exspec.assert *params
                    end
                  when "expect"
                    execute(command, parameters(param_string, COMMENT_SIGN), callbacks) do |params|
                      exspec.expect *params
                    end
                  when "expect_inspect"
                    execute(command, parameters(param_string, COMMENT_SIGN), callbacks) do |params|
                      exspec.expect_inspect *params
                    end
                  when "skip"
                    raise SkipSignal
                  when "spec", "current_spec"
                    execute(command, callbacks) do
                      exspec.current_spec.full_name
                    end
                  when "description"
                    execute(command, callbacks) do
                      exspec.current_spec.full_description
                    end
                  when "load_current", "reload_current", "discard"
                    execute(command, callbacks) do
                      exspec.load exspec.current_spec
                    end
                  when "load_parent", "up", "independent"
                    execute(command, callbacks) do
                      spec = exspec.current_spec
                      spec = spec.parent unless spec.nil?
                      exspec.load spec
                    end
                  when "load#"
                    execute(command, parameters(param_string), callbacks) do |params|
                      menu_action(params, Spec) { |spec| spec.load }
                    end
                  when "run#", "run_spec#", "run_segment#"
                    execute(command, parameters(param_string), callbacks) do |params|
                      menu_action(params, Spec) { |spec| spec.run }
                    end
                  when "run_stack#"
                    execute(command, parameters(param_string), callbacks) do |params|
                      menu_action(params, Spec) { |spec| spec.run_stack }
                    end
                  when "include#", "include_segment#", "call#", "call_segment#"
                    execute(command, parameters(param_string), callbacks) do |params|
                      menu_action(params, Spec) { |spec| spec.include }
                    end
                  when "ignore", "erase", "delete"
                    execute(command, callbacks) do
                      exspec.erase_last_instruction
                      return_spec exspec.logger.last_value
                    end
                  when "ignore#", "erase#", "delete#"
                    execute(command, parameters(param_string), callbacks) do |params|
                      menu_action(params) do |entry|
                        exspec.logger.entries.delete entry
                      end
                      return_spec exspec.logger.last_value
                    end
                  when "reset", "clear"
                    execute(command, callbacks) do
                      exspec.reset
                    end
                  when "log", "instructions", "history"
                    execute(command, callbacks) do
                      menu(exspec.logger.entries) { |entry| entry[:instruction] }
                    end
                  when "stack"
                    execute(command, callbacks) do
                      menu(exspec.current_spec && exspec.current_spec.stack) do |spec|
                        spec.name
                      end
                    end
                  when "specs", "tests"
                    execute(command, parameters(param_string), callbacks) do |params|
                      menu(exspec.specs *params) { |spec| spec.name }
                    end
                  when "specs#", "tests#"
                    execute(command, parameters(param_string), callbacks) do |params|
                      menu_action(params, Spec) do |spec|
                        menu(spec.children) { |spec| spec.name }
                      end
                    end
                  when "no_log", "without_logging", "silent", "no_history"
                    val = exspec.without_logging { exspec.execute param_string }
                    return_spec exspec.logger.last_value
                    val
                  when "log_off", "disable_log", "history_off", "disable_history"
                    execute(command, callbacks) do
                      exspec.logger.enabled = false
                      exspec.last_value
                    end
                  when "log_on", "enable_log", "history_on", "enable_history"
                    execute(command, callbacks) do
                      exspec.logger.enabled = true
                      return_spec exspec.logger.last_value
                    end
                  else
                    eval = true
                end
        end
      end
      if eval
        val = execute(callbacks) do
          exspec.eval instruction
        end
      end
      val
    end

    private

    def menu(options=nil)
      return @menu || [] unless options.is_a?(Array)
      @menu = options
      puts '====================================='
      @menu.each.with_index do |option, index|
        puts "#{index}. #{block_given? ? yield(option) : option}"
      end
      puts '====================================='
      @menu
    end

    def menu_action(params, type=nil)
      index = params.is_a?(Array) ? params[0] : nil
      return nil if index.nil?
      index = index.to_i
      element = menu[index]
      return element unless type.nil? || element.is_a?(type)
      yield element, index
    end

    def execute(command=nil, params=nil, callbacks, &execute)
      val = nil
      callbacks.before command, params
      begin
        val = execute.call params
      rescue Exception => e
        val = e
        raise
      ensure
        callbacks.after command, params, val
      end
      val
    end

    def parameters(param_string, *separators)
      param_string.strip!
      params = []
      separators.each do |separator|
        parts = " #{param_string}".split separator
        if parts.length > 1
          param = parts[0].strip
          params << (param.empty? ? nil : param)
          param_string = parts[1..-1].join(separator).strip
        end
      end
      params << (param_string.empty? ? nil : param_string)
      params.reverse.drop_while(&:nil?).reverse
    end
  end
end