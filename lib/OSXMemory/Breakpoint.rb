require 'FFI'
require_relative 'Libc'

module OSXMemoryModules
  class Breakpoint
    INT3 = [0xCC].pack('C')
    attr_accessor :addr, :installed

    def initialize(task, addr, &action)
      @task = task
      @addr = addr
      @action = action
      @orig = false
      @installed = false
    end

    def perform_action(thread)
      @action.call(thread)
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

    def uninstall
      @installed = false

      if @orig
        @task.suspend
        @task.write(@addr, @orig)
        @task.resume
      end
    end
  end
end