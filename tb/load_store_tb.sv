`timescale 1ns/1ps

module load_store_tb;

    // signals connected to the load/store unit

    logic [1:0] addr_low;        // which box(byte) in the word
    logic [2:0] funct3;         // size and sign
    logic mem_write;            // 1 = store
    logic [31:0] store_data;    // value to store
    logic [31:0] mem_rdata;    // word comng from memeory
    logic [3:0] be;            // byte enables (output)
    logic [31:0] wdata;        // data to memory (output)
    logic [31:0] load_data;    // loaded value (output)

    int errors = 0;         // failed tests
    int tests = 0;          // all tests

load_store uut (                // create and connect the unnit 
    .addr_low(addr_low), .funct3(funct3), .mem_write(mem_write),
    .store_data(store_data), .mem_rdata(mem_rdata), 
    .be(be), .wdata(wdata), .load_data(load_data)
);

// store check

task check_store (input [2:0] f3, input [1:0] addr, input we,
                   input [3:0] exp_be, input [31:0] exp_wdata, input string name);
    funct3 = f3; 
    addr_low = addr;
    mem_write = we;
    #10;
    tests++;
    if (be !== exp_be || wdata !== exp_wdata) begin         // either one wrong
    errors++;
    $display("FAIL  %-16s be=%b wdata=%h, expected be=%b wdata=%h",
                     name, be, wdata, exp_be, exp_wdata);
        end else
            $display("pass  %-16s be=%b wdata=%h", name, be, wdata);
endtask

// laod check

task check_load (input [2:0] f3, input [1:0]addr,
                 input [31:0]expected , input string name);
    funct3 = f3;
    addr_low = addr;
    mem_write = 0;
    #10;
    tests++;
    if (load_data !== expected) begin
        errors++;
    $display("FAIL  %-16s got %h, expected %h", name, load_data, expected);
    end else
    $display("pass  %-16s load_data=%h", name, load_data);
endtask   

initial begin 
    $dumpfile("load_store.vcd");
    $dumpvars(0, load_store_tb);

// ---------- Stores: value 0x1234ABCD from the register ----------
        store_data = 32'h1234ABCD;          // byte = CD, half-word = ABCD
        mem_rdata  = 32'h0;                 // not used for stores

        //          funct3  box   we  be       wdata          name
        check_store(3'b010, 2'd0, 1, 4'b1111, 32'h1234ABCD, "sw  box 0");    // all 4 boxes
        check_store(3'b000, 2'd0, 1, 4'b0001, 32'hCDCDCDCD, "sb  box 0");    // only box 0
        check_store(3'b000, 2'd2, 1, 4'b0100, 32'hCDCDCDCD, "sb  box 2");    // only box 2
        check_store(3'b000, 2'd3, 1, 4'b1000, 32'hCDCDCDCD, "sb  box 3");    // only box 3
        check_store(3'b001, 2'd0, 1, 4'b0011, 32'hABCDABCD, "sh  lower");    // boxes 1, 0
        check_store(3'b001, 2'd2, 1, 4'b1100, 32'hABCDABCD, "sh  upper");    // boxes 3, 2
        check_store(3'b010, 2'd0, 0, 4'b0000, 32'h1234ABCD, "not a store");  // we = 0: no boxes

// ---------- Loads: memory word 0x88442211 ----------
        mem_rdata = 32'h88442211;           // box3=88 box2=44 box1=22 box0=11

        //         funct3  box   expected       name
        check_load(3'b010, 2'd0, 32'h88442211, "lw  box 0");     // whole word
        check_load(3'b000, 2'd3, 32'hFFFFFF88, "lb  box 3");     // 88 is negative: fill with F
        check_load(3'b000, 2'd1, 32'h00000022, "lb  box 1");     // 22 is positive: fill with 0
        check_load(3'b100, 2'd3, 32'h00000088, "lbu box 3");     // unsigned: always fill with 0
        check_load(3'b100, 2'd0, 32'h00000011, "lbu box 0");     // box 0
        check_load(3'b001, 2'd2, 32'hFFFF8844, "lh  upper");     // 8844 is negative: fill with F
        check_load(3'b001, 2'd0, 32'h00002211, "lh  lower");     // 2211 is positive: fill with 0
        check_load(3'b101, 2'd2, 32'h00008844, "lhu upper");     // unsigned: fill with 0

        $display("------------------------------");
        if (errors == 0) $display("ALL %0d TESTS PASSED", tests);
        else             $display("%0d of %0d TESTS FAILED", errors, tests);
        $finish;
    end

endmodule