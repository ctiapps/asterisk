module Asterisk
  module Generator
    def self.current_dir
      path = File.real_path(Dir.current).split("/")
      path.join("/")
    end
  end
end
