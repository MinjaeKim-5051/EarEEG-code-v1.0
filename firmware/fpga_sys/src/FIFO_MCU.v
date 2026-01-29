///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: FIFO_MCU.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Description here>
//
// Targeted device: <Family::IGLOO> <Die::AGL600V5> <Package::144 FBGA>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

//`timescale <time_units> / <precision>

module FIFO_MCU(
   output wire [11:0] debug,
   output wire [3:0] debug2,

   input  wire        FPGA_CLK,          // sys_clk or its division
   input  wire        ti_clk,            // Communication clk (Opalkelly API CLK)
   input  wire        data_CLK,          // FDATA_G
   input  wire        RST,               // reset
   input  wire        fifo_trig,         // fifo start trigger
   input  wire        din,               // input data
   input  wire        rd_en_OkPipeOut,   // output fifo rd_en (okPipeOut ep_read)
   input  wire        data_trig,         // READ_G
   
   output wire [11:0] rd_data_cnt_FIFO_out, // output fifo rd_count
   output wire read_enable,
   output wire [15:0] dout,              // output data
   output wire [3:0]  de_out             // output data (deserial)
   );


   //assign variable
   //FIFO IN part
   reg start_FIFO_in_ready;
   reg start_FIFO_in;
   reg first_check;

   wire full_FIFO_in, empty_FIFO_in; // FIFO flags (if full, empty = high)
   wire dout_FIFO_in;                // FIFO output
   wire wr_en_FIFO_in;               // write enable
   wire rd_en_FIFO_in;               // read enable

   assign wr_en_FIFO_in = start_FIFO_in && ~full_FIFO_in;


   //FIFO output part
   reg [15:0] r_dout_rec_FPGA_in;
   reg [ 4:0] r_count16;
   reg        start_FIFO_out;

   reg [2:0] r_count4;

   wire full_FIFO_out, empty_FIFO_out; // FIFO flags (if full, empty = high)
   wire wr_en_FIFO_out;                // write enable
   reg rd_en_FIFO_out;                // read enable
   assign wr_en_FIFO_out = start_FIFO_out && ~full_FIFO_out;
   // assign rd_en_FIFO_out = rd_en_OkPipeOut;
   assign read_enable = rd_en_FIFO_out;

   //Debugging
   assign debug[11] = ~data_CLK;
   assign debug[10] = FPGA_CLK;
   assign debug[9] = wr_en_FIFO_in;
   assign debug[8] = rd_en_FIFO_in;
   assign debug[7] = full_FIFO_in;
   assign debug[6] = empty_FIFO_in;
   assign debug[5] = dout_FIFO_in;
   assign debug[4] = first_check;
   assign debug[3] = wr_en_FIFO_out;
   assign debug[2] = rd_en_FIFO_out;
   assign debug[1] = full_FIFO_out;
   assign debug[0] = empty_FIFO_out;



   //==================================================
   // FIFO control (initialization)
   
   initial begin
      start_FIFO_in_ready = 0;
      start_FIFO_in = 0;
   end

   always @(posedge fifo_trig) begin
      // start_FIFO_in_ready <= ~start_FIFO_in_ready;
      start_FIFO_in_ready <= 1'b1;
   end

   always @(posedge data_CLK) begin
      if (data_trig) begin
         if (~start_FIFO_in_ready) begin
            start_FIFO_in <= 1'b0;
         end
         else begin
            start_FIFO_in <= 1'b1;
         end
      end
      else begin
         start_FIFO_in <= start_FIFO_in;
      end
   end

   /*
   always @(posedge data_trig) begin
      if (~start_FIFO_in_ready) begin
         start_FIFO_in <= 1'b0;
      end
      else begin
         start_FIFO_in <= 1'b1;
      end
   end
   */

   //--------------------------------------------------
   // Data in only
   
   FIFO_control u_FIFO_control( // rd_clk should be faster than wr_clk      
      .rd_clk(FPGA_CLK),
      .reset(RST),
      .empty(empty_FIFO_in),
      .rd_timing(rd_en_FIFO_in)
      );

   
	fifo_1b_1b FIFO_IC_1bit( // 1bit IC in
      .RESET(RST),             // 
      .WCLOCK(~data_CLK),    // 
      .RCLOCK(FPGA_CLK),     // 
      .DATA(din),             // 
      .WE(wr_en_FIFO_in), // 
      .RE(rd_en_FIFO_in), // 
      .Q(dout_FIFO_in),   // 
      .FULL(full_FIFO_in),   // 
      .EMPTY(empty_FIFO_in)  //
   );


   //--------------------------------------------------
   // Data processing between IN/OUT FIFOs & Make wr_en for FIFO out
   
   initial begin
      r_dout_rec_FPGA_in <= 0;
      r_count16 <= 0;
      start_FIFO_out <= 0;
      first_check <= 0;
      r_count4 <= 0;
   end

   always @(posedge FPGA_CLK or posedge RST) begin
      if (RST) begin
         r_dout_rec_FPGA_in <= 0;
         r_count16 <= 0;
         start_FIFO_out <= 0;
         first_check <= 0;
      end
      else begin
         if (rd_en_FIFO_in) begin
            if (!first_check) begin
                r_dout_rec_FPGA_in <= r_dout_rec_FPGA_in;
                first_check <= 1'b1;
            end
            else begin
                r_dout_rec_FPGA_in[0] <= dout_FIFO_in;
                r_dout_rec_FPGA_in[15:1] <= r_dout_rec_FPGA_in[14:0];
                if (r_count16 == 5'd15) begin
                    r_count16 <= 5'd0;
                    start_FIFO_out <= 1'b1;
                end
                else begin
                    r_count16 <= r_count16 + 1'b1;
                    start_FIFO_out <= 0;
                end
            end       
         end
         else begin
            r_dout_rec_FPGA_in <= r_dout_rec_FPGA_in;
            r_count16 <= r_count16;
            start_FIFO_out <= 0;
         end
      end
   end
   //--------------------------------------------------
   // 
//
   ////--------------------------------------------------
   // Data out only
   always @(negedge FPGA_CLK) begin
      if (rd_data_cnt_FIFO_out == 1) begin
         rd_en_FIFO_out = 1;
      end
      else begin
         rd_en_FIFO_out = 0; 
      end
   end
    


   // assign rd_en_FIFO_out = rd_en_OkPipeOut && ~empty_FIFO_out;
   
   fifo_16b_16b FIFO_FPGA_to_PC(
                                        // FIFO wr_depth = 8192 ~= 8sec
      .RESET(RST),
      .WCLOCK(FPGA_CLK),              // modified FPGA CLK (~FPGA_CLK)
      //.RCLOCK(ti_clk),                    // OK FrontPanel CLK
      .RCLOCK(FPGA_CLK),
      .DATA(r_dout_rec_FPGA_in), // ADC raw data
      .WE(wr_en_FIFO_out),                 //
      .RE(1'b1),                 //
      .Q(dout),                     // HI_poA0
      .RDCNT(rd_data_cnt_FIFO_out),            // rd_data_count
      .FULL(full_FIFO_out),                   // to ensure that the FIFO is never full or empty,
      .EMPTY(empty_FIFO_out)                  // python UI will only read a certain amount of data
                                            // when there are sufficient amount of them
    );
    
    
    assign de_out[0] = dout[1];
    assign de_out[1] = dout[5];
    assign de_out[2] = dout[9];
    assign de_out[3] = dout[13];

    /*
    Deserializer_16to4 Deserializer_16to4_u(
    .data_clk(FPGA_CLK),
    .data16(dout),
    .read(rd_en_FIFO_out),
    .reset(RST),

    .data4(de_out)
    );
    */
    

endmodule
