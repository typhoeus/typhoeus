if RUBY_PLATFORM == 'java'
  require 'spoon'
  module Kernel
    def spawn(*args)
      Spoon.spawnp(*args)
    end
  end
elsif RUBY_VERSION =~ /1.8/
  module Kernel
    def spawn(*args)
      if pid = fork
      else exec(*args)
      end
      pid
    end
  end
end

