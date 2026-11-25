`timescale 1ns/1ps

module cpu_tb;

// signals connected to the CPU

logic clk =0;                            // clcok starts at 0
logic rst_n;                            // reset, active low
logic [31:0] imem_addr, imem_rdata;     // instruction memory port
logic [31:0] dmem_addr, dmem_wdata, dmem_rdata; // data memory port
logic dmem_we;               // 1 = store 
logic [3:0] dmem_be;         // byte enables
logic halt;                  // 1 = ecall reached   

// The two memories ( 4KB each)

logic [31:0] imem [0:1023];     // instruction memory:1024 words
logic [31:0] dmem [0:1023];     // data memory:1024 words (addresses 0x2000-0x2FFF)

int errors = 0;     // failes checks
int tests = 0;      // all checks
int cycles = 0;     // clock cycles the program took

// THE CPU
riscv_core uut (
    .clk(clk), .rst_n(rst_n),
    .imem_addr(imem_addr), .imem_rdata(imem_rdata),
    .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata), .dmem_rdata(dmem_rdata),
    .dmem_we(dmem_we), .dmem_be(dmem_be),
    .halt(halt)
);

always #5 clk = ~ clk;          // 10ns clock = 100MHz

// Memory behavior behaviour
// [11:2] turns a byte address into a word number (divide by 4, keep 10 bits)

assign imem_rdata = imem[imem_addr[11:2]];      // instruction read: instant
assign dmem_rdata = dmem[dmem_addr[11:2]];      //data read: instant

always @(posedge clk) begin             // data write on the clock edge
    if (dmem_we) begin                  // only for stores
        if (dmem_be[0])
            dmem[dmem_addr[11:2]][7:0] <= dmem_wdata[7:0];        //box 0
        if (dmem_be[1])
            dmem[dmem_addr[11:2]][15:8] <= dmem_wdata[15:8];      //box 1
        if (dmem_be[2])
            dmem[dmem_addr[11:2]][23:16] <= dmem_wdata[23:16];    //box 2
        if (dmem_be[3])
            dmem[dmem_addr[11:2]][31:24] <= dmem_wdata[31:24];    //box 3    
    end
end

// check tasks

task check_reg(input int r, input [31:0] expected, input string name);
        tests++;
        if (uut.u_regfile.regs[r] !== expected) begin       // look inside the register file
            errors++;
            $display("FAIL  x%-2d %-22s got %h, expected %h", r, name, uut.u_regfile.regs[r], expected);
        end else
            $display("pass  x%-2d %-22s = %h", r, name, expected);
    endtask

    task check_mem(input int word, input [31:0] expected, input string name);
        tests++;
        if (dmem[word] !== expected) begin
            errors++;
            $display("FAIL  mem %-22s got %h, expected %h", name, dmem[word], expected);
        end else
            $display("pass  mem %-22s = %h", name, expected);
    endtask

// ---------------- The test ----------------
    initial begin
        $dumpfile("cpu.vcd");                   // waveform file
        $dumpvars(0, cpu_tb);                   // record all signals

    for (int i = 0; i < 1024; i++) begin    // start both memories at 0
            imem[i] = 32'd0;
            dmem[i] = 32'd0;
        end
$readmemh("programs/test_basic.hex", imem);   // load the program

        rst_n = 0;                              // hold reset for 2 cycles
        repeat (2) @(negedge clk);
        rst_n = 1;     

// run until ecall, with a timeout so a broken CPU can't hang forever
        while (halt !== 1'b1 && cycles < 10000) begin
            @(posedge clk);                     // one clock = one instruction
            #1;                                 // let signals settle after the edge
            cycles++;
        end

 if (halt !== 1'b1) begin
            $display("TIMEOUT: program never reached ecall (PC = %h)", imem_addr);
            errors++;
        end else
            $display("Program finished after %0d cycles (PC = %h)", cycles, imem_addr);

$display("------------------------------");
        //        reg  expected       what it tests
        check_reg(0,  32'h00000000, "x0 always zero");
        check_reg(1,  32'h00000074, "jal return addr");
        check_reg(2,  32'h00000003, "addi");
        check_reg(3,  32'h0000000D, "add");
        check_reg(4,  32'h00000007, "sub");
        check_reg(5,  32'h00000002, "and");
        check_reg(6,  32'h0000000B, "or");
        check_reg(7,  32'h00000009, "xor");
        check_reg(8,  32'h00000001, "slt");
        check_reg(9,  32'h00000050, "sll");
        check_reg(10, 32'hFFFFFFF8, "addi negative");
        check_reg(11, 32'hFFFFFFFC, "srai");
        check_reg(12, 32'h0000000F, "srli");
        check_reg(13, 32'h00002000, "lui");
        check_reg(14, 32'h0000000D, "sw then lw");
        check_reg(15, 32'hFFFFFFF8, "sb then lb");
        check_reg(16, 32'h000000F8, "sb then lbu");
        check_reg(17, 32'h0000000F, "loop sum 5+4+3+2+1");
        check_reg(18, 32'h00000000, "loop counter");
        check_reg(19, 32'h00000000, "skipped by beq");
        check_reg(20, 32'h0000002A, "function ran");
        check_reg(21, 32'h00000007, "returned from jalr");
        check_reg(22, 32'h00000078, "auipc");
        check_reg(23, 32'hFFFFFFF8, "sh then lh");
        check_reg(24, 32'h0000FFF8, "sh then lhu");

//        word expected       what it tests
        check_mem(0, 32'h0000000D, "0x2000 (sw)");
        check_mem(1, 32'h000000F8, "0x2004 (sb)");
        check_mem(2, 32'h0000FFF8, "0x2008 (sh)");

        $display("------------------------------");
        if (errors == 0) $display("ALL %0d TESTS PASSED", tests);
        else             $display("%0d of %0d TESTS FAILED", errors, tests);
        $finish;
    end

endmodule
