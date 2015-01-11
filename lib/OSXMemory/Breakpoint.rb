require 'FFI'
require_relative 'Libc'

module OSXMemoryModules
  class Breakpoint
    INT3 = [0xCC].pack('C')
    attr_accessor :addr, :installed, :execute_alone, :is_cleanup, :orig

    def initialize(task, addr, &action)
      @task = task
      @addr = addr
      @action = action
      @orig = false
      @installed = false
      @execute_alone = false
      @is_cleanup = false
    end

    def perform_action(thread, options)
      @action.call(thread, options)
    end

    def install
      @installed = true
      @task.suspend

      @task.protect(@addr, INT3.size, false, Protection::ALL)
      original = @task.read(@addr, INT3.size)

      if original != INT3
        @orig = @task.read(@addr, INT3.size)
        @task.write(@addr, INT3)
      end
      
      @task.resume
    end

    def uninstall(revert = true)
      @installed = false

      if @orig && revert
        @task.suspend
        @task.write(@addr, @orig)
        @task.resume
      end
    end
  end
end