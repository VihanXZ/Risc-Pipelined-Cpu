// ============================================================
// data_mem_tb.v
// ============================================================

`timescale 1ns/1ps

module data_mem_tb;

    reg         clk;
    reg  [31:0] addr, write_data;
    reg         mem_read, mem_write;
    wire [31:0] read_data;

    data_mem uut (
        .clk(clk),
        .addr(addr),
        .write_data(write_data),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .read_data(read_data)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("data_mem.vcd");
        $dumpvars(0, data_mem_tb);
    end

    initial begin
        clk = 0;
        mem_read = 0; mem_write = 0;
        addr = 0; write_data = 0;

        // sw: store 99 at address 12 (word index 3, since 12 >> 2 = 3)
        @(negedge clk);
        addr = 32'd12;
        write_data = 32'd99;
        mem_write = 1;

        // stop writing, now try to read the same address back (lw)
        @(negedge clk);
        mem_write = 0;
        mem_read  = 1;
        addr      = 32'd12;

        #1;
        if (read_data === 32'd99)
            $display("PASS: sw then lw at addr 12 -> read_data = %0d", read_data);
        else
            $display("FAIL: expected 99, got %0d", read_data);

        // check an address we never wrote to is still 0
        @(negedge clk);
        addr = 32'd40;
        #1;
        if (read_data === 32'd0)
            $display("PASS: untouched address correctly reads 0");
        else
            $display("FAIL: untouched address expected 0, got %0d", read_data);

        #10;
        $display("Data memory testbench finished.");
        $finish;
    end

endmodule
