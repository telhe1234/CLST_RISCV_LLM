`timescale 1ns/1ps
module DataMemory_tb;
  reg clk = 0;
  reg rst = 1;
  reg [31:0] addr;
  reg [31:0] wd;
  reg mem_read;
  reg mem_write;
  reg [2:0] funct3;
  wire [31:0] rd;
  integer i;
  DataMemory dut(
    .clk(clk), .rst(rst),
    .addr(addr), .wd(wd),
    .mem_read(mem_read), .mem_write(mem_write),
    .funct3(funct3),
    .rd(rd)
  );

  always #5 clk = ~clk;

  localparam [2:0] F3_LB  = 3'b000;
  localparam [2:0] F3_LH  = 3'b001;
  localparam [2:0] F3_LW  = 3'b010;
  localparam [2:0] F3_LBU = 3'b100;
  localparam [2:0] F3_LHU = 3'b101;

  localparam [2:0] F3_SB  = 3'b000;
  localparam [2:0] F3_SH  = 3'b001;
  localparam [2:0] F3_SW  = 3'b010;

  task expect_rd;
    input [31:0] expected;
    input [255:0] msg;
    begin
      #2;
      if (rd !== expected) begin
        $display("FAIL: %s | expected=%h got=%h", msg, expected, rd);
        $finish;
      end
      else begin
        $display("PASS: %s | rd=%h", msg, rd);
      end
    end
  endtask

  task expect_word;
    input integer word_addr;
    input [31:0] expected;
    input [255:0] msg;
    begin
      if (dut.mem[word_addr] !== expected) begin
        $display("FAIL: %s | mem[%0d] expected=%h got=%h", msg, word_addr, expected, dut.mem[word_addr]);
        $finish;
      end
      else begin
        $display("PASS: %s | mem[%0d]=%h", msg, word_addr, dut.mem[word_addr]);
      end
    end
  endtask

  initial begin
    addr = 0;
    wd = 0;
    mem_read = 0;
    mem_write = 0;
    funct3 = F3_LW;

    #2;
    #8;
    rst = 0;

    for (i = 0; i < 512; i = i + 1)
      dut.mem[i] = 32'h00000000;

    // SW + LW
    addr = 32'h00000000;
    wd = 32'hDEADBEEF;
    funct3 = F3_SW;
    mem_write = 1;
    #10;
    mem_write = 0;
    expect_word(0, 32'hDEADBEEF, "SW wrote full word");

    mem_read = 1;
    funct3 = F3_LW;
    expect_rd(32'hDEADBEEF, "LW read full word");
    mem_read = 0;

    // SB at byte offset 1: expect little-endian lane update
    addr = 32'h00000001;
    wd = 32'h000000AA;
    funct3 = F3_SB;
    mem_write = 1;
    #10;
    mem_write = 0;
    expect_word(0, 32'hDEADAAEF, "SB updated byte lane 1");

    // SH at byte offset 2
    addr = 32'h00000002;
    wd = 32'h00001234;
    funct3 = F3_SH;
    mem_write = 1;
    #10;
    mem_write = 0;
    expect_word(0, 32'h1234AAEF, "SH updated upper halfword");

    // LB / LBU from byte 0xEF
    addr = 32'h00000000;
    mem_read = 1;
    funct3 = F3_LB;
    expect_rd(32'hFFFFFFEF, "LB sign extension");
    funct3 = F3_LBU;
    expect_rd(32'h000000EF, "LBU zero extension");
    mem_read = 0;

    // LH / LHU from lower halfword 0xAAEF
    addr = 32'h00000000;
    mem_read = 1;
    funct3 = F3_LH;
    expect_rd(32'hFFFFAAEF, "LH sign extension");
    funct3 = F3_LHU;
    expect_rd(32'h0000AAEF, "LHU zero extension");
    mem_read = 0;

    // Separate word to check positive LB/LH cases
    dut.mem[1] = 32'h007F0180; // bytes: 80 01 7F 00
    addr = 32'h00000004;
    mem_read = 1;
    funct3 = F3_LB;
    expect_rd(32'hFFFFFF80, "LB negative byte in word1 byte0");
    addr = 32'h00000005;
    funct3 = F3_LBU;
    expect_rd(32'h00000001, "LBU positive byte in word1 byte1");
    addr = 32'h00000006;
    funct3 = F3_LH;
    expect_rd(32'h0000007F, "LH positive halfword from upper half");
    addr = 32'h00000004;
    funct3 = F3_LHU;
    expect_rd(32'h00000180, "LHU lower halfword");
    mem_read = 0;

    $display("passed!");
    $finish;
  end
endmodule