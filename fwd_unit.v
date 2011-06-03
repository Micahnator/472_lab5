module fwd_unit(IDEX_Rs, IDEX_Rt, EXMEM_Rd, EXMEM_WB, MEMWB_Rd, MEMWB_WB, ForwardA, ForwardB);
  input [4:0] IDEX_Rs, IDEX_Rt, EXMEM_Rd, EXMEM_WB, MEMWB_Rd, MEMWB_WB;
  output reg [1:0] ForwardA, ForwardB;
  
  /// only forward r-format instructions for now
  
  /*
  ForwardA = 00 ; The first ALU operand comes from the register file
  ForwardA = 10 ; The first ALU operand is forwarded from the prior ALU result
  ForwardA = 01 ; The first ALU operand is forwarded from data memory or an earlier ALU result
  
  ForwardB = 00 ; The second ALU operand comes from the register file
  ForwardB = 10 ; The second ALU operand is forwarded from the prior ALU result
  ForwardB = 01 ; The second ALU operand is forwarded from data memory or an earlier ALU result
  */
  always @ (*)
  begin
  /// set default values
  assign ForwardA = 2'b00;
  assign ForwardB = 2'b00;
  
  /// EX hazard
  if ((EXMEM_WB == 1'b1)
    && (EXMEM_Rd != 1'b0)
    && (EXMEM_Rd == IDEX_Rs))
  begin
    assign ForwardA = 2'b10;
  end
  
  if((EXMEM_WB == 1'b1)
    && (EXMEM_Rd != 1'b0)
    && (EXMEM_Rd == IDEX_Rt))
  begin
    assign ForwardB = 2'b10;
  end
  
  /// MEM hazard
  if ((MEMWB_WB == 1'b1)
    && (MEMWB_Rd != 1'b0)
    && ! ((EXMEM_WB == 1'b1) && (EXMEM_Rd != 1'b0) && (EXMEM_Rd != IDEX_Rs))
    && (MEMWB_Rd == IDEX_Rs))
  begin
    assign ForwardA = 2'b01;
  end

  if ((MEMWB_WB == 1'b1)
    && (MEMWB_Rd != 1'b0)
    && ! (EXMEM_WB && (EXMEM_Rd != 1'b0) && (EXMEM_Rd != IDEX_Rt))
    && (MEMWB_Rd == IDEX_Rt))
  begin
    assign ForwardB = 2'b01;
  end
  end
endmodule