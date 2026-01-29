module Out_Fifo_Buffer
    #(parameter DATA_BIT = 32, parameter INPUT_WIDTH = 13, parameter W_COUNT_BOUNDARY = 2, parameter W_COUNT_RESIDUE = 6)(
    input wire clk, // clk synchronized with filter output (~500Hz)
    input wire f_clk, 
    input wire [INPUT_WIDTH - 1:0] data,
    input wire reset,
    input wire done,
    
    output reg [DATA_BIT - 1:0] out_ready,
    output wire go,

    // TEST OUTPUTS
    output wire [8:0] t_w_pnt, //T
    output wire t_w_pnt_s, //T
    output wire [1:0] t_r_ready, //T
    output wire [DATA_BIT - 1:0] t_fifo_reg_0, //T
    output wire [DATA_BIT - 1:0] t_fifo_reg_1, //T
    output wire t_r_pnt_s, //T
    output wire t_i_done, //T
    output wire t_block //T
);

reg [DATA_BIT - 1:0] fifo_reg [1:0]; // actual storage 2 sets of storage capable of holding 168 bytes
reg [8:0] w_pnt; //writing pointer
reg w_pnt_s; // storage selected by w_ptr(0 or 1)
reg [1:0] r_ready; 
reg r_pnt_s;
reg i_done;
reg block;

initial begin
w_pnt <= 9'b000000000;
w_pnt_s <= 1'b0;
r_ready[0] <= 1'b0;
r_ready[1] <= 1'b0;
r_pnt_s <= 1'b0;
i_done <= 1'b0;
block <= 1'b0;
end

always @(posedge f_clk) begin

    if (done) begin
        i_done <= 1'b1;
    end
    
    if (r_ready[r_pnt_s] & ~block) begin
        out_ready <= fifo_reg[r_pnt_s];
        fifo_reg[r_pnt_s] <= {DATA_BIT{1'b0}};
        block <= 1'b1;
    end
    
    if (i_done & ~r_ready[0] & ~r_ready[1]) begin
        i_done <= 1'b0;
        r_pnt_s <= r_pnt_s + 1;
        block <= 1'b0;
    end
end

always @(posedge clk) begin
    if (reset) begin
        w_pnt <= 9'b000000000;
        w_pnt_s <= 1'b0;
        r_ready[0] <= 1'b0;
        r_ready[1] <= 1'b0;
    end

    if (i_done) begin
        if (w_pnt_s) r_ready[0] <= 1'b0;
        else r_ready[1] <= 1'b0;
    end

    if (w_pnt < W_COUNT_BOUNDARY) begin
        fifo_reg[w_pnt_s][(DATA_BIT-w_pnt*INPUT_WIDTH) -: INPUT_WIDTH] <= data;
        w_pnt <= w_pnt + 1;
    end else begin
        fifo_reg[w_pnt_s][W_COUNT_RESIDUE + INPUT_WIDTH - 1:W_COUNT_RESIDUE] <= data;
        fifo_reg[w_pnt_s][W_COUNT_RESIDUE - 1:0] <= {W_COUNT_RESIDUE{1'b0}};
        w_pnt <= 9'b000000000;
        r_ready[w_pnt_s] <= 1'b1;
        w_pnt_s <= w_pnt_s + 1;
    end
end

assign go = (r_ready[0] || r_ready[1]) & ~i_done;

//TEST OUTPUT assignments

assign t_w_pnt = w_pnt; //T
assign t_w_pnt_s = w_pnt_s; //T
assign t_r_ready = r_ready; //T
assign t_fifo_reg_0 = fifo_reg[0]; //T
assign t_fifo_reg_1 = fifo_reg[1]; //T
assign t_r_pnt_s = r_pnt_s; //T
assign t_i_done = i_done; //T
assign t_block = block; //T

endmodule

