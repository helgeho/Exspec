module Exspec
  module Extension
    @@module = self
    @@extensions = {}

    def self.loaded
      apply :loaded
    end

    def self.config(config)
      apply :config, nil, false, config
    end

    def self.start_exspec
      apply :start_exspec, nil, true
    end

    def self.set_execute_callbacks(options)
      apply :set_execute_callbacks, nil, false, options
    end

    def self.initialize_exspec(exspec, components)
      apply :initialize_exspec, exspec, false, components
    end

    def self.initialized_exspec(exspec)
      apply :initialized_exspec, nil, false, exspec
    end

    def self.execute_command(executor, command, param_string, options)
      apply :execute_command, executor, true, command, param_string, options
    end

    def self.setup_context(context_manager)
      apply :setup_context, context_manager
    end

    def self.setup_global_context(context_manager, global_instance)
      apply :setup_global_context, context_manager, false, global_instance
    end

    def self.setup_exspec_context(context_manager)
      apply :setup_exspec_context, context_manager
    end

    def self.test_hook(hook, spec)
      apply extension_point(:test_hook, hook), nil, false, spec
    end

    def self.apply(extension_point, extended_instance=nil, return_first=false, *args)
      extensions(extension_point).each do |extension|
        val = if extended_instance
                extended_instance.instance_exec *args, &extension
              else
                extension.call *args
              end
        return val if return_first && !val.nil?
      end
      return nil
    end

    def self.extension_point(name, *args)
      args.unshift(name).map(&:to_s).join(":").to_sym
    end

    def self.extensions(extension_point)
      @@extensions[extension_point.to_sym] ||= []
    end

    def method_missing(method, *args, &block)
      def_extension @@module.extension_point(method, *args), block
    end

    def extensions(extension_point)
      @@module.extensions extension_point
    end

    def def_extension(extension_point, block)
      extensions(extension_point.to_sym) << block
    end
  end
end