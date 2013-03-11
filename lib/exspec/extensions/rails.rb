module Exspec::Rails
  extend Exspec::Extension

  @@rails = self
  @@app_path = nil
  @@enabled = true

  def self.enabled=(value)
    @@enabled = value
  end

  def self.is_available?
    return @@enabled && !!app_path
  end

  def self.app_path
    return @@app_path if @@app_path
    parent_dirs do |path|
      if File.file?(File.expand_path("config/boot.rb", path)) && File.file?(File.expand_path("config/application.rb", path))
        @@app_path = path
        return @@app_path
      end
    end
    nil
  end

  def self.start_console
    if is_available?
      begin
        require_environment
        ::Rails::Console.start(::Rails.application)
        return true
      rescue Exception => e
        @@enabled = false
      end
    end
    return false
  end

  def self.require_environment
    if is_available?
      begin
        require "rails"
        require "rails/commands/console"
        require File.expand_path("config/boot", app_path)
        require File.expand_path("config/application", app_path)
        ::Rails.application.require_environment!
      rescue Exception => e
        @@enabled = false
      end
    end
  end

  config do |config|
    if is_available?
      config[:test_dir] = File.expand_path(config[:test_dir], app_path)
    end
  end

  setup_global_context do
    @@rails.require_environment
  end

  setup_context do
    if @@rails.is_available?
      begin
        ::ActionDispatch::Reloader.cleanup!
        ::ActionDispatch::Reloader.prepare!
      rescue Exception => e
        @@enabled = false
      end
    end
  end

  start_irb do
    start_console
  end
end