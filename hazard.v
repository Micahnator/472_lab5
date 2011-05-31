module hazard(
  input clk,
  input reset,
  input [31:0] ID_Instr,
  input [4:0] EX_rt,
  input EX_MemRead,
  output ID_Write,
  output nop_mux);
  
  ///parameters
  parameter WATCHING=1'b0, STALL=1'b1;
  ///state registers
  reg state, next_state;
    
  ///registers to store the output values
  reg ID_Write_reg, nop_mux_reg;
  assign ID_Write = ID_Write_reg;
  assign nop_mux = nop_mux_reg;
  
  ///isolate the relevant components of the instruction in the ID stage
  wire [4:0] ID_rs, ID_rt;
  assign ID_rs = ID_Instr[25:21];
  assign ID_rt = ID_Instr[20:16];
  
  //check for stall condition
  wire data_stall;
  assign data_stall = (EX_MemRead && ((EX_rt == ID_rs) || (EX_rt == ID_rt)));
  
  ///next state logic
  always @ (state or data_stall)
  begin
    ///next_state = WATCHING;///default condition
    case (state)
      STALL:
        begin
          next_state = WATCHING;
        end
      WATCHING:
        if (data_stall) begin
          next_state = STALL;
        end else begin
          next_state = WATCHING;
        end
      default: begin
        next_state = WATCHING;
      end
    endcase
  end
  
  ///sequential logic
  always @ (posedge clk)
  begin
    if (reset) begin
      state = WATCHING;
    end else begin
      state = next_state;
    end
  end
  
  ///output logic
  always @ (posedge clk)
  begin
    if (reset) begin
      ID_Write_reg = 1'b1;
      nop_mux_reg = 1'b0;
    end 
    else begin
      case (state)
        WATCHING: begin
          ID_Write_reg = 1'b1;
          nop_mux_reg = 1'b0;
        end
        STALL: begin
          ID_Write_reg = 1'b0;
          nop_mux_reg = 1'b1;
        end
        default: begin
          ID_Write_reg = 1'b1;
          nop_mux_reg = 1'b0;
        end
      endcase
    end
  end
endmodule
      