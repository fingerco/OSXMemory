#!/usr/bin/env ruby
require 'sys/proctable'
require_relative '../OSXMemory'

matches = Sys::ProcTable.ps.select{|p| p.comm =~ /Calculator/ }
abort("No PID") if matches.empty?
pid = matches.first.pid

task = OSXMemory.task_for_pid pid
threads = task.threads
task.attach

hitcount = 0

puts "ADDING BREAKPOINT"
task.add_breakpoint(0x10000164e) do
  hitcount += 1
  puts "Clear hit #{hitcount} times"
end

task.process_loop()