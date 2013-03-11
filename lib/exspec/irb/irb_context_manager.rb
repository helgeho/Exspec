require_relative "../context_manager"

module Exspec
  class IrbContextManager < ContextManager
    delegate :irb_workspace, :irb_context, :to => :exspec

    def context
      irb_workspace.binding
    end

    def context=(value)
      irb_workspace.instance_variable_set(:@binding, value)
    end

    def last_output
      irb_context.inspect_last_value
    end

    def last_value
      irb_context.last_value
    end

    def last_value=(value)
      irb_context.set_last_value(value)
    end

    def define_eval(&eval)
      @eval = eval
    end

    def eval(instruction)
      @eval.call instruction
    end
  end
end