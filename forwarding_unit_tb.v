// ============================================================
// forwarding_unit_tb.v
// ============================================================

`timescale 1ns/1ps

module forwarding_unit_tb;

    reg  [4:0] id_ex_rs1_addr, id_ex_rs2_addr, ex_mem_rd_addr, mem_wb_rd_addr;
    reg        ex_mem_reg_write, mem_wb_reg_write;
    wire [1:0] forward_a, forward_b;

    forwarding_unit uut (
        .id_ex_rs1_addr(id_ex_rs1_addr), .id_ex_rs2_addr(id_ex_rs2_addr),
        .ex_mem_rd_addr(ex_mem_rd_addr), .ex_mem_reg_write(ex_mem_reg_write),
        .mem_wb_rd_addr(mem_wb_rd_addr), .mem_wb_reg_write(mem_wb_reg_write),
        .forward_a(forward_a), .forward_b(forward_b)
    );

    initial begin
        // ---- Case 1: no hazard at all ----
        id_ex_rs1_addr=5'd3; id_ex_rs2_addr=5'd4;
        ex_mem_rd_addr=5'd7; ex_mem_reg_write=1'b1;
        mem_wb_rd_addr=5'd9; mem_wb_reg_write=1'b1;
        #1;
        if (forward_a===2'b00 && forward_b===2'b00)
            $display("PASS: no hazard -> forward_a=00, forward_b=00");
        else
            $display("FAIL: no hazard -> got forward_a=%b forward_b=%b", forward_a, forward_b);

        // ---- Case 2: EX/MEM hazard on rs1 (this is the add x1,x2,x3 case) ----
        id_ex_rs1_addr=5'd3; id_ex_rs2_addr=5'd4;
        ex_mem_rd_addr=5'd3; ex_mem_reg_write=1'b1;
        mem_wb_rd_addr=5'd9; mem_wb_reg_write=1'b1;
        #1;
        if (forward_a===2'b01)
            $display("PASS: EX/MEM hazard on rs1 -> forward_a=01");
        else
            $display("FAIL: EX/MEM hazard on rs1 -> got forward_a=%b", forward_a);

        // ---- Case 3: MEM/WB hazard on rs2 (2 instructions back) ----
        id_ex_rs1_addr=5'd3; id_ex_rs2_addr=5'd4;
        ex_mem_rd_addr=5'd7; ex_mem_reg_write=1'b1;
        mem_wb_rd_addr=5'd4; mem_wb_reg_write=1'b1;
        #1;
        if (forward_b===2'b10)
            $display("PASS: MEM/WB hazard on rs2 -> forward_b=10");
        else
            $display("FAIL: MEM/WB hazard on rs2 -> got forward_b=%b", forward_b);

        // ---- Case 4: BOTH ex_mem and mem_wb match rs1 -> ex_mem wins (more recent) ----
        id_ex_rs1_addr=5'd6; id_ex_rs2_addr=5'd4;
        ex_mem_rd_addr=5'd6; ex_mem_reg_write=1'b1;
        mem_wb_rd_addr=5'd6; mem_wb_reg_write=1'b1;
        #1;
        if (forward_a===2'b01)
            $display("PASS: both match rs1 -> EX/MEM correctly takes priority (forward_a=01)");
        else
            $display("FAIL: priority case -> got forward_a=%b", forward_a);

        // ---- Case 5: x0 special case - never forward writes to x0 ----
        id_ex_rs1_addr=5'd0; id_ex_rs2_addr=5'd4;
        ex_mem_rd_addr=5'd0; ex_mem_reg_write=1'b1;
        mem_wb_rd_addr=5'd9; mem_wb_reg_write=1'b1;
        #1;
        if (forward_a===2'b00)
            $display("PASS: x0 never forwarded -> forward_a=00");
        else
            $display("FAIL: x0 case -> got forward_a=%b", forward_a);

        #10;
        $display("Forwarding unit testbench finished.");
        $finish;
    end

endmodule
