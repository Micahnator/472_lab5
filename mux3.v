module mux3( sel, a, b, c, y );
    parameter bitwidth=32;
    input [1:0]sel;
    input [bitwidth-1:0] a, b, c;
    output [bitwidth-1:0] y;
    
    wire [bitwidth-1:0] x;
    
    mux2 #(bitwidth) M1(sel[1], a, c, x);
    mux2 #(bitwidth) M2(sel[0], x, b, y);
    
    // 00 = a
    // 01 = b
    // 10 = c
    // 11 = b // hm... bad

endmodule
