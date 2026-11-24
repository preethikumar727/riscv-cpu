`timescale 1ns/1ps

// 32 * 32 bit register file for an RV32I RVSC-V processor
// 2 read ports(rs1, rs2): combinational no clock needed
// 1 write port(rd): writes on the rising edge ,when we = 1
// x0 alwayss 0 and can never be written
//synchronous reset (active low) clears all the registers


module regfile # (parameter BYPASS = 1 )(       // BYPASS =1 for the pipeline , 0 for single-cycle
    input logic         clk,
    input logic         rst_n,          //reset, active low -reset when when signal is 0
    input logic         we,             // write enable
    input logic [4:0]   rs1,           // number of first register to read
    input logic [4:0]   rs2,           // number of second register to read
    input logic [4:0]    rd,           // number of register to write
    input logic [31:0]   rd_data,       // value to write into rd
    output logic [31:0]   rs1_data,       // value stored in rs1
    output logic [31:0]   rs2_data       // value stored in rs2
);

// 32 registers, each 32 bits wide

logic [31:0] regs [31:0];

///// write port- sequential logic //////

always_ff @(posedge clk) begin
    if (!rst_n) begin
        for (int i =0; i< 32; i++)
        regs[i] <=32'd0;                        //reset:clear every register
    end else if (we && (rd != 5'd0)) begin      // checking rd (destination is not equal to x0)
       regs[rd] <= rd_data;                         //never write to x0
    end
    end

///// read port -combinational logic /////
// Register x0 always reads as 0
// bypass: if the same regisster is being written right now,
// return the new value (needed later by the pipeline)
// otherwise, return the stored value
// conditional operator: condition ? vaule_if_true : value_if_false

 assign rs1_data = (rs1 == 5'd0)                    ? 32'd0   :
                      (BYPASS && we && (rd == rs1))    ? rd_data :
                                                         regs[rs1];

assign rs2_data = (rs2 == 5'd0)                    ? 32'd0   :
                      (BYPASS && we && (rd == rs2))    ? rd_data :
                                                         regs[rs2];


endmodule


