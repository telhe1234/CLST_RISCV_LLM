`timescale 1ns/1ps
module ProgramCounter_tb;
  reg clk=0;
  reg rst=1;
  reg [31:0] next_pc;
  wire [31:0] pc;

  ProgramCounter dut(.clk(clk), .rst(rst), .next_pc(next_pc), .pc(pc));

  always #5 clk = ~clk;

  initial begin
    next_pc = 32'h0;
    #2;

    // Expect reset drives PC to 0 (if you implement optional reset)
    #8; rst = 0;
    next_pc = 32'h0000_0004;
    #10;
    if (pc !== 32'h0000_0004) begin $display("FAIL: PC didn't update to 4"); $finish; end

    next_pc = 32'h0000_0010;
    #10;
    if (pc !== 32'h0000_0010) begin $display("FAIL: PC didn't update to 0x10"); $finish; end

    rst = 1;
    #10;
    if (pc !== 32'h0000_0000) begin $display("FAIL: PC didn't reset to 0"); $finish; end

    $display("passed!");
    $finish;
  end
endmodule
