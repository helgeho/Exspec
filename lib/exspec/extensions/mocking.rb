module Exspec::Mocking
  extend Exspec::Extension

  execute_command do |command, param_string, options|
    case command
      when "mock", "stub"
        execute(command, parameters(param_string), options) do |params|
          if params.empty?
            exspec.commit "#{Exspec::COMMAND_PREFIX}mock", Mock.new
          else
            mock_var = params[0]
            exspec.commit "#{Exspec::COMMAND_PREFIX}mock #{mock_var}"
            puts "assigning #{command} to #{mock_var}"
            context.raw_eval "#{mock_var} = #{Mock.name}.new"
          end
        end
    end
  end

  class Mock < BasicObject
    def initialize
      @methods = {}
      @attributes = {}
      @children = {}
      @method_calls = []
    end

    def new(*args, &block)
      _log_call :new, args, block
      _defined?(:new) ? _call(:new, *args, &block) : self
    end

    def ==(*args, &block)
      _log_call :==, args, block
      _defined?(:==) ? _call(:==, *args, &block) : false
    end

    def inspect(*args, &block)
      _log_call :inspect, args, block
      _defined?(:inspect) ? _call(:inspect, *args, &block) : "#<Exspec Mock>"
    end

    def to_s(*args, &block)
      _log_call :to_s, args, block
      _defined?(:to_s) ? _call(:to_s, *args, &block) : "Exspec Mock"
    end

    def nil?(*args, &block)
      _log_call :nil?, args, block
      _defined?(:nil?) ? _call(:nil?, *args, &block) : false
    end

    def _def(method, &body)
      @methods[method.to_sym] = body
    end

    def _defined?(method)
      @methods.include? method.to_sym
    end

    def _method_calls(method=nil)
      if method.nil?
        @method_calls
      else
        @method_calls.select { |call| call[:method] == method.to_sym }
      end
    end

    def _clear_calls
      @method_calls.clear
    end

    def _have_been_called?(method)
      @method_calls.any? { |call| call[:method] == method.to_sym }
    end

    def _times_called(method)
      @method_calls.count { |call| call[:method] == method.to_sym }
    end

    def _first_call(method)
      @method_calls.find { |call| call[:method] == method.to_sym }
    end

    def _last_call(method)
      @method_calls.reverse.find { |call| call[:method] == method.to_sym }
    end

    def _log_call(method, args, block)
      @method_calls << { :method => method.to_sym, :args => args, :block => block }
    end

    def _attribute_set?(attribute)
      @attributes.include? attribute.to_sym
    end

    def _attribute(attribute)
      @attributes[attribute.to_sym]
    end

    def _set_attribute(attribute, value)
      @attributes[attribute.to_sym] = value
    end

    def _child(name)
      name = name.to_sym
      if @children.include? name
        @attributes[name]
      else
        @attributes[name] = Mock.new
      end
    end

    def _call(method, *args, &block)
      return @methods[method.to_sym].call (args + [block]) if _defined? method
      if method.to_s.end_with?("=") && !args.empty?
        return _set_attribute(method.to_s.chop, args[0])
      elsif _attribute_set?(method)
        return _attribute(method)
      end
      _child(method)
    end

    def method_missing(method, *args, &block)
      _log_call method, args, block
      _call(method, *args, &block)
    end
  end
end