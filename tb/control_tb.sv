`timescale 1ns/1ps

module control_tb;

// Signal connected to the control unit

logic [31:0] instr;
logic reg_write;
logic [2:0] imm_sel;
logic [1:0] alu_a_sel;
logic alu_b_sel;
logic [3:0] alu_ctrl;
logic mem_read;
logic mem_write;
logic [1:0] wb_sel;
logic branch;
logic jal;
logic jalr;
logic halt;

int errors =0;
int tests =0;

// creating the control unit and connecting every port
control uut (
    .instr(instr),
    .reg_write(reg_write), .imm_sel(imm_sel),
    .alu_a_sel(alu_a_sel), .alu_b_sel(alu_b_sel), .alu_ctrl(alu_ctrl),
    .mem_read(mem_read),   .mem_write(mem_write), .wb_sel(wb_sel),
    .branch(branch), .jal(jal), .jalr(jalr), .halt(halt)
    );

// check task:apply one instruction, compare all 12 outputs

task check(input [31:0] in_instr,       // the instruction to test
               input string name,           // a label for printing
               input       e_rw,            // expected reg_write
               input [2:0] e_imm,           // expected imm_sel
               input [1:0] e_a,             // expected alu_a_sel
               input       e_b,             // expected alu_b_sel
               input [3:0] e_alu,           // expected alu_ctrl
               input       e_mr,            // expected mem_read
               input       e_mw,            // expected mem_write
               input [1:0] e_wb,            // expected wb_sel
               input       e_br,            // expected branch
               input       e_jal,           // expected jal
               input       e_jalr,          // expected jalr
               input       e_halt);         // expected halt
        instr = in_instr;                   // give the instruction to the control unit
        #10;                                // wait for the outputs to settle
        tests++;                            // count this test


 if ({reg_write, imm_sel, alu_a_sel, alu_b_sel, alu_ctrl, mem_read, mem_write,
             wb_sel, branch, jal, jalr, halt} !==
            {e_rw, e_imm, e_a, e_b, e_alu, e_mr, e_mw, e_wb, e_br, e_jal, e_jalr, e_halt}) begin

errors++;                       // if something did not match

$display("FAIL  %-18s", name);  // show which instruction failed
$display(" got:  rw=%b imm=%0d a=%0d b=%b alu=%0d mr=%b mw=%b wb=%0d br=%b jal=%b jalr=%b halt=%b",
                     reg_write, imm_sel, alu_a_sel, alu_b_sel, alu_ctrl,
                     mem_read, mem_write, wb_sel, branch, jal, jalr, halt);

$display(" expected: rw=%b imm=%0d a=%0d b=%b alu=%0d mr=%b mw=%b wb=%0d br=%b jal=%b jalr=%b halt=%b",
                     e_rw, e_imm, e_a, e_b, e_alu, e_mr, e_mw, e_wb, e_br, e_jal, e_jalr, e_halt);
end else begin
            $display("pass  %-18s", name);  // everything matched
        end
    
endtask

// tests

//   imm: 0=I 1=S 2=B 3=U 4=J        a: 0=rs1 1=PC 2=zero      b: 0=rs2 1=imm
    //   alu: 0=ADD 1=SUB 2=AND 4=XOR 9=SRA                    wb: 0=ALU 1=memory 2=PC+4


initial begin
    $dumpfile("control.vcd");           // waveform file
    $dumpvars(0, control_tb);           // record every signal

//.            instruction      name                rw imm a  b alu    mr mw wb br jl jr ht
// R-type math: write rd, ALU input B = register

        check(32'h002081B3, "add x3,x1,x2",     1, 0, 0, 0, 4'd0, 0, 0, 0, 0, 0, 0, 0);
        check(32'h402081B3, "sub x3,x1,x2",     1, 0, 0, 0, 4'd1, 0, 0, 0, 0, 0, 0, 0);  // bit 30 = 1 → SUB
        check(32'h0020C1B3, "xor x3,x1,x2",     1, 0, 0, 0, 4'd4, 0, 0, 0, 0, 0, 0, 0);  // funct3 = 100
        check(32'h4020D1B3, "sra x3,x1,x2",     1, 0, 0, 0, 4'd9, 0, 0, 0, 0, 0, 0, 0);  // funct3 = 101, bit 30 = 1

// I-type math: write rd, ALU input B = immediate
        check(32'h00508193, "addi x3,x1,5",     1, 0, 0, 1, 4'd0, 0, 0, 0, 0, 0, 0, 0);
        check(32'h40008193, "addi x3,x1,1024",  1, 0, 0, 1, 4'd0, 0, 0, 0, 0, 0, 0, 0);  // bit 30 = 1 but must stay ADD
        check(32'h4040D193, "srai x3,x1,4",     1, 0, 0, 1, 4'd9, 0, 0, 0, 0, 0, 0, 0);  // bit 30 = 1 → SRA
        check(32'h00F0F193, "andi x3,x1,15",    1, 0, 0, 1, 4'd2, 0, 0, 0, 0, 0, 0, 0);  // funct3 = 111

        // Load: read memory, rd gets memory data
        check(32'h00852203, "lw x4,8(x10)",     1, 0, 0, 1, 4'd0, 1, 0, 1, 0, 0, 0, 0);

        // Store: write memory, no register write
        check(32'h00152423, "sw x1,8(x10)",     0, 1, 0, 1, 4'd0, 0, 1, 0, 0, 0, 0, 0);

        // Branch: B-type immediate, branch = 1, nothing written
        check(32'h00208863, "beq x1,x2,16",     0, 2, 0, 0, 4'd0, 0, 0, 0, 1, 0, 0, 0);

        // Jumps: rd gets PC + 4 (return address)
        check(32'h028000EF, "jal x1,40",        1, 4, 0, 0, 4'd0, 0, 0, 2, 0, 1, 0, 0);
        check(32'h00008067, "jalr x0,0(x1)",    1, 0, 0, 1, 4'd0, 0, 0, 2, 0, 0, 1, 0);

        // Upper immediates
        check(32'h123452B7, "lui x5,0x12345",   1, 3, 2, 1, 4'd0, 0, 0, 0, 0, 0, 0, 0);  // A = zero → 0 + imm
        check(32'h00001297, "auipc x5,0x1",     1, 3, 1, 1, 4'd0, 0, 0, 0, 0, 0, 0, 0);  // A = PC → PC + imm

        // System and others
        check(32'h00000073, "ecall",            0, 0, 0, 0, 4'd0, 0, 0, 0, 0, 0, 0, 1);  // halt = 1
        check(32'h00100073, "ebreak",           0, 0, 0, 0, 4'd0, 0, 0, 0, 0, 0, 0, 0);  // does nothing
        check(32'h0FF0000F, "fence",            0, 0, 0, 0, 4'd0, 0, 0, 0, 0, 0, 0, 0);  // does nothing

        // ---------- Summary ----------
        $display("------------------------------");
        if (errors == 0) $display("ALL %0d TESTS PASSED", tests);
        else             $display("%0d of %0d TESTS FAILED", errors, tests);
        $finish;                            // end the simulation
    end

endmodule


