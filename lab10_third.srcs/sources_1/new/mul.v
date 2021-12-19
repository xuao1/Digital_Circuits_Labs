`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/19 16:49:54
// Design Name: 
// Module Name: mul
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mul(
input   [7:0]   a,b,
output  [7:0]   out 
);

wire    [7:0]   mul_1;
wire    [7:0]   mul_2;
wire    [7:0]   mul_3;
wire    [7:0]   mul_4;
wire    [7:0]   mul_5;
wire    [7:0]   mul_6;
wire    [7:0]   mul_7;
wire    [7:0]   mul_8;

assign mul_1 = (b[0]==1'b1)?(a):(8'h0);
assign mul_2 = (b[1]==1'b1)?({a[6:0],1'b0}):(8'h0);
assign mul_3 = (b[2]==1'b1)?({a[5:0],2'b0}):(8'h0);
assign mul_4 = (b[3]==1'b1)?({a[4:0],3'b0}):(8'h0);
assign mul_5 = (b[4]==1'b1)?({a[3:0],4'b0}):(8'h0);
assign mul_6 = (b[5]==1'b1)?({a[2:0],5'b0}):(8'h0);
assign mul_7 = (b[6]==1'b1)?({a[1:0],6'b0}):(8'h0);
assign mul_8 = (b[7]==1'b1)?({a[0],7'b0}):(8'h0);

wire    [7:0]   tmp_1;
wire    [7:0]   tmp_2;
wire    [7:0]   tmp_3;
wire    [7:0]   tmp_4;
wire    [7:0]   tmp_5;
wire    [7:0]   tmp_6;

add_8   add1(.s(tmp_1),.cout(),.a(mul_1),.b(mul_2),.cin(1'b0));
add_8   add2(.s(tmp_2),.cout(),.a(mul_3),.b(mul_4),.cin(1'b0));
add_8   add3(.s(tmp_3),.cout(),.a(mul_5),.b(mul_6),.cin(1'b0));
add_8   add4(.s(tmp_4),.cout(),.a(mul_7),.b(mul_8),.cin(1'b0));
add_8   add5(.s(tmp_5),.cout(),.a(tmp_1),.b(tmp_2),.cin(1'b0));
add_8   add6(.s(tmp_6),.cout(),.a(tmp_3),.b(tmp_4),.cin(1'b0));
add_8   add7(.s(out),.cout(),.a(tmp_5),.b(tmp_6),.cin(1'b0));


endmodule