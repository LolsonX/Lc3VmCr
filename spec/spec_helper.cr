require "spec"
require "./helpers/*"
require "../src/lc3_vm"

def setup_registries(dst : UInt16, 
                     src1 : (Lc3Vm::Registers | UInt16) = 0_u16, 
                     src2 : (Lc3Vm::Registers | UInt16) = 0_u16, 
                     dst_val = 0_u16, val1 = 0_u16, val2 = 0_u16)

  Lc3Vm::REG[dst] = dst_val
  Lc3Vm::REG[src1] = val1
  if src1 != src2
    Lc3Vm::REG[src2] = val2
  end
end

def reset
  Lc3Vm.reset
end