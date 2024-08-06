require "./spec_helper"

describe Lc3Vm do
  describe "add" do
    context "when adding is immiedate" do
      destination_register = Lc3Vm::Registers::R0.value
      source_register = Lc3Vm::Registers::R1.value
      it "stores result in correct register" do
        setup_registries(dst: destination_register, src1: source_register)
        value = 1_u16
        instruction = InstructionHelper.add_imm(destination_register, source_register, value)
        Lc3Vm.execute(instruction)
        Lc3Vm::REG[destination_register].should eq(value)
        reset
      end

      it "adds two positve numbers correctly" do
        setup_registries(destination_register, source_register, val1: 1_u16)
        value = 1_u16
        instruction = InstructionHelper.add_imm(destination_register, source_register, value)
        Lc3Vm.execute(instruction)
        Lc3Vm::REG[destination_register].should eq(Lc3Vm::REG[source_register] + value)
        reset
      end

      it "adds two negative value correctly" do
        setup_registries(destination_register, src1: source_register, val1: UInt16::MAX)
        value = UInt16::MAX # -1 - value is 5 bit long not 16 bits
        instruction = InstructionHelper.add_imm(destination_register, source_register, value)
        Lc3Vm.execute(instruction)
        Lc3Vm::REG[destination_register].to_i16!.should eq(-2)
        reset
      end

      it "adds positive and negative value correctly" do
        setup_registries(destination_register, src1: source_register, val1: UInt16::MAX)
        value = 1_u16
        instruction = InstructionHelper.add_imm(destination_register, source_register, value)
        Lc3Vm.execute(instruction)
        Lc3Vm::REG[destination_register].to_i16!.should eq(0)
        reset
      end
    end

    context "when adding is between 2 registers" do

      destination_register = Lc3Vm::Registers::R0.value
      source_register = Lc3Vm::Registers::R1.value
      source2_register = Lc3Vm::Registers::R2.value

      it "stores result in correct register" do
        setup_registries(destination_register, src1: source_register, src2: source2_register, 
                         val1: 2_u16, val2: 1_u16)
        instruction = InstructionHelper.add_reg(destination_register, source_register, source2_register)
        Lc3Vm.execute(instruction)
        Lc3Vm::REG[destination_register].should eq(Lc3Vm::REG[source_register] + Lc3Vm::REG[source2_register])
        reset
      end
    end
  end

  describe "and" do
    context "when and is performed in immiedate" do
      destination_register = Lc3Vm::Registers::R0.value
      source_register = Lc3Vm::Registers::R1.value
      it "stores result in correct register" do
        setup_registries(destination_register, src1: source_register,
                         val1: 0_u16, dst_val: 0_u16)
        value = 1_u16
        instruction = InstructionHelper.and_imm(destination_register, source_register, value)
        Lc3Vm.execute(instruction)
        Lc3Vm::REG[destination_register].should eq(value & Lc3Vm::REG[source_register])
        reset
      end
    end

    context "when and is performed between 2 registers" do
      destination_register = Lc3Vm::Registers::R0.value
      source_register = Lc3Vm::Registers::R1.value
      source2_register = Lc3Vm::Registers::R2.value

      it "stores result in correct register" do
        setup_registries(destination_register, src1: source_register, src2: source2_register, 
                         val1: 2_u16, val2: 1_u16)
        instruction = InstructionHelper.and_reg(destination_register, source_register, source2_register)
        Lc3Vm.execute(instruction)
        Lc3Vm::REG[destination_register].should eq(Lc3Vm::REG[source_register] & Lc3Vm::REG[source2_register])
        reset
      end
    end
  end

  describe "load" do
    context "when loading directly" do
      destination_register = Lc3Vm::Registers::R0.value
      offset = 1_u16
      address = Lc3Vm::REG[Lc3Vm::Registers::RPC] + offset
      value = 10_u16
      it "gets value from memory" do
        Lc3Vm::MEMORY[address] = value
        instruction = InstructionHelper.load(destination_register, offset)
        Lc3Vm.execute(instruction)
        Lc3Vm::REG[destination_register].should eq(value)
        reset
      end
    end

    context "when loading indirectly" do
      destination_register = Lc3Vm::Registers::R0.value
      offset = 1_u16
      address = Lc3Vm::REG[Lc3Vm::Registers::RPC] + offset
      mem_point = 10_u16
      value = 11_u16
      it "gets value from memory" do
        Lc3Vm::MEMORY[address] = mem_point
        Lc3Vm::MEMORY[mem_point] = value
        instruction = InstructionHelper.load_indirect(destination_register, offset)
        Lc3Vm.execute(instruction)
        Lc3Vm::REG[destination_register].should eq(value)
        reset
      end
    end

    context "when loading relativly to register" do
      destination_register = Lc3Vm::Registers::R0.value
      baser = Lc3Vm::Registers::R1.value
      offset = 1_u16
      it "gets value from memory" do
        Lc3Vm::REG[baser] = 10_u16
        Lc3Vm::MEMORY[Lc3Vm::REG[baser] + offset] = 10_u16
        instruction = InstructionHelper.load_from_register(destination_register, baser, offset)
        Lc3Vm.execute(instruction)
        Lc3Vm::REG[destination_register].should eq(10_u16)
        reset
      end
    end

    context "when loading effective address" do
      destination_register = Lc3Vm::Registers::R0.value
      starting_point = 0x3000_u16
      offset = 1_u16
      it "gets value from memory" do
        Lc3Vm::REG[Lc3Vm::Registers::RPC] = starting_point
        instruction = InstructionHelper.load_effective_address(destination_register, offset)
        Lc3Vm.execute(instruction)
        Lc3Vm::REG[destination_register].should eq(starting_point + offset)
        reset
      end
    end
  end

  describe "not" do
    destination_register = Lc3Vm::Registers::R0.value
    source_register = Lc3Vm::Registers::R1.value

    it "negates all bits" do
      Lc3Vm::REG[source_register] = 0_u16
      instruction = InstructionHelper.not(destination_register, source_register)
      Lc3Vm.execute(instruction)
      Lc3Vm::REG[destination_register].should eq(UInt16::MAX)
      reset
    end
  end

  describe "st" do
    source_register = Lc3Vm::Registers::R1.value

    it "stores data from registry in memory RPC + offset" do
      rpc = 0x3000_u16
      Lc3Vm::REG[source_register] = 1_u16
      Lc3Vm::REG[Lc3Vm::Registers::RPC] = rpc
      offset = 1_u16
      instruction = InstructionHelper.store(source_register, offset)
      Lc3Vm.execute(instruction)
      Lc3Vm::MEMORY[rpc + offset].should eq(1_u16)
      reset
    end
  end

  describe "sti" do
    source_register = Lc3Vm::Registers::R1.value

    it "stores data from registry in memory address read from RPC + OFFSET" do
      rpc = 0x3000_u16
      offset = 1_u16
      Lc3Vm::REG[source_register] = 1_u16
      Lc3Vm::REG[Lc3Vm::Registers::RPC] = rpc
      Lc3Vm::MEMORY[rpc + offset] = 10_u16
      instruction = InstructionHelper.store_indirect(source_register, offset)
      Lc3Vm.execute(instruction)
      Lc3Vm::MEMORY[10_u16].should eq(1_u16)
      reset
    end
  end

  describe "str" do
    source_register = Lc3Vm::Registers::R1.value
    baser = Lc3Vm::Registers::R2.value

    it "stores data from registry in memory BASER + offset" do
      baser_value = 0x2000_u16
      offset = 1_u16
      Lc3Vm::REG[source_register] = 1_u16
      Lc3Vm::REG[baser] = baser_value
      Lc3Vm::MEMORY[baser_value + offset] = 10_u16
      instruction = InstructionHelper.store_from_register(source_register, baser, offset)
      Lc3Vm.execute(instruction)
      Lc3Vm::MEMORY[baser_value + offset].should eq(1_u16)
      reset
    end
  end

  describe "jmp" do
    baser = Lc3Vm::Registers::R2.value

    it "stores data from registry in RPC" do
      baser_value = 0x2000_u16
      Lc3Vm::REG[baser] = baser_value
      instruction = InstructionHelper.jump(baser)
      Lc3Vm.execute(instruction)
      Lc3Vm::REG[Lc3Vm::Registers::RPC].should eq(baser_value)
      reset
    end
  end

  describe "jsr" do
    context "when offset mode" do
      it "stores correct data in RPC" do
        Lc3Vm::REG[Lc3Vm::Registers::RPC] = 0x0007_u16
        offset = 0x0600_u16
        instruction = InstructionHelper.jump_to_subroutine_offset(offset)
        Lc3Vm.execute(instruction)
        Lc3Vm::REG[Lc3Vm::Registers::RPC].should eq(offset)
        reset
      end

      it "stores source address in R7" do
        Lc3Vm::REG[Lc3Vm::Registers::RPC] = 0x0007_u16
        offset = 0x0600_u16
        instruction = InstructionHelper.jump_to_subroutine_offset(offset)
        Lc3Vm.execute(instruction)
        Lc3Vm::REG[Lc3Vm::Registers::R7].should eq(0x0007_u16)
        reset
      end
    end

    context "when baser mode" do
      baser = Lc3Vm::Registers::R1.value
      it "stores correct data in RPC" do
        Lc3Vm::REG[Lc3Vm::Registers::RPC] = 0x0007_u16
        baser_value = 0x2000_u16
        Lc3Vm::REG[baser] = baser_value
        instruction = InstructionHelper.jump_to_subroutine_direct(baser)
        Lc3Vm.execute(instruction)
        Lc3Vm::REG[Lc3Vm::Registers::RPC].should eq(baser_value)
        reset
      end

      it "stores source address in R7" do
        Lc3Vm::REG[Lc3Vm::Registers::RPC] = 0x0007_u16
        baser_value = 0x2000_u16
        Lc3Vm::REG[baser] = baser_value
        instruction = InstructionHelper.jump_to_subroutine_direct(baser)
        Lc3Vm.execute(instruction)
        Lc3Vm::REG[Lc3Vm::Registers::R7].should eq(0x0007_u16)
        reset
      end
    end
  end

  describe "br" do
    context "when condition is met" do
      it "changes RPC" do
        Lc3Vm::REG[Lc3Vm::Registers::RPC] = 0x3000_u16
        Lc3Vm::REG[Lc3Vm::Registers::RCND] = 1_u16
        condition = 1_u16
        offset = 1_u16
        instruction = InstructionHelper.branch(condition, offset)
        Lc3Vm.execute(instruction)
        Lc3Vm::REG[Lc3Vm::Registers::RPC].should eq(offset)
        reset
      end
    end
    
    context "when_condition is not met" do
      it "does not change RPC" do
        Lc3Vm::REG[Lc3Vm::Registers::RPC] = 0x3000_u16
        Lc3Vm::REG[Lc3Vm::Registers::RCND] = 0_u16
        condition = 1_u16
        offset = 1_u16
        instruction = InstructionHelper.branch(condition, offset)
        Lc3Vm.execute(instruction)
        Lc3Vm::REG[Lc3Vm::Registers::RPC].should eq(0x3000_u16)
        reset
      end
    end
  end
end
