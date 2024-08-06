
module Lc3Vm
  class Memory
    getter :memory

    def initialize
      @memory = Array(UInt16).new(65535, 0)
    end

    def [](address : Number) : UInt16
      @memory[address]
    end

    def [](range : Range) : Array(UInt16)
      @memory[range]
    end

    def []=(address, value) : UInt16
      @memory[address] = value
    end

    def clear
      @memory = Array(UInt16).new(65535, 0)
    end
  end
end