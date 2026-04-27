`timescale 1ns/1ps

module SingleCycleCPU_tb;

  reg clk;
  reg rst;

  wire [31:0] PC;
  wire [31:0] instr;
  wire [31:0] NextPC;
  wire [31:0] PC_plus4;
  wire [31:0] BranchTarget;
  wire [31:0] regData1;
  wire [31:0] regData2;
  wire [31:0] imm;
  wire [31:0] ALUResult;
  wire        Zero;
  wire [31:0] MemData;
  wire [31:0] WriteData;
  wire        PCSrc;

  integer errors;
  integer i;

  SingleCycleCPU uut (
    .clk          (clk),
    .rst          (rst),
    .PC           (PC),
    .instr        (instr),
    .NextPC       (NextPC),
    .PC_plus4     (PC_plus4),
    .BranchTarget (BranchTarget),
    .regData1     (regData1),
    .regData2     (regData2),
    .imm          (imm),
    .ALUResult    (ALUResult),
    .Zero         (Zero),
    .MemData      (MemData),
    .WriteData    (WriteData),
    .PCSrc        (PCSrc)
  );

  // 10ns clock
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  task step;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task run_cycles(input integer n);
    integer k;
    begin
      for (k = 0; k < n; k = k + 1)
        step();
    end
  endtask

  task clear_imem;
    begin
      for (i = 0; i < 256; i = i + 1)
        uut.u_imem.mem[i] = 32'h00000013; // NOP
    end
  endtask

  task clear_dmem;
    begin
      for (i = 0; i < 512; i = i + 1)
        uut.u_dmem.mem[i] = 32'h00000000;
    end
  endtask

  task check_reg(
    input [4:0] regnum,
    input [31:0] expected,
    input [255:0] msg
  );
    reg [31:0] got;
    begin
      got = uut.u_rf.regs[regnum];
      if (got !== expected) begin
        $display("FAIL: %s | x%0d expected=0x%08h got=0x%08h", msg, regnum, expected, got);
        $display("      PC=0x%08h instr=0x%08h NextPC=0x%08h", PC, instr, NextPC);
        errors = errors + 1;
      end else begin
        $display("PASS: %s | x%0d = 0x%08h", msg, regnum, got);
      end
    end
  endtask

  task check_byte(
    input integer addr,
    input [7:0] expected,
    input [255:0] msg
  );
    reg [7:0] got;
    reg [31:0] word;
    integer word_addr;
    integer byte_off;
    begin
      word_addr = addr >> 2;
      byte_off  = addr & 3;
      word = uut.u_dmem.mem[word_addr];
      case (byte_off)
        0: got = word[7:0];
        1: got = word[15:8];
        2: got = word[23:16];
        default: got = word[31:24];
      endcase
      if (got !== expected) begin
        $display("FAIL: %s | mem_byte[%0d] expected=0x%02h got=0x%02h", msg, addr, expected, got);
        errors = errors + 1;
      end else begin
        $display("PASS: %s | mem_byte[%0d] = 0x%02h", msg, addr, got);
      end
    end
  endtask

  // Timeout guard
  initial begin
    #5000;
    $display("FAIL: timeout");
    $display("PC=0x%08h instr=0x%08h NextPC=0x%08h", PC, instr, NextPC);
    $finish;
  end

  initial begin
    errors = 0;
    rst    = 1'b1;

    // Let any DUT initial blocks settle
    run_cycles(2);

    clear_imem();
    clear_dmem();

    // Setup
    uut.u_imem.mem[0]  = 32'h00500093; // addi x1, x0, 5
    uut.u_imem.mem[1]  = 32'h00A00113; // addi x2, x0, 10
    uut.u_imem.mem[2]  = 32'hFFF00193; // addi x3, x0, -1

    // R-type
    uut.u_imem.mem[3]  = 32'h00208233; // add  x4,  x1, x2
    uut.u_imem.mem[4]  = 32'h401102B3; // sub  x5,  x2, x1
    uut.u_imem.mem[5]  = 32'h0020C333; // xor  x6,  x1, x2
    uut.u_imem.mem[6]  = 32'h0020E3B3; // or   x7,  x1, x2
    uut.u_imem.mem[7]  = 32'h0020F433; // and  x8,  x1, x2
    uut.u_imem.mem[8]  = 32'h002094B3; // sll  x9,  x1, x2
    uut.u_imem.mem[9]  = 32'h00115533; // srl  x10, x2, x1
    uut.u_imem.mem[10] = 32'h4011D5B3; // sra  x11, x3, x1
    uut.u_imem.mem[11] = 32'h0020A633; // slt  x12, x1, x2
    uut.u_imem.mem[12] = 32'h001136B3; // sltu x13, x2, x1

    // I-type
    uut.u_imem.mem[13] = 32'h00308713; // addi  x14, x1, 3
    uut.u_imem.mem[14] = 32'h0FF0C793; // xori  x15, x1, 255
    uut.u_imem.mem[15] = 32'h00F0E813; // ori   x16, x1, 15
    uut.u_imem.mem[16] = 32'h00F0F893; // andi  x17, x1, 15
    uut.u_imem.mem[17] = 32'h00109913; // slli  x18, x1, 1
    uut.u_imem.mem[18] = 32'h00115993; // srli  x19, x2, 1
    uut.u_imem.mem[19] = 32'h4011DA13; // srai  x20, x3, 1
    uut.u_imem.mem[20] = 32'h0060AA93; // slti  x21, x1, 6
    uut.u_imem.mem[21] = 32'h00613B13; // sltiu x22, x2, 6

    // Loads/stores
    uut.u_imem.mem[22] = 32'h00402023; // sw   x4,0(x0)
    uut.u_imem.mem[23] = 32'h00002B83; // lw   x23,0(x0)
    uut.u_imem.mem[24] = 32'h00300223; // sb   x3,4(x0)
    uut.u_imem.mem[25] = 32'h00301323; // sh   x3,6(x0)
    uut.u_imem.mem[26] = 32'h00400C03; // lb   x24,4(x0)
    uut.u_imem.mem[27] = 32'h00404C83; // lbu  x25,4(x0)
    uut.u_imem.mem[28] = 32'h00601D03; // lh   x26,6(x0)
    uut.u_imem.mem[29] = 32'h00605D83; // lhu  x27,6(x0)

    // Branches
    uut.u_imem.mem[30] = 32'h00208463; // beq  x1,x2,+8
    uut.u_imem.mem[31] = 32'h00100E13; // addi x28,x0,1
    uut.u_imem.mem[32] = 32'h00108463; // beq  x1,x1,+8
    uut.u_imem.mem[33] = 32'h00200E93; // addi x29,x0,2
    uut.u_imem.mem[34] = 32'h00300E93; // addi x29,x0,3

    uut.u_imem.mem[35] = 32'h00209463; // bne  x1,x2,+8
    uut.u_imem.mem[36] = 32'h00400F13; // addi x30,x0,4
    uut.u_imem.mem[37] = 32'h00500F13; // addi x30,x0,5

    uut.u_imem.mem[38] = 32'h0020C463; // blt  x1,x2,+8
    uut.u_imem.mem[39] = 32'h00600F93; // addi x31,x0,6
    uut.u_imem.mem[40] = 32'h00700F93; // addi x31,x0,7

    uut.u_imem.mem[41] = 32'h00115463; // bge  x2,x1,+8
    uut.u_imem.mem[42] = 32'h00800713; // addi x14,x0,8
    uut.u_imem.mem[43] = 32'h00900713; // addi x14,x0,9

    uut.u_imem.mem[44] = 32'h0020E463; // bltu x1,x2,+8
    uut.u_imem.mem[45] = 32'h00800613; // addi x12,x0,8
    uut.u_imem.mem[46] = 32'h00900613; // addi x12,x0,9

    uut.u_imem.mem[47] = 32'h00117463; // bgeu x2,x1,+8
    uut.u_imem.mem[48] = 32'h00A00693; // addi x13,x0,10
    uut.u_imem.mem[49] = 32'h00B00693; // addi x13,x0,11

    // U-type
    uut.u_imem.mem[50] = 32'h123450B7; // lui   x1,0x12345
    uut.u_imem.mem[51] = 32'h00001117; // auipc x2,0x1

    // Jumps
    uut.u_imem.mem[52] = 32'h008001EF; // jal x3,+8
    uut.u_imem.mem[53] = 32'h06300213; // addi x4,x0,99
    uut.u_imem.mem[54] = 32'h03700213; // addi x4,x0,55

    uut.u_imem.mem[55] = 32'h0E400293; // addi x5,x0,228
    uut.u_imem.mem[56] = 32'h00028367; // jalr x6,0(x5)
    uut.u_imem.mem[57] = 32'h04D00393; // addi x7,x0,77

    uut.u_imem.mem[58] = 32'h00000013;
    uut.u_imem.mem[59] = 32'h00000013;

    // Release reset
    #20;
    rst = 1'b0;

    // after instructions 0..12
    run_cycles(13);
    check_reg(1,  32'd5,          "setup addi x1");
    check_reg(2,  32'd10,         "setup addi x2");
    check_reg(3,  32'hFFFFFFFF,   "setup addi x3");
    check_reg(4,  32'd15,         "ADD");
    check_reg(5,  32'd5,          "SUB");
    check_reg(6,  32'd15,         "XOR");
    check_reg(7,  32'd15,         "OR");
    check_reg(8,  32'd0,          "AND");
    check_reg(9,  32'd5120,       "SLL");
    check_reg(10, 32'd0,          "SRL");
    check_reg(11, 32'hFFFFFFFF,   "SRA");
    check_reg(12, 32'd1,          "SLT");
    check_reg(13, 32'd0,          "SLTU");

    // after instructions 13..21
    run_cycles(9);
    check_reg(14, 32'd8,          "ADDI");
    check_reg(15, 32'd250,        "XORI");
    check_reg(16, 32'd15,         "ORI");
    check_reg(17, 32'd5,          "ANDI");
    check_reg(18, 32'd10,         "SLLI");
    check_reg(19, 32'd5,          "SRLI");
    check_reg(20, 32'hFFFFFFFF,   "SRAI");
    check_reg(21, 32'd1,          "SLTI");
    check_reg(22, 32'd0,          "SLTIU");

    // after instructions 22..29
    run_cycles(8);
    check_reg(23, 32'd15,         "LW after SW");
    check_reg(24, 32'hFFFFFFFF,   "LB sign extension");
    check_reg(25, 32'h000000FF,   "LBU zero extension");
    check_reg(26, 32'hFFFFFFFF,   "LH sign extension");
    check_reg(27, 32'h0000FFFF,   "LHU zero extension");
    check_byte(4, 8'hFF,          "SB wrote low byte");
    check_byte(6, 8'hFF,          "SH byte 0");
    check_byte(7, 8'hFF,          "SH byte 1");

    // finish remaining program
    run_cycles(30);

    check_reg(28, 32'd1,          "BEQ not taken path");
    check_reg(29, 32'd3,          "BEQ taken path");
    check_reg(30, 32'd5,          "BNE taken path");
    check_reg(31, 32'd7,          "BLT taken path");
    check_reg(14, 32'd9,          "BGE taken path");
    check_reg(12, 32'd9,          "BLTU taken path");
    check_reg(13, 32'd11,         "BGEU taken path");

    check_reg(1,  32'h12345000,   "LUI");
    check_reg(2,  32'h000010CC,   "AUIPC");
    check_reg(4,  32'd55,         "JAL target wrote x4");
    check_reg(5,  32'd228,        "JALR base register");
    check_reg(6,  32'd228,        "JALR link register");
    check_reg(7,  32'd77,         "JALR destination reached");

    if (errors == 0) begin
      $display("==================================");
      $display("EXPANDED DIRECTED RV32I CHECKS PASSED");
      $display("==================================");
      $display("passed!");
      $display("==================================");
    end else begin
      $display("==================================");
      $display("TEST FAILED WITH %0d ERROR(S)", errors);
      $display("==================================");
    end

    $finish;
  end

endmodule
