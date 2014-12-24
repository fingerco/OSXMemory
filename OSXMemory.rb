require 'FFI'
require_relative "OSXMemory/Task"
require_relative "OSXMemory/Thread"
require_relative "OSXMemory/ThreadState"
require_relative "OSXMemory/Libc"

class OSXMemory
  include OSXMemoryModules

  def self.task_for_pid(pid)
    port = FFI::MemoryPointer.new :uint, 1
    response = Libc.task_for_pid(Libc.mach_task_self, pid, port)
    abort("TASK FOR PID ERROR: #{response}") if response != 0
    Task.new port.read_uint
  end
end