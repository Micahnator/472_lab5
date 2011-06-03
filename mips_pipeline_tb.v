module mips_pipeline_tb();
  reg clk, reset;
  
  //run the clock
  always
    #50 clk = ~clk;
  
  //instantiate cpu
  mips_pipeline mps(clk, reset);
  
  //initialize stimulus signals
  initial begin
    clk = 1'b0;
    reset = 1'b0;
    
    #50 reset = 1;
    #75 reset = 0;
  end
endmodule
