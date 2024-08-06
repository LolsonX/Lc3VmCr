module Lc3Vm
  enum Registers : UInt8
    R0
    R1
    R2
    R3
    R4
    R5
    R6
    R7
    RPC
    RCND
    RCNT
  end

  class Registry
    getter :registry

    def initialize
      @registry = Array(UInt16).new(Registers::RCNT.value, 0)
    end

    def [](reg : (UInt16 | Registers)) : UInt16
      if reg.is_a?(Registers)
        return registry[reg.value]
      end
      
      registry[reg]
    end

    def []=(reg : UInt16 | Registers, val : UInt16) : UInt16
      if reg.is_a?(Registers)
        return (registry[reg.value] = val)
      end

      registry[reg] = val
    end

    def clear
      @registry = Array(UInt16).new(Registers::RCNT.value, 0)
    end
  end
end