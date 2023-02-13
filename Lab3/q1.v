//Q2
module d_ff(
    input clk,rst,d,
    output q
);
    reg q;
    always@(posedge clk)
        begin
            if(rst == 1)
                q<= 1'b1;
            else
                q<=d;
        end
endmodule
//Q3
module Counter(
    input clk,rst_n,
    output reg [3:0] q
);
    always@(posedge clk or negedge rst_n)
        begin
            if(rst_n == 0)
                q <= 4'b0;
            else
                q <= q + 4'b1;
        end
endmodule
//solution to q4
module LessenCounter(
    input clk,rst_n,
    output reg [3:0] q
);
    always@(posedge clk or negedge rst_n)
        begin
            if(rst_n == 0)
                q <= 4'b1001;
            else
                if(q == 4'b0)
                    q <= 4'b1001;
                else
                    q <= q - 4'b1;
        end
endmodule
//solution to q5
module LessenCounter_2(
    input clk,rst,
    output reg [3:0] q
);
    always@(posedge clk or posedge rst)
        begin
            if(rst == 1)
                q <= 4'b1001;
            else
                if(q == 4'b0)
                    q <= 4'b1001;
                else
                    q <= q - 4'b1;
        end
endmodule