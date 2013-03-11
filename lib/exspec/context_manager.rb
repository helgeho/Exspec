module Exspec
  class ContextManager
    def initialize(exspec)
      @exspec = exspec
      @global_context = context
      setup_global_context
      setup_exspec_context
      start_new_context
    end

    attr_reader :exspec, :last_value
    attr_accessor :last_exspec_value

    def start_new_context
      context = global_eval "lambda { binding }.call"
      self.context = context
      Extension.setup_context self
      context
    end

    def context
      @binding ||= Object.new.instance_eval "binding"
    end

    def context=(value)
      @binding = value
    end

    def last_value=(value)
      @last_value=value
      global_eval "_ = exspec.last_value"
      value
    end

    def last_exspec_value
      @last_exspec_value
    end

    def last_exspec_value=(value)
      @last_exspec_value = value
      exspec_eval "_ = exspec.last_exspec_value"
    end

    def eval(statement)
      self.last_value = raw_eval statement
    end

    def raw_eval(statement)
      context.eval statement
    end

    def global_eval(statement)
      @global_context.eval statement
    end

    def exspec_eval(statement)
      @exspec_context.eval statement
    end

    private

    def setup_global_context
      global_instance = global_eval "self"
      global_instance.instance_variable_set :@exspec, @exspec
      global_instance.class.send :attr_reader, :exspec
      global_eval "_ = nil"
      Extension.setup_global_context self, global_instance
    end

    def setup_exspec_context
      @exspec_context = global_eval "lambda { |_| binding }.call nil"
      Extension.setup_exspec_context self
    end
  end
end