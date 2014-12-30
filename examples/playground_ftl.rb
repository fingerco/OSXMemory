#!/usr/bin/env ruby
require 'sys/proctable'
require_relative '../lib/OSXMemory'

matches = Sys::ProcTable.ps.select{|p| p.comm =~ /^FTL$/ }
abort("No PID") if matches.empty?
pid = matches.first.pid

puts "PID: #{pid}"
task = OSXMemory.task_for_pid pid
threads = task.threads
task.attach

BREAKPOINT_POSITION = 0x10001d4b4

saved_position_x = nil
saved_position_y = nil

task.add_breakpoint(BREAKPOINT_POSITION) do |thread|
  state = thread.state
  position_x_address = state.rdi + 0x18
  position_y_address = state.rdi + 0x1c

  saved_position_x ||= task.read(position_x_address, 4).unpack('N').first
  saved_position_y ||= task.read(position_y_address, 4).unpack('N').first

  task.write(position_x_address, [saved_position_x].pack('N'))
  task.write(position_y_address, [saved_position_y].pack('N'))
end

task.process_loop()