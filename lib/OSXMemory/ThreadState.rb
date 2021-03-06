require 'FFI'
require_relative 'FFIStruct'

module OSXMemoryModules
  class ThreadState < FFIStruct
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

    def immutable_state
      {
        rax: self.rax,
        rbx: self.rbx,
        rcx: self.rcx,
        rdx: self.rdx,
        rdi: self.rdi,
        rsi: self.rsi,
        rbp: self.rbp,
        rsp: self.rsp,
        r8: self.r8,
        r9: self.r9,
        r10: self.r10,
        r11: self.r11,
        r12: self.r12,
        r13: self.r13,
        r14: self.r14,
        r15: self.r15,
        rip: self.rip,
        rflags: self.rflags,
        cs: self.cs,
        fs: self.fs,
        gs: self.gs
      }
    end

    def load_immutable_state(state)
      state.each do |register, value|
        self.send(register.to_s + '=', value)
      end

      self
    end
  end
end