///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: earEEG_prototype.v
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

// `default_nettype none // disable implicit nets to reduce some types of bugs
// ================================================================
// Module Name: earEEG_prototype()
// ================================================================
// This module is
// - Top module that receive(send) input(output) signals from(to) outside
// - Top module that control & generate other modules and signals
// ================================================================

module earEEG_prototype #(parameter OSR = 64, parameter BIT = 12) (
    input wire sys_clk_ori,   // System Clock 200MHz
    input wire reset,     // Active High
    // input wire previn,    // Active High
    input wire NEXTOUT,

   // input  wire  [7:0] previn_code, // Used for PREVIN 
    
    // for debugging
    // output previn_cnt_debug,
    // output previn_debug,
    // output wire [3:0] de_out_debug,
    // output wire [11:0] FIFOdebug_debug,
    // output wire [11:0] ADCOUT_dummy_debug,
    //output wire [BIT+2*$clog2(OSR)-1:0] CIC_OUT_debug1,
    //output wire [BIT+2*$clog2(OSR)-1:0] CIC_OUT_debug2,
    //output wire [(BIT+2*$clog2(OSR))*2-1:0] CIC_OUT_2ch_debug0,
    //output wire [(BIT+2*$clog2(OSR))*2-1:0] CIC_OUT_2ch_debug1,
    //output wire [(BIT+2*$clog2(OSR))*2-1:0] CIC_OUT_2ch_debug2,
    //output wire [(BIT+2*$clog2(OSR))*2-1:0] CIC_OUT_2ch_copy_debug0,
    //output wire [(BIT+2*$clog2(OSR))*2-1:0] CIC_OUT_2ch_copy_debug1,
    //output wire [(BIT+2*$clog2(OSR))*2-1:0] CIC_OUT_2ch_copy_debug2,
    // output wire [6:0] slave_address_debug,
    //output wire full_debug,

    input wire SCL,
    inout wire SDA,
    output wire [1:0] debug_I2C,
    // output wire stop_sign_debug,
    // output wire check_debug,
    //----------------------------------------------

    // output wire [BIT+2*$clog2(OSR)-1:0] CIC,
    output wire [7:0] outputs  // Outputs[7:0]
                              // : fadc_G, fch_G, READ_G, LOAD_G, fdata_G, previn, reset, fdown

   );

    INBUF INBUF_0(
        .PAD ( sys_clk_ori ),	
        .Y   ( sys_clk ) 
    );

    reg previn_cnt;
    reg previn;

    reg [7:0] r_outputs_sync;
    reg rst_n;
    reg r_R_L_con;
    wire [5:0] new_clks; // fdown, fadc_G, fch_G, READ_G, LOAD_G, fdata_G
    wire R_L_state; 
    wire previn_ori;
    reg [7:0] previn_code;

    wire [11:0] FIFOdebug;
    wire [15:0] dout;
    wire [3:0] de_out;
    wire read_enable;

    wire [11:0] ADCOUT1;
    wire [11:0] ADCOUT2;
    // wire signed [11:0] ADCOUT_dummy1;
    // wire signed [11:0] ADCOUT_dummy2;

    // wire  [BIT+2*$clog2(OSR)-1:0] INT_1ST;
    // wire  [BIT+2*$clog2(OSR)-1:0] INT_2ND;
    // wire  [BIT+2*$clog2(OSR)-1:0] DOWN_DATA;
    // wire  [BIT+2*$clog2(OSR)-1:0] DIFF_1ST;
    wire  [BIT+2*$clog2(OSR)-1:0] CIC_OUT1;
    wire  [BIT+2*$clog2(OSR)-1:0] CIC_OUT2;


    // assign outputs = r_outputs_sync;
    assign outputs[0] = r_outputs_sync[0];
    assign outputs[1] = !r_outputs_sync[1];
    assign outputs[2] = r_outputs_sync[2];
    assign outputs[3] = r_outputs_sync[3];
    assign outputs[4] = r_outputs_sync[4];
    assign outputs[5] = r_outputs_sync[5];
    assign outputs[6] = r_outputs_sync[6];
    assign outputs[7] = r_outputs_sync[7];
    // assign CIC = CIC_OUT;
    //--------------------------------------------------

    // Sync outputs
    always @(posedge sys_clk or negedge rst_n) begin //  delay , 
        if (!rst_n) begin
            r_outputs_sync <= 0;
        end
        else begin
            r_outputs_sync <= {(new_clks[4]),  // fadc_G
                            (new_clks[3]),  // fch_G
                            (new_clks[2]),  // READ_G
                            (new_clks[1]),  // LOAD_G
                            (new_clks[0]),  // fdata_G
                            (previn_ori),   // PREVIN
                            (rst_n),        // rst_n
                            (new_clks[5])};        // fdown
        end
    end
   
   //==================================================

    initial begin
        rst_n <= 1'b1;
        r_R_L_con <= 1'b0;
        previn_cnt <= 1'b0;
    end

    always @(posedge reset) begin
        rst_n <= ~rst_n;
    end

    
    always @(negedge new_clks[0] or negedge rst_n) begin
        if (!rst_n) begin
            previn <= 1'b0;
            previn_cnt <= 1'b0;
        end
        else begin
            if (!previn_cnt) begin
                previn_cnt <= 1'b1;
                previn <= ~previn;
            end
            else begin
                previn_cnt <= previn_cnt;
            end
        end
    end

    always @(posedge previn or negedge rst_n) begin
        if (!rst_n) begin
            r_R_L_con <= 1'b0;
        end
        else begin
            // r_R_L_con <= ~r_R_L_con;
            r_R_L_con <= 1'b1;
        end
    end


   //--------------------------------------------------


    clk_gen m_clk_gen(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .new_clks(new_clks),
        .R_L_con(r_R_L_con),
        .R_L_state(R_L_state)
    );

    previn_gen m_previn_gen(
        .fdata_G(new_clks[0] & R_L_state),
        .rst_n(rst_n),         // reset active low
        .previn_trig(previn),  // previn trigger input
        .previn_code(8'b00000111),
        .previn(previn_ori)   // Out
    );


    
    FIFO_MCU FIFO_MCU_u(
        .debug(FIFOdebug),

        .FPGA_CLK(sys_clk),         // sys_clk
        .ti_clk(new_clks[2]),        // Communication clk (READ_G)
        .data_CLK(new_clks[0]),      // FDATA_G
        .RST(!rst_n),                // reset
        .fifo_trig(new_clks[1]),     // fifo start trigger (LOAD_G)
        .din(NEXTOUT),              // input data
        .rd_en_OkPipeOut(1'b1),     // [NOT USED NOW] output fifo rd_en (okPipeOut ep_read)
        .data_trig(new_clks[2]),     // READ_G
        .rd_data_cnt_FIFO_out(),    // output fifo rd_count
        .read_enable(read_enable),  // for DSM
        .dout(dout),                // output data
        .de_out(de_out)             // deserialized output data
    );
    
    // Hook-ch2 | Base-ch4 | foam-ch1&3
    // de_out[0] - ch4
    // de_out[1] - ch1
    // de_out[2] - ch2
    // de_out[3] - ch3

    DSM_to_Binary DSM_to_Binary_u0(
        .clk(!new_clks[4]),          // ~FADC_G
        .reset(!rst_n),
        .in_stream(de_out[0]),      // 4bit deserialized output
        .start_trig(read_enable),   // start trigger

        .out_data(ADCOUT1)    // DSM output (-2048~2047)
        //.out_data_pos(ADCOUT1)       // DSM output (0~4095)
    );

    DSM_to_Binary DSM_to_Binary_u2(
        .clk(!new_clks[4]),          // ~FADC_G
        .reset(!rst_n),
        .in_stream(de_out[1]),      // 4bit deserialized output
        .start_trig(read_enable),   // start trigger

        .out_data(ADCOUT2)    // DSM output (-2048~2047)
        //.out_data_pos(ADCOUT2)       // DSM output (0~4095)
    );


    CICfilter #(.OSR(OSR), .BIT(BIT)) CICfilter_u0(
        .RST_S(!rst_n),
        .FADC(new_clks[4]),
        .FDOWN(new_clks[5]),
        .RECOV_DATA(ADCOUT1),
        .CIC_OUT(CIC_OUT1)        
    );

    CICfilter #(.OSR(OSR), .BIT(BIT)) CICfilter_u2(
        .RST_S(!rst_n),
        .FADC(new_clks[4]),
        .FDOWN(new_clks[5]),
        .RECOV_DATA(ADCOUT2),
        .CIC_OUT(CIC_OUT2)        
    );


    reg [6:0] slave_address;
    wire stop_sign;

    reg [47:0] CIC_OUT_2ch [0:35];
    reg [47:0] CIC_OUT_2ch_copy [0:35];
    
    // assign CIC_OUT_2ch_imsi = {24'b1010_1111_1100_0000_0110_0000, 24'b0000_0110_0000_1100_1111_1010};
    
    reg [5:0] CIC_cnt = 0;
    reg [5:0] i;
    
    wire [5:0] done_cnt;

    reg full_check;

    always @(posedge new_clks[5]) begin
        CIC_OUT_2ch[CIC_cnt] = {CIC_OUT1, CIC_OUT2};
        CIC_cnt = CIC_cnt + 1;
        if (CIC_cnt == 36) begin
            CIC_cnt = 0;
            full_check = 1;
            for(i=0;i<36;i=i+1) begin
                CIC_OUT_2ch_copy[i] = CIC_OUT_2ch[i];
            end
        end
        else begin
            full_check = 0;
        end
    end
    
    
    
    I2C_slave_txrx I2C_slave_txrx_u (
        .sys_clk(sys_clk),
        .reset(!rst_n),
        .sda(SDA),
        .scl(SCL),
        .slave_address(7'b1011000),
        //.stop_sign(stop_sign),
        .fdown(new_clks[5]),
        .full_CIC(full_check),

        .in_from_CIC(CIC_OUT_2ch_copy[done_cnt]),
 
        .done(done_cnt),
        // output wire [2:0] debug4,
        // output wire [6:0] debug3,
        // output wire [4:0] debug2,
        .debug(debug_I2C)
    );
    
    /*
    reg check = 0;
    always @(posedge new_clks[5] or posedge stop_sign) begin
        if (stop_sign) begin
            slave_address <= 7'b0000000;
            check <= 0;
        end

        else if (!stop_sign) begin
            slave_address <= 7'b0000000;
            check <= 0;
        end

        if (new_clks[5]) begin
            slave_address <= 7'b1011000;
            check <= 1;
        end
    end
    */
    

    /*
    always @(posedge new_clks[5]) begin
        if (new_clks[5]) begin
            slave_address <= 7'b1011000;
        end
    end

    always @(posedge stop_sign) begin
        if (stop_sign) begin
            slave_address <= 7'b0000000;
        end
    end
    */


    /*
    parameter TEST_OUT_DIR = "C:/Microsemi/NEXTOUT_DATA/";
    integer my_file;
    
    always @(posedge reset) begin
        my_file = $fopen({TEST_OUT_DIR,"CIC.csv"}, "w");
        $fdisplay(my_file, "%s,%s,%s,%s,%s,%s,%s,%s", "Time", "RECOV_DATA", "INT_1ST", "INT_2ND", "DOWN_DATA", "DIFF_1ST", "CIC_OUT", "OSR");
        $fclose(my_file);
    end
    
    always @* begin
        @(negedge new_clks[4]);
        @(negedge new_clks[4]);
        forever begin
            @(negedge new_clks[4]);
            $fdisplay(my_file, "%f,%d,%d,%d,%d,%d,%d,%d", $realtime, ADCOUT, INT_1ST, INT_2ND, DOWN_DATA, DIFF_1ST, CIC_OUT, OSR);
        end
        //$fclose(my_file);
    end
    */


    // for bebugging
    // assign de_out_debug = de_out;
    // assign FIFOdebug_debug = FIFOdebug;
    // assign ADCOUT_dummy_debug = ADCOUT_dummy;
    //assign CIC_OUT_debug1 = CIC_OUT1;
    //assign CIC_OUT_debug2 = CIC_OUT2;
    //assign CIC_OUT_2ch_debug0 = CIC_OUT_2ch[0];
    //assign CIC_OUT_2ch_debug1 = CIC_OUT_2ch[1];
    //assign CIC_OUT_2ch_debug2 = CIC_OUT_2ch[2];
    //assign CIC_OUT_2ch_copy_debug0 = CIC_OUT_2ch_copy[0];
    //assign CIC_OUT_2ch_copy_debug1 = CIC_OUT_2ch_copy[1];
    //assign CIC_OUT_2ch_copy_debug2 = CIC_OUT_2ch_copy[2];
    // assign slave_address_debug = slave_address;
    // assign stop_sign_debug = stop_sign;
    //assign full_debug = full_check;
    // assign previn_cnt_debug = previn_cnt;
    // assign previn_debug = previn;
    
    // --------------------------------------------------------------------

endmodule