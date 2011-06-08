//    A simple 32-bit by 32-word read-only memory model
//    ECE 313 Fall 2002


//  11/21/02 - modified to access up to 64 words JN

module rom32(address, data_out);
  input  [31:0] address;
  output [31:0] data_out;
  reg    [31:0] data_out;

  parameter BASE_ADDRESS = 25'd0; // address that applies to this memory

  wire [5:0] mem_offset;
  wire address_select;

  assign mem_offset = address[7:2];  // drop 2 LSBs to get word offset

  assign address_select = (address[31:8] == BASE_ADDRESS);  // address decoding

  always @(address_select or mem_offset)

  begin
    if ((address % 4) != 0) $display($time, " rom32 error: unaligned address %d", address);
    if (address_select == 1)
    begin
      case (mem_offset) 
          5'd0 : data_out = { 6'd35, 5'd0, 5'd2, 16'd4 };             // lw $2, 4($0)    r2=1
          5'd1 : data_out = { 6'd35, 5'd0, 5'd3, 16'd8 };             // lw $3, 8($0)    r3=2
//<<<<<<< HEAD
          // 5'd2 : data_out = { 6'd35, 5'd0, 5'd4, 16'd20 };            // lw $4, 20($0)   r4=5
          // 5'd3 : data_out = { 6'd0, 5'd4, 5'd5, 16'd1 };              // add $5, $4, $0   r5=r4+0
          // 5'd4 : data_out = { 6'd0, 5'd0, 5'd0, 5'd5, 5'd0, 6'd32 };  // add $5, $0, $0  r5=0
          // 5'd5 : data_out = { 6'd0, 5'd5, 5'd2, 5'd5, 5'd0, 6'd32 };  // add $5, $5, $1  r5 = r6 + 1
          // 5'd6 : data_out = 0; // no-op to stall until add is done
          // 5'd7 : data_out = 0; // no-op to stall until add is done
          // 5'd8 : data_out = 0; // no-op to stall until add is done                              
          // 5'd9 : data_out = { 6'd0, 5'd4, 5'd5, 5'd6, 5'd0, 6'd42 };  // slt $6, $4, $5  is $5 > 54?
          // 5'd10 : data_out = 0; // no-op to stall until slt is done
          // 5'd11 : data_out = 0; // no-op to stall until slt is done  
          // 5'd12 : data_out = 0; // no-op to stall until slt is done                                
          // 5'd13 : data_out = { 6'd4, 5'd6, 5'd0, -16'd9 };             // beq $6, $zero, -9  if not, go back 2
          // 5'd14 : data_out = 32'b0; // no-op after branch
          // 5'd15 : data_out = 32'b0; // no-op after branch
          // 5'd16 : data_out = 32'b0; // no-op after branch
          // 5'd17 : data_out = { 6'd43, 5'd0, 5'd5, 16'd0 };             // MEM[0] = $5
          // 5'd18 : data_out = { 6'd4, 5'd0, 5'd0, -16'd18 };            // beq $0, $0, -18 restart loop at word 3
//=======
          5'd2 : data_out = { 6'd35, 5'd0, 5'd4, 16'd20 };             // lw $4, 20($0)  r4=5
          5'd3 : data_out = { 6'd0, 5'd0, 5'd0, 5'd5, 5'd0, 6'd32 };  // add $5, $0, $0  r5=0
         // 5'd4 : data_out = 0; // no-op to stall until add is done
         // 5'd5 : data_out = 0; // no-op to stall until add is done
         // 5'd6 : data_out = 0; // no-op to stall until add is done
          5'd4 : data_out = { 6'd0, 5'd5, 5'd2, 5'd5, 5'd0, 6'd32 };  // add $5, $5, $2  r5 = r5 + 1
          5'd5 : data_out = 0; // no-op to stall until add is done
          5'd6 : data_out = 0; // no-op to stall until add is done
          5'd7 : data_out = 0; // no-op to stall until add is done                              
          5'd8 : data_out = { 6'd0, 5'd4, 5'd5, 5'd6, 5'd0, 6'd42 };  // slt $6, $4, $5  is $5 > 54?
          5'd9 : data_out = 0; // no-op to stall until slt is done
          5'd10 : data_out = 0; // no-op to stall until slt is done  
          5'd11 : data_out = 0; // no-op to stall until slt is done                                
          5'd12 : data_out = { 6'd4, 5'd6, 5'd0, -16'd9 };             // beq $6, $zero, -9  if not, go back 2
          5'd13 : data_out = 32'b0; // no-op after branch
          5'd14 : data_out = 32'b0; // no-op after branch
          5'd15 : data_out = 32'b0; // no-op after branch
          5'd16 : data_out = { 6'd43, 5'd0, 5'd5, 16'd0 };             // MEM[0] = $5
          5'd17 : data_out = { 6'd4, 5'd0, 5'd0, -16'd15 };            // beq $0, $0, -18 restart loop at word 3
//>>>>>>> forwarding
          // add more cases here as desired
          default data_out = 32'hxxxx;
      endcase

      $display($time, " reading data: rom32[%h] => %h", address, data_out);

    end
  end 
endmodule



