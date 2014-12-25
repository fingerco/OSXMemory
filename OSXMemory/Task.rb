require 'FFI'
require_relative 'Libc'
require_relative 'Constants'
require 'pry'

module OSXMemoryModules
  class Task
    attr_accessor :task_id

    def initialize(pid, task_id = false)
      @pid = pid
      @breakpoints = []
      @orig_instructions = {}

      unless task_id
        port = FFI::MemoryPointer.new :uint, 1
        response = Libc.task_for_pid(Libc.mach_task_self, pid, port)
        abort("TASK FOR PID ERROR: #{response}") if response != 0
        task_id = port.read_uint
      end

      @task_id = task_id
    end


    def threads
      threads = FFI::MemoryPointer.new :pointer, 1
      count = FFI::MemoryPointer.new :int, 1
      response = Libc.task_threads(@task_id, threads, count)
      abort("COULD NOT FETCH THREADS: #{response}") if response != 0
      
      thread_ids = threads.read_pointer.read_array_of_uint(count.read_uint)
      thread_ids.map{|thread_id| Thread.new thread_id }
    end

    def attach
      response = ptrace(Ptrace::ATTACH, 0, 0)
      wait_for_process_signal
      self.continue
      response.first
    end

    def detach
      response = ptrace(Ptrace::DETACH, 0, Wait::UNTRACED)
      response.first
    end

    def read(addr, size)
      buf = FFI::MemoryPointer.new(size)
      len = FFI::MemoryPointer.new(:uint).write_uint(size)
      response = Libc.vm_read_overwrite(@task_id, addr, size, buf, len)
      abort("COULD NOT READ TASK: #{response}") if response != 0
      buf.read_string(len.read_uint)
    end

    def write(addr, data)
      response = Libc.vm_write(@task_id, addr, data, data.size)
      abort("COULD NOT WRITE TASK: #{response}") if response != 0
      response
    end

    def protect(addr, size, setmax, protection)
      setmax = setmax ? 1 : 0
      response = Libc.vm_protect(@task_id, addr, size, setmax, protection)
      abort("COULD NOT PROTECT TASK: #{response}") if response != 0
      response
    end

    def suspend
      response = Libc.task_suspend(@task_id)
      abort("COULD NOT SUSPEND TASK: #{response}") if response != 0
      response
    end

    def continue(addr = 1, data = 0)
      response = ptrace(Ptrace::CONTINUE, addr, data)
      response.first
    end

    def step
      response = ptrace(Ptrace::STEP, 1, 0)
      response.first
    end

    def resume
      response = Libc.task_resume(@task_id)
      abort("COULD NOT RESUME TASK: #{response}") if response != 0
      response
    end

    def add_breakpoint(addr, &block)
      breakpoint = Breakpoint.new(self, addr, &block)
      @breakpoints << breakpoint
      breakpoint.install
      breakpoint
    end

    def reinstall_breakpoints(addr)
      @breakpoints.each do |bp|
        bp.install if bp.addr == addr && !bp.installed
      end
    end

    def remove_breakpoints(addr)
      matches = @breakpoints.select {|bp| bp.addr == addr }
      matches.each {|bp| bp.uninstall }
      (matches.empty? ? false : matches)
    end

    def process_loop
      @exited = false

      while !@exited do
        wait_for_signal
      end
    end

    private

    def ptrace(request, addr, data)
      FFI.errno = 0
      response = Libc.ptrace(request, @pid, addr, data)
      abort("COULD NOT EXECUTE PTRACE: #{FFI.errno}") if response == -1 && FFI.errno != 0
      [response, data]
    end


    def wait_for_signal(opts = 0)
      response = wait_for_process_signal(opts)
      status = response[1]
      wstatus = status & 0x7f
      signal = status >> 8

      if response[0] != 0 #r[0] == 0 iff wait had nothing to report and NOHANG option was passed
        case
        when wstatus == 0 #WIFEXITED
          self.detach
          @exited = true
        when wstatus != 0x7f #WIFSIGNALED
          @exited = false
        when signal == 0xB #SIGSEGV
          self.threads.each do |thread|
            puts thread.state.dump
          end

          abort("SEGMENTATION FAULT IN CHILD")
        when signal != 0x13 #WIFSTOPPED

          self.threads.each do |thread|
            state = thread.state
            state.rip -= 1

            @breakpoints.each do |bp|
              bp.perform_action(thread) if bp.addr == state.rip
            end
          end

          self.threads.each do |thread|
            state = thread.state
            state.rip -= 1

            if self.remove_breakpoints(state.rip)
              thread.save_state(state)
              self.step
              wait_for_process_signal
              self.reinstall_breakpoints(state.rip)
            end

          end

          self.continue
        when signal == 0x13 #WIFCONTINUED
          #Do nothing for the moment
        end
      end

      response
    end

    def wait_for_process_signal(opts = 0)
      stat = FFI::MemoryPointer.new :int, 1
      FFI.errno = 0
      response = Libc.waitpid(@pid, stat, opts)
      abort("COULD NOT EXECUTE WAITPID: #{FFI.errno}") if response == -1

      [response, stat.read_int]
    end
  end
end