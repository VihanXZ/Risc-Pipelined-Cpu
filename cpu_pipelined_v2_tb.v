// ============================================================
// cpu_pipelined_v2_tb.v
// Same program, same hazard - but this time forwarding should
// fix it. x1 should now come out as 15, correctly.
// ============================================================

`timescale 1ns/1ps

module cpu_pipelined_v2_tb;

    reg clk, rst;

    cpu_pipelined_v2 uut (.clk(clk), .rst(rst));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("cpu_pipelined_v2.vcd");
        $dumpvars(0, cpu_pipelined_v2_tb);
    end

    initial begin
        clk = 0;
        rst = 1;
        #12;
        rst = 0;

        #150;

        $display("---- Results (with forwarding) ----");
        if (uut.rf.registers[2] === 32'd10)
            $display("PASS: x2 = %0d", uut.rf.registers[2]);
        else
            $display("FAIL: x2 expected 10, got %0d", uut.rf.registers[2]);

        if (uut.rf.registers[3] === 32'd5)
            $display("PASS: x3 = %0d", uut.rf.registers[3]);
        else
            $display("FAIL: x3 expected 5, got %0d", uut.rf.registers[3]);

        if (uut.rf.registers[1] === 32'd15)
            $display("PASS: x1 = %0d (10 + 5, forwarded correctly!)", uut.rf.registers[1]);
        else
            $display("FAIL: x1 expected 15, got %0d - forwarding did not fix the hazard", uut.rf.registers[1]);

        if (uut.dmem.mem[0] === 32'd15)
            $display("PASS: mem[0] = %0d (sw correctly stored the forwarded x1 value)", uut.dmem.mem[0]);
        else
            $display("FAIL: mem[0] expected 15, got %0d", uut.dmem.mem[0]);

        if (uut.rf.registers[4] === 32'd15)
            $display("PASS: x4 = %0d (loaded back correctly)", uut.rf.registers[4]);
        else
            $display("FAIL: x4 expected 15, got %0d", uut.rf.registers[4]);

        $display("CPU (with forwarding) testbench finished.");
        $finish;
    end

endmodule
