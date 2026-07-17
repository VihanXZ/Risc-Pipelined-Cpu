// ============================================================
// forwarding_unit.v
// Every cycle, for BOTH alu operands (a and b), this checks:
// "is the register I need about to be written by an instruction
// currently sitting in ex_mem or mem_wb?" If yes, say so - the
// CPU will use that fresher value instead of the stale one
// sitting in id_ex.
//
// forward_a / forward_b encoding:
//   2'b00 = no hazard, use the normal id_ex value
//   2'b01 = forward from ex_mem (1 instruction back - closer, so higher priority)
//   2'b10 = forward from mem_wb (2 instructions back)
// ============================================================

module forwarding_unit (
    input  wire [4:0] id_ex_rs1_addr,   // what the EX-stage instruction needs
    input  wire [4:0] id_ex_rs2_addr,

    input  wire [4:0] ex_mem_rd_addr,   // 1 instruction ahead in the pipeline
    input  wire       ex_mem_reg_write,

    input  wire [4:0] mem_wb_rd_addr,   // 2 instructions ahead in the pipeline
    input  wire       mem_wb_reg_write,

    output reg [1:0] forward_a,
    output reg [1:0] forward_b
);

    always @(*) begin
        // ---- operand A (rs1) ----
        // rd_addr != 0 matters because x0 is hardwired to zero -
        // "writing" to x0 is meaningless, never forward it.
        if (ex_mem_reg_write && (ex_mem_rd_addr != 5'b0) && (ex_mem_rd_addr == id_ex_rs1_addr))
            forward_a = 2'b01;
        else if (mem_wb_reg_write && (mem_wb_rd_addr != 5'b0) && (mem_wb_rd_addr == id_ex_rs1_addr))
            forward_a = 2'b10;
        else
            forward_a = 2'b00;

        // ---- operand B (rs2) ----
        if (ex_mem_reg_write && (ex_mem_rd_addr != 5'b0) && (ex_mem_rd_addr == id_ex_rs2_addr))
            forward_b = 2'b01;
        else if (mem_wb_reg_write && (mem_wb_rd_addr != 5'b0) && (mem_wb_rd_addr == id_ex_rs2_addr))
            forward_b = 2'b10;
        else
            forward_b = 2'b00;
    end

endmodule
