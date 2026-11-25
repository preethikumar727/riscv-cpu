`timescale 1ns/1ps

// single-cycle RV32I CPU: connects all the blocks together

module riscv_core (
    input  logic        clk,          // clock
    input  logic        rst_n,        // reset, active low
    output logic [31:0] imem_addr,    // address of the instruction to fetch (the PC)
    input  logic [31:0] imem_rdata,   // instruction from instruction memory
    output logic [31:0] dmem_addr,    // data memory address
    output logic [31:0] dmem_wdata,   // data to store
    input  logic [31:0] dmem_rdata,   // data loaded from memory
    output logic        dmem_we,      // 1 = store
    output logic [3:0]  dmem_be,      // byte enables for stores
    output logic        halt          // 1 = ecall reached, program finished
);

// Internals wires 

logic [31:0] pc, pc_next, pc_plus4, pc_target, jalr_target;         //proram counter values
logic [31:0] instr;                           //current instruction
logic [31:0] rs1_data, rs2_data;              // values raed from registers
logic [31:0] imm;                             // immediate from the instruction
logic [31:0] alu_a, alu_b, alu_result;        //ALU inputs and output
logic [31:0] load_data;                       //values from a load, after extension
logic [31:0] wb_data;                         //  value written back to rd
logic br_take;                                // 1 = branchcondition is true


// control signals (outputs of the control unit)
logic reg_write , alu_b_sel, mem_read, mem_write, branch, jal, jalr;
logic [2:0] imm_sel;
logic [1:0] alu_a_sel, wb_sel;
logic [3:0] alu_ctrl;

// FETCH: PC and instruction
always_ff @(posedge clk) begin          //the PC is a register
if (!rst_n) 
    pc <= 32'd0;                         // reset:start at address 0
else if (!halt)                         // each clock: move to the next instruction
    pc <= pc_next;                      // (once halted , the PC stops)
end

assign imem_addr = pc;                  // ask instruction memory for thr instruction at PC
assign instr = imem_rdata;             // the instruction that comes back

//DECODE: control, register, immediate
control u_control (                     // like a manger : decodes the instruction
        .instr(instr),
        .reg_write(reg_write), .imm_sel(imm_sel),
        .alu_a_sel(alu_a_sel), .alu_b_sel(alu_b_sel),.alu_ctrl(alu_ctrl),
        .mem_read(mem_read),.mem_write(mem_write), .wb_sel(wb_sel),
        .branch(branch),.jal(jal), .jalr(jalr), .halt(halt)
);

regfile #(.BYPASS (0)) u_regfile (          //32 registers , bypass OFF for single-cyle
.clk(clk), .rst_n(rst_n),
.we(reg_write),                             // write only whencontrol says so
.rs1(instr[19:15]),                         // rs1 number: bits 19-15
.rs2(instr[24:20]),                         // rs2 number: bits 24-20
.rd(instr[11:7]),                           // rd number: bits 11- 7
.rd_data(wb_data),                           // value to write : from the writeback selector
.rs1_data(rs1_data), .rs2_data(rs2_data)        
);

imm_gen u_imm_gen (                  // pulls out the immediate
    .instr(instr), . imm_sel(imm_sel), .imm(imm)
);

// EXECUTE: ALU and branch comparator
always_comb begin
    case(alu_a_sel)
    2'd1: alu_a = pc;               //auipc: PC +imm
    2'd2: alu_a = 32'd0;            // lui: 0 + imm
    default : alu_a = rs1_data;     // everything else:rs1
    endcase
end 

assign alu_b = alu_b_sel ? imm : rs2_data;      //ALU input B selector:imediate or rs2

alu u_alu (                                         // does the caluculation
    .a(alu_a), .b(alu_b), . alu_ctrl(alu_ctrl),
    .result(alu_result), .zero()                    // zero flag not needed (branch_comp is used)
);

branch_comp u_branch_comp (                    // decides if a branch jumps
      .a(rs1_data), .b(rs2_data), .funct3(instr[14:12]), .take(br_take)
);

// Memory: load/store unit
load_store u_load_store (
    .addr_low(alu_result[1:0]),         // Which byte in the word
    .funct3(instr[14:12]),              // size and sign
    .mem_write(mem_write),             // is this a store
    .store_data(rs2_data),             // stores write the value of rs2
    .mem_rdata(dmem_rdata),            // word from data memory
    .be(dmem_be), .wdata(dmem_wdata),  // to data memory
    .load_data(load_data)              // extended load result
);

assign dmem_addr = alu_result;          // load/stores: rs1 + imm (from the ALU)
assign dmem_we = mem_write;             // write memoryonly for stores

// Writeback selector
always_comb begin
    case(wb_sel)
    2'd1: wb_data = load_data;          //loads: data from memory
    2'd2: wb_data = pc_plus4;           //jal/jalr: return address
    default: wb_data = alu_result;      //everything else :ALU result
    endcase
end

// Next PC
assign pc_plus4 = pc + 32'd4;       // the next instruction in order
assign pc_target = pc + imm;        // branch and jal target
assign jalr_target = {alu_result[31:1], 1'b0}; // jalr target =rs1 + imm, lowest bit cleared

always_comb begin
    if (jalr)
        pc_next = jalr_target;
    else if (jal || (branch && br_take))
        pc_next = pc_target;
    else 
        pc_next = pc_plus4;
end
endmodule