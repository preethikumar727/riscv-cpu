`timescale 1ns/1ps

module branch_comp_tb;
    logic [31:0] a, b;
    logic [2:0] funct3;
    logic take;

    int errors = 0;
    int tests = 0;

    branch_comp uut (.a(a), .b(b), .funct3(funct3), .take(take));

// appling inputs, wait, and compare take with expected answer

    task check(input [2:0] f3, input [31:0] in_a, input [31:0] in_b,
               input expected, input string name);
        funct3 = f3; a = in_a; b = in_b;
        #10;
        tests++;
        if (take !== expected) begin
            errors++;
            $display("FAIL  %-22s a=%h b=%h -> take=%b, expected %b", name, a, b, take, expected);
        end else begin
            $display("pass  %-22s a=%h b=%h -> take=%b", name, a, b, take);
        end
    endtask

    initial begin
        $dumpfile("branch_comp.vcd");
        $dumpvars(0, branch_comp_tb);        // recording all signals

// funct3       a       b                       take            name
        check(3'b000, 32'd5,        32'd5 ,       1, "beq 5 == 5");           // equal: jump
        check(3'b000, 32'd5,        32'd3,        0, "beq  5 == 3");          // not equal: no jump
        check(3'b001, 32'd5,        32'd3,        1, "bne  5 != 3");          // not equal: jump
        check(3'b001, 32'd5,        32'd5,        0, "bne  5 != 5");          // equal: no jump
        check(3'b100, 32'hFFFFFFFF, 32'd1,        1, "blt  -1 < 1");          // signed: -1 is smaller
        check(3'b100, 32'd1,        32'hFFFFFFFF, 0, "blt  1 < -1");          // signed: 1 is bigger
        check(3'b101, 32'd1,        32'hFFFFFFFF, 1, "bge  1 >= -1");         // signed: true
        check(3'b101, 32'd5,        32'd5,        1, "bge  5 >= 5");          // equal counts as >=
        check(3'b110, 32'hFFFFFFFF, 32'd1,        0, "bltu 0xFFFFFFFF < 1");  // unsigned: huge, so false
        check(3'b110, 32'd1,        32'hFFFFFFFF, 1, "bltu 1 < 0xFFFFFFFF");  // unsigned: true
        check(3'b111, 32'hFFFFFFFF, 32'd1,        1, "bgeu 0xFFFFFFFF >= 1"); // unsigned: true
        check(3'b111, 32'd3,        32'd5,        0, "bgeu 3 >= 5");          // false
        check(3'b010, 32'd5,        32'd5,        0, "invalid funct3");       // not a branch: never jump

$display("------------------------------");
        if (errors == 0) $display("ALL %0d TESTS PASSED", tests);
        else             $display("%0d of %0d TESTS FAILED", errors, tests);
        $finish;                            // end the simulation
    end

endmodule