`timescale 1ns/1ps
module MainControl_tb;
  reg [6:0] opcode;

  wire branch;
  wire mem_read;
  wire mem_to_reg;
  wire [1:0] alu_op;
  wire mem_write;
  wire alu_src;
  wire reg_write;
  wire jal_en;
  wire jalr_en;
  wire lui_en;
  wire auipc_en;

  MainControl dut(
    .opcode(opcode),
    .branch(branch),
    .mem_read(mem_read),
    .mem_to_reg(mem_to_reg),
    .alu_op(alu_op),
    .mem_write(mem_write),
    .alu_src(alu_src),
    .reg_write(reg_write),
    .jal_en(jal_en),
    .jalr_en(jalr_en),
    .lui_en(lui_en),
    .auipc_en(auipc_en)
  );

  task check;
    input [6:0] op;
    input exp_alu_src;
    input exp_mem_to_reg;
    input exp_reg_write;
    input exp_mem_read;
    input exp_mem_write;
    input exp_branch;
    input exp_jal;
    input exp_jalr;
    input exp_lui;
    input exp_auipc;
    input [1:0] exp_alu_op;
    begin
      opcode = op; #1;
      if (alu_src   !== exp_alu_src   ||
          mem_to_reg!== exp_mem_to_reg||
          reg_write !== exp_reg_write ||
          mem_read  !== exp_mem_read  ||
          mem_write !== exp_mem_write ||
          branch    !== exp_branch    ||
          jal_en    !== exp_jal       ||
          jalr_en   !== exp_jalr      ||
          lui_en    !== exp_lui       ||
          auipc_en  !== exp_auipc     ||
          alu_op    !== exp_alu_op) begin
        $display("FAIL opcode=%b", op);
        $display(" got: ALUSrc=%b MemtoReg=%b RegWrite=%b MemRead=%b MemWrite=%b Branch=%b JAL=%b JALR=%b LUI=%b AUIPC=%b ALUOp=%b",
          alu_src, mem_to_reg, reg_write, mem_read, mem_write, branch, jal_en, jalr_en, lui_en, auipc_en, alu_op);
        $display(" exp: ALUSrc=%b MemtoReg=%b RegWrite=%b MemRead=%b MemWrite=%b Branch=%b JAL=%b JALR=%b LUI=%b AUIPC=%b ALUOp=%b",
          exp_alu_src, exp_mem_to_reg, exp_reg_write, exp_mem_read, exp_mem_write, exp_branch, exp_jal, exp_jalr, exp_lui, exp_auipc, exp_alu_op);
        $finish;
      end
    end
  endtask

  initial begin
    check(7'b0110011, 0,0,1,0,0,0,0,0,0,0, 2'b10); // R-type
    check(7'b0010011, 1,0,1,0,0,0,0,0,0,0, 2'b11); // I-type ALU-immediate
    check(7'b0000011, 1,1,1,1,0,0,0,0,0,0, 2'b00); // Loads
    check(7'b0100011, 1,0,0,0,1,0,0,0,0,0, 2'b00); // Stores
    check(7'b1100011, 0,0,0,0,0,1,0,0,0,0, 2'b01); // Branches
    check(7'b1101111, 0,0,1,0,0,0,1,0,0,0, 2'b00); // JAL
    check(7'b1100111, 1,0,1,0,0,0,0,1,0,0, 2'b00); // JALR
    check(7'b0110111, 0,0,1,0,0,0,0,0,1,0, 2'b00); // LUI
    check(7'b0010111, 1,0,1,0,0,0,0,0,0,1, 2'b00); // AUIPC
    check(7'b1110011, 0,0,0,0,0,0,0,0,0,0, 2'b00); // SYSTEM

    opcode = 7'b1010101; #1;
    if (alu_src|mem_to_reg|reg_write|mem_read|mem_write|branch|jal_en|jalr_en|lui_en|auipc_en|(alu_op!=2'b00)) begin
      $display("FAIL default/illegal not all-zero");
      $finish;
    end

    $display("passed!");
    $finish;
  end
endmodule