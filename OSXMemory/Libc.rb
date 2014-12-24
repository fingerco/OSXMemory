module OSXMemoryModules
  module Libc
    extend FFI::Library
    ffi_lib FFI::Library::LIBC
    typedef :int, :kern_return_t

    typedef :ulong_long, :memory_object_offset_t
    typedef :uint, :vm_inherit_t
    typedef :uint, :natural_t
    typedef :natural_t, :mach_msg_type_number_t
    typedef :natural_t, :mach_port_name_t
    typedef :mach_port_name_t, :mach_port_t
    typedef :mach_port_t, :vm_map_t
    typedef :mach_port_t, :task_t
    typedef :mach_port_t, :thread_act_t
    typedef :int, :vm_region_flavor_t
    typedef :int, :vm_prot_t
    typedef :int, :vm_behavior_t
    typedef :int, :policy_t
    typedef :int, :boolean_t
    typedef :int, :thread_state_flavor_t
    typedef :int, :thread_flavor_t

    attach_function :mach_task_self, [], :mach_port_t
    attach_function :task_for_pid, [:mach_port_name_t, :int, :pointer], :kern_return_t
    attach_function :task_threads, [:task_t, :pointer, :pointer], :kern_return_t
    
    attach_function :thread_get_state, [:thread_act_t, :thread_state_flavor_t, :pointer, :pointer], :kern_return_t
    attach_function :thread_set_state, [:thread_act_t, :thread_state_flavor_t, :pointer, :mach_msg_type_number_t], :kern_return_t
  end
end