// ============================================================
// imm_gen.v
// Takes the full 32-bit instruction, figures out its format
// from the opcode, and reassembles the immediate value into
// one clean, sign-extended 32-bit number.
// Combinational - no clock, reacts instantly.
// ============================================================

module imm_gen (
    input  wire [31:0] instr,      // full instruction
    output reg  [31:0] imm_out     // reassembled, sign-extended immediate
);

    localparam OP_ITYPE  = 7'b0010011; // addi, andi, ori
    localparam OP_LOAD   = 7'b0000011; // lw (also I-type format)
    localparam OP_STORE  = 7'b0100011; // sw
    localparam OP_BRANCH = 7'b1100011; // beq, bne

    wire [6:0] opcode = instr[6:0];

    always @(*) begin
        case (opcode)

            // --------------------------------------------
            // I-type: immediate is one contiguous 12-bit
            // field at instr[31:20]. Sign-extend by
            // replicating bit 31 (the sign bit) 20 times.
            // --------------------------------------------
            OP_ITYPE, OP_LOAD: begin
                imm_out = {{20{instr[31]}}, instr[31:20]};
            end

            // --------------------------------------------
            // S-type: immediate is split across two chunks
            // because rs2's bit position [24:20] has to stay
            // the same across R/I/S formats for the hardware
            // that reads rs2 to be reusable without a mux
            // deciding "where is rs2 this time". The tradeoff
            // is the immediate gets split instead.
            //   upper 7 bits -> instr[31:25]
            //   lower 5 bits -> instr[11:7]
            // --------------------------------------------
            OP_STORE: begin
                imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end

            // --------------------------------------------
            // B-type: immediate encodes a branch OFFSET in
            // instruction-pairs (always even), so bit 0 is
            // never stored - it's implicitly 0. The bits are
            // also reordered in the instruction (again, to
            // keep other fields aligned the same way across
            // formats) and must be reassembled in this exact
            // order:
            //   instr[31]    -> imm[12]  (sign bit)
            //   instr[7]     -> imm[11]
            //   instr[30:25] -> imm[10:5]
            //   instr[11:8]  -> imm[4:1]
            //   imm[0] is always 0 (not stored)
            // --------------------------------------------
            OP_BRANCH: begin
                imm_out = {{19{instr[31]}}, instr[31], instr[7],
                           instr[30:25], instr[11:8], 1'b0};
            end

            default: begin
                imm_out = 32'b0;
            end

        endcase
    end

endmodule
