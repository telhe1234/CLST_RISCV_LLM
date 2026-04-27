`timescale 1ns/1ps
module PCSelect_tb;
  reg [31:0] pc_plus4;
  reg [31:0] branch_target;
  reg [31:0] jal_target;
  reg [31:0] jalr_target;

  reg pcsrc;
  reg jal_en;
  reg jalr_en;

  wire [31:0] next_pc;

  PCSelect dut(
    .pc_plus4(pc_plus4),
    .branch_target(branch_target),
    .jal_target(jal_target),
    .jalr_target(jalr_target),
    .pcsrc(pcsrc),
    .jal_en(jal_en),
    .jalr_en(jalr_en),
    .next_pc(next_pc)
  );

  task expect;
    input [31:0] exp;
    begin
      #1;
      if (next_pc !== exp) begin
        $display("FAIL: got next_pc=%h exp=%h (pc4=%h bt=%h jt=%h jrt=%h pcsrc=%b jal=%b jalr=%b)",
          next_pc, exp, pc_plus4, branch_target, jal_target, jalr_target, pcsrc, jal_en, jalr_en);
        $finish;
      end
    end
  endtask

  initial begin
    pc_plus4      = 32'h0000_0004;
    branch_target = 32'h0000_0100;
    jal_target    = 32'h0000_0200;
    jalr_target   = 32'h0000_0300;

    // Case 4: default => PC+4
    pcsrc=0; jal_en=0; jalr_en=0;
    expect(32'h0000_0004);

    // Case 3: taken branch (Branch assumed true externally; pcsrc=1)
    pcsrc=1; jal_en=0; jalr_en=0;
    expect(32'h0000_0100);

    // Case 2: JAL overrides branch
    pcsrc=1; jal_en=1; jalr_en=0;
    expect(32'h0000_0200);

    // Case 1: JALR highest priority
    pcsrc=1; jal_en=1; jalr_en=1;
    expect(32'h0000_0300);

    $display("passed!");
    $finish;
  end
endmodule
