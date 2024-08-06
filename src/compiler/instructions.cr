module Instructions
    extend self
  
    def add_imm(dr : UInt16, src1 : UInt16, val : UInt16) : UInt16
      dr = dr << 9
      src1 = src1 << 6
      val = val & 0x001F
      (0x1000 | dr | src1 | val | 1_u16 << 5).to_u16
    end
  
    def add_reg(dr : UInt16, src1 : UInt16, src2 : UInt16) : UInt16
      dr = dr << 9
      src1 = src1 << 6
      src2 = src2 & 0x0007
      (0x1000 | dr | src1 | src2).to_u16
    end
  
    def and_imm(dr : UInt16, src1 : UInt16, val : UInt16) : UInt16
      dr = dr << 9
      src1 = src1 << 6
      val = val & 0x001F
      (0x5000 | dr | src1 | val | 1_u16 << 5).to_u16
    end
  
    def and_reg(dr : UInt16, src1 : UInt16, src2 : UInt16) : UInt16
      dr = dr << 9
      src1 = src1 << 6
      (0x5000 | dr | src1 | src2).to_u16
    end
  
    def load(dr : UInt16, offset : UInt16) : UInt16
      dr = dr << 9
      offset = offset & 0x01FF_u16
      (0x2000_u16 | dr | offset).to_u16
    end
  
    def load_indirect(dr : UInt16, offset : UInt16) : UInt16
      dr = dr << 9
      offset = offset & 0x01FF_u16
      (0xA000_u16 | dr | offset).to_u16
    end
  
    def load_from_register(dr : UInt16, baser : UInt16, offset : UInt16) : UInt16
      dr = dr << 9
      baser = baser << 6
      (0x6000 | dr | baser | offset).to_u16
    end
  
    def load_effective_address(dr : UInt16, offset : UInt16) : UInt16
      dr = dr << 9
      offset = offset & 0x00FF
      (0xE000 | dr | offset).to_u16
    end
  
    def not(dr : UInt16, src : UInt16) : UInt16
      dr = dr << 9
      src = src << 6
      (0x9000 | dr | src).to_u16
    end
  
    def store(source : UInt16, offset : UInt16) : UInt16
      source = source << 9
      offset = offset & 0x01FF
      (0x3000 | source | offset).to_u16
    end
  
    def store_indirect(source : UInt16, offset : UInt16) : UInt16
      source = source << 9
      offset = offset & 0x01FF
      (0xB000 | source | offset).to_u16
    end
  
    def store_from_register(source : UInt16, baser : UInt16, offset : UInt16) : UInt16
      source = source << 9
      baser = baser << 6
      offset = offset & 0x003F
      (0x7000 | source | baser | offset).to_u16
    end
  
    def jump(baser : UInt16) : UInt16
      baser = baser << 6
      (0xC000 | baser ).to_u16
    end
  
    def jump_to_subroutine_direct(baser : UInt16) : UInt16
      baser = baser << 6
      (0x4000 | baser ).to_u16
    end
  
    def jump_to_subroutine_offset(offset : UInt16) : UInt16
      offset = 0x07FF & offset
      (0x4800 | offset ).to_u16
    end
  
    def branch(condition : UInt16, offset : UInt16)
      condition = condition << 9
      offset = offset & 0x1FFF
      (0x0000 | condition | offset).to_u16
    end
  
    def trap(vector_num : UInt16) : UInt16
      (0xF020 | vector_num).to_u16
    end
  end