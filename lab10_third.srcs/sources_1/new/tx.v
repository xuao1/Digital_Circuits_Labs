`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/17 18:14:59
// Design Name: 
// Module Name: tx
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


//本模块实现了串口数据的输出
//当输出开始,信号 tx_ready 为 1 时，开始将 tx_data 转化为协议规定好的 tx 进行输出
//一次发送8bits数据，tx_rd关联tx模块与tx_fifo模块
//当tx_fifo非空，并且tx模块还没有开始转化输出时，tx_rd=1
//此时这个信号控制tx_fifo读取一个8bit的数据，送入tx模块的tx_data

module tx(
    input           clk,rst,
    output  reg     tx,//输出信号
    input           tx_ready,//当tx_fifo非空时，这个标志位位1，开始转化输出
    output  reg     tx_rd,
    input   [7:0]   tx_data
);
//输入是时钟信号，复位信号。要输出的8bit数据，以及开始输出数据的标志信号
//当标志信号为1，则按照868为周期输出10个信号，包括起始的低位信号，和结束的高位信号
parameter   DIV_CNT   = 10'd867;
parameter   TX_CNT    = 4'h9;//已发送数据的上限
parameter   C_IDLE    = 1'b0;//空闲状态
parameter   C_TX      = 1'b1;//发送状态
    
reg         curr_state,next_state;    
reg [9:0]   div_cnt;//时钟周期数
reg [4:0]   tx_cnt;//已发送的数据数目
reg [7:0]   tx_reg;//要发送的数据

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
            if(tx_ready==1'b1)
                next_state  = C_TX;
            else
                next_state  = C_IDLE;
        C_TX:
            if((div_cnt==DIV_CNT)&&(tx_cnt>=TX_CNT))//数据输出数目达到上限
                next_state  = C_IDLE;
            else
                next_state  = C_TX;
    endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        div_cnt <= 10'h0;
    else if(curr_state==C_TX)//当前状态是输出状态
    begin
        if(div_cnt>=DIV_CNT)
            div_cnt <= 10'h0;
        else
            div_cnt <= div_cnt + 10'h1;
    end
    else//当前状态是空闲状态
        div_cnt <= 10'h0;
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        tx_cnt  <= 4'h0;
    else if(curr_state==C_TX)//当前状态是输出状态
    begin
        if(div_cnt==DIV_CNT)//输出一个可读入的数据
            tx_cnt <= tx_cnt + 1'b1;
    end
    else
        tx_cnt <= 4'h0;
end

//tx_rd,即将开始输出标志，或者获取tx_data模块
always@(posedge clk or posedge rst)
begin
    if(rst)
        tx_rd   <= 1'b0;
    else if((curr_state==C_IDLE)&&(tx_ready==1'b1))//输出完成
        tx_rd   <= 1'b1;
    else
        tx_rd   <= 1'b0;
end

//此时由tx_data更新tx_reg
always@(posedge clk or posedge rst)
begin
    if(rst)
        tx_reg  <= 8'b0;
    else if((curr_state==C_IDLE)&&(tx_ready==1'b1))
        tx_reg  <= tx_data;
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        tx  <= 1'b1;//空闲
    else if(curr_state==C_IDLE)
        tx  <= 1'b1;//空闲
    else if(div_cnt==10'h0)//输出状态
    begin
        case(tx_cnt)
            4'h0:   tx  <= 1'b0;//第一个低位数据
            4'h1:   tx  <= tx_reg[0];
            4'h2:   tx  <= tx_reg[1];
            4'h3:   tx  <= tx_reg[2];
            4'h4:   tx  <= tx_reg[3];
            4'h5:   tx  <= tx_reg[4];
            4'h6:   tx  <= tx_reg[5];
            4'h7:   tx  <= tx_reg[6];
            4'h8:   tx  <= tx_reg[7];
            4'h9:   tx  <= 1'b1;
        endcase
    end
end
endmodule

