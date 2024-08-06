require "./instructions"

class Compiler
  PROGRAM = [
    0xF026,    # 1111 0000 0010 0110             TRAP trp_in_u16  ;read an uint16_t from stdin and put it in R0
    0x1220,    # 0001 0010 0010 0000             ADD R1,R0,x0     ;add contents of R0 to R1
    0xF026,    # 1111 0000 0010 0110             TRAP trp_in_u16  ;read an uint16_t from stdin and put it in R0
    0x1240,    # 0001 0010 0010 0000             ADD R1,R1,R0     ;add contents of R0 to R1
    0x1060,    # 0001 0000 0110 0000             ADD R0,R1,x0     ;add contents of R1 to R0
    0xF027,    # 1111 0000 0010 0111             TRAP trp_out_u16;show the contents of R0 to stdout
    0xF025     # 1111 0000 0010 0101             HALT             ;halt
  ] of UInt16
  
  def compile(out_file_path : String) : Void
    File.open(out_file_path, "wb") do |f|
      PROGRAM.each do |instruction|
        f.write_bytes(instruction, IO::ByteFormat::LittleEndian)
      end
      f.write_bytes(0)
    end
  end
end

Compiler.new.compile("program.bin")