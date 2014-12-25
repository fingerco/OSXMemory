module OSXMemoryModules
  module Ptrace
    TRACE_ME = 0 # child declares it's being traced
    #(READ|WRITE)_[IDU] are not valid in OSX but defined in ptrace.h
    READ_I = 1 # read word in child's I space
    READ_D = 2 # read word in child's D space
    READ_U = 3 # read word in child's user structure
    WRITE_I = 4 # write word in child's I space
    WRITE_D = 5 # write word in child's D space
    WRITE_U = 6 # write word in child's user structure
    CONTINUE = 7 # continue the child
    KILL = 8 # kill the child process
    STEP = 9 # single step the child
    ATTACH = 10 # trace some running process
    DETACH = 11 # stop tracing a process
    SIGEXC = 12 # signals as exceptions for current_proc
    THUPDATE = 13 # signal for thread
    ATTACHEXC = 14 # attach to running process with signal exception
    FORCEQUOTA = 30 # Enforce quota for root
    DENY_ATTACH = 31 #Prevent process from being traced
    FIRSTMACH = 32 # for machine-specific requests
  end

  module Wait
    NOHANG = 0x01 # [XSI] no hang in wait/no child to reap
    UNTRACED = 0x02 # [XSI] notify on stop, untraced child
    EXITED = 0x04 # [XSI] Processes which have exitted
    STOPPED = 0x08 # [XSI] Any child stopped by signal
    CONTINUED = 0x10 # [XSI] Any child stopped then continued
    NOWWAIT = 0x20 # [XSI] Leave process returned waitable
  end


  module Protection
    READ = 0x1 #read permission
    WRITE = 0x2 #write permission
    EXECUTE = 0x4 #execute permission
    NONE = 0x0 #no rights
    ALL = 0x7 #all permissions
  end
end