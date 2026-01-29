// ===========================================================================
// Hierarchy
// Global_Control_Top (Semi-top Module)
// ? CLK_Gen (Current Module)
//--------------------------------------------------
// Info
// IC003? ?? CLK ???
//
// - CLK_G (6.144MHz = FDATA x 12): ?? ?? CLK
// - FLED (6.144MHz = FDATA x 12): CLK_G? ??, ? SPI ?? ???
// - FSPI (768kHz = FADC x 12bit)
// - FDATA (512kHz = FADC x 8) <-- ??? CLK ??
// - FADC, FCH (64kHz) <-- ??? CLK ??
// - FDATA_CIC (24kHz)
// - FHARD (8kHz = FDOWN x 8)
// - FDOWN (1kHz)
// 
// ? Warning ?
// CLK? SPI ?? ???? ?? reset
// ===========================================================================
module CLK_Gen_SGC(
    input  wire CLK_G,     // ?? ?? CLK
    input  wire SPI_EN,    // SPI enable, CLK reset
    input  wire RST_S,     // All reset
    output wire FLED,      // LED ??, ADC history reset, = CLK_G
    output wire FSPI,      // SPI IN CLK, 1/8 FLED
    output wire FDATA,     // ADC data ?? CLK, 1/12 FLED
    output wire FADC,      // ADC CLK, 1/8 FDATA
    output wire FCH,       // ADC chopping CLK, = FADC
    output wire FDATA_CIC, // CIC data ?? CLK, 1/32 FSPI
    output wire FHARD,     // Hamadard FE? CLK, 1/8 FADC
    output wire FDOWN      // CIC down sampling CLK, 1/8 FHARD
    );
    //--------------------------------------------------
    // variables
    // - Main

    // ===========================================================================
    // Main Code
    //--------------------------------------------------
    // Reset setting
    wire SPI_EN_RST_S;
    assign SPI_EN_RST_S = SPI_EN | RST_S;

    //--------------------------------------------------
	// Clock Divider
    // - FLED
    reg r_FLED_OFF = 0;
    always @(negedge CLK_G) begin
        r_FLED_OFF <= SPI_EN_RST_S;
    end

    // - FSPI
    reg [2:0] r_FF_chain3_FSPI = 0;
    always @(negedge CLK_G or posedge SPI_EN_RST_S) begin
        if (SPI_EN_RST_S) begin
            r_FF_chain3_FSPI[0] <= 0;
        end
        else begin
            r_FF_chain3_FSPI[0] <= !r_FF_chain3_FSPI[0];
        end
    end
    always @(posedge r_FF_chain3_FSPI[0] or posedge SPI_EN_RST_S) begin
        if (SPI_EN_RST_S) begin
            r_FF_chain3_FSPI[1] <= 0;
        end
        else begin
            r_FF_chain3_FSPI[1] <= !r_FF_chain3_FSPI[1];
        end
    end
    always @(posedge r_FF_chain3_FSPI[1] or posedge SPI_EN_RST_S) begin
        if (SPI_EN_RST_S) begin
            r_FF_chain3_FSPI[2] <= 0;
        end
        else begin
            r_FF_chain3_FSPI[2] <= !r_FF_chain3_FSPI[2];
        end
    end

    // - FDATA
    reg [2:0] J_CNT3 = 0; // 3 register Johnson Counter
    always @(negedge CLK_G or posedge SPI_EN_RST_S) begin
        if (SPI_EN_RST_S) begin
            J_CNT3 <= 0;
        end
        else begin
            J_CNT3[1] <= J_CNT3[0];
            J_CNT3[2] <= J_CNT3[1];
            J_CNT3[0] <= !J_CNT3[2];
        end
    end
    reg r_FDATA = 0;
    always @(posedge J_CNT3[0] or posedge SPI_EN_RST_S) begin
        if (SPI_EN_RST_S) begin
            r_FDATA <= 0;
        end
        else begin
            r_FDATA <= !r_FDATA;
        end
    end
    
    // - FADC & FCH
    reg [2:0] r_FF_chain3_FADC = 0;
    always @(posedge r_FDATA or posedge SPI_EN_RST_S) begin
        if (SPI_EN_RST_S) begin
            r_FF_chain3_FADC[0] <= 0;
        end
        else begin
            r_FF_chain3_FADC[0] <= !r_FF_chain3_FADC[0];
        end
    end
    always @(posedge r_FF_chain3_FADC[0] or posedge SPI_EN_RST_S) begin
        if (SPI_EN_RST_S) begin
            r_FF_chain3_FADC[1] <= 0;
        end
        else begin
            r_FF_chain3_FADC[1] <= !r_FF_chain3_FADC[1];
        end
    end
    always @(posedge r_FF_chain3_FADC[1] or posedge SPI_EN_RST_S) begin
        if (SPI_EN_RST_S) begin
            r_FF_chain3_FADC[2] <= 0;
        end
        else begin
            r_FF_chain3_FADC[2] <= !r_FF_chain3_FADC[2];
        end
    end

    // - FDATA_CIC
    reg [4:0] r_FF_chain5_FDATA_CIC = 0;
    always @(posedge r_FF_chain3_FSPI[2] or posedge SPI_EN_RST_S) begin
        if (SPI_EN_RST_S) begin
            r_FF_chain5_FDATA_CIC[0] <= 0;
        end
        else begin
            r_FF_chain5_FDATA_CIC[0] <= !r_FF_chain5_FDATA_CIC[0];
        end
    end
    always @(posedge r_FF_chain5_FDATA_CIC[0] or posedge SPI_EN_RST_S) begin
        if (SPI_EN_RST_S) begin
            r_FF_chain5_FDATA_CIC[1] <= 0;
        end
        else begin
            r_FF_chain5_FDATA_CIC[1] <= !r_FF_chain5_FDATA_CIC[1];
        end
    end
    always @(posedge r_FF_chain5_FDATA_CIC[1] or posedge SPI_EN_RST_S) begin
        if (SPI_EN_RST_S) begin
            r_FF_chain5_FDATA_CIC[2] <= 0;
        end
        else begin
            r_FF_chain5_FDATA_CIC[2] <= !r_FF_chain5_FDATA_CIC[2];
        end
    end
    always @(posedge r_FF_chain5_FDATA_CIC[2] or posedge SPI_EN_RST_S) begin
        if (SPI_EN_RST_S) begin
            r_FF_chain5_FDATA_CIC[3] <= 0;
        end
        else begin
            r_FF_chain5_FDATA_CIC[3] <= !r_FF_chain5_FDATA_CIC[3];
        end
    end
    always @(posedge r_FF_chain5_FDATA_CIC[3] or posedge SPI_EN_RST_S) begin
        if (SPI_EN_RST_S) begin
            r_FF_chain5_FDATA_CIC[4] <= 0;
        end
        else begin
            r_FF_chain5_FDATA_CIC[4] <= !r_FF_chain5_FDATA_CIC[4];
        end
    end

    // - FHARD
    reg [2:0] r_FF_chain3_FHARD = 0;
    always @(posedge r_FF_chain3_FADC[2] or posedge SPI_EN_RST_S) begin
        if (SPI_EN_RST_S) begin
            r_FF_chain3_FHARD[0] <= 0;
        end
        else begin
            r_FF_chain3_FHARD[0] <= !r_FF_chain3_FHARD[0];
        end
    end
    always @(posedge r_FF_chain3_FHARD[0] or posedge SPI_EN_RST_S) begin
        if (SPI_EN_RST_S) begin
            r_FF_chain3_FHARD[1] <= 0;
        end
        else begin
            r_FF_chain3_FHARD[1] <= !r_FF_chain3_FHARD[1];
        end
    end
    always @(posedge r_FF_chain3_FHARD[1] or posedge SPI_EN_RST_S) begin
        if (SPI_EN_RST_S) begin
            r_FF_chain3_FHARD[2] <= 0;
        end
        else begin
            r_FF_chain3_FHARD[2] <= !r_FF_chain3_FHARD[2];
        end
    end

    // - FDOWN
    reg [2:0] r_FF_chain3_FDOWN = 0;
    always @(posedge r_FF_chain3_FHARD[2] or posedge SPI_EN_RST_S) begin
        if (SPI_EN_RST_S) begin
            r_FF_chain3_FDOWN[0] <= 0;
        end
        else begin
            r_FF_chain3_FDOWN[0] <= !r_FF_chain3_FDOWN[0];
        end
    end
    always @(posedge r_FF_chain3_FDOWN[0] or posedge SPI_EN_RST_S) begin
        if (SPI_EN_RST_S) begin
            r_FF_chain3_FDOWN[1] <= 0;
        end
        else begin
            r_FF_chain3_FDOWN[1] <= !r_FF_chain3_FDOWN[1];
        end
    end
    always @(posedge r_FF_chain3_FDOWN[1] or posedge SPI_EN_RST_S) begin
        if (SPI_EN_RST_S) begin
            r_FF_chain3_FDOWN[2] <= 0;
        end
        else begin
            r_FF_chain3_FDOWN[2] <= !r_FF_chain3_FDOWN[2];
        end
    end

	//--------------------------------------------------
	// Clock Synchronize
    reg r_FSPI_sync = 0, r_FDATA_sync = 0, r_FADC_sync = 0, r_FDATA_CIC_sync = 0, r_FHARD_sync = 0, r_FDOWN_sync = 0; // r_FLED_sync = 0, r_FCH_sync = 0, 
    always @(posedge CLK_G or posedge SPI_EN_RST_S) begin
        if (SPI_EN_RST_S) begin
            r_FSPI_sync <= 0;
            r_FDATA_sync <= 0;
            r_FADC_sync <= 0;
            // r_FCH_sync <= 0;
            r_FDATA_CIC_sync <= 0;
            r_FHARD_sync <= 0;
            r_FDOWN_sync <= 0;
        end
        else begin
            r_FSPI_sync <= r_FF_chain3_FSPI[2];
            r_FDATA_sync <= r_FDATA;
            r_FADC_sync <= r_FF_chain3_FADC[2];
            // r_FCH_sync <= r_FF_chain3_FADC[2];
            r_FDATA_CIC_sync <= r_FF_chain5_FDATA_CIC[4];
            r_FHARD_sync <= r_FF_chain3_FHARD[2];
            r_FDOWN_sync <= r_FF_chain3_FDOWN[2];
        end
    end
    assign FLED = (CLK_G & !(SPI_EN_RST_S | r_FLED_OFF)); // CLK_G ??: 1 AND gate delay
    assign FSPI = r_FSPI_sync;                      // CLK_G ??: 1 FF delay
    assign FDATA = r_FDATA_sync;                    // CLK_G ??: 1 FF delay
    assign FADC = r_FADC_sync;                      // CLK_G ??: 1 FF delay
    assign FCH = r_FADC_sync;                       // CLK_G ??: 1 FF delay
    assign FDATA_CIC = r_FDATA_CIC_sync;            // CLK_G ??: 1 FF delay
    assign FHARD = r_FHARD_sync;                    // CLK_G ??: 1 FF delay
    assign FDOWN = r_FDOWN_sync;                    // CLK_G ??: 1 FF delay

    // ===========================================================================
endmodule