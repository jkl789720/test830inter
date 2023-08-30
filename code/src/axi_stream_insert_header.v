module axi_stream_insert_header #(
parameter DATA_WD = 32,
parameter DATA_BYTE_WD = DATA_WD / 8,
parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD)
) (
input clk,
input rst_n,
// AXI Stream input original data
input valid_in,
input [DATA_WD-1 : 0] data_in,
input [DATA_BYTE_WD-1 : 0] keep_in,
input last_in,
output ready_in,
// AXI Stream output with header inserted
output valid_out,
output [DATA_WD-1 : 0] data_out,
output [DATA_BYTE_WD-1 : 0] keep_out,
output last_out,
input ready_out,
// The header to be inserted to AXI Stream input
input valid_insert,
input [DATA_WD-1 : 0] data_insert,
input [DATA_BYTE_WD-1 : 0] keep_insert,
input [BYTE_CNT_WD-1 : 0] byte_insert_cnt,
output ready_insert
);
// Your code here
reg [DATA_WD-1 : 0] data_insert_dff0 ;//打拍

wire transfer_valid;//传输有效信号
assign transfer_valid=ready_in&&valid_out;

reg work_flag;//传输繁忙信号
reg work_flag_dff0;
wire work_flag_pos;//上升沿


//------------

reg [1:0] last_in_dff;//打拍
reg [1:0] valid_in_dff;



reg [DATA_WD-1 : 0] data_in_dff0,data_in_dff1;
reg [DATA_BYTE_WD-1 : 0] keep_in_dff0,keep_in_dff1;
reg [DATA_BYTE_WD-1 : 0] keep_insert_dff0;

reg [BYTE_CNT_WD-1 : 0] byte_insert_cnt_dff0;

//传输繁忙信号
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        work_flag<=0;
    else if(last_out)//优先级决定这个放前面
        work_flag<=0;
    else if(valid_in)
        work_flag<=1;
end

//检测上升沿
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        work_flag_dff0<=0;
    else
        work_flag_dff0<=work_flag;
end

assign work_flag_pos=~work_flag_dff0&&work_flag;
//--------------------打拍信号以便生成输出信号------------------------------------//
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        data_insert_dff0<=0;
    else 
        case(byte_insert_cnt_dff0)
            0:data_insert_dff0<={8'b0,data_insert[23:0]};
            1:data_insert_dff0<={16'b0,data_insert[15:0]};
            2:data_insert_dff0<={24'b0,data_insert[7:0]};
            3:data_insert_dff0<=data_insert;
        endcase
end


//
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        data_in_dff0<=0;
        data_in_dff1<=0;
    end
    else begin
        data_in_dff0<=data_in;
        data_in_dff1<=data_in_dff0;
    end
        
end
//keep_in打两拍
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        keep_in_dff0<=0;
        keep_in_dff1<=0;
    end
    else begin
        keep_in_dff0<=keep_in;
        keep_in_dff1<=keep_in_dff0;
    end
end

 always@(posedge clk or negedge rst_n)begin
     if(!rst_n)begin
         keep_insert_dff0<=0;
     end
     else begin
         keep_insert_dff0<=keep_insert;
     end
        
 end 
 always@(posedge clk or negedge rst_n)begin
     if(!rst_n)begin
         byte_insert_cnt_dff0<=0;
     end
     else begin
         byte_insert_cnt_dff0<=byte_insert_cnt;
     end
        
 end

//将last_in打两拍
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        last_in_dff<=0;
    else
        last_in_dff<={last_in_dff[0],last_in};
end
//将valid_in打两拍
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        valid_in_dff<=0;
    else
        valid_in_dff<={valid_in_dff[0],valid_in};
end
//生成输出信号
assign last_out=last_in_dff[1];

assign data_out=(work_flag_pos)?data_insert_dff0:data_in_dff1;
assign keep_out=(work_flag_pos)?keep_insert_dff0:keep_in_dff1;
assign valid_out=ready_out&&(work_flag_pos?1:valid_in_dff[1]);//下游器件准备好才能拉高数据有效信号，进行流量控制
assign ready_in=1;
assign ready_insert=1;

endmodule