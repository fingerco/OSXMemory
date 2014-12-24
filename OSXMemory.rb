require 'FFI'
require_relative "OSXMemory/ThreadState"
require_relative "OSXMemory/Libc"

class OSXMemory
  include OSXMemoryModules

  X86_THREAD_STATE64    = 4

  def self.thread_state(thread)
    state = FFI::MemoryPointer.new ThreadState
    count = FFI::MemoryPointer.new(:int, 1).write_uint ThreadState::COUNT

    r = Libc.thread_get_state(thread, X86_THREAD_STATE64, state, count)
    abort("THREAD STATE ERROR: #{r}") if r != 0
    ThreadState.new state
  end

  def self.task_for_pid(pid)
    port = FFI::MemoryPointer.new :uint, 1
    r = Libc.task_for_pid(Libc.mach_task_self, pid, port)
    abort("TASK FOR PID ERROR: #{r}") if r != 0
    port.read_uint
  end

  def self.threads_for_task(task)
    threads = FFI::MemoryPointer.new :pointer, 1
    count = FFI::MemoryPointer.new :int, 1
    r = Libc.task_threads(task, threads, count)
    raise KernelCallError.new(:task_threads, r) if r != 0
    threads.read_pointer.read_array_of_uint(count.read_uint)
  end
	
end