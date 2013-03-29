require_relative "context_delegator"

def parent_dirs
  root = File.expand_path "/"
  level = 0
  begin
    relative = "../" * level
    path = File.expand_path relative
    yield path
    level += 1
  end until path == root
end