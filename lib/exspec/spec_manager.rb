require "fileutils"
require_relative "spec"

module Exspec
  class SpecManager
    def initialize(exspec)
      @exspec = exspec
      @current_spec = nil
    end

    attr_reader :exspec
    attr_accessor :current_spec

    def save(logger, description)
      spec = create_spec description
      file = spec.file
      FileUtils.mkdir_p(File.dirname(file))
      File.open(file, "w") do |f|
        f.write(logger.instructions.join "\n")
      end
      @current_spec = spec
    end

    def spec(description)
      return description if description.kind_of?(Spec) || description.nil?

      description = description.strip
      parent = description.start_with?(SPEC_SEPARATOR) ? nil : current_spec
      parent_dir = parent.nil? ? TEST_DIR : parent.directory
      file = File.expand_path(description, parent_dir)
      return create_spec file if File.file?(file)

      current = parent
      description.split(SPEC_SEPARATOR).each do |spec|
        spec.strip!
        next if spec.empty?
        current = create_spec spec, current
      end
      current
    end

    def parent(description)
      spec = spec(description)
      parent_dir = File.dirname(spec.file)
      parent_file = parent_dir + SPEC_EXTENSION
      return nil if parent_dir == TEST_DIR || !File.exist?(parent_file)
      parent_name = Spec.name(parent_file)
      create_spec parent_name, nil, parent_file
    end

    def specs(parent=current_spec, recursive=false)
      parent = "" if parent.nil?
      if parent.is_a?(String)
        parent = parent.strip
        relative_directory = current_spec.nil? ? TEST_DIR : current_spec.directory
        parent_directory = File.expand_path(parent, relative_directory)
        return find_specs(parent_directory, recursive) if File.directory?(parent_directory)
      end
      parent = spec(parent)
      return [] if parent.nil? || !parent.exist?
      find_specs(parent.directory, recursive)
    end

    private

    def file(name, parent)
      directory = parent.nil? ? TEST_DIR : parent.file.chomp(SPEC_EXTENSION)
      File.join(directory, name + SPEC_EXTENSION)
    end

    def create_spec(description, parent=current_spec, file=nil)
      name = Spec.name description
      parent = (parent.nil? || !parent.exist?) ? nil : parent
      file = File.file?(description) ? description : file(name, parent) if file.nil?
      Spec.new self, name, file, parent
    end

    def find_specs(directory, recursively=false)
      specs = []
      return specs unless File.directory? directory
      Dir.entries(directory).sort.each do |file|
        next if file.gsub(".", "").empty?
        file = File.expand_path(file, directory)
        if File.directory? file
          specs.push(*find_specs(file, recursively)) if recursively
        elsif file.end_with? SPEC_EXTENSION
          specs << create_spec(file)
        end
      end
      specs
    end
  end
end