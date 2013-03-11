module Exspec
  class ExecuteCallbacks
    def initialize
      @before = []
      @after = []
    end

    def before(command=nil, params=nil, &block)
      if block_given?
        @before << block
      else
        @before.each { |proc| proc.call(command, params) }
      end
    end

    def after(command=nil, params=nil, value=nil, &block)
      if block_given?
        @after << block
      else
        @after.each { |proc| proc.call(command, params, value) }
      end
    end
  end
end