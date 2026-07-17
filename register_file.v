// ============================================================
// register_file.v
// 32 registers, each 32 bits wide (this is x0 - x31 in RISC-V)
// 2 read ports (rs1, rs2) because most instructions read TWO
// source registers at once (e.g. add x1, x2, x3 reads x2 and x3)
// 1 write port (rd) because an instruction writes at most ONE
// result back
// ============================================================

module register_file (
    input  wire        clk,        // clock - writes happen on rising edge
    input  wire        rst,        // reset - clears all registers to 0

    input  wire [4:0]  rs1_addr,   // which register to read (port 1) - 5 bits because 2^5 = 32 registers
    input  wire [4:0]  rs2_addr,   // which register to read (port 2)
    output wire [31:0] rs1_data,   // value read out from rs1_addr
    output wire [31:0] rs2_data,   // value read out from rs2_addr

    input  wire [4:0]  rd_addr,    // which register to write into
    input  wire [31:0] rd_data,    // value to write
    input  wire        rd_wen      // write-enable: only write if this is 1
);

    // The actual storage: 32 registers, each 32 bits.
    // Think of this as an array reg[0] ... reg[31]
    reg [31:0] registers [0:31];

    integer i;

    // ------------------------------------------------------
    // WRITE logic (synchronous - only happens on clock edge)
    // ------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            // On reset, clear every register to 0
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;
        end
        else if (rd_wen && rd_addr != 5'b0) begin
            // Only write if write-enable is high.
            // rd_addr != 0 check: in RISC-V, register x0 is
            // hardwired to always be zero - writes to it are
            // silently ignored. This is a real RISC-V rule,
            // not an extra feature you're adding.
            registers[rd_addr] <= rd_data;
        end
    end

    // ------------------------------------------------------
    // READ logic (combinational - happens instantly, no clock)
    // Reading is NOT clocked because the ID stage needs the
    // values immediately within the same cycle it decodes
    // the instruction.
    // ------------------------------------------------------
    assign rs1_data = (rs1_addr == 5'b0) ? 32'b0 : registers[rs1_addr];
    assign rs2_data = (rs2_addr == 5'b0) ? 32'b0 : registers[rs2_addr];

endmodule
