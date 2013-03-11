require "irb"
require_relative "irb_exspec"

require 'io/console'

module IRB
  class Context
    alias_method :_initialize, :initialize
    alias_method :_evaluate, :evaluate

    def initialize(irb, workspace = nil, input_method = nil, output_method = nil)
      _initialize(irb, workspace, input_method, output_method)
      @exspec = Exspec::IrbExspec.new self, @workspace
    end

    def evaluate(line, line_no)
      @exspec.irb_execute line do |instruction|
        _evaluate instruction, line_no
      end
    end

    def inspect
      "#<#{self.class.name}>"
    end
  end

  class ReadlineInputMethod
    def history
      HISTORY.collect.to_a
    end

    def history=(value)
      HISTORY.clear
      HISTORY.push(*value)
    end
  end
end

class RubyLex
  alias_method :_lex, :lex

  def lex
    if @lex_state == EXPR_BEG
      i = 0
      while peek(i) and (line = @rests.join("").strip).length < Exspec::COMMAND_PREFIX.length
        i += 1
      end
      if line.start_with? Exspec::COMMAND_PREFIX
        skip = true
        while c = getc
          next if skip &&= (c =~ /[\s]/)
          break if c =~ /[\n\r]/
        end
        return get_readed
      end
    end
    _lex
  end
end