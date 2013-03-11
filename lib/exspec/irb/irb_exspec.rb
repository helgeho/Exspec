require_relative "../../exspec"
require_relative "irb_context_manager"
require_relative "irb_patch"

module Exspec
  class IrbExspec < Exspec
    def initialize(context, workspace)
      @irb_context = context
      @irb_workspace = workspace
      @irb_context_manager = IrbContextManager.new self
      super :context_manager => @irb_context_manager
    end

    attr_reader :irb_context, :irb_workspace

    def irb_execute(line, &eval)
      @irb_context_manager.define_eval &eval if block_given?
      execute line
    end

    def expect_inspect(expect=nil, comment=nil)
      if expect.nil? && @irb_context.io.is_a?(IRB::ReadlineInputMethod)
        begin
          history = @irb_context.io.history
          @irb_context.io.history = [inspect_last_value]
          @irb_context.io.prompt = "fuzzy expectation: "
          puts "What inspect value do you expect (only the static content, press up to get the last one):"
          input = @irb_context.io.gets.strip
        rescue Exception => e
          puts "Error: #{e}"
        ensure
          @irb_context.io.history = history
          expect = input.empty? ? expect : input
        end
      end
      super expect, comment
    end

    def self.start_irb
      require_relative "irb_patch"
      started = Extension.apply :start_irb, nil, true
      IRB.start unless started
    end
  end
end