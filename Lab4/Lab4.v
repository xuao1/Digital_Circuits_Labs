// 1
module test(
    input a,
    output reg b
);
    always@(*) begin
        if(a) b = 1'b0;
        else b = 1'b1;
    end
endmodule

// 2
module test(
    input [4:0] a,
    output reg [4:0] b    
);
    always@(*)
        b = a;
endmodule

//4
module sub_test(
    input a,b,
    output c
);
    assign c = (a<b)? a : b;
endmodule

module test(
    input a,b,c,
    output o
);
    wire temp;
    sub_test sub_test1(.a(a),.b(b),.c(temp));
    sub_test sub_test2(.a(temp),.b(c),.c(o));
endmodule

//5
module sub_test(
    input a,b;
    output o
);
    assign o = a + b;
endmodule

module test(
    input a,b,
    output c
);
    sub_test sub_test(.a(a),.b(b),.o(c));
endmodule







