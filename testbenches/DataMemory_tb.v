`timescale 1ns/1ps
module DataMemory_tb;
  reg clk=0;
  reg rst=1;
  reg [31:0] addr;
  reg [31:0] wd;
  reg mem_read;
  reg mem_write;
  reg [2:0] funct3;
  wire [31:0] rd;

  DataMemory dut(
    .clk(clk), .rst(rst),
    .addr(addr), .wd(wd),
    .mem_read(mem_read), .mem_write(mem_write),
    .funct3(funct3),
    .rd(rd)
  );

  always #5 clk = ~clk;

  localparam [2:0] F3_SW_LW = 3'b010; // funct3=010 for LW/SW in RV32I

  initial begin
    addr=0; wd=0; mem_read=0; mem_write=0; funct3=F3_SW_LW;
    #2;

    #8; rst=0;

    // Store word
    addr = 32'h0000_0000;
    wd   = 32'hDEAD_BEEF;
    funct3 = F3_SW_LW;
    mem_write = 1; mem_read = 0;
    #10;
    mem_write = 0;

    // Load word
    mem_read = 1; mem_write = 0;
    #2; // if combinational read, data may appear quickly
    #10; // if synchronous read, allow a cycle
    if (rd !== 32'hDEAD_BEEF) begin
      $display("FAIL: LW didn't return stored word, got %h", rd);
      $finish;
    end
    mem_read = 0;

    $display("passed!");
    $finish;
  end
endmodule
