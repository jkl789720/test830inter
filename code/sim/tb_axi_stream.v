`timescale 1ns / 1ps
module tb_axi_stream();
parameter DATA_WD = 32                             ;
parameter DATA_BYTE_WD = DATA_WD / 8               ;
parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD)       ;
reg clk;
reg rst_n;
reg en;

// AXI Stream input original data
wire  valid_in                       ;
wire  [DATA_WD-1 : 0] data_in        ;
wire  [DATA_BYTE_WD-1 : 0] keep_in   ;
wire  last_in                        ;
wire ready_in                       ;
// The header to be inserted to AXI Stream input
wire  valid_insert                       ;
wire  [DATA_WD-1 : 0] data_insert        ;
reg [DATA_BYTE_WD-1 : 0]   keep_insert ;
wire [BYTE_CNT_WD-1 : 0] byte_insert_cnt;
wire  ready_insert                      ;


// AXI Stream output with header inserted
wire valid_out                      ;
wire [DATA_WD-1 : 0] data_out       ;
wire [DATA_BYTE_WD-1 : 0] keep_out  ;
wire last_out                       ;
wire ready_out                       ;

assign ready_out=1;

axi_stream_insert_header 
#(
    .DATA_WD      (DATA_WD      ),
    .DATA_BYTE_WD (DATA_BYTE_WD ),
    .BYTE_CNT_WD  (BYTE_CNT_WD  )
)
u_axi_stream_insert_header(
    .clk             (clk             ),
    .rst_n           (rst_n           ),
    .valid_in        (valid_in        ),
    .data_in         (data_in         ),
    .keep_in         (keep_in         ),
    .last_in         (last_in         ),
    .ready_in        (ready_in        ),
    .valid_out       (valid_out       ),
    .data_out        (data_out        ),
    .keep_out        (keep_out        ),
    .last_out        (last_out        ),
    .ready_out       (ready_out       ),
    .valid_insert    (valid_insert    ),
    .data_insert     (data_insert     ),
    .keep_insert     (keep_insert     ),
    .byte_insert_cnt (byte_insert_cnt ),
    .ready_insert    (ready_insert    )
);
    
//************************************data通道生成****************************//
localparam TRANS_NUM = 8;

reg [2:0] cnt_trans; 
wire add_cnt_trans,end_cnt_trans;
reg trans_flag;


wire transfer_valid;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        trans_flag<=0;
    else if(en)
        trans_flag<=1;
    else if(end_cnt_trans)
        trans_flag<=0;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        cnt_trans<=0;
    else if(add_cnt_trans)begin
        if(end_cnt_trans)
            cnt_trans<=0;
        else
            cnt_trans<=cnt_trans+1;
    end 
end
assign add_cnt_trans=trans_flag;
assign end_cnt_trans=add_cnt_trans&&cnt_trans==TRANS_NUM-1;


assign transfer_valid=ready_in&&valid_in;

//生成原始数据通道
assign valid_in=trans_flag;

assign last_in=end_cnt_trans;

assign keep_in=(last_in)?4'b1100:4'hf;

assign data_in=cnt_trans;

//*************************header通道生成**************************************//
assign valid_insert=1;


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        keep_insert<=0;
    else
        case (byte_insert_cnt)
            0:keep_insert<=4'b0001;
            1:keep_insert<=4'b0011;
            2:keep_insert<=4'b0111;
            3:keep_insert<=4'b1111;
        endcase
end

assign data_insert=$random;
assign byte_insert_cnt=$random;

//控制逻辑  en使能一次8个数据传输，也就是一包数据传输        
    initial begin
        clk   = 0;
        rst_n = 0;
        en=0;
        #20
        rst_n=1;
        
        repeat(10)begin
            en=1;
            #20
            en=0;
            #(20*50);
            end
            en=0;
    end
    
    always #10 clk=~clk;
    
endmodule
