// the tests cover:
// Every format (I, S, B, U, J), at least twice each.
// Negative numbers for each signed format, to check sign extension.
// Edge cases: the largest positive (2047) and most negative (−2048) I-type values.
// The shuffled bits: bne ... 2048 checks that B-type’s imm[11] comes from instr[7], and jal ... 2048 checks J-type’s imm[11] comes from instr[20]. These are the bits people most often get wrong.
// The default case: an unused imm_sel value gives 0 

`timescale 1ns/1ps

module imm_gen_tb;

logic [31:0] instr;
logic [2:0] imm_sel;
logic [31:0] imm;

int errors = 0;
int tests = 0;

imm_gen uut (.instr(instr), .imm_sel(imm_sel), .imm(imm));

// applying an instruction and format, then compare with the expected immidiate

 task check(input[2:0]sel, input[31:0]in_instr, input [31:0] expected, input string name);
       imm_sel = sel; instr = in_instr;
       #10;
       tests++;
       if (imm !== expected) begin
        errors++;
        $display(" FAIL %-20s instr=%h -> got %h, expected %h", name, instr, imm, expected);
       end else begin 
        $display("PASS %-20s instr=%h -> imm=%h", name, instr,imm);
       end
 endtask

 initial begin
    $dumpfile("imm_gen.vcd");
    $dumpvars(0, imm_gen_tb);

    // I-type (imm_sel = 0): addi, loads, jalr
    check(3'd0, 32'h00508193, 32'h00000005, "addi x3,x1,5");
        check(3'd0, 32'hFFF08193, 32'hFFFFFFFF, "addi x3,x1,-1");     // negative
        check(3'd0, 32'h7FF12203, 32'h000007FF, "lw x4,2047(x2)");    // largest positive
        check(3'd0, 32'h80030293, 32'hFFFFF800, "addi x5,x6,-2048");  // most negative
// S-type (imm_sel = 1): stores
        check(3'd1, 32'h00552423, 32'h00000008, "sw x5,8(x10)");
        check(3'd1, 32'hFE552E23, 32'hFFFFFFFC, "sw x5,-4(x10)");     // negative

        // B-type (imm_sel = 2): branches
        check(3'd2, 32'h00208863, 32'h00000010, "beq x1,x2,16");
        check(3'd2, 32'hFE208CE3, 32'hFFFFFFF8, "beq x1,x2,-8");      // backward (loop)
        check(3'd2, 32'h004190E3, 32'h00000800, "bne x3,x4,2048");    // tests imm[11] = instr[7]

        // U-type (imm_sel = 3): lui, auipc
        check(3'd3, 32'h123453B7, 32'h12345000, "lui x7,0x12345");
        check(3'd3, 32'hFFFFF3B7, 32'hFFFFF000, "lui x7,0xFFFFF");

        // J-type (imm_sel = 4): jal
        check(3'd4, 32'h001000EF, 32'h00000800, "jal x1,2048");       // tests imm[11] = instr[20]
        check(3'd4, 32'hFFDFF0EF, 32'hFFFFFFFC, "jal x1,-4");         // backward
        check(3'd4, 32'h344120EF, 32'h00012344, "jal x1,0x12344");    // tests imm[19:12]

        // Unused imm_sel value gives 0 (the default branch)
        check(3'd7, 32'hFFFFFFFF, 32'h00000000, "default (sel=7)");

        $display("------------------------------");
        if (errors == 0) $display("ALL %0d TESTS PASSED", tests);
        else             $display("%0d of %0d TESTS FAILED", errors, tests);
        $finish;
 end
endmodule