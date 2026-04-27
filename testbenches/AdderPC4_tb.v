`timescale 1ns/1ps
module AdderPC4_tb;
  reg [31:0] pc;
  wire [31:0] pc_plus4;

  AdderPC4 dut(.pc(pc), .pc_plus4(pc_plus4));

  initial begin
    pc = 32'h0; #1;
    if (pc_plus4 !== 32'd4) begin $display("FAIL: 0+4"); $finish; end

    pc = 32'h0000_0010; #1;
    if (pc_plus4 !== 32'h0000_0014) begin $display("FAIL: 0x10+4"); $finish; end

    $display("passed!");
    $finish;
  end
endmodule
