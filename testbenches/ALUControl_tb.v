`timescale 1ns/1ps

module ALUControl_tb;

  reg  [1:0] alu_op;
  reg  [2:0] funct3;
  reg  [6:0] funct7;
  wire [3:0] alu_ctrl;

  // DUT
  ALUControl uut (
    .alu_op   (alu_op),
    .funct3   (funct3),
    .funct7   (funct7),
    .alu_ctrl (alu_ctrl)
  );

  // CLST-06 frozen encodings
  localparam [3:0] AND  = 4'b0000;
  localparam [3:0] OR   = 4'b0001;
  localparam [3:0] ADD  = 4'b0010;
  localparam [3:0] XOR  = 4'b0011;
  localparam [3:0] SLL  = 4'b0100;
  localparam [3:0] SRL  = 4'b0101;
  localparam [3:0] SUB  = 4'b0110;
  localparam [3:0] SRA  = 4'b0111;
  localparam [3:0] SLT  = 4'b1000;
  localparam [3:0] SLTU = 4'b1001;

  task expect;
    input [1:0] op;
    input [2:0] f3;
    input [6:0] f7;
    input [3:0] exp;
    begin
      alu_op = op;
      funct3 = f3;
      funct7 = f7;
      #1;
      if (alu_ctrl !== exp) begin
        $display("FAIL: alu_op=%b funct3=%b funct7=%b got=%b exp=%b",
                 alu_op, funct3, funct7, alu_ctrl, exp);
        $finish;
      end
    end
  endtask

  initial begin
    // ALUOp meanings:
    // 00 -> ADD (address/base+imm)
    // 01 -> branch compare
    // 10 -> R-type decode
    // 11 -> I-type ALU-immediate decode

    // ALUOp=00 => ADD regardless of funct
    expect(2'b00, 3'b000, 7'b0000000, ADD);
    expect(2'b00, 3'b111, 7'b0100000, ADD);

    // ALUOp=01 => branch compare path (implemented as SUB in this ALUControl)    expect(2'b01, 3'b000, 7'b0000000, SUB);
    expect(2'b01, 3'b111, 7'b0100000, SUB);

    // ALUOp=10 => R-type decode by funct3/funct7
    expect(2'b10, 3'b000, 7'b0000000, ADD);  // ADD
    expect(2'b10, 3'b000, 7'b0100000, SUB);  // SUB
    expect(2'b10, 3'b001, 7'b0000000, SLL);
    expect(2'b10, 3'b010, 7'b0000000, SLT);
    expect(2'b10, 3'b011, 7'b0000000, SLTU);
    expect(2'b10, 3'b100, 7'b0000000, XOR);
    expect(2'b10, 3'b101, 7'b0000000, SRL);
    expect(2'b10, 3'b101, 7'b0100000, SRA);
    expect(2'b10, 3'b110, 7'b0000000, OR);
    expect(2'b10, 3'b111, 7'b0000000, AND);

    // ALUOp=11 => I-type ALU-immediate decode
    expect(2'b11, 3'b000, 7'b1111111, ADD);  // ADDI with negative imm must still be ADD
    expect(2'b11, 3'b001, 7'b0000000, SLL);  // SLLI
    expect(2'b11, 3'b010, 7'b0000000, SLT);  // SLTI
    expect(2'b11, 3'b011, 7'b0000000, SLTU); // SLTIU
    expect(2'b11, 3'b100, 7'b0000000, XOR);  // XORI
    expect(2'b11, 3'b101, 7'b0000000, SRL);  // SRLI
    expect(2'b11, 3'b101, 7'b0100000, SRA);  // SRAI
    expect(2'b11, 3'b110, 7'b0000000, OR);   // ORI
    expect(2'b11, 3'b111, 7'b0000000, AND);  // ANDI

    $display("passed!");
    $finish;
  end

endmodule
