module Exspec
  class Logger
    def initialize
      @log = []
      @enabled = true
      @erased_last = false
    end

    def enabled?
      @enabled
    end

    def enabled=(value)
      @enabled = value
    end

    def entries
      @log
    end

    def instructions
      @log.map{ |entry| entry[:instruction] }
    end

    def clear
      @log.clear
    end

    def log(instruction, value)
      if @enabled
        instruction.gsub! /\n+/, ";\n"
        @log << {:instruction => instruction.strip, :value => value}
        @erased_last = false
      end
      value
    end

    def erase_last_instruction
      erasing = !@erased_last
      if erasing
        @log.pop
        @erased_last = true
      end
      erasing
    end

    def last_instruction
      return nil if @log.empty?
      @log.last[:instruction]
    end

    def last_value
      return nil if @log.empty?
      @log.last[:value]
    end

    def last_entry
      return nil if @log.empty?
      @log.last
    end

    def without_logging
      enabled = enabled?
      self.enabled = false
      val = yield
    ensure
      self.enabled = enabled
      val
    end
  end
end