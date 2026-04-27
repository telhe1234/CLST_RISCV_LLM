`timescale 1ns/1ps
module ALU_tb;
  reg [31:0] a, b;
  reg [3:0] alu_ctrl;
  wire [31:0] result;
  wire zero;

  ALU dut(.a(a), .b(b), .alu_ctrl(alu_ctrl), .result(result), .zero(zero));

  // CLST-06 frozen encodings
  localparam [3:0] ALU_AND  = 4'b0000;
  localparam [3:0] ALU_OR   = 4'b0001;
  localparam [3:0] ALU_ADD  = 4'b0010;
  localparam [3:0] ALU_XOR  = 4'b0011;
  localparam [3:0] ALU_SLL  = 4'b0100;
  localparam [3:0] ALU_SRL  = 4'b0101;
  localparam [3:0] ALU_SUB  = 4'b0110;
  localparam [3:0] ALU_SRA  = 4'b0111;
  localparam [3:0] ALU_SLT  = 4'b1000;
  localparam [3:0] ALU_SLTU = 4'b1001;

  task expect;
    input [31:0] exp;
    input exp_zero;
    begin
      #1;
      if (result !== exp) begin
        $display("FAIL: alu_ctrl=%b a=%h b=%h got=%h exp=%h", alu_ctrl, a, b, result, exp);
        $finish;
      end
      if (zero !== exp_zero) begin
        $display("FAIL: zero mismatch alu_ctrl=%b got=%b exp=%b (result=%h)", alu_ctrl, zero, exp_zero, result);
        $finish;
      end
    end
  endtask

  initial begin
    // AND
    a = 32'hF0F0_0F0F; b = 32'h0FF0_FF00; alu_ctrl = ALU_AND;
    expect(32'h00F0_0F00, 1'b0);

    // OR
    alu_ctrl = ALU_OR;
    expect(32'hFFF0_FF0F, 1'b0);

    // XOR
    alu_ctrl = ALU_XOR;
    expect(32'hFF00_F00F, 1'b0);

    // ADD
    a = 32'd7; b = 32'd5; alu_ctrl = ALU_ADD;
    expect(32'd12, 1'b0);

    // SUB => zero=1
    a = 32'd9; b = 32'd9; alu_ctrl = ALU_SUB;
    expect(32'd0, 1'b1);

    // SLL
    a = 32'h0000_0001; b = 32'd8; alu_ctrl = ALU_SLL;
    expect(32'h0000_0100, 1'b0);

    // SRL
    a = 32'h8000_0000; b = 32'd1; alu_ctrl = ALU_SRL;
    expect(32'h4000_0000, 1'b0);

    // SRA (signed)
    a = 32'h8000_0000; b = 32'd1; alu_ctrl = ALU_SRA;
    expect(32'hC000_0000, 1'b0);

    // SLT (signed): (-1 < 1) => 1
    a = 32'hFFFF_FFFF; b = 32'd1; alu_ctrl = ALU_SLT;
    expect(32'd1, 1'b0);

    // SLTU (unsigned): (0xFFFF_FFFF < 1) => 0
    alu_ctrl = ALU_SLTU;
    expect(32'd0, 1'b1); // result==0 => zero=1

    $display("passed!");
    $finish;
  end
endmodule
