`timescale 1ns/1ps

// Prepares store data and byte enables
// and extracts/extends loaded bytes and half words

module load_store (
    input logic [1:0] addr_low,        // bottom 2 bits of the address: which byte in the words
    input logic [2:0] funct3,          // size and sign:lb/lh/lw/lbu/lhu, sb/sh/sw
    input logic  mem_write,            // 1 = this is a store(from the control unit)
    input logic [31:0] store_data,     // (from register rs2)
    input logic [31:0] mem_rdata,      // full word read from data memory
    output logic [3:0] be,             // byte enables:which byte slots to write
    output logic [31:0] wdata,         // data sent to memory for a store
    output logic [31:0] load_data      // final 32-bit value for a laod
);

// store

always_comb begin
     be =4'b0000;                // default:write no bytes
     wdata = store_data;         //default:send the full word

     if (mem_write) begin        // only store write memory
     case (funct3)
        3'b000: begin                       // sb: store byte
            be = 4'b0001 << addr_low;       // one enable bit, moved to the chosen byte
            wdata ={4{store_data[7:0]}};    // copy the byte into all 4 slots
        end
        3'b001:begin                                 // sh:store half-word
            be = addr_low[1] ? 4'b1100 : 4'b0011;   // upper half or lower half
            wdata ={2{store_data[15:0]}};           // copy the half-word into both halves
        end
        default: begin                  // sw:store word
            be = 4'b1111;               // write all 4 bytes
            wdata = store_data;         // the full word
        end
     endcase
     end
end 

// loads
logic [7:0] byte_sel;       // the chosen type
logic [15:0] half_sel;      // the chosen half-word

always_comb begin           // pick the byte the address points to
    case (addr_low)
       2'd0: byte_sel = mem_rdata[7:0];
       2'd1: byte_sel = mem_rdata[15:8];
       2'd2: byte_sel = mem_rdata[23:16];
       2'd3: byte_sel = mem_rdata[31:24];
    endcase

    half_sel = addr_low [1] ? mem_rdata[31:16] :        // address ends in 10 : upper half
                              mem_rdata[15:0];          // address ends in 00: lower half

case (funct3)                   // extend to 32 bits
    3'b000: load_data = {{24{byte_sel[7]}}, byte_sel};      // lb: sign-extend byte
    3'b001: load_data = {{16{half_sel[15]}}, half_sel};     // lh: sign-extend half
    3'b100: load_data = {24'd0, byte_sel};                  // lbu: zero-extend byte
    3'b101: load_data = {16'd0, half_sel};                  // lhu: zero-extend half
   default: load_data = mem_rdata;                          // lw: full word
endcase
end
endmodule

