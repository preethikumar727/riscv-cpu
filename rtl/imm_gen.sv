`timescale 1ns/1ps

// extracts the immediate (constant) from an instruction

module imm_gen (
    input logic [31:0] instr,          // the full 32-bit instruction
    input logic [2:0]  imm_sel,         //which formate : 0 = I-type
    output logic [31:0] imm             // the 32-bit immediate
);

always_comb begin
    case(imm_sel)
    3'd0: imm = {{20{instr[31]}}, instr[31:20]}; // I-type
    3'd1: imm = {{20{instr[31]}}, instr[31:25], instr[11:7]}; // S-Type
    3'd2: imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}; // B-Type
    3'd3: imm = {instr[31:12], 12'b0}; // U-Type
    3'd4: imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21],1'b0}; // J-type

    default: imm =32'd0;
    endcase
end

endmodule

// how it works
// addi x3, x1, 5 (x3 = x1 + 5). The assembler turns it into these 32 bits:
//  31      20 19   15 14 12 11    7 6       0
//[000000000101] [00001] [000] [00011] [0010011]
//immediate=5   rs1=1  funct3  rd=3   opcode
// In hex, that’s 00508193.

// The immediate generator does this:

// instr[31:20] = 000000000101 = 5
// instr[31] = 0 (positive), so 20 copies of 0
// Joined: 00000000000000000000 + 000000000101 = 00000005

// The ALU gets 5 as a full 32-bit number. 

//In hex, that’s 00508193.

//Now take addi x3, x1, -1 (x3 = x1 − 1). In 12-bit two’s complement, −1 is all ones:

// [111111111111] [00001] [000] [00011] [0010011]
// In hex, that’s FFF08193.
// instr[31:20] = 111111111111
// instr[31] = 1 (negative), so 20 copies of 1
// Joined: 11111111111111111111 + 111111111111 = FFFFFFFF
// FFFFFFFF is −1 in 32 bits. ✓