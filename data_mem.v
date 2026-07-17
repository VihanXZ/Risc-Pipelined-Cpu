// ============================================================
// data_mem.v
// Where lw and sw actually operate. Same array-of-registers
// pattern as register_file.v: synchronous write, combinational
// read - for exactly the same reasons as before (write commits
// on a clock edge like real hardware, but a read must be
// available instantly within the same cycle it's requested).
// ============================================================

module data_mem (
    input  wire        clk,
    input  wire [31:0] addr,       // byte address (from ALU: rs1 + immediate)
    input  wire [31:0] write_data, // value to store (sw) - comes from rs2
    input  wire        mem_read,   // 1 = this is a lw
    input  wire        mem_write,  // 1 = this is a sw
    output wire [31:0] read_data   // value loaded (lw)
);

    // 256 words = 1KB of data memory, same size reasoning as
    // instruction memory - plenty for a small test program.
    reg [31:0] mem [0:255];

    integer i;
    initial begin
        // Start all-zero rather than random/undefined, so your
        // first lw tests are predictable instead of garbage.
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'b0;
    end

    // ------------------------------------------------------
    // WRITE (sw) - synchronous, only commits on clock edge,
    // only if mem_write is actually asserted by the control unit.
    // ------------------------------------------------------
    always @(posedge clk) begin
        if (mem_write)
            mem[addr >> 2] <= write_data;
    end

    // ------------------------------------------------------
    // READ (lw) - combinational. Note this ALWAYS outputs
    // whatever is at that address, even for non-load
    // instructions - it's mem_to_reg (from the control unit)
    // that decides later whether this value actually gets
    // used or ignored. mem_read isn't strictly needed to
    // gate this read in a design this simple, but it's kept
    // as an input since a real memory (especially one with
    // side effects, like memory-mapped I/O) would use it.
    // ------------------------------------------------------
    assign read_data = mem[addr >> 2];

endmodule
