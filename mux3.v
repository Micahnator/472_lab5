module mux3( sel, a, b, c, y );
    parameter bitwidth=32;
    input [1:0]sel;
    input [bitwidth-1:0] a, b, c;
    output [bitwidth-1:0] y;
    
    wire [bitwidth-1:0] x;
    
    assign y = a;
    // mux2 #(bitwidth) M1(sel[0], a, c, x);
    // mux2 #(bitwidth) M2(sel[1], x, b, y);
    
    // 00 = a
    // 01 = b
    // 10 = c
    // 11 = b // hm... bad
    
 //   always @(sel)
 //   begin
  //    case (sel)
   //     2'b00 : y <= a;
   //     2'b01 : y <= b;
   //     2'b10 : y <= c;
   //     2'b11 : y <= 32'b0; // error
   //   endcase 
   // end
endmodule
