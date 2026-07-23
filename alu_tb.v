// ============================================================
// alu_tb.v
// Tests every operation the ALU supports, plus the zero flag.
// Same overall pattern as register_file_tb.v: drive inputs,
// wait, check outputs, print PASS/FAIL.
// ============================================================

`timescale 1ns/1ps

module alu_tb;

    reg  [31:0] a, b;   // "reg"  these are the values that the testbench will control
    reg  [3:0]  alu_op;
    wire [31:0] result;// while these are the values that the alu file will give us
    wire        zero;

    // Same operation codes as in alu.v - kept in sync manually
    // since this is a separate file (the real design will later
    // share these via a common header/package, but for now this
    // is fine).
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_SLT  = 4'b0100;

    alu uut (
        .a(a),
        .b(b),
        .alu_op(alu_op),
        .result(result),
        .zero(zero)
    );

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, alu_tb);
    end

    // Helper task: runs one test case and prints PASS/FAIL.
    // Using a task avoids repeating the same check logic 6 times. it is basically like a function in other programming languages
    task run_test;
        input [31:0] in_a, in_b;
        input [3:0]  op;
        input [31:0] expected;
        input [127:0] name; // just used to print a readable label
        begin
            a = in_a; b = in_b; alu_op = op;
            #1; // let combinational logic settle
            if (result === expected)
                $display("PASS: %0s -> result = %0d", name, result);
            else
                $display("FAIL: %0s -> expected %0d, got %0d", name, expected, result);
        end
    endtask

    initial begin
        // ADD: 15 + 10 = 25
        run_test(32'd15, 32'd10, ALU_ADD, 32'd25, "ADD");

        // SUB: 15 - 10 = 5
        run_test(32'd15, 32'd10, ALU_SUB, 32'd5, "SUB");

        // SUB that gives zero, to also check the zero flag: 10 - 10 = 0
        a = 32'd10; b = 32'd10; alu_op = ALU_SUB;
        #1;
        if (zero === 1'b1)
            $display("PASS: zero flag correctly set when result is 0");
        else
            $display("FAIL: zero flag should be 1 when result is 0");

        // AND: 4'b1100 & 4'b1010 = 4'b1000 = 8
        run_test(32'd12, 32'd10, ALU_AND, 32'd8, "AND");

        // OR: 4'b1100 | 4'b1010 = 4'b1110 = 14
        run_test(32'd12, 32'd10, ALU_OR, 32'd14, "OR");

        // SLT: 3 < 5 -> should be 1
        run_test(32'd3, 32'd5, ALU_SLT, 32'd1, "SLT (true case)");

        // SLT: 5 < 3 -> should be 0
        run_test(32'd5, 32'd3, ALU_SLT, 32'd0, "SLT (false case)");

        #10;
        $display("ALU testbench finished.");
        $finish;
    end

endmodule
