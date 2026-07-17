// ============================================================
// register_file_tb.v
// Testbench = a piece of code that is NOT synthesizable hardware.
// Its only job is to feed inputs into your module and check
// that the outputs are what you expect. Think of it as a
// unit test written in Verilog.
// ============================================================

`timescale 1ns/1ps
// This line means: 1 time-unit in this file = 1 nanosecond,
// with 1 picosecond precision. Needed for #delay statements below.

module register_file_tb;

    // These match the module's ports. reg = you drive it,
    // wire = the module drives it and you just observe it.
    reg         clk;
    reg         rst;
    reg  [4:0]  rs1_addr, rs2_addr, rd_addr;
    reg  [31:0] rd_data;
    reg         rd_wen;
    wire [31:0] rs1_data, rs2_data;

    // Instantiate (create one copy of) the module under test.
    // This connects our testbench signals to its ports.
    register_file uut (
        .clk(clk),
        .rst(rst),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .rd_wen(rd_wen)
    );

    // ------------------------------------------------------
    // Clock generator: toggle clk every 5ns -> 10ns period
    // -> 100MHz clock. This block runs forever.
    // ------------------------------------------------------
    always #5 clk = ~clk;

    // ------------------------------------------------------
    // Waveform dump - this is what lets GTKWave show you
    // the signals. Without these two lines, no .vcd file
    // is produced and there's nothing to view.
    // ------------------------------------------------------
    initial begin
        $dumpfile("register_file.vcd");
        $dumpvars(0, register_file_tb);
    end

    // ------------------------------------------------------
    // The actual test sequence
    // ------------------------------------------------------
    initial begin
        // 1) Initialize everything and reset
        clk = 0;
        rst = 1;
        rd_wen = 0;
        rs1_addr = 0; rs2_addr = 0; rd_addr = 0; rd_data = 0;
        #12;              // hold reset for a bit more than one clock period
        rst = 0;

        // 2) Write the value 100 into register x5
        @(negedge clk);   // change inputs safely away from the clock edge
        rd_addr = 5'd5;
        rd_data = 32'd100;
        rd_wen  = 1;

        // 3) Write the value 250 into register x10
        @(negedge clk);
        rd_addr = 5'd10;
        rd_data = 32'd250;
        rd_wen  = 1;

        // 4) Stop writing, now try to read both back
        @(negedge clk);
        rd_wen   = 0;
        rs1_addr = 5'd5;   // should read 100
        rs2_addr = 5'd10;  // should read 250

        #1; // small delay so the combinational read settles before we check
        if (rs1_data === 32'd100)
            $display("PASS: x5 read back as %0d", rs1_data);
        else
            $display("FAIL: x5 expected 100, got %0d", rs1_data);

        if (rs2_data === 32'd250)
            $display("PASS: x10 read back as %0d", rs2_data);
        else
            $display("FAIL: x10 expected 250, got %0d", rs2_data);

        // 5) Try to write to x0 - this MUST be ignored (RISC-V rule)
        @(negedge clk);
        rd_addr = 5'd0;
        rd_data = 32'd999;
        rd_wen  = 1;

        @(negedge clk);
        rd_wen   = 0;
        rs1_addr = 5'd0;
        #1;
        if (rs1_data === 32'd0)
            $display("PASS: x0 stayed 0 even after attempted write");
        else
            $display("FAIL: x0 expected 0, got %0d", rs1_data);

        #20;
        $display("Testbench finished.");
        $finish;
    end

endmodule
