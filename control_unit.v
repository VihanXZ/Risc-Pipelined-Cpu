// ============================================================
// control_unit.v
// The decision-maker of the CPU. Pure combinational logic
// (no clock) - just like the ALU, it reacts instantly to the
// opcode/funct3/funct7 bits coming from the instruction.
//
// Supports this instruction subset:
//   R-type : add, sub, and, or, slt      (opcode 0110011)
//   I-type : addi, andi, ori             (opcode 0010011)
//   load   : lw                          (opcode 0000011)
//   store  : sw                          (opcode 0100011)
//   branch : beq, bne                    (opcode 1100011)
// ============================================================

module control_unit (
    input  wire [6:0] opcode,      // instruction[6:0]
    input  wire [2:0] funct3,      // instruction[14:12]
    input  wire       funct7_5,    // instruction[30] - the ONE bit that
                                    // distinguishes add (0) from sub (1)

    output reg        reg_write,   // 1 = this instruction writes a register
    output reg        alu_src,     // 0 = ALU's 2nd input is rs2 (register)
                                    // 1 = ALU's 2nd input is the mmediate integer
    output reg        mem_read,    // 1 = read from data memory (lw)
    output reg        mem_write,   // 1 = write to data memory (sw)
    output reg        mem_to_reg,  // 1 = value written back to rd comes
                                    // from memory (lw), 0 = comes from ALU
    output reg        branch,      // 1 = this is a branch instruction
    output reg  [3:0] alu_op       // final code sent straight into alu.v
                                    // (matches ALU_ADD/ALU_SUB/etc in alu.v)
);

    // Opcodes as constants - much more readable than raw binary
    // scattered through the case statement below.
    localparam OP_RTYPE  = 7'b0110011;
    localparam OP_ITYPE  = 7'b0010011;   // addi, andi, ori
    localparam OP_LOAD   = 7'b0000011;   // lw
    localparam OP_STORE  = 7'b0100011;   // sw
    localparam OP_BRANCH = 7'b1100011;   // beq, bne

    // Must match the codes inside alu.v exactly
    localparam ALU_ADD = 4'b0000;
    localparam ALU_SUB = 4'b0001;
    localparam ALU_AND = 4'b0010;
    localparam ALU_OR  = 4'b0011;
    localparam ALU_SLT = 4'b0100;

    always @(*) begin
        // ------------------------------------------------
        // It is good to defaults every cycle, so we never accidentally
        // leave a signal at its old value (that would make
        // this behave like it has memory, which it must not -
        // it has to be purely combinational).
        // ------------------------------------------------
        reg_write  = 1'b0;
        alu_src    = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        branch     = 1'b0;
        alu_op     = ALU_ADD;

        case (opcode)

            // --------------------------------------------
            // R-type: add, sub, and, or, slt
            // Both operands come from registers (alu_src=0).
            // Exact operation depends on funct3 + funct7_5.
            // --------------------------------------------
            OP_RTYPE: begin
                reg_write = 1'b1;
                alu_src   = 1'b0;
                case (funct3)
                    3'b000: alu_op = funct7_5 ? ALU_SUB : ALU_ADD; // add vs sub
                    3'b111: alu_op = ALU_AND;
                    3'b110: alu_op = ALU_OR;
                    3'b010: alu_op = ALU_SLT;
                    default: alu_op = ALU_ADD;
                endcase
            end

            // --------------------------------------------
            // I-type arithmetic: addi, andi, ori
            // Second operand is the immediate, not a register
            // (alu_src=1). funct7 doesn't exist for I-type,
            // so only funct3 decides the operation.
            // --------------------------------------------
            OP_ITYPE: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                case (funct3)
                    3'b000: alu_op = ALU_ADD; // addi
                    3'b111: alu_op = ALU_AND; // andi
                    3'b110: alu_op = ALU_OR;  // ori
                    default: alu_op = ALU_ADD;
                endcase
            end

            // --------------------------------------------
            // lw: compute address as rs1 + immediate (ADD),
            // read memory, write the loaded value back to rd.
            // --------------------------------------------
            OP_LOAD: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                alu_op     = ALU_ADD; //compute address as rs1 + immediate (ADD)
            end

            // --------------------------------------------
            // sw: compute address as rs1 + immediate (ADD),
            // write rs2's value into memory. Nothing gets
            // written back to a register, so reg_write stays 0.
            // --------------------------------------------
            OP_STORE: begin
                alu_src   = 1'b1;
                mem_write = 1'b1;
                alu_op    = ALU_ADD;
            end

            // --------------------------------------------
            // beq/bne: compare rs1 and rs2 by subtracting them
            // (ALU_SUB) and checking the ALU's zero flag.
            // beq branches when zero=1, bne when zero=0 - that
            // distinction is handled OUTSIDE the ALU, using
            // funct3 directly in the branch-decision logic 
            // . Nothing gets written to a register.
            // --------------------------------------------
            OP_BRANCH: begin
                branch = 1'b1;
                alu_src = 1'b0;
                alu_op  = ALU_SUB;
            end

            default: begin
                // Unknown opcode - keep everything at safe defaults
                // (do nothing, write nothing, touch no memory).
            end

        endcase
    end

endmodule
