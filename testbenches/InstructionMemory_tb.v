`timescale 1ns/1ps
module InstructionMemory_tb;
  reg [31:0] addr;
  wire [31:0] instr;

  InstructionMemory dut(.addr(addr), .instr(instr));

  initial begin
    // preload a couple words (requires InstructionMemory to have: reg [31:0] mem [0:255];)
    dut.mem[0] = 32'hDEADBEEF;
    dut.mem[1] = 32'h12345678;

    addr = 32'h0; #1;
    if (instr !== 32'hDEADBEEF) $display("FAIL @0 got=%h", instr);

    addr = 32'h4; #1;
    if (instr !== 32'h12345678) $display("FAIL @4 got=%h", instr);

    $display("passed!");
    $finish;
  end
endmodule
