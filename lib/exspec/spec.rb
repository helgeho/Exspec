require "active_support/core_ext"

class Spec
  def self.name(description)
    name = File.basename(description, File.extname(description))
    name = name.split(".").last.strip
    name.underscore.gsub(/[\W_]+/, "_")
  end

  def initialize(spec_manager, name, file, parent=nil)
    @spec_manager = spec_manager
    @name = name
    @file = file
    @parent = parent
  end

  attr_reader :name, :file

  def full_name
    ".#{stack.map(&:name).join "."}"
  end

  def description
    name.gsub("_", " ").capitalize + "."
  end

  def full_description
    stack.map(&:description).join " "
  end

  def parent
    @parent || @spec_manager.parent(self)
  end

  def exist?
    File.file? file
  end

  def for_instructions(&block)
    content = File.read(file)
    buffer = []
    index = 0
    content.each_line.with_index do |line, line_index|
      line.strip!
      if line.end_with? ";"
        buffer << line.chop
      else
        buffer << line
        block.call buffer.join("\n"), index, (line_index + 1)
        buffer.clear
        index += 1
      end
    end
  end

  def stack
    return @stack if @stack
    reverse_stack = []
    reverse_stack << self
    spec = self
    while spec = spec.parent
      reverse_stack << spec
    end
    @stack = reverse_stack.reverse
  end

  def directory
    file.chomp(File.extname(file))
  end

  def load
    @spec_manager.exspec.load self
  end

  def run
    @spec_manager.exspec.run self
  end

  def run
    @spec_manager.exspec.run_stack self
  end

  def include
    @spec_manager.exspec.include self
  end

  def children
    @spec_manager.specs self
  end

  def hash
    file.hash
  end

  def ==(spec)
    return false if !spec.is_a?(self.class)
    file.eql? spec.file
  end

  def eql?(spec)
    self == spec
  end

  def inspect
    "#<Spec:#{full_name}>"
  end
end