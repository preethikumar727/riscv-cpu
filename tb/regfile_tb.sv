`timescale 1ns/1ps

//self checking testbench for regfile.sv

module regfile_tb;

logic clk=0;
logic rst_n, we;
logic [4:0] rs1,rs2,rd;
logic [31:0] rd_data;
logic [31:0] rs1_data, rs2_data;
logic [4:0] idx;

int errors =0;
int tests =0;

regfile uut (
    .clk(clk), .rst_n(rst_n), .we(we),
    .rs1(rs1), .rs2(rs2), .rd(rd), .rd_data(rd_data),
    .rs1_data(rs1_data), .rs2_data(rs2_data)
);

// clock: flips evry 5ns, so one full cycle = 10 ns 
always #5 clk = ~ clk;

// write one register. Inputs change on the falling edge,
// so they are stable when the rising edge saves them.
task write_reg(input [4:0] r, input [31:0] value);
    @(negedge clk);
    we = 1; rd = r; rd_data = value;
    @(negedge clk);
    we = 0;
endtask

// read a register on both ports and compare with the expected value
task check_read(input [4:0] r, input [31:0] expected, input string name);
    rs1 = r; rs2 = r;
    #1;
    tests++;
    if (rs1_data !== expected || rs2_data !== expected) begin
        errors++;
        $display("FAIL %-12s x%0d -> rs1_data=%h rs2_data=%h, expected %h",
                 name, r, rs1_data, rs2_data, expected);
    end else begin
        $display("pass %-12s x%0d = %h", name, r, rs1_data);
    end
endtask

initial begin 
    $dumpfile("regfile.vcd");
    $dumpvars(0, regfile_tb);

// start everything at 0 and reset held active
rst_n = 0; we = 0; rs1 = 0; rs2 = 0; rd = 0; rd_data = 0;
@(negedge clk); @ (negedge clk);
rst_n =1;

// 1. After reset, registers read 0
        check_read(5'd1, 32'd0, "reset");
        check_read(5'd31, 32'd0,"reset");

// 2. Write and read back
        write_reg(5'd1,  32'h12345678);
        check_read(5'd1,  32'h12345678, "write/read");
        write_reg(5'd31, 32'hDEADBEEF);
        check_read(5'd31, 32'hDEADBEEF, "write/read");

// 3. x0 can never be written
        write_reg(5'd0, 32'hFFFFFFFF);
        check_read(5'd0, 32'd0, "x0 is zero");

// 4. No write when we = 0
        @(negedge clk);
        we = 0; rd = 5'd5; rd_data = 32'hAAAAAAAA;
        @(negedge clk);
        check_read(5'd5, 32'd0, "we=0");

// 5. Two ports read different registers at the same time
        write_reg(5'd2, 32'h00000002);
        write_reg(5'd3, 32'h00000003);
        rs1 = 5'd2; rs2 = 5'd3;
        #1;
        tests++;
if (rs1_data !== 32'h2 || rs2_data !== 32'h3) begin
            errors++;
            $display("FAIL  two ports    got %h and %h", rs1_data, rs2_data);
        end else
            $display("pass  two ports    x2 = %h, x3 = %h", rs1_data, rs2_data);

// 6. Overwrite a register
        write_reg(5'd1, 32'h0BADF00D);
        check_read(5'd1, 32'h0BADF00D, "overwrite");

// 7. Bypass: reading a register while it is being written
        //    gives the new value immediately (before the clock edge)
        @(negedge clk);
        we = 1; rd = 5'd7; rd_data = 32'h77777777;
        rs1 = 5'd7;
        #1;
        tests++;
        if (rs1_data !== 32'h77777777) begin
            errors++;
            $display("FAIL  bypass       got %h, expected 77777777", rs1_data);
        end else
            $display("pass  bypass       x7 = %h", rs1_data);
            @(negedge clk);
        we = 0;

// 8. Write every register x1..x31 with a unique value, then read all back
        for (int i = 1; i < 32; i++) begin
            idx = i;
            write_reg(idx, i * 32'h01010101);
        end
        for (int i = 1; i < 32; i++) begin
            idx = i;
            check_read(idx, i * 32'h01010101, "all regs");
        end

        $display("------------------------------");
        if (errors == 0) $display("ALL %0d TESTS PASSED", tests);
        else             $display("%0d of %0d TESTS FAILED", errors, tests);
        $finish;
    end

endmodule
