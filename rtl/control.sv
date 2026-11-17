`timescale 1ns/1ps

// main control unit for the RV32I
// Reads the instruction and produces the control signals for every block.

module control(
    input logic[31:0] instr,         // the full instruction
    output logic     reg_write,     // 1= write result into rd
    output logic [2:0] imm_sel,     //immediate format: 0=I, 1=S, 2=B, 3=U, 4=J
    output logic [1:0] alu_a_sel,   // ALU input A: 0=rs1 , 1=Pc, 2=zero
    output logic       alu_b_sel,   // ALU input B: 0=rs2, 1=immediate
    output logic [3:0] alu_ctrl,    // ALU operation
    output logic mem_read,          // 1 =load
    output logic mem_write,         // 1= store
    output logic [1:0] wb_sel,     // write-back: 0= ALU , 1=memory, 2=PC+4
    output logic  branch,           // 1= branch instruction
    output logic jal,     //1=jal, jump to a fixed place, save retur addres
    output logic jalr,    //1= jalr,jumpy to the adress in a register
    output logic halt     //1=ecall(stop the program)
);

// Instruction feilds 

logic [6:0] opcode;
logic [2:0] funct3;
logic     funct7_5;         // name of one single bit of the instruction bit30

assign opcode = instr[6:0];
assign funct3 = instr[14:12];
assign funct7_5 = instr[30];

// opcodes

localparam OP_R = 7'b0110011;
localparam OP_I = 7'b0010011;
localparam OP_LOAD = 7'b0000011;
localparam OP_STORE = 7'b0100011;
localparam OP_BRANCH = 7'b1100011;
localparam OP_JAL = 7'b1101111;
localparam OP_JALR = 7'b1100111;
localparam OP_LUI = 7'b0110111;    // load upper immediate
localparam OP_AUIPC = 7'b0010111;  // add upper immediate to PC
localparam OP_SYSTEM = 7'b1110011;  // system instructions

// ALU codes

localparam ALU_ADD = 4'b0000;
localparam ALU_SUB = 4'b0001;
localparam ALU_AND = 4'b0010;
localparam ALU_OR = 4'b0011;
localparam ALU_XOR = 4'b0100;
localparam ALU_SLT = 4'b0101;    // 1 if a < b (signed), else 0
localparam ALU_SLTU  = 4'b0110;  // 1 if a < b (unsigned), else 0
localparam ALU_SLL  = 4'b0111;   // a shifted left by b
localparam ALU_SRL  = 4'b1000;   // a shifted right by b, fill with 0's
localparam ALU_SRA  = 4'b1001;   // a shifted right by b, fill with sign bit

// OTHER SELECT CODES

localparam IMM_I = 3'd0, IMM_S =3'd1, IMM_B = 3'd2, IMM_U = 3'd3, IMM_J = 3'd4;     // imm_select values
localparam A_RS1 = 2'd0, A_PC = 2'd1, A_ZERO = 2'd2;            // alu_a_sel values
localparam B_RS2 = 1'b0, B_IMM = 1'b1;                          //alu_b_sel values
localparam WB_ALU = 2'd0, WB_MEM = 2'd1, WB_PC4 = 2'd2;         // we_sel values


// ALU operation for R-Type and I-TYPE math

logic [3:0] alu_funct;            // alu operation choosen by funct3

always_comb begin 
    case(funct3)
        3'b000: alu_funct = (opcode == OP_R && funct7_5) ? ALU_SUB : ALU_ADD;       // sub only for R-type with bit 30 = 1
        3'b001: alu_funct = ALU_SLL;  // sll, slli
        3'b010: alu_funct = ALU_SLT;  // slt, slti
        3'b011: alu_funct = ALU_SLTU; // sltu, sltiu
        3'b100: alu_funct = ALU_XOR;  // xor, xori
        3'b101: alu_funct = funct7_5 ? ALU_SRA : ALU_SRL; // bit 30 =1 : sra/srai , else srl/srli
        3'b110: alu_funct = ALU_OR;  // or, ori
        3'b111: alu_funct = ALU_AND;  // and, andi
        default: alu_funct = ALU_ADD;  //safety default (never actaually reached)
    endcase
end

// main decoder

always_comb begin
    
    // each case below only changes the signals that differ from these

    reg_write = 1'b0;               // do not write any register
    imm_sel = IMM_I;                // any format is fin when unused
    alu_a_sel = A_RS1;              // ALU =input A = rs1
    alu_b_sel = B_RS2;              // ALU input B = rs2
    alu_ctrl = ALU_ADD;             // ALU adds (used by loads, stores, jalr, lui, auipc)
    mem_read = 1'b0 ;                // no memory read
    mem_write = 1'b0 ;               // no memory erite
    wb_sel = WB_ALU;                // write-back source = ALU result
    branch = 1'b0 ;    // not a branch
    jal = 1'b0;
    jalr = 1'b0;
    halt = 1'b0;       // don't stop

  case(opcode)

  OP_R: begin                   // add x3, x1, x2 (rd =rs1 op rs2)
    reg_write = 1'b1;           // result goes into rd
    alu_ctrl = alu_funct;       // operation chosen by funct3 / bit 30
  end
  
  OP_I:begin                    // addi x3, x1, 5 (rd =rs1 op imm)
    reg_write = 1'b1;           // result goes into rd
    alu_b_sel = B_IMM;          // second values goes into rd
    alu_ctrl = alu_funct;       // operation chosen by funct3/bit 30
  end

  OP_LOAD: begin                // lw x4, 8(x2) (rd=memory[rs1+imm])
    reg_write = 1'b1;           // loaded value goes into rd
    alu_b_sel = B_IMM;          // ALU computes address = rs1 +imm
    mem_read = 1'b1;            // read from data memory
    wb_sel = WB_MEM;             // rd gets the data from memory, not the ALU
  end

  OP_STORE:begin                // sw x5, 8(x10) (memory[rs1+imm]=rs2)
    imm_sel = IMM_S;            // S-Type immediate (splt in two pieces)
    alu_b_sel = B_IMM;          // ALU computes address = rs1 +imm
    mem_write = 1'b1;           // write rs2 into data memory
  end                           // reg_write stays 0: stores don't write a register

  OP_BRANCH: begin              // beq x1, x2, label (if condition, PC =PC + imm)
    imm_sel = IMM_B;            // B -type immediate (branch distance)
    branch = 1'b1;              // tell the PC logic this is a branch
  end                           // reg_write stays 0: branches don't write a register

  OP_JAL: begin                 // jal x1, label (rd = PC + 4,PC = rs1 + imm)
    reg_write = 1'b1;           // save the return address
    imm_sel = IMM_J;            // ALU computes target = rs1 + imm
    wb_sel = WB_PC4;            // rd gets PC +4 (the return address)
    jal = 1'b1;                 // tell the PC logic to jump to the ALU result
  end

  OP_JALR: begin                // jalr x0, 0(x1) (rd = PC +4, PC = rs1 + imm)
    reg_write = 1'b1;           // save the return address
    alu_b_sel = B_IMM;          // ALU computes target = rs1 + imm
    wb_sel = WB_PC4;            // rd gets PC +4 ( the return address)
    jalr = 1'b1;                // tell the PC to jump to thr alu result
  end
  
  OP_LUI: begin                 // lui x7, 0x12345 (rd = imm << 12)
    reg_write = 1'b1;           // result goes into rd
    imm_sel = IMM_U;            // U-type immediate (upper 20 bits)
    alu_a_sel = A_ZERO;         // ALU input A= 0
    alu_b_sel = B_IMM;          // ALU input B= immediate, so result = 0 + imm
  end

  OP_AUIPC: begin                 // auipc x7, 0x1 (rd = PC + (imm << 12))
    reg_write = 1'b1;             // result goes into rd
    imm_sel = IMM_U;              // U-type immediate (upper 20 bits)
    alu_a_sel = A_PC;             // ALU input A =PC
    alu_b_sel = B_IMM;            // ALU input B = immediate, so result = PC + imm
  end

  OP_SYSTEM: begin
    if (funct3 == 3'b000 && instr[31:20] == 12'd0)          // all zeros in bits 31-20 means ecall
            halt = 1'b1;                // ecall: stop the program(ebreak does nothing)
  end   

  default: ;

endcase
end 
endmodule



