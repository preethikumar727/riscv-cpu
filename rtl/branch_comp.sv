`timescale 1ns/1ps

module branch_comp (
    input logic [31:0] a,           // value of register rs1
    input logic [31:0] b,           // value of the regidter rs2
    input logic [2:0] funct3,       // which branch (beq,bne,blt..)
    output logic take               // 1= condition true, so jump
);
always_comb begin
    case(funct3)
    3'b000 : take = (a == b) ;                           // beq: jump if equal
    3'b001 : take = (a != b);                            // bne: jump if not equal
    3'b100 : take = ($signed(a) < $signed(b)) ;          // blt: jump if less (signed)
    3'b101 : take = ($signed(a) >= $signed(b));          // bge: jump if greater or equal (signed)
    3'b110 : take = (a < b);                             // bltu: jump is less (unsigned)
    3'b111 : take = (a >= b);                            // bgeu: jump if greater or equal (unsigned)
    default: take = 1'b0;                               // 010, 011 are not branch: never jump
    endcase
end
endmodule
   