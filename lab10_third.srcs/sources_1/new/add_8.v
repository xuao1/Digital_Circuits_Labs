`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/19 15:38:38
// Design Name: 
// Module Name: add_8
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


module add_8(
output  [7:0]   s,
output          cout,
input   [7:0]   a,b,
input           cin
);
wire [6:0] carry;
	
add     add0(s[0],  carry[0],   a[0],   b[0],   cin);
add     add1(s[1],  carry[1],   a[1],   b[1],   carry[0]);
add     add2(s[2],  carry[2],   a[2],   b[2],   carry[1]);
add     add3(s[3],  carry[3],   a[3],   b[3],   carry[2]);
add     add4(s[4],  carry[4],   a[4],   b[4],   carry[3]);
add     add5(s[5],  carry[5],   a[5],   b[5],   carry[4]);
add     add6(s[6],  carry[6],   a[6],   b[6],   carry[5]);
add     add7(s[7],  cout,       a[7],   b[7],   carry[6]);
endmodule
