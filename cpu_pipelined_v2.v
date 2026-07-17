// ============================================================
// cpu_pipelined_v2.v
// Same structure as cpu_pipelined_v1.v, with forwarding added.
// Two changes from v1:
//   1. id_ex now also carries rs1_addr/rs2_addr forward (the
//      forwarding unit needs to know which registers THIS
//      instruction needs, not just what it read back in ID).
//   2. Right before the ALU, forwarded_rs1/forwarded_rs2 pick
//      between the normal id_ex value, ex_mem's fresh result,
//      or mem_wb's fresh result - based on the forwarding unit's
//      decision.
// ============================================================

module cpu_pipelined_v2 (
    input wire clk,
    input wire rst
);

    wire flush_if_id, flush_id_ex;
    wire [31:0] pc_next;

    // ============================================================
    // IF STAGE
    // ============================================================
    reg  [31:0] pc;
    wire [31:0] pc_plus4 = pc + 32'd4;
    wire [31:0] instr_if;

    instr_mem imem (.pc(pc), .instr(instr_if));

    always @(posedge clk) begin
        if (rst) pc <= 32'b0;
        else     pc <= pc_next;
    end

    reg [31:0] if_id_instr, if_id_pc;
    always @(posedge clk) begin
        if (rst || flush_if_id) begin
            if_id_instr <= 32'b0;
            if_id_pc    <= 32'b0;
        end else begin
            if_id_instr <= instr_if;
            if_id_pc    <= pc;
        end
    end

    // ============================================================
    // ID STAGE
    // ============================================================
    wire [6:0] opcode   = if_id_instr[6:0];
    wire [4:0] rd_addr  = if_id_instr[11:7];
    wire [2:0] funct3   = if_id_instr[14:12];
    wire [4:0] rs1_addr = if_id_instr[19:15];
    wire [4:0] rs2_addr = if_id_instr[24:20];
    wire       funct7_5 = if_id_instr[30];

    wire reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch;
    wire [3:0] alu_op;
    control_unit ctrl (
        .opcode(opcode), .funct3(funct3), .funct7_5(funct7_5),
        .reg_write(reg_write), .alu_src(alu_src), .mem_read(mem_read),
        .mem_write(mem_write), .mem_to_reg(mem_to_reg), .branch(branch),
        .alu_op(alu_op)
    );

    wire [31:0] rs1_data, rs2_data, writeback_data;
    register_file rf (
        .clk(clk), .rst(rst),
        .rs1_addr(rs1_addr), .rs2_addr(rs2_addr),
        .rs1_data(rs1_data), .rs2_data(rs2_data),
        .rd_addr(mem_wb_rd_addr), .rd_data(writeback_data), .rd_wen(mem_wb_reg_write)
    );

    wire [31:0] imm_out;
    imm_gen immg (.instr(if_id_instr), .imm_out(imm_out));

    // ---- ID/EX pipeline register ----
    // NEW: id_ex_rs1_addr and id_ex_rs2_addr are carried forward now
    reg [31:0] id_ex_pc, id_ex_rs1_data, id_ex_rs2_data, id_ex_imm;
    reg [4:0]  id_ex_rd_addr, id_ex_rs1_addr, id_ex_rs2_addr;
    reg [2:0]  id_ex_funct3;
    reg        id_ex_reg_write, id_ex_alu_src, id_ex_mem_read,
               id_ex_mem_write, id_ex_mem_to_reg, id_ex_branch;
    reg [3:0]  id_ex_alu_op;

    always @(posedge clk) begin
        if (rst || flush_id_ex) begin
            id_ex_reg_write <= 1'b0; id_ex_alu_src <= 1'b0;
            id_ex_mem_read  <= 1'b0; id_ex_mem_write <= 1'b0;
            id_ex_mem_to_reg<= 1'b0; id_ex_branch <= 1'b0;
            id_ex_alu_op    <= 4'b0;
            id_ex_pc <= 32'b0; id_ex_rs1_data <= 32'b0; id_ex_rs2_data <= 32'b0;
            id_ex_imm <= 32'b0; id_ex_rd_addr <= 5'b0;
            id_ex_rs1_addr <= 5'b0; id_ex_rs2_addr <= 5'b0;
            id_ex_funct3 <= 3'b0;
        end else begin
            id_ex_pc        <= if_id_pc;
            id_ex_rs1_data  <= rs1_data;
            id_ex_rs2_data  <= rs2_data;
            id_ex_imm       <= imm_out;
            id_ex_rd_addr   <= rd_addr;
            id_ex_rs1_addr  <= rs1_addr;
            id_ex_rs2_addr  <= rs2_addr;
            id_ex_funct3    <= funct3;
            id_ex_reg_write <= reg_write;
            id_ex_alu_src   <= alu_src;
            id_ex_mem_read  <= mem_read;
            id_ex_mem_write <= mem_write;
            id_ex_mem_to_reg<= mem_to_reg;
            id_ex_branch    <= branch;
            id_ex_alu_op    <= alu_op;
        end
    end

    // ============================================================
    // EX STAGE
    // ============================================================
    // ---- Forwarding unit: decide, every cycle, whether either
    // operand needs a fresher value than what id_ex is holding ----
    wire [1:0] forward_a, forward_b;
    forwarding_unit fwd (
        .id_ex_rs1_addr(id_ex_rs1_addr), .id_ex_rs2_addr(id_ex_rs2_addr),
        .ex_mem_rd_addr(ex_mem_rd_addr), .ex_mem_reg_write(ex_mem_reg_write),
        .mem_wb_rd_addr(mem_wb_rd_addr), .mem_wb_reg_write(mem_wb_reg_write),
        .forward_a(forward_a), .forward_b(forward_b)
    );

    // ---- The actual shortcut muxes ----
    // forward code: 00 = use id_ex (normal), 01 = use ex_mem's fresh
    // result, 10 = use mem_wb's fresh result.
    wire [31:0] forwarded_rs1 =
        (forward_a == 2'b01) ? ex_mem_alu_result :
        (forward_a == 2'b10) ? writeback_data    : id_ex_rs1_data;

    wire [31:0] forwarded_rs2 =
        (forward_b == 2'b01) ? ex_mem_alu_result :
        (forward_b == 2'b10) ? writeback_data    : id_ex_rs2_data;

    // forwarded_rs2 (not the raw id_ex value) feeds BOTH the ALU
    // mux below AND the store-data path further down - a sw right
    // after the instruction that computes its value needs this too.
    wire [31:0] alu_input_b = id_ex_alu_src ? id_ex_imm : forwarded_rs2;

    wire [31:0] alu_result_w;
    wire        alu_zero_w;
    alu alu_unit (
        .a(forwarded_rs1), .b(alu_input_b), .alu_op(id_ex_alu_op),
        .result(alu_result_w), .zero(alu_zero_w)
    );

    wire branch_taken   = id_ex_branch && (id_ex_funct3[0] ? ~alu_zero_w : alu_zero_w);
    wire [31:0] branch_target = id_ex_pc + id_ex_imm;

    assign flush_if_id = branch_taken;
    assign flush_id_ex = branch_taken;
    assign pc_next      = branch_taken ? branch_target : pc_plus4;

    // ---- EX/MEM pipeline register ----
    reg [31:0] ex_mem_alu_result, ex_mem_rs2_data;
    reg [4:0]  ex_mem_rd_addr;
    reg        ex_mem_reg_write, ex_mem_mem_read, ex_mem_mem_write, ex_mem_mem_to_reg;

    always @(posedge clk) begin
        if (rst) begin
            ex_mem_alu_result <= 32'b0; ex_mem_rs2_data <= 32'b0; ex_mem_rd_addr <= 5'b0;
            ex_mem_reg_write <= 1'b0; ex_mem_mem_read <= 1'b0;
            ex_mem_mem_write <= 1'b0; ex_mem_mem_to_reg <= 1'b0;
        end else begin
            ex_mem_alu_result <= alu_result_w;
            ex_mem_rs2_data   <= forwarded_rs2;   // forwarded value, for sw's store data
            ex_mem_rd_addr    <= id_ex_rd_addr;
            ex_mem_reg_write  <= id_ex_reg_write;
            ex_mem_mem_read   <= id_ex_mem_read;
            ex_mem_mem_write  <= id_ex_mem_write;
            ex_mem_mem_to_reg <= id_ex_mem_to_reg;
        end
    end

    // ============================================================
    // MEM STAGE
    // ============================================================
    wire [31:0] mem_read_data_w;
    data_mem dmem (
        .clk(clk), .addr(ex_mem_alu_result), .write_data(ex_mem_rs2_data),
        .mem_read(ex_mem_mem_read), .mem_write(ex_mem_mem_write),
        .read_data(mem_read_data_w)
    );

    wire [31:0] mem_stage_result = ex_mem_mem_to_reg ? mem_read_data_w : ex_mem_alu_result;

    // ---- MEM/WB pipeline register ----
    reg [31:0] mem_wb_result;
    reg [4:0]  mem_wb_rd_addr;
    reg        mem_wb_reg_write;

    always @(posedge clk) begin
        if (rst) begin
            mem_wb_result <= 32'b0; mem_wb_rd_addr <= 5'b0; mem_wb_reg_write <= 1'b0;
        end else begin
            mem_wb_result    <= mem_stage_result;
            mem_wb_rd_addr   <= ex_mem_rd_addr;
            mem_wb_reg_write <= ex_mem_reg_write;
        end
    end

    // ============================================================
    // WB STAGE
    // ============================================================
    assign writeback_data = mem_wb_result;

endmodule
