`timescale 1ns/1ps
module RegisterFile_tb;
  reg clk=0;
  reg we;
  reg [4:0] rs1, rs2, rd;
  reg [31:0] wd;
  wire [31:0] rd1, rd2;

  RegisterFile dut(.clk(clk), .we(we), .rs1(rs1), .rs2(rs2), .rd(rd), .wd(wd), .rd1(rd1), .rd2(rd2));

  always #5 clk = ~clk;

  initial begin
    we=0; rs1=0; rs2=0; rd=0; wd=0;
    #2;

    // x0 must read 0
    rs1=0; rs2=0; #1;
    if (rd1 !== 0 || rd2 !== 0) begin $display("FAIL: x0 not zero"); $finish; end

    // write x1 = 0x1234
    rd=5'd1; wd=32'h0000_1234; we=1;
    #10; we=0;

    rs1=5'd1; rs2=5'd0; #1;
    if (rd1 !== 32'h0000_1234) begin $display("FAIL: x1 readback"); $finish; end
    if (rd2 !== 32'h0) begin $display("FAIL: x0 changed"); $finish; end

    // attempt write x0 (must be ignored)
    rd=5'd0; wd=32'hFFFF_FFFF; we=1;
    #10; we=0;
    rs1=0; #1;
    if (rd1 !== 32'h0) begin $display("FAIL: x0 write not ignored"); $finish; end

    $display("passed!");
    $finish;
  end
endmodule
