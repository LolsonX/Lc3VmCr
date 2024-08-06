require "./lc3_vm/*"

module Lc3Vm
  extend self

  alias OpCode = UInt16

  VERSION = "0.1.0"
  PC_START = UInt16.new(0x3000)

  MEMORY = Memory.new
  REG = Registry.new
  NOPS = 16

  def running
    @@running
  end

  OP_FUNS = [
    ->(instruction : UInt16) { branch(instruction) }, #0x0 br
    ->(instruction : UInt16) { add(instruction) }, #0x1 add
    ->(instruction : UInt16) { load(instruction) }, #0x2 ld
    ->(instruction : UInt16) { store(instruction) }, #0x3 st
    ->(instruction : UInt16) { jump_subroutine(instruction) }, #0x4 jsr
    ->(instruction : UInt16) { and(instruction) }, #0x5 and
    ->(instruction : UInt16) { load_from_register(instruction) }, #0x6 ldr
    ->(instruction : UInt16) { store_from_register(instruction) }, #0x7 str
    ->(instruction : UInt16) {  }, #0x8 rti
    ->(instruction : UInt16) { not(instruction) }, #0x9 not
    ->(instruction : UInt16) { load_indirect(instruction) }, #0xA ldi
    ->(instruction : UInt16) { store_indirect(instruction) }, #0xB sti
    ->(instruction : UInt16) { jump(instruction) }, #0xC jmp
    ->(instruction : UInt16) {  }, #0xD noop
    ->(instruction : UInt16) { load_effective_address(instruction) }, #0xE lea
    ->(instruction : UInt16) { trap(instruction) }  #0xF trap
  ]

  def extract_dr(instruction : UInt16) : UInt16
    (instruction & 0x0E00) >> 9
  end

  def extract_src1(instruction : UInt16) : UInt16
    (instruction & 0x00E0) >> 6
  end

  def extract_src2(instruction : UInt16) : UInt16
    (instruction & 0x0007)
  end

  def extract_imm_mode(instruction : UInt16) : UInt16
    (instruction & (1_u16 << 5)) >> 5
  end

  def extract_value(instruction : UInt16) : UInt16
    val = (instruction & 0x001F)
    if (val & 0x0010).zero?
      return val
    end

    0xFFF0_u16 + (val & 0x000F)
  end

  def extract_offset(instruction : UInt16, size : UInt16) : UInt16
    (0xFFFF >> (16 - size)).to_u16 & instruction
  end

  def extract_trap_vector(instruction)
    (instruction & 0xFF.to_u16) - 0x20.to_u16
  end

  def branch(instruction : UInt16)
    condition = extract_dr(instruction)
    unless(condition & REG[Registers::RCND]).zero?
      REG[Registers::RPC] = extract_offset(instruction, 9)
    end
  end

  def add(instruction : UInt16)
    dr = extract_dr(instruction)
    src1 = extract_src1(instruction)

    if extract_imm_mode(instruction) != 0
      val = extract_value(instruction)
      add_const(dr, src1, val)
    else
      src2 = extract_src2(instruction)
      add_reg(dr, src1, src2)
    end
  end

  def add_reg(dr : UInt16, src1 : UInt16, src2 : UInt16)
    REG[dr] = REG[src1] + REG[src2]
    set_flags(dr)
  end

  def add_const(dr : UInt16, src : UInt16, val : UInt16)
    REG[dr] = REG[src] &+ val
    set_flags(dr)
  end

  def load(instruction : UInt16)
    dr = extract_dr(instruction)
    address = REG[Registers::RPC] + extract_offset(instruction, 6)
    REG[dr] = MEMORY[address]
    set_flags(dr)
  end

  def store(instruction : UInt16)
    src = extract_dr(instruction)
    offset = extract_offset(instruction, 9)
    MEMORY[REG[Registers::RPC] + offset] = REG[src]
  end

  def jump_subroutine(instruction : UInt16)
    REG[Registers::R7] = REG[Registers::RPC]
    REG[Registers::RPC] = if (instruction & 0x0800).positive?
      extract_offset(instruction, 11)
    else
      REG[extract_src1(instruction)]
    end
  end

  def and(instruction : UInt16)
    dr = extract_dr(instruction)
    src1 = extract_src1(instruction)

    if extract_imm_mode(instruction) != 0
      val = extract_value(instruction)
      and_const(dr, src1, val)
    else
      src2 = extract_src2(instruction)
      and_reg(dr, src1, src2)
    end
  end

  def and_reg(dr : UInt16, src1 : UInt16, src2 : UInt16)
    REG[dr] = REG[src1] & REG[src2]
    set_flags(dr)
  end

  def and_const(dr : UInt16, src : UInt16, val : UInt16)
    REG[dr] = REG[src] & val
    set_flags(dr)
  end

  def load_indirect(instruction : UInt16)
    dr = extract_dr(instruction)
    memory_pointer = REG[Registers::RPC] + extract_offset(instruction, 6)
    address = MEMORY[memory_pointer]
    REG[dr] = MEMORY[address]
    set_flags(dr)
  end

  def store_indirect(instruction : UInt16)
    src = extract_dr(instruction)
    offset = extract_offset(instruction, 9)
    address = MEMORY[REG[Registers::RPC] + offset]
    MEMORY[address] = REG[src]
  end

  def not(instruction : UInt16)
    dr = extract_dr(instruction)
    src = extract_src1(instruction)
    REG[dr] = ~REG[src]
  end

  def load_from_register(instruction : UInt16)
    dr = extract_dr(instruction)
    baser = extract_src1(instruction)
    address = REG[baser] + extract_offset(instruction, 3)
    REG[dr] = MEMORY[address]
    set_flags(dr)
  end

  def store_from_register(instruction : UInt16)
    src = extract_dr(instruction)
    baser = extract_src1(instruction)
    offset = extract_offset(instruction, 6)
    address = REG[baser] + offset
    MEMORY[address] = REG[src]
  end

  def jump(instruction : UInt16)
    baser = extract_src1(instruction)
    REG[Registers::RPC] = REG[baser]
  end

  def load_effective_address(instruction : UInt16)
    dr = extract_dr(instruction)
    REG[dr] = REG[Registers::RPC] + extract_offset(instruction, 9)
    set_flags(dr)
  end

  def trap(instruction : UInt16)
    trap_code = extract_trap_vector(instruction)
    TRAPS_VECTOR[trap_code].call
  end

  def operation(instruction : UInt16)
    instruction >> 12
  end

  def execute(instruction)
    OP_FUNS[operation(instruction)].call(instruction)
  end

  def set_flags(register : UInt16)
    if REG[register].zero?
      REG[Registers::RCND] = Flags::FZ.value
    elsif REG[register] >> 15
      REG[Registers::RCND] = Flags::FN.value
    else
      REG[Registers::RCND] = Flags::FP.value
    end
  end

  def reset
    MEMORY.clear
    REG.clear
  end

  def stop
    @@running = false
  end

  def debug_info
    puts "CURRENT RPC: #{REG[Registers::RPC].to_s(16)}"
    puts "INSTRUCTION: #{MEMORY[REG[Registers::RPC]].to_s(16)}\n\n"
  end

  def start
    @@running = true
    REG[Registers::RPC] = PC_START
    while running && REG[Registers::RPC] < 0xFFFF_u16
      #debug_info
      execute(MEMORY[REG[Registers::RPC]])
      REG[Registers::RPC] += 1_u16
      #STDIN.gets
    end
  end

  def load_image
    offset = 0_u16
    File.open("program.bin", "rb") do |f|
      until (bytes = f.read_bytes(UInt16)).zero?
        MEMORY[PC_START + offset] = bytes
        offset += 1_u16
      end
    end
  end
end

Lc3Vm.load_image
Lc3Vm.start