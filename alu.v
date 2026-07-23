// ============================================================
// alu.v
// The calculator of the CPU. Pure combinational logic:
// no clock, no memory, output reacts instantly to input changes.
// Takes two 32-bit numbers + an operation code, produces a
// 32-bit result and a "zero" flag (used later for branches).
// ============================================================

module alu (
    input  wire [31:0] a,          // first operand
    input  wire [31:0] b,          // second operand
    input  wire [3:0]  alu_op,     // operation select code
    output reg  [31:0] result,     // the answer
    output wire   zero        // 1 if result == 0 (used for beq/bne later)
);

    // Operation codes - just labels we're choosing ourselves.
    // The control unit  will set alu_op to one of
    // these based on the instruction it decodes.
    localparam ALU_ADD  = 4'b0000; // here localparam is basically used to give a easy to remeber or meaningful name to a specific value(such as 4'b0000 in this case)
    localparam ALU_SUB  = 4'b0001;// also this name is valid only within this file
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_SLT  = 4'b0100;  // set-less-than: result = 1 if a < b, else 0

    // always @(*) means: re-run this block instantly whenever
    // ANY signal on the right-hand side changes. This is what
    // makes it combinational (no clock needed).
    always @(*) begin
        case (alu_op)
            ALU_ADD: result = a + b;
            ALU_SUB: result = a - b;
            ALU_AND: result = a & b;
            ALU_OR:  result = a | b;
            ALU_SLT: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            // $signed() tells Verilog to treat these as signed
            // (two's complement) numbers for the comparison -
            // RISC-V's slt instruction compares signed values.
            default: result = 32'b0;
        endcase
    end

    // zero flag: 1 exactly when result is all zeros.
    // Later, beq (branch if equal) will compute a-b through the
    // ALU and check this flag - if a-b == 0, then a == b.
    assign zero = (result == 32'b0);

endmodule
