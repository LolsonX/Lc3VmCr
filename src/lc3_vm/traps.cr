module Lc3Vm
  TRAPS_VECTOR = [ 
    Traps.get_char,
    Traps.put_char,
    Traps.puts_word,
    Traps.get_char_echo,
    Traps.puts_byte,
    Traps.halt,
    Traps.get_word,
    Traps.put_word
  ]

  module Traps
    extend self

    def get_char
      ->{ REG[Registers::R0] = STDIN.raw do
        (STDIN.read_byte || 0).to_u16 
      end}
    end

    def put_char : Proc(Void)
      ->{ STDOUT.print(REG[Registers::R0]) }
    end

    def puts_word
      ->{
        address = REG[Registers::R0]
        until MEMORY[address].zero?
          STDOUT.print(MEMORY[address])
          address += 1
        end
      }
    end

    def get_char_echo
      ->{ STDOUT.print(REG[Registers::R0] = (STDIN.raw { STDIN.read_byte } || 0).to_u16) }
    end

    def puts_byte
      ->{
        address = REG[Registers::R0]
        loop do
          msb, lsb = read_bytes(MEMORY[address])
          break if msb.zero?
          STDOUT.print(msb)
          break if lsb.zero?
          STDOUT.print(lsb)
          address += 1
        end
      }
    end

    def halt
      ->{ Lc3Vm.stop }
    end

    def get_word
      ->{ REG[Registers::R0] = STDIN.raw { (STDIN.read_bytes(UInt16) || 0).to_u16}}
    end

    def put_word
      ->{ STDOUT.print(REG[Registers::R0]) }
    end

    def read_bytes(word)
      [(MEMORY[word] & 0xF0) >> 4, MEMORY[word] & 0x0F]
    end
  end
end