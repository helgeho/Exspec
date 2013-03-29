require 'capybara'
require 'capybara/dsl'

module Exspec::Capybara
  extend Exspec::Extension

  @@capybara = nil

  class CapybaraDSL < ContextDelegator
    include Capybara::DSL
  end

  def self.config
    config = {
      :driver => :selenium
    }
    Exspec::Extension.apply :capybara_config, nil, false, config
    config
  end

  initialized_exspec do |exspec|
    @@capybara = CapybaraDSL.new exspec.context
    Exspec::Extension.apply :capybara_setup, Capybara, false, config
  end

  capybara_setup do |config|
    self.current_driver = config[:driver]
  end

  setup_global_context do |global_instance|
    class << global_instance
      def capybara
        @@capybara
      end

      def page
        @@capybara.page
      end
    end
  end

  # for examples see the comments after the commands below
  # returned values can be checked with Exspec's assertion commands
  execute_command do |command, param_string, options|
    case command
      when "capybara", "!" # E.g. !! visit "http://www.github.com"
        execute(command, parameters(param_string), options) do
          val = value_or_exception do
            @@capybara.instance_eval param_string
          end
          commit "!capybara #{param_string}", val
        end
      when "!$", "!find" # E.g. !!$ div.myCssClass
        execute(command, parameters(param_string), options) do
          val = value_or_exception do
            @@capybara.instance_eval { page.find(param_string) }
          end
          commit "!capybara page.find(\"#{param_string.inspect[1..-2]}\")", val
        end
      when "!<", "!eval" # E.g. !!< $("input").text() (to read values from JavaScript)
        execute(command, parameters(param_string), options) do
          val = value_or_exception do
            @@capybara.instance_eval { page.evaluate_script param_string }
          end
          commit "!capybara page.evaluate_script(\"#{param_string.inspect[1..-2]}\")", val
        end
      when "!>", "!exec" # E.g. !!> $(".button").click() (to execute JavaScript)
        execute(command, parameters(param_string), options) do
          val = value_or_exception do
            @@capybara.instance_eval { page.execute_script param_string }
          end
          commit "!capybara page.execute_script(\"#{param_string.inspect[1..-2]}\")"
        end
    end
  end
end