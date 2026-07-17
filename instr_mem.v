// ============================================================
// instr_mem.v
// Holds your program as a simple array, loaded from a text
// file full of hex instruction values (one per line).
// Read-only, combinational (PC changes -> instruction changes
// instantly, no clock needed to "fetch").
// ============================================================

module instr_mem (
    input  wire [31:0] pc,        // program counter - byte address
    output wire [31:0] instr      // instruction at that address
);

    // 256 words = 1KB of instruction memory - plenty for a
    // 10-15 instruction test program with room to spare.
    reg [31:0] mem [0:255];

    // Loads hex values from program.hex into mem[] at time 0,
    // before simulation logic starts running. Each line in
    // program.hex is one 32-bit instruction in hex, e.g. 003100b3
    initial begin
        $readmemh("program.hex", mem);
    end

    // PC is a BYTE address (RISC-V convention - addresses count
    // bytes, not words), but each instruction is 4 bytes, so we
    // divide by 4 (>> 2, a 2-bit right shift) to get the actual
    // array index. This is why RISC-V instructions are always at
    // addresses like 0, 4, 8, 12... never 1, 2, 3.
    assign instr = mem[pc >> 2];

endmodule
