`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/17 19:54:47
// Design Name: 
// Module Name: rx
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

//本模块实现了串口数据的输入
//开始将 rx 转化为协议规定好的 rx_data 进行输入
//一次接收8bits数据，存储到rx_data,需及时使用
//完成输入8bit的数据后，rx_vld=1

module rx(
    input               clk,rst,
    input               rx,//输入的数据
    output  reg         rx_vld,//读完所有数据的标志位
    output  reg  [7:0]  rx_data//存储的读入数据
    );

parameter   DIV_CNT   = 10'd867;
parameter   HDIV_CNT  = 10'd433;
parameter   RX_CNT    = 4'h8;
parameter   C_IDLE    = 1'b0;//空闲状态
parameter   C_RX      = 1'b1;//接收状态

reg         curr_state;
reg         next_state;
reg [9:0]   div_cnt;
reg [3:0]   rx_cnt;//记录已经接收了多少数据
reg         rx_reg_0,rx_reg_1,rx_reg_2,rx_reg_3,rx_reg_4,rx_reg_5,rx_reg_6,rx_reg_7;
wire        rx_pulse;

always@(posedge clk or posedge rst)
begin
    if(rst)
        curr_state  <= C_IDLE;
    else
        curr_state  <= next_state;
end    

always@(*)
begin
    case(curr_state)
        C_IDLE:
            if(div_cnt==HDIV_CNT)//低电平进入，下一个状态为接收状态
                next_state  = C_RX;
            else
                next_state  = C_IDLE;
        C_RX:
            if((div_cnt==DIV_CNT)&&(rx_cnt>=RX_CNT))//8位数据接收完毕
                next_state  = C_IDLE;
            else
                next_state  = C_RX;
    endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        div_cnt <= 10'h0;
    else if(curr_state == C_IDLE)//在空闲状态
    begin
        if(rx==1'b1)//空闲帧
            div_cnt <= 10'h0;
        else if(div_cnt < HDIV_CNT)//不在空闲帧，即第一个低位检测到，开始输入数据
            div_cnt <= div_cnt + 10'h1;
        else//第一个开始计数的低位检测完毕
            div_cnt <= 10'h0;    
    end
    else if(curr_state == C_RX)//在接收状态。计数器在0~867之间循环
    begin
        if(div_cnt >= DIV_CNT)
            div_cnt <= 10'h0;
        else
            div_cnt <= div_cnt + 10'h1;
    end
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        rx_cnt  <= 4'h0;
    else if(curr_state == C_IDLE)
        rx_cnt  <= 4'h0;
    else if((div_cnt == DIV_CNT)&&(rx_cnt<4'hF))//在接收状态并且当前新读入一个数据
        rx_cnt  <= rx_cnt + 1'b1;      
end

assign rx_pulse = (curr_state==C_RX)&&(div_cnt==DIV_CNT);//读新数据的一个时钟周期

always@(posedge clk)
begin
    if(rx_pulse)
    begin
        case(rx_cnt)
            4'h0: rx_reg_0 <= rx;
            4'h1: rx_reg_1 <= rx;
            4'h2: rx_reg_2 <= rx;
            4'h3: rx_reg_3 <= rx;
            4'h4: rx_reg_4 <= rx;
            4'h5: rx_reg_5 <= rx;
            4'h6: rx_reg_6 <= rx;
            4'h7: rx_reg_7 <= rx;
        endcase//根据已读的数据数量，将当前数据读入
    end
end

always@(posedge clk or posedge rst)
begin
    if(rst)
    begin
        rx_vld  <= 1'b0;
        rx_data <= 8'h55;
    end    
    else if((curr_state==C_RX)&&(next_state==C_IDLE))//已经读完所有数据
    begin
        rx_vld  <= 1'b1;
        rx_data <= {rx_reg_7,rx_reg_6,rx_reg_5,rx_reg_4,rx_reg_3,rx_reg_2,rx_reg_1,rx_reg_0};
    end
    else
        rx_vld  <= 1'b0;
end
endmodule

