#!/usr/bin/env ruby
require 'FFI'

class OSXMemory

  module Libc
    extend FFI::Library
    ffi_lib FFI::Library::LIBC
    attach_function :thread_get_state, [:thread_act_t, :thread_state_flavor_t, :pointer, :pointer], :kern_return_t
    attach_function :thread_set_state, [:thread_act_t, :thread_state_flavor_t, :pointer, :mach_msg_type_number_t], :kern_return_t
  end

  
	
end