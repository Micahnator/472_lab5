module hazard(
  input clk,
  input reset,
  input [31:0] ID_Instr,
  input [4:0] EX_rt,
  input EX_MemRead,
  output ID_Write,
  output nop_mux);
  
  ///parameters
  ///parameter WATCHING=1'b0, STALL=1'b1;
  ///state registers
  ///reg state, next_state;
    
  ///registers to store the output values
  reg ID_Write_reg, nop_mux_reg;
  assign ID_Write = ID_Write_reg;
  assign nop_mux = nop_mux_reg;
  
  ///isolate the relevant components of the instruction in the ID stage
  wire [4:0] ID_rs, ID_rt;
  assign ID_rs = ID_Instr[25:21];
  assign ID_rt = ID_Instr[20:16];
  
  ///check for stall condition
  wire data_stall;
  assign data_stall = (EX_MemRead && ((EX_rt == ID_rs) || (EX_rt == ID_rt)));
  
  always @ (data_stall)
  begin
    if (data_stall) begin
      nop_mux_reg = 1'b1;
      ID_Write_reg = 1'b0;
    end else begin
      nop_mux_reg = 1'b0;
      ID_Write_reg = 1'b1;
    end
  end
endmodule
      
  
