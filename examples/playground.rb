#!/usr/bin/env ruby
require '../OSXMemory'
require 'sys/proctable'

matches = Sys::ProcTable.ps.select{|p| p.comm =~ /Calculator/ }
abort("No PID") if matches.empty?
pid = matches.first.pid

task = OSXMemory.task_for_pid pid
threads = task.threads
state = threads.first.state

puts state.dump