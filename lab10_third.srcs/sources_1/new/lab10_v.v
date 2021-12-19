`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/17 21:00:30
// Design Name: 
// Module Name: lab10_v
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

//程序的核心模块
//对时钟周期的认识，每个状态占用周期数需要仔细规划，always是选择在时钟上升沿还是*

module lab10_v(
input               clk,
input               rst,
input               rx,//输入信号 
output              tx,//输出信号，以上两个信号是与FPGA的shell的串口数据,需要特殊处理
output reg  [7:0]   led,//输出到LED
input       [7:0]   sw,//通过开关读入
output wire [2:0]   hexplay_an,
output reg  [3:0]   hexplay_data
);

parameter   C_IDLE          = 4'b0000;
parameter   C_CMD_DC        = 4'b0010;
parameter   C_CMD_WB        = 4'b0011;
parameter   C_CMD_RB        = 4'b0100;
parameter   C_CMD_ERR       = 4'b0111; 
parameter   C_TXFIFO_WR     = 4'b0101;
parameter   C_TXFIFO_WAIT   = 4'b0110;
parameter   C_CMD_ADD       = 4'b1000;

reg         [7:0]   ALU_operand_1;
reg         [7:0]   ALU_operand_2;
reg         [7:0]   ALU_result;

reg         [7:0]   ALU_addr_0;
reg         [7:0]   ALU_addr_1;
reg         [7:0]   ALU_addr_2;

reg                 ALU_rd;
reg                 ALU_wd;       

wire        [7:0]   tx_data;
wire        [7:0]   rx_data;

reg         [3:0]   curr_state;
reg         [3:0]   next_state;

wire                is_wb_cmd;
wire                is_rb_cmd;
wire                is_add_cmd;

reg         [3:0]   tx_byte_cnt;
reg         [3:0]   rx_byte_cnt;

reg         [7:0]   rx_byte_buff_0;
reg         [7:0]   rx_byte_buff_1;
reg         [7:0]   rx_byte_buff_2;
reg         [7:0]   rx_byte_buff_3;
reg         [7:0]   rx_byte_buff_4;
reg         [7:0]   rx_byte_buff_5;
reg         [7:0]   rx_byte_buff_6;
reg         [7:0]   rx_byte_buff_7;
reg         [7:0]   rx_byte_buff_8;
reg         [7:0]   rx_byte_buff_9;
reg         [7:0]   rx_byte_buff_10;
reg         [7:0]   rx_byte_buff_11;

reg         [7:0]   tx_byte_buff_0;
reg         [7:0]   tx_byte_buff_1;
reg         [7:0]   tx_byte_buff_2;
reg         [7:0]   tx_byte_buff_3;
reg         [7:0]   tx_byte_buff_4;
reg         [7:0]   tx_byte_buff_5;
reg         [7:0]   tx_byte_buff_6;
reg         [7:0]   tx_byte_buff_7;

reg         [31:0]  hexplay_buff;//存储数据的作用
reg         [127:0] store_buff;

reg                 rx_fifo_en;     
wire     [7:0]      rx_fifo_data;       
wire                rx_fifo_empty;

reg                 wr_en;
reg      [7:0]      wr_addr;
reg      [7:0]      wr_data;

reg                 rd_en;
reg      [7:0]      rd_addr;
reg      [7:0]      rd_data;

reg      [7:0]      tx_fifo_din;
reg                 tx_fifo_wr_en;
wire                tx_fifo_full;
wire                tx_fifo_empty;

rx                  rx_inst(
.clk                (clk),
.rst                (rst),
.rx                 (rx),
.rx_vld             (rx_vld),
.rx_data            (rx_data)
);    
//串行输入信号为rx，取完所有数据的标志为rx_vld，获得的数据存储在rx_data

tx                  tx_inst(
.clk                (clk),
.rst                (rst),
.tx                 (tx ),
.tx_ready           (~tx_fifo_empty),
.tx_rd              (tx_rd),//从tx_fifo再读一次数据的标志位
.tx_data            (tx_data)
);
//要输出的数据为tx_data，若tx_fifo不为空，则开始串行输出数据，输出信号为tx，输出完的标志位为tx_rd

fifo_32x8bit_0      rx_fifo( 
.clk                (clk), 
.rst                (rst), 
.din                (rx_data), 
.wr_en              (rx_vld), 
.rd_en              (rx_fifo_en), 
.dout               (rx_fifo_data), 
.full               (), 
.empty              (rx_fifo_empty)
);

fifo_32x8bit_0      tx_fifo( 
.clk                (clk), 
.rst                (rst), 
.din                (tx_fifo_din), 
.wr_en              (tx_fifo_wr_en), 
.rd_en              (tx_rd),//读使能有效，当且仅当tx_fifo非空，且需要从tx_fifo读出下一个8bits
.dout               (tx_data), 
.full               (tx_fifo_full), 
.empty              (tx_fifo_empty)
);

always@(*)
begin
    case(curr_state)
        C_IDLE:
            if((rx_vld==1'b1)&&(rx_data==8'h0a))//读完一行shell指令，读到了换行符
                next_state  = C_CMD_DC;
            else
                next_state  = C_IDLE;
        C_CMD_DC:
            if(rx_fifo_empty)
            begin
                if(is_wb_cmd)
                    next_state  = C_CMD_WB;
                else if(is_rb_cmd)
                    next_state  = C_CMD_RB;
                else if(is_add_cmd)
                    next_state  = C_CMD_ADD;
                else
                    next_state  = C_CMD_ERR;
            end
            else
                next_state  = C_CMD_DC;
        C_CMD_WB:
            next_state  = C_IDLE;
        C_CMD_RB://需要两个时钟周期完成
            if(rd_en==1'b1)
                next_state  = C_TXFIFO_WR;
            else
                next_state  = C_CMD_RB;
        C_CMD_ADD:
            if(ALU_rd==1'b1)
                next_state  = C_CMD_WB;
            else
                next_state  = C_CMD_ADD;
        C_CMD_ERR:
            next_state  = C_TXFIFO_WR;
        C_TXFIFO_WR:
            if(tx_byte_cnt==4'h0)
                next_state = C_TXFIFO_WAIT;
            else
                next_state = C_TXFIFO_WR;
        C_TXFIFO_WAIT:
            if(tx_fifo_empty)
                next_state = C_IDLE;
            else
                next_state = C_TXFIFO_WAIT;
        default:
            next_state      = C_IDLE;
    endcase
end

always@(posedge clk or posedge rst)//状态转移
begin
    if(rst)
        curr_state  <= C_IDLE;
    else
        curr_state  <= next_state;
end

//tx_byte_cnt，要向shell输出的数据块数
always@(posedge clk or posedge rst)
begin
    if(rst)
        tx_byte_cnt <= 4'h0;
    else if(curr_state==C_IDLE)
        tx_byte_cnt <= 4'h0;
    else if(curr_state==C_CMD_RB)
        tx_byte_cnt <= 4'h2;
    else if(curr_state==C_CMD_ERR)
        tx_byte_cnt <= 4'h6;
    else if(curr_state==C_TXFIFO_WR)
    begin
        if(tx_byte_cnt!=4'h0)
            tx_byte_cnt <= tx_byte_cnt - 4'h1;
    end
end

//tx_byte_buff，即将向shell输出的数据
//在C_TXFIFO_WR和C_TCFIFO_WAIT状态下，进行转化输出
always@(posedge clk or posedge rst)
begin
    if(rst)
    begin
        tx_byte_buff_0  <= 8'h0;
        tx_byte_buff_1  <= 8'h0;
        tx_byte_buff_2  <= 8'h0;
        tx_byte_buff_3  <= 8'h0;
        tx_byte_buff_4  <= 8'h0;
        tx_byte_buff_5  <= 8'h0;
        tx_byte_buff_6  <= 8'h0;
        tx_byte_buff_7  <= 8'h0;
    end
    else if(curr_state==C_IDLE)
    begin
        tx_byte_buff_0  <= 8'h0;
        tx_byte_buff_1  <= 8'h0;
        tx_byte_buff_2  <= 8'h0;
        tx_byte_buff_3  <= 8'h0;
        tx_byte_buff_4  <= 8'h0;
        tx_byte_buff_5  <= 8'h0;
        tx_byte_buff_6  <= 8'h0;
        tx_byte_buff_7  <= 8'h0;
    end
    else if(curr_state==C_CMD_RB)
    begin
        tx_byte_buff_0  <= "\n";
        if(rd_data[7:4]<=4'h9)//0~9
            tx_byte_buff_2  <= {4'h3,rd_data[7:4]};
        else
            tx_byte_buff_2  <= rd_data[7:4] - 4'ha + "a";
        if(rd_data[3:0]<=4'h9)//0~9
            tx_byte_buff_1  <= {4'h3,rd_data[3:0]};
        else
            tx_byte_buff_1  <= rd_data[3:0] - 4'ha + "a";
    end
    else if(curr_state==C_CMD_ERR)
    begin
        tx_byte_buff_6  <= "E";
        tx_byte_buff_5  <= "R";
        tx_byte_buff_4  <= "R";
        tx_byte_buff_3  <= "O";
        tx_byte_buff_2  <= "R";
        tx_byte_buff_1  <= "!";
        tx_byte_buff_0  <= "\n";
    end
end

//开始执行C_CMD_DC中的操作
//DECODE 来自shell的输入，已经由模块rx和rx_fifo存在rx_fifo中
//在C_CMD_DC状态，置rx_fifo_en为1，从rx_fifo获得rx_fifo_data
//存储到rx_byte_buff,准备在后续状态中使用
//更新 is_wb_cmd 和 is_rb_cmd

//rx_fifo_en
always@(posedge clk or posedge rst)
begin
    if(rst)
        rx_fifo_en  <= 1'b0;
    else if(curr_state==C_CMD_DC)
        rx_fifo_en  <= 1'b1;
    else
        rx_fifo_en  <= 1'b0;
end

//rx_byte_cnt,记录从rx_fifo中读取的数据块
always@(posedge clk or posedge rst)
begin
    if(rst)
        rx_byte_cnt <= 4'h0;
    else if(curr_state==C_CMD_DC)
    begin
        if((rx_fifo_en)&&(rx_fifo_empty==1'b0)&&(rx_byte_cnt<4'hf))//最多读16个8bit数据
            rx_byte_cnt <= rx_byte_cnt + 4'b1;
    end
    else
        rx_byte_cnt <= 4'h0;
end

//rx_byte_buff,将rx_fifo中的数据存到rx_byte_buff中
always@(posedge clk or posedge rst)
begin
    if(rst)
    begin
        rx_byte_buff_0  <= 8'h0;
        rx_byte_buff_1  <= 8'h0;
        rx_byte_buff_2  <= 8'h0;
        rx_byte_buff_3  <= 8'h0;
        rx_byte_buff_4  <= 8'h0;
        rx_byte_buff_5  <= 8'h0;
        rx_byte_buff_6  <= 8'h0;
        rx_byte_buff_7  <= 8'h0;
        rx_byte_buff_8  <= 8'h0;
        rx_byte_buff_9  <= 8'h0;
        rx_byte_buff_10  <= 8'h0;
        rx_byte_buff_11  <= 8'h0;
    end
    else if(curr_state==C_IDLE)
    begin
        rx_byte_buff_0  <= 8'h0;
        rx_byte_buff_1  <= 8'h0;
        rx_byte_buff_2  <= 8'h0;
        rx_byte_buff_3  <= 8'h0;
        rx_byte_buff_4  <= 8'h0;
        rx_byte_buff_5  <= 8'h0;
        rx_byte_buff_6  <= 8'h0;
        rx_byte_buff_7  <= 8'h0;
        rx_byte_buff_8  <= 8'h0;
        rx_byte_buff_9  <= 8'h0;
        rx_byte_buff_10  <= 8'h0;
        rx_byte_buff_11  <= 8'h0;
    end
    else if(curr_state==C_CMD_DC)
    begin
        case(rx_byte_cnt)
            4'h0:   rx_byte_buff_0 <= rx_fifo_data;
            4'h1:   rx_byte_buff_1 <= rx_fifo_data;
            4'h2:   rx_byte_buff_2 <= rx_fifo_data;
            4'h3:   rx_byte_buff_3 <= rx_fifo_data;
            4'h4:   rx_byte_buff_4 <= rx_fifo_data;
            4'h5:   rx_byte_buff_5 <= rx_fifo_data;
            4'h6:   rx_byte_buff_6 <= rx_fifo_data;
            4'h7:   rx_byte_buff_7 <= rx_fifo_data;
            4'h8:   rx_byte_buff_8 <= rx_fifo_data;
            4'h9:   rx_byte_buff_9 <= rx_fifo_data;
            4'ha:   rx_byte_buff_10 <= rx_fifo_data;
            4'hb:   rx_byte_buff_11 <= rx_fifo_data;
        endcase
    end
end 

assign  is_wb_cmd = (curr_state==C_CMD_DC)
                    &&(rx_byte_buff_0=="w")&&(rx_byte_buff_1=="b")
                    &&(rx_byte_buff_2==" ")&&(rx_byte_buff_5==" ")
                    &&(((rx_byte_buff_3>="0")&&(rx_byte_buff_3<="9"))||((rx_byte_buff_3>="a")&&(rx_byte_buff_3<="f")))
                    &&(((rx_byte_buff_4>="0")&&(rx_byte_buff_4<="9"))||((rx_byte_buff_4>="a")&&(rx_byte_buff_4<="f")))
                    &&(((rx_byte_buff_6>="0")&&(rx_byte_buff_6<="9"))||((rx_byte_buff_6>="a")&&(rx_byte_buff_6<="f")))
                    &&(((rx_byte_buff_7>="0")&&(rx_byte_buff_7<="9"))||((rx_byte_buff_7>="a")&&(rx_byte_buff_7<="f")));
assign  is_rb_cmd = (curr_state==C_CMD_DC)
                    &&(rx_byte_buff_0=="r")&&(rx_byte_buff_1=="b")
                    &&(rx_byte_buff_2==" ")
                    &&(((rx_byte_buff_3>="0")&&(rx_byte_buff_3<="9"))||((rx_byte_buff_3>="a")&&(rx_byte_buff_3<="f")))
                    &&(((rx_byte_buff_4>="0")&&(rx_byte_buff_4<="9"))||((rx_byte_buff_4>="a")&&(rx_byte_buff_4<="f")));

assign  is_add_cmd = (curr_state==C_CMD_DC)
                    &&(rx_byte_buff_0=="a")&&(rx_byte_buff_1=="d")&&(rx_byte_buff_2=="d")
                    &&(rx_byte_buff_3==" ")
                    &&(((rx_byte_buff_4>="0")&&(rx_byte_buff_4<="9"))||((rx_byte_buff_4>="a")&&(rx_byte_buff_4<="f")))
                    &&(((rx_byte_buff_5>="0")&&(rx_byte_buff_5<="9"))||((rx_byte_buff_5>="a")&&(rx_byte_buff_5<="f")))
                    &&(rx_byte_buff_6==" ")
                    &&(((rx_byte_buff_7>="0")&&(rx_byte_buff_7<="9"))||((rx_byte_buff_7>="a")&&(rx_byte_buff_7<="f")))
                    &&(((rx_byte_buff_8>="0")&&(rx_byte_buff_8<="9"))||((rx_byte_buff_8>="a")&&(rx_byte_buff_8<="f")))
                    &&(rx_byte_buff_9==" ")
                    &&(((rx_byte_buff_10>="0")&&(rx_byte_buff_10<="9"))||((rx_byte_buff_10>="a")&&(rx_byte_buff_10<="f")))
                    &&(((rx_byte_buff_11>="0")&&(rx_byte_buff_11<="9"))||((rx_byte_buff_11>="a")&&(rx_byte_buff_11<="f")));

//至此，完成C_CMD_DC状态中的全部操作

//执行C_CMD_ADD指令
//先根据rx_fifo_buff更新ALU_addr
//再根据ALU_addr更新ALU_operand
//对ALU_operand进行add运算，存储在ALU_result中
//根据ALU_addr，将ALU_result存回地址中

//ALU_addr,ALU_rd
always@(posedge clk or posedge rst) begin
    if(rst) begin
        ALU_rd   <= 1'b0;
        ALU_addr_0  <= 8'h0;//结果存储的地址
        ALU_addr_1  <= 8'h0;
        ALU_addr_2  <= 8'h0;
    end
    else if(curr_state == C_CMD_ADD) begin
        ALU_rd   <= 1'b1;
        if((rx_byte_buff_4>="0")&&(rx_byte_buff_4<="9"))
            ALU_addr_0[7:4] <= rx_byte_buff_4[3:0];
        else
            ALU_addr_0[7:4] <= rx_byte_buff_4[2:0] + 4'h9;
        if((rx_byte_buff_5>="0")&&(rx_byte_buff_5<="9"))
            ALU_addr_0[3:0] <= rx_byte_buff_5[3:0];
        else
            ALU_addr_0[3:0] <= rx_byte_buff_5[2:0] + 4'h9;
        if((rx_byte_buff_7>="0")&&(rx_byte_buff_7<="9"))
            ALU_addr_1[7:4] <= rx_byte_buff_7[3:0];
        else
            ALU_addr_1[7:4] <= rx_byte_buff_7[2:0] + 4'h9;
        if((rx_byte_buff_8>="0")&&(rx_byte_buff_8<="9"))
            ALU_addr_1[3:0] <= rx_byte_buff_8[3:0];
        else
            ALU_addr_1[3:0] <= rx_byte_buff_8[2:0] + 4'h9;
        if((rx_byte_buff_10>="0")&&(rx_byte_buff_10<="9"))
            ALU_addr_2[7:4] <= rx_byte_buff_10[3:0];
        else
            ALU_addr_2[7:4] <= rx_byte_buff_10[2:0] + 4'h9;
        if((rx_byte_buff_11>="0")&&(rx_byte_buff_11<="9"))
            ALU_addr_2[3:0] <= rx_byte_buff_11[3:0];
        else
            ALU_addr_2[3:0] <= rx_byte_buff_11[2:0] + 4'h9;
    end
    else begin
        ALU_rd   <= 1'b0;
        ALU_addr_0  <= 8'h0;//结果存储的地址
        ALU_addr_1  <= 8'h0;
        ALU_addr_2  <= 8'h0;
    end
end  

//ALU_wd,
always @(posedge clk or posedge rst) begin
    if(rst) begin
        ALU_wd <= 1'b0;
        ALU_operand_1 <= 8'h0;
        ALU_operand_2 <= 8'h0;
    end
    else if((curr_state==C_CMD_ADD)&&ALU_rd) begin
        ALU_wd <= 1'b1;//通过这个标志位，使得写比读晚一个周期
        case(ALU_addr_1)
            8'h0:   ALU_operand_1 = sw;
            8'h10:  ALU_operand_1 = hexplay_buff[7:0];
            8'h11:  ALU_operand_1 = hexplay_buff[15:8];
            8'h12:  ALU_operand_1 = hexplay_buff[23:16];
            8'h13:  ALU_operand_1 = hexplay_buff[31:24];
            8'h20:  ALU_operand_1 = store_buff[7:0];
            8'h21:  ALU_operand_1 = store_buff[15:8];
            8'h22:  ALU_operand_1 = store_buff[23:16];
            8'h23:  ALU_operand_1 = store_buff[31:24];
            8'h24:  ALU_operand_1 = store_buff[39:32];
            8'h25:  ALU_operand_1 = store_buff[47:40];
            8'h26:  ALU_operand_1 = store_buff[55:48];
            8'h27:  ALU_operand_1 = store_buff[63:56];
            8'h28:  ALU_operand_1 = store_buff[71:64];
            8'h29:  ALU_operand_1 = store_buff[79:72];
            8'h2a:  ALU_operand_1 = store_buff[87:80];
            8'h2b:  ALU_operand_1 = store_buff[95:88];
            8'h2c:  ALU_operand_1 = store_buff[103:96];
            8'h2d:  ALU_operand_1 = store_buff[111:104];
            8'h2e:  ALU_operand_1 = store_buff[119:112];
            8'h2f:  ALU_operand_1 = store_buff[127:120];
            default:ALU_operand_1 = 8'h0;
        endcase
        case(ALU_addr_2)
            8'h0:   ALU_operand_2 = sw;
            8'h10:  ALU_operand_2 = hexplay_buff[7:0];
            8'h11:  ALU_operand_2 = hexplay_buff[15:8];
            8'h12:  ALU_operand_2 = hexplay_buff[23:16];
            8'h13:  ALU_operand_2 = hexplay_buff[31:24];
            8'h20:  ALU_operand_2 = store_buff[7:0];
            8'h21:  ALU_operand_2 = store_buff[15:8];
            8'h22:  ALU_operand_2 = store_buff[23:16];
            8'h23:  ALU_operand_2 = store_buff[31:24];
            8'h24:  ALU_operand_2 = store_buff[39:32];
            8'h25:  ALU_operand_2 = store_buff[47:40];
            8'h26:  ALU_operand_2 = store_buff[55:48];
            8'h27:  ALU_operand_2 = store_buff[63:56];
            8'h28:  ALU_operand_2 = store_buff[71:64];
            8'h29:  ALU_operand_2 = store_buff[79:72];
            8'h2a:  ALU_operand_2 = store_buff[87:80];
            8'h2b:  ALU_operand_2 = store_buff[95:88];
            8'h2c:  ALU_operand_2 = store_buff[103:96];
            8'h2d:  ALU_operand_2 = store_buff[111:104];
            8'h2e:  ALU_operand_2 = store_buff[119:112];
            8'h2f:  ALU_operand_2 = store_buff[127:120];
            default:ALU_operand_2 = 8'h0;
        endcase
    end
    else begin
        ALU_wd <= 1'b0;
        ALU_operand_1 <= 8'h0;
        ALU_operand_2 <= 8'h0;
    end
end

//ALU_result
always @(*) begin
    ALU_result = ALU_operand_1 + ALU_operand_2;
end


//执行C_CMD_WB指令
//根据rx_fifo_buff_3和4 更新 wr_addr,根据rx_fifo_buff_6和7 更新wr_data
//置wr_en=1,根据 wr_data，将wr_data 更新到 led 或者 hexplay_buff准备输出到数码管

//wr_addr,wr_data,wr_en
always@(posedge clk or posedge rst)
begin
    if(rst)
    begin
        wr_en   <= 1'b0;
        wr_addr[7:4] <= 4'h0;
        wr_addr[3:0] <= 4'h0;
        wr_data[7:4] <= 4'h0;
        wr_data[3:0] <= 4'h0;
    end
    else if(curr_state == C_CMD_WB)
    begin
        wr_en   <= 1'b1;
        if(ALU_wd==1'b1) begin//上一个状态是进行运算
            wr_addr <= ALU_addr_0;
            wr_data <= ALU_result;
        end
        else begin//直接写的操作
            if((rx_byte_buff_3>="0")&&(rx_byte_buff_3<="9"))
                wr_addr[7:4] <= rx_byte_buff_3[3:0];
            else
                wr_addr[7:4] <= rx_byte_buff_3[2:0] + 4'h9;
            if((rx_byte_buff_4>="0")&&(rx_byte_buff_4<="9"))
                wr_addr[3:0] <= rx_byte_buff_4[3:0];
            else
                wr_addr[3:0] <= rx_byte_buff_4[2:0] + 4'h9;
            if((rx_byte_buff_6>="0")&&(rx_byte_buff_6<="9"))
                wr_data[7:4] <= rx_byte_buff_6[3:0];
            else
                wr_data[7:4] <= rx_byte_buff_6[2:0] + 4'h9;
            if((rx_byte_buff_7>="0")&&(rx_byte_buff_7<="9"))
                wr_data[3:0] <= rx_byte_buff_7[3:0];
            else
                wr_data[3:0] <= rx_byte_buff_7[2:0] + 4'h9;
        end   
    end
    else
    begin
        wr_en   <= 1'b0;
        wr_addr[7:4] <= 4'h0;
        wr_addr[3:0] <= 4'h0;
        wr_data[7:4] <= 4'h0;
        wr_data[3:0] <= 4'h0;
    end
end    

//led,hexplay_buff
//这个就作为程序内部的存储
always@(posedge clk or posedge rst)
begin
    if(rst)
    begin
        led             <= 8'h0;
        hexplay_buff    <= 32'h0; 
        store_buff      <= 128'h0;
    end    
    else if(wr_en)
    begin
        case(wr_addr)
            8'h0:   led                 <= wr_data;
            8'h10:  hexplay_buff[7:0]   <= wr_data;
            8'h11:  hexplay_buff[15:8]  <= wr_data;
            8'h12:  hexplay_buff[23:16] <= wr_data;
            8'h13:  hexplay_buff[31:24] <= wr_data;
            8'h20:  store_buff[7:0]     <= wr_data;
            8'h21:  store_buff[15:8]    <= wr_data;
            8'h22:  store_buff[23:16]   <= wr_data;
            8'h23:  store_buff[31:24]   <= wr_data;
            8'h24:  store_buff[39:32]   <= wr_data;
            8'h25:  store_buff[47:40]   <= wr_data;
            8'h26:  store_buff[55:48]   <= wr_data;
            8'h27:  store_buff[63:56]   <= wr_data;
            8'h28:  store_buff[71:64]   <= wr_data;
            8'h29:  store_buff[79:72]   <= wr_data;
            8'h2a:  store_buff[87:80]   <= wr_data;
            8'h2b:  store_buff[95:88]   <= wr_data;
            8'h2c:  store_buff[103:96]  <= wr_data;
            8'h2d:  store_buff[111:104] <= wr_data;
            8'h2e:  store_buff[119:112] <= wr_data;
            8'h2f:  store_buff[127:120] <= wr_data;
        endcase
    end     
end

//以上，处理完C_CMD_WB状态

//开始处理C_CMD_RB状态，这个状态会转移到向shell输出的C_TXFIFO_WR状态
//根据rx_byte_buff_3和4更新rd_addr
//置tx_byte_cnt=2，会向shell输出2byte数据
//置rd_en=1,根据rd_addr,由sw或对应的hexplay_buff 更新rd_data
//根据rd_data，更新tx_fifo_buff，为向shell输出做准备

//rd_addr,rd_data,rd_en
always@(posedge clk or posedge rst)
begin
    if(rst)
    begin
        rd_en        <= 1'b0;
        rd_addr[7:4] <= 4'h0; 
        rd_addr[3:0] <= 4'h0; 
    end    
    else if(curr_state==C_CMD_RB)//当前指令是rb，处理地址，将ASCII码转化为数字
    begin
        rd_en   <= 1'b1;
        //'1'的ASCII码为：00110001
        //'a'的ASCII码为：01100001
        if((rx_byte_buff_3>="0")&&(rx_byte_buff_3<="9"))
            rd_addr[7:4] <= rx_byte_buff_3[3:0];
        else
            rd_addr[7:4] <= rx_byte_buff_3[2:0] + 4'h9;
        if((rx_byte_buff_4>="0")&&(rx_byte_buff_4<="9"))
            rd_addr[3:0] <= rx_byte_buff_4[3:0];
        else
            rd_addr[3:0] <= rx_byte_buff_4[2:0] + 4'h9;
    end    
    else
    begin
        rd_en   <= 1'b0;
        rd_addr[7:4] <= 4'h0; 
        rd_addr[3:0] <= 4'h0; 
    end    
end   

//rd_data
always@(*)//不要设置为时钟周期上升沿
begin
    if(rd_en)
    begin
        case(rd_addr)
            8'h0:   rd_data = sw;
            8'h10:  rd_data = hexplay_buff[7:0];
            8'h11:  rd_data = hexplay_buff[15:8];
            8'h12:  rd_data = hexplay_buff[23:16];
            8'h13:  rd_data = hexplay_buff[31:24];
            8'h20:  rd_data = store_buff[7:0];
            8'h21:  rd_data = store_buff[15:8];
            8'h22:  rd_data = store_buff[23:16];
            8'h23:  rd_data = store_buff[31:24];
            8'h24:  rd_data = store_buff[39:32];
            8'h25:  rd_data = store_buff[47:40];
            8'h26:  rd_data = store_buff[55:48];
            8'h27:  rd_data = store_buff[63:56];
            8'h28:  rd_data = store_buff[71:64];
            8'h29:  rd_data = store_buff[79:72];
            8'h2a:  rd_data = store_buff[87:80];
            8'h2b:  rd_data = store_buff[95:88];
            8'h2c:  rd_data = store_buff[103:96];
            8'h2d:  rd_data = store_buff[111:104];
            8'h2e:  rd_data = store_buff[119:112];
            8'h2f:  rd_data = store_buff[127:120];
            default:rd_data = 8'h0;
        endcase
    end
    else
        rd_data = 8'h0;
end

//以上，处理完C_CMD_WR状态

//C_TXFIFO_WR和C_TXFIFO_WIAT状态中：
//首先根据tx_byte_cnt，用tx_byte_buff 更新tx_fifo_din
//置tx_fifo的写使能 tx_fifo_wr_en为1，将tx_fifo_din存入tx_fifo
//每clk,tx_byte_cnt减一
//tx_fifo输出为tx_data,通过tx模块转化为tx信号，通过串口输出到FPGA的shell

//tx_fifo_din,tx_fifo_wr_en
always@(posedge clk or posedge rst)
begin
    if(rst)
    begin
        tx_fifo_wr_en   <= 1'b0;
        tx_fifo_din     <= 8'h0;
    end
    else if(curr_state==C_TXFIFO_WR)
    begin
        tx_fifo_wr_en   <= 1'b1;
        case(tx_byte_cnt)
            4'h6:   tx_fifo_din <= tx_byte_buff_6;
            4'h5:   tx_fifo_din <= tx_byte_buff_5;
            4'h4:   tx_fifo_din <= tx_byte_buff_4;
            4'h3:   tx_fifo_din <= tx_byte_buff_3;
            4'h2:   tx_fifo_din <= tx_byte_buff_2;
            4'h1:   tx_fifo_din <= tx_byte_buff_1;
            4'h0:   tx_fifo_din <= tx_byte_buff_0;
            default:tx_fifo_din <= 8'h0;
        endcase
    end
    else
    begin
        tx_fifo_wr_en   <= 1'b0;
        tx_fifo_din     <= 8'h0;
    end
end


//刷新输出到FPGA led以及数码管
reg [20:0] hexplay_cnt;
always @(posedge clk or posedge rst) begin
    if(rst) hexplay_cnt=0;
    else hexplay_cnt<=hexplay_cnt+21'd1;    
end

assign hexplay_an=hexplay_cnt[20:18];

always @(*) begin
    case (hexplay_an)
        3'd0: hexplay_data<=hexplay_buff[3:0];
        3'd1: hexplay_data<=hexplay_buff[7:4];
        3'd2: hexplay_data<=hexplay_buff[11:8];
        3'd3: hexplay_data<=hexplay_buff[15:12];
        3'd4: hexplay_data<=hexplay_buff[19:16];
        3'd5: hexplay_data<=hexplay_buff[23:20];
        3'd6: hexplay_data<=hexplay_buff[27:24];
        3'd7: hexplay_data<=hexplay_buff[31:28];
    endcase
end

endmodule
