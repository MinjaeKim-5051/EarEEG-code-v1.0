///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: i2c_slave_txrx.v
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

module I2C_slave_txrx(
    input wire sys_clk,
    input wire reset,
    inout wire sda,
    input wire scl,
    input wire [6:0] slave_address,
    input wire fdown,

    input wire [47:0] in_from_CIC,
    input wire full_CIC,

    output wire [7:0] done,
    // output wire [2:0] debug4,
    // output wire [6:0] debug3,
    // output wire [4:0] debug2,
    output wire [1:0] debug
    
);
    
    // Address setting
    // reg [6:0] slave_address;
    // assign slave_address = 7'b1011000;
    

    // Internal Signals
    // ------------------------------------------------------------
    reg [47:0] data_to_mcu;
    reg [4:0] bit_cnt = 0;
    reg [6:0] received_address = 0;
    reg read_bit; // Master 1 -> read , 0 -> write

    reg [7:0] done_cnt = 0;
    assign done = done_cnt;
    // ------------------------------------------------------------


    // SDA, SCL edge detection
    // ------------------------------------------------------------
    reg [2:0] scl_synch = 3'b000;

    always @(posedge sys_clk) begin
        scl_synch = {scl_synch[1:0], scl};
    end 

    wire scl_posedge = (scl_synch[1:0] == 2'b01); 
    wire scl_negedge = (scl_synch[1:0] == 2'b10);

    reg [2:0] sda_synch = 3'b000;

    always @(posedge sys_clk) begin
        sda_synch = {sda_synch[1:0], sda};
    end

    wire sda_synched = sda_synch[0] & sda_synch[1] & sda_synch[2];
    // ------------------------------------------------------------



    // Start and Stop Detection
    // ------------------------------------------------------------
    reg start = 1'b0;
    reg stop = 1'b0;
    reg address_match = 1'b0;

    always @(negedge sda) begin
        start = scl;
    end

    always @(posedge sda) begin
        stop = scl;
    end
    // ------------------------------------------------------------
    


    // Set cycle state
    // ------------------------------------------------------------
    reg incycle = 1'b0;

    always @(posedge start or posedge stop) begin
        if (start) begin
            incycle <= 1'b1;
        end

        else if (stop) begin    
            incycle <= 1'b0;
        end
    end
    // ------------------------------------------------------------
   

    /*
    wire fifo_full;
    wire fifo_empty;
    reg [11:0] rdcnt;
    reg read_en = 0;
    reg [23:0] gotoMCU;
    
    fifo_24b_24b FIFO_I2C( // 1bit IC in
        .RESET(reset),             // 
        .WCLOCK(fdown),    // 
        .RCLOCK(fdown),     // 
        .DATA(in_from_CIC),             // 
        .WE(1'b1), // 
        .RE(read_en), // 
        .Q(gotoMCU),   // 
        .FULL(fifo_full),   // 
        .EMPTY(fifo_empty),
        .RDCNT(rdcnt) //
    );

    always @(negedge fdown) begin
        if (rdcnt == 1) begin
            read_en <= 1;
            slave_address <= 7'b1011000;
        end
        else begin
            read_en <= 0;
            slave_address <= 7'b0000000;
        end
    end
    */


    // I2C logic operation
    // ------------------------------------------------------------
    reg sda_data = 1'bz;
    reg [3:0] current_value;

    always @(posedge scl_posedge or negedge incycle) begin
        if (~incycle) begin
            bit_cnt = 0;
            received_address = 0;
            address_match = 0;
        end

        else begin
            if (bit_cnt == 17) begin
                bit_cnt = 9;
            end

            else begin
                bit_cnt = bit_cnt + 1;
                if (bit_cnt < 8) begin
                    received_address[7 - bit_cnt] = sda_synched;
                end

                else if (bit_cnt == 8) begin
                    read_bit = sda_synched; 
                    address_match = (slave_address == received_address) ? 1'b1 : 1'b0;
                end
            end
        end
    end


    reg full_reg = 1;
    reg full_check;

    always @(posedge scl_negedge or posedge reset) begin
        if (reset) begin
            done_cnt = 0;
            full_reg = 1;
        end

        else begin
            if (full_CIC) begin
                full_check = 1;
                done_cnt = 0;
            end
            else begin
                if (!full_reg) begin
                    full_check = 0;
                end
                else begin
                    full_check = 1;
                end
            end

            if ((bit_cnt == 8) & (address_match) & (full_check)) begin
                data_to_mcu <= in_from_CIC;
                // data_to_mcu <= {full_CIC, 3'b000, full_check, 3'b000, done_cnt, in_from_CIC[7:0], full_CIC, 3'b000, full_check, 3'b000, done_cnt, in_from_CIC[7:0]};
                current_value = 0;
                sda_data = 1'b0;
            end

            else if ((bit_cnt >= 9) & (read_bit) & (address_match) & (current_value < 6) & (full_check)) begin
                if ((bit_cnt - 9) == 8) begin
                    sda_data = 1'bz;
                    current_value = current_value + 1;
                    data_to_mcu <= data_to_mcu >> 8;
                    
                    if (current_value == 6) begin
                        done_cnt = done_cnt + 1;
                    end

                    if (done_cnt == 36) begin
                        done_cnt = 0;
                        full_reg = 0;
                    end

                    else if (done_cnt < 36) begin
                        full_reg = 1;
                    end 
                end

                else begin
                    sda_data = data_to_mcu[7 - (bit_cnt - 9)]; 
                end
            end

            else begin
                sda_data = 1'bz;
            end
        end
    end
    
    assign sda = sda_data;


    // ------------------------------------------------------------


    // Debugging parameter
    // ------------------------------------------------------------
    
    // assign debug[8] = address_match;
    // assign debug[7] = incycle;
    // assign debug[6] = start;
    // assign debug[5] = read_bit;
    // assign debug[4] = 1'b0;
    // assign debug[3] = 1'b1;
    // assign debug[2] = full_reg; // sda_data;
    assign debug[1] = sda;
    assign debug[0] = scl;
    // assign debug2 = bit_cnt;
    // assign debug3 = received_address;
    // assign debug4 = current_value;
    
    //assign debug_bit_cnt[0] = bit_cnt[0];
    //assign debug_bit_cnt[1] = bit_cnt[1];
    //assign debug_bit_cnt[2] = bit_cnt[2];
    //assign debug_bit_cnt[3] = bit_cnt[3];


    // ------------------------------------------------------------

endmodule
