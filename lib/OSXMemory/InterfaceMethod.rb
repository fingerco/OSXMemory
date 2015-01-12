module OSXMemoryModules
  class InterfaceMethod
    attr_accessor :name, :params, :start_offset, :return_offset

    def initialize(name, params, start_offset, return_offsets, &block)
      @name = name
      @params = params
      @start_offset = start_offset
      @return_offsets = return_offsets
      @start_proc = nil
      @return_proc = nil
      @cleanup_proc = nil
      @injected = false
      @injections_bps = {}

      self.instance_eval(&block) if block
    end

    def prepare_start(&start_proc); @start_proc = start_proc; end
    def prepare_return(&return_proc); @return_proc = return_proc; end
    def prepare_cleanup(&cleanup_proc); @cleanup_proc = cleanup_proc; end

    def inject_at_address(interface_object, addr, args, &returned_block)
      breakpoint_size = OSXMemory::Breakpoint::INT3.size

      start_breakpoint = interface_object.instance.add_breakpoint(addr) do |thread, options|
        original_state = thread.state.immutable_state
        original_state[:rip] = addr + 1

        new_state = thread.state

        addr_ptr = [addr].pack('Q')
        new_state.rsp -= addr_ptr.size
        interface_object.instance.write(new_state.rsp, addr_ptr)

        # Set up the function arguments
        @params.each do |name, register|
          new_state.send(register.to_s + '=', args[name])
        end

        new_state.rip = @start_offset
        thread.save_state(new_state)

        @start_proc.call(thread) if @start_proc

        options[:return_cleanup] = Proc.new do |thread, options|
          options[:reinstall_bp] = false
          options[:remove_after_execution] = true
          new_state = thread.state.load_immutable_state(original_state)

          thread.save_state(new_state)
          @cleanup_proc.call(thread) if @cleanup_proc
        end

        return_breakpoints = []

        @return_offsets.each do |return_offset|
          return_breakpoint = interface_object.instance.add_breakpoint(return_offset) do |thread, options|
            @return_proc.call(thread) if @return_proc
            returned_block.call(thread.state.rax, thread) if returned_block
            return_breakpoints.each {|return_bp| return_bp.uninstall }
          end

          return_breakpoint.is_cleanup = true
          return_breakpoint.execute_alone = true
          return_breakpoints << return_breakpoint
        end
      end

      start_breakpoint.execute_alone = true
      @injections_bps[[addr, args]] = start_breakpoint
    end
  end
end