// ============================================================
// imm_gen_tb.v
// Builds one hand-crafted instruction for each format by
// concatenating its fields (this doubles as a worked example
// of exactly how each format packs its bits), feeds it in,
// and checks the immediate comes back out correctly.
// ============================================================

`timescale 1ns/1ps

module imm_gen_tb;

    reg  [31:0] instr;
    wire [31:0] imm_out;

    imm_gen uut (
        .instr(instr),
        .imm_out(imm_out)
    );

    initial begin
        $dumpfile("imm_gen.vcd");
        $dumpvars(0, imm_gen_tb);
    end

    initial begin
        // ------------------------------------------------
        // addi x1, x2, 5
        // I-type layout: imm[11:0] | rs1 | funct3 | rd | opcode
        // ------------------------------------------------
        instr = {12'd5, 5'b00010, 3'b000, 5'b00001, 7'b0010011};
        #1;
        if ($signed(imm_out) === 32'sd5)
            $display("PASS: addi x1,x2,5 -> imm = %0d", $signed(imm_out));
        else
            $display("FAIL: addi -> expected 5, got %0d", $signed(imm_out));

        // ------------------------------------------------
        // sw x2, 8(x1)   (store x2's value at address x1+8)
        // S-type layout: imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode
        // imm = 8 = 12'b000000001000 -> imm[11:5]=0000000, imm[4:0]=01000
        // ------------------------------------------------
        instr = {7'b0000000, 5'b00010, 5'b00001, 3'b010, 5'b01000, 7'b0100011};
        #1;
        if ($signed(imm_out) === 32'sd8)
            $display("PASS: sw x2,8(x1) -> imm = %0d", $signed(imm_out));
        else
            $display("FAIL: sw -> expected 8, got %0d", $signed(imm_out));

        // ------------------------------------------------
        // beq x1, x2, 16   (branch offset of 16 bytes)
        // B-type layout:
        //   imm[12] | imm[10:5] | rs2 | rs1 | funct3 | imm[4:1] | imm[11] | opcode
        // imm = 16 -> imm[12]=0, imm[11]=0, imm[10:5]=000000,
        //              imm[4:1]=1000, imm[0]=0 (implied, not stored)
        // ------------------------------------------------
        instr = {1'b0, 6'b000000, 5'b00010, 5'b00001, 3'b000, 4'b1000, 1'b0, 7'b1100011};
        #1;
        if ($signed(imm_out) === 32'sd16)
            $display("PASS: beq x1,x2,16 -> imm = %0d", $signed(imm_out));
        else
            $display("FAIL: beq -> expected 16, got %0d", $signed(imm_out));

        // ------------------------------------------------
        // Bonus check: a NEGATIVE immediate to confirm sign
        // extension actually works, not just positive numbers.
        // addi x1, x2, -5  ->  -5 as 12-bit two's complement
        // = 12'b111111111011
        // ------------------------------------------------
        instr = {12'b111111111011, 5'b00010, 3'b000, 5'b00001, 7'b0010011};
        #1;
        if ($signed(imm_out) === -32'sd5)
            $display("PASS: addi x1,x2,-5 -> imm = %0d", $signed(imm_out));
        else
            $display("FAIL: addi negative -> expected -5, got %0d", $signed(imm_out));

        #10;
        $display("Immediate generator testbench finished.");
        $finish;
    end

endmodule
