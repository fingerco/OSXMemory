require 'FFI'

class OSXMemory

  X86_THREAD_STATE64    = 4
  
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

  class ThreadState < FFI::Struct
    FLAVOR = 4
    COUNT = 42
    SIZE = 168

    layout :rax, :uint64,
           :rbx, :uint64,
           :rcx, :uint64,
           :rdx, :uint64,
           :rdi, :uint64,
           :rsi, :uint64,
           :rbp, :uint64,
           :rsp, :uint64,
           :r8, :uint64,
           :r9, :uint64,
           :r10, :uint64,
           :r11, :uint64,
           :r12, :uint64,
           :r13, :uint64,
           :r14, :uint64,
           :r15, :uint64,
           :rip, :uint64,
           :rflags, :uint64,
           :cs, :uint64,
           :fs, :uint64,
           :gs, :uint64

    def methods(regular=true)
      (super + self.members.map{|x| [x, (x.to_s+"=").intern]}).flatten
    end

    def method_missing(meth, *args)
      super unless self.respond_to? meth
      if meth.to_s =~ /=$/
        self.__send__(:[]=, meth.to_s.gsub(/=$/,'').intern, *args)
      else
        self.__send__(:[], meth, *args)
      end
    end

    def respond_to?(meth, include_priv=false)
      !((self.methods & [meth, meth.to_s]).empty?) || super
    end

    def dump(&block)
      maybe_hex = lambda {|a| begin; "\n" + (" " * 9) + block.call(a, 16).hexdump(true)[10..-2]; rescue; ""; end }
      maybe_dis = lambda {|a| begin; "\n" + block.call(a, 16).distorm.map {|i| "         " + i.mnem}.join("\n"); rescue; ""; end }

      string =<<EOM
      -----------------------------------------------------------------------
      CONTEXT:
      RIP: #{self.rip.to_s(16).rjust(16, "0")} #{maybe_dis.call(self.rip)}

      RAX: #{self.rax.to_s(16).rjust(16, "0")} #{maybe_hex.call(self.rax)}
      RBX: #{self.rbx.to_s(16).rjust(16, "0")} #{maybe_hex.call(self.rbx)}
      RCX: #{self.rcx.to_s(16).rjust(16, "0")} #{maybe_hex.call(self.rcx)}
      RDX: #{self.rdx.to_s(16).rjust(16, "0")} #{maybe_hex.call(self.rdx)}
      RDI: #{self.rdi.to_s(16).rjust(16, "0")} #{maybe_hex.call(self.rdi)}
      RSI: #{self.rsi.to_s(16).rjust(16, "0")} #{maybe_hex.call(self.rsi)}
      RBP: #{self.rbp.to_s(16).rjust(16, "0")} #{maybe_hex.call(self.rbp)}
      RSP: #{self.rsp.to_s(16).rjust(16, "0")} #{maybe_hex.call(self.rsp)}
EOM
    end
  end

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