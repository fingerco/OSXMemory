require 'FFI'
require_relative 'ThreadState'
require_relative 'Libc'

module OSXMemoryModules
  class Thread
    attr_accessor :thread_id

    def initialize(thread_id)
      @thread_id = thread_id
    end

    def state
      state = FFI::MemoryPointer.new ThreadState
      count = FFI::MemoryPointer.new(:int, 1).write_uint ThreadState::COUNT

      response = Libc.thread_get_state(@thread_id, Libc::X86_THREAD_STATE64, state, count)
      abort("THREAD STATE ERROR: #{response}") if response != 0
      ThreadState.new state
    end

    def save_state(state)
      response = Libc.thread_set_state(@thread_id, Libc::X86_THREAD_STATE64, state.to_ptr, ThreadState::COUNT)
      #abort("THREAD SAVE STATE ERROR: #{response}") if response != 0
      state
    end
  end
end