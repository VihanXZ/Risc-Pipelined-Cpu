// ============================================================
// instr_mem_tb.v
// Checks that instr_mem correctly loads program.hex and
// returns the right instruction for a given PC value.
// Needs program.hex added as a separate file alongside this
// testbench (see note below).
// ============================================================

`timescale 1ns/1ps

module instr_mem_tb;

    reg  [31:0] pc;
    wire [31:0] instr;

    instr_mem uut (
        .pc(pc),
        .instr(instr)
    );

    initial begin
        $dumpfile("instr_mem.vcd");
        $dumpvars(0, instr_mem_tb);
    end

    initial begin
        // PC=0 -> first instruction: add x1,x2,x3 -> 0x003100b3
        pc = 32'd0;
        #1;
        if (instr === 32'h003100b3)
            $display("PASS: PC=0 -> instr = %h (add x1,x2,x3)", instr);
        else
            $display("FAIL: PC=0 -> expected 003100b3, got %h", instr);

        // PC=4 -> second instruction (next word, since each
        // instruction is 4 bytes): addi x2,x0,10 -> 0x00a00113
        pc = 32'd4;
        #1;
        if (instr === 32'h00a00113)
            $display("PASS: PC=4 -> instr = %h (addi x2,x0,10)", instr);
        else
            $display("FAIL: PC=4 -> expected 00a00113, got %h", instr);

        #10;
        $display("Instruction memory testbench finished.");
        $finish;
    end

endmodule
