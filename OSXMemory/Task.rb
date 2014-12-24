require 'FFI'
require_relative 'Libc'

module OSXMemoryModules
  class Task
    attr_accessor :task_id

    def initialize(task_id)
      @task_id = task_id
    end


    def threads
      threads = FFI::MemoryPointer.new :pointer, 1
      count = FFI::MemoryPointer.new :int, 1
      response = Libc.task_threads(@task_id, threads, count)
      raise KernelCallError.new(:task_threads, response) if response != 0
      
      thread_ids = threads.read_pointer.read_array_of_uint(count.read_uint)
      thread_ids.map{|thread_id| Thread.new thread_id }
    end
  end
end