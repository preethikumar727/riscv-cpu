// self checking testbench for alu.sv

module alu_tb;


logic [31:0] a, b;
logic [3:0] alu_ctrl;
logic [31:0] result;
logic zero;

int errors =0;
int tests =0;

alu uut (.a(a), .b(b), .alu_ctrl(alu_ctrl), .result(result), .zero(zero));

// Apply inputs, wait, then compare against the expected answer

task check (input [3:0] op, input [31:0] in_a, input [31:0] in_b, 
            input [31:0] expected, input string name);

alu_ctrl = op;  a = in_a; b = in_b;
#10;
tests++;       // adds 1 to the test counter, so at the end we can report how many test ran

if ( result !== expected) begin
    errors++;
    $display("FAIL  %-5s a=%h b=%h -> got %h, expected %h", name , a, b,result, expected);
end else begin
    $display("pass  %-5s a=%h b=%h -> %h ",  name , a, b,result);
end
endtask

initial begin 
     $dumpfile("alu.vcd");
     $dumpvars(0,alu_tb);

// ADD
//check( op, in_a, in_b, expected , name)

check (4'b0000, 32'd5,  32'd3, 32'd8, "ADD");
check (4'b0000, 32'hFFFFFFFF, 32'd1, 32'd0, "ADD"); //overflow wraps

check(4'b0001, 32'd10,         32'd4,          32'd6,          "SUB");
check(4'b0001, 32'd0,          32'd1,          32'hFFFFFFFF,   "SUB");  // gives -1

// AND / OR / XOR
        check(4'b0010, 32'hF0F0F0F0,   32'hFF00FF00,   32'hF000F000,   "AND");
        check(4'b0011, 32'hF0F0F0F0,   32'h0F0F0F0F,   32'hFFFFFFFF,   "OR");
        check(4'b0100, 32'hAAAAAAAA,   32'hFFFFFFFF,   32'h55555555,   "XOR");
        // SLT (signed): -1 < 1 is true
        check(4'b0101, 32'hFFFFFFFF,   32'd1,          32'd1,          "SLT");
        // SLTU (unsigned): 0xFFFFFFFF < 1 is false
        check(4'b0110, 32'hFFFFFFFF,   32'd1,          32'd0,          "SLTU");
        // Shifts
        check(4'b0111, 32'd1,          32'd4,          32'd16,         "SLL");
        check(4'b1000, 32'h80000000,   32'd4,          32'h08000000,   "SRL");
        check(4'b1001, 32'h80000000,   32'd4,          32'hF8000000,   "SRA");  // keeps sign bit
 
// Zero flag (branches depend on this)
        alu_ctrl = 4'b0001; a = 32'd7; b = 32'd7; #10;
        tests++;
        if (zero !== 1'b1) begin
            errors++;
            $display("FAIL  zero flag should be 1 when 7-7");
        end else
            $display("pass  zero flag");
 
        $display("------------------------------");
        if (errors == 0) $display("ALL %0d TESTS PASSED", tests);
        else             $display("%0d of %0d TESTS FAILED", errors, tests);
        $finish;
    end
 
endmodule




