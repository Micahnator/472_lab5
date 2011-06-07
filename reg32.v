// Title         : 32-Bit Register with Synchronous Reset
// Project       : ECE 313 - Computer Organization
//-----------------------------------------------------------------------------
// File          : reg32.v
// Author        : John Nestor  <nestorj@lafayette.edu>
// Organization  : Lafayette College
// 
// Created       : October 2002
// Last modified : 7 January 2005
//-----------------------------------------------------------------------------
// Description :
//   Simple 32-bit register with synchronous reset  used in the implementations of
//   the MIPS processor subset described in Ch. 5-6 of "Computer Organization and Design,
//   3rd ed." by David Patterson & John Hennessey, Morgan Kaufmann, 2004 (COD3e).  
//
//-----------------------------------------------------------------------------
/// This Module has been updated to have a "gate" input that gates the updating of the register
module reg32 (clk, reset, d_in, d_out, gate);
    input       	clk, reset;
    input	[31:0]	d_in;
    input gate;
    output 	[31:0] 	d_out;
    reg 	[31:0]	 d_out;
   
    always @(posedge clk)
    begin
        if (reset) begin
          d_out <= 0;
        end
        else if (!gate) begin
          ///do nothing, just hold
        end  
        else begin
          d_out <= d_in;
        end
    end

endmodule
	
