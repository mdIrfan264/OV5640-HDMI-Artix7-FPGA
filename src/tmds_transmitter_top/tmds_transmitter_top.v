// tmds_transmitter_top.v
// Top-level that instantiates three OutputSERDES modules (for R, G, B)
// and provides a differential TMDS clock output.
//
// Inputs:
//   PixelClk  - pixel clock (1x), also used for TMDS clock pair
//   SerialClk - high-speed clock for serialization (5x PixelClk)
//   aRst      - async reset
//   tmds_r/g/b - 10-bit TMDS encoded words from TMDS encoder for each channel
//
// Outputs:
//   TMDS_Clk_p/n  - differential TMDS clock pair
//   TMDS_Data0_p/n - Blue channel (usually channel 0)
//   TMDS_Data1_p/n - Green channel (usually channel 1)
//   TMDS_Data2_p/n - Red channel (usually channel 2)

module tmds_transmitter_top (
    input  wire         PixelClk,     // Pixel clock (1x)
    input  wire         SerialClk,    // Serializer clock (5x PixelClk)
    input  wire         aRst,         // Async reset (active high)

    input  wire [9:0]   tmds_r,       // TMDS encoded Red channel (10-bit)
    input  wire [9:0]   tmds_g,       // TMDS encoded Green channel (10-bit)
    input  wire [9:0]   tmds_b,       // TMDS encoded Blue channel (10-bit)

    // TMDS differential outputs
    output wire         TMDS_Clk_p,
    output wire         TMDS_Clk_n,
    output wire         TMDS_Data0_p,
    output wire         TMDS_Data0_n,
    output wire         TMDS_Data1_p,
    output wire         TMDS_Data1_n,
    output wire         TMDS_Data2_p,
    output wire         TMDS_Data2_n
);

    // ---------------------------------------------------------
    // TMDS Clock output:
    // For DVI/HDMI the TMDS clock pair toggles at pixel clock rate.
    // A common simple approach is to drive the differential buffer
    // directly with PixelClk (OBUFDS). This is fine for many boards.
    // More advanced implementations use a DDR serializer to produce
    // a 10-bit pattern for the clock line; for most use cases driving
    // PixelClk differentially is acceptable.
    // ---------------------------------------------------------
    OBUFDS #(
        .IOSTANDARD("TMDS_33")
    ) tmdo_clk_buf (
        .I (PixelClk),
        .O (TMDS_Clk_p),
        .OB(TMDS_Clk_n)
    );

    // ---------------------------------------------------------
    // Instantiate three single-channel serializers.
    // The OutputSERDES module should perform:
    //  - bit reversal (LSB-first mapping),
    //  - OSERDESE2 master/slave cascade
    //  - OBUFDS to produce differential pair.
    //
    // We assume the OutputSERDES module interface:
    //   OutputSERDES #(.kParallelWidth(10)) inst (
    //      .PixelClk(PixelClk),
    //      .SerialClk(SerialClk),
    //      .aRst(aRst),
    //      .pDataOut(tmds_x),
    //      .sDataOut_p(...),
    //      .sDataOut_n(...)
    //   );
    // ---------------------------------------------------------

    // Blue channel (Data0)
    OutputSERDES #(
        .kParallelWidth(10)
    ) serdes_blue (
        .PixelClk  (PixelClk),
        .SerialClk (SerialClk),
        .aRst      (aRst),
        .pDataOut  (tmds_b),
        .sDataOut_p(TMDS_Data0_p),
        .sDataOut_n(TMDS_Data0_n)
    );

    // Green channel (Data1)
    OutputSERDES #(
        .kParallelWidth(10)
    ) serdes_green (
        .PixelClk  (PixelClk),
        .SerialClk (SerialClk),
        .aRst      (aRst),
        .pDataOut  (tmds_g),
        .sDataOut_p(TMDS_Data1_p),
        .sDataOut_n(TMDS_Data1_n)
    );

    // Red channel (Data2)
    OutputSERDES #(
        .kParallelWidth(10)
    ) serdes_red (
        .PixelClk  (PixelClk),
        .SerialClk (SerialClk),
        .aRst      (aRst),
        .pDataOut  (tmds_r),
        .sDataOut_p(TMDS_Data2_p),
        .sDataOut_n(TMDS_Data2_n)
    );

endmodule
