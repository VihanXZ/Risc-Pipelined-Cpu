// ============================================================
// control_unit_tb.v
// Feeds in opcode/funct3/funct7 combinations for one
// instruction of each type, and checks the control signals
// that come out match what that instruction should do.
// ============================================================

`timescale 1ns/1ps

module control_unit_tb;

    reg  [6:0] opcode;
    reg  [2:0] funct3;
    reg        funct7_5;

    wire       reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch;
    wire [3:0] alu_op;

    control_unit uut (
        .opcode(opcode),
        .funct3(funct3),
        .funct7_5(funct7_5),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .alu_op(alu_op)
    );

    initial begin
        $dumpfile("control_unit.vcd");
        $dumpvars(0, control_unit_tb);
    end

    initial begin
        // ---- add (R-type, funct3=000, funct7_5=0) ----
        opcode = 7'b0110011; funct3 = 3'b000; funct7_5 = 1'b0;
        #1;
        if (reg_write === 1'b1 && alu_src === 1'b0 && alu_op === 4'b0000)
            $display("PASS: add -> reg_write=1 alu_src=0 alu_op=ADD");
        else
            $display("FAIL: add -> got reg_write=%b alu_src=%b alu_op=%b", reg_write, alu_src, alu_op);

        // ---- sub (R-type, funct3=000, funct7_5=1) ----
        opcode = 7'b0110011; funct3 = 3'b000; funct7_5 = 1'b1;
        #1;
        if (alu_op === 4'b0001)
            $display("PASS: sub -> alu_op=SUB");
        else
            $display("FAIL: sub -> got alu_op=%b", alu_op);

        // ---- addi (I-type, funct3=000) ----
        opcode = 7'b0010011; funct3 = 3'b000; funct7_5 = 1'b0;
        #1;
        if (reg_write === 1'b1 && alu_src === 1'b1 && alu_op === 4'b0000)
            $display("PASS: addi -> reg_write=1 alu_src=1 alu_op=ADD");
        else
            $display("FAIL: addi -> got reg_write=%b alu_src=%b alu_op=%b", reg_write, alu_src, alu_op);

        // ---- lw (load) ----
        opcode = 7'b0000011; funct3 = 3'b010; funct7_5 = 1'b0;
        #1;
        if (reg_write === 1'b1 && mem_read === 1'b1 && mem_to_reg === 1'b1 && alu_src === 1'b1)
            $display("PASS: lw -> reg_write=1 mem_read=1 mem_to_reg=1 alu_src=1");
        else
            $display("FAIL: lw -> got reg_write=%b mem_read=%b mem_to_reg=%b alu_src=%b",
                       reg_write, mem_read, mem_to_reg, alu_src);

        // ---- sw (store) ----
        opcode = 7'b0100011; funct3 = 3'b010; funct7_5 = 1'b0;
        #1;
        if (mem_write === 1'b1 && reg_write === 1'b0 && alu_src === 1'b1)
            $display("PASS: sw -> mem_write=1 reg_write=0 alu_src=1");
        else
            $display("FAIL: sw -> got mem_write=%b reg_write=%b alu_src=%b", mem_write, reg_write, alu_src);

        // ---- beq (branch) ----
        opcode = 7'b1100011; funct3 = 3'b000; funct7_5 = 1'b0;
        #1;
        if (branch === 1'b1 && alu_op === 4'b0001 && reg_write === 1'b0)
            $display("PASS: beq -> branch=1 alu_op=SUB reg_write=0");
        else
            $display("FAIL: beq -> got branch=%b alu_op=%b reg_write=%b", branch, alu_op, reg_write);

        #10;
        $display("Control unit testbench finished.");
        $finish;
    end

endmodule
