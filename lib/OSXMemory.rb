require 'FFI'
require_relative "OSXMemory/Task"
require_relative "OSXMemory/Thread"
require_relative "OSXMemory/ThreadState"
require_relative "OSXMemory/Breakpoint"
require_relative "OSXMemory/Libc"
require_relative "OSXMemory/InterfaceProperty"
require_relative "OSXMemory/InterfaceObject"

class OSXMemory
  include OSXMemoryModules

  def self.task_for_pid(pid)
    Task.new pid
  end
end