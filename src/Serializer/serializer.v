//======================================
// Serializer for TMDS HDMI Data
// Converts 10-bit parallel TMDS data to 1-bit high-speed serial
// using Xilinx OSERDESE2 primitive.
//======================================
module tmds_serializer (
    input  wire        clk_serial,    // 5x or 10x pixel clock (e.g., 742.5 MHz for 74.25 MHz pixel clock)
    input  wire        clk_pixel,     // pixel clock (e.g., 74.25 MHz)
    input  wire [9:0]  tmds_data,     // 10-bit parallel TMDS encoded data
    output wire        tmds_serial    // high-speed serial output
);

    // OSERDESE2 works with 8:1 or 10:1 using DDR mode
    // We split the 10-bit data into two groups:
    // First 8 bits loaded normally, last 2 bits loaded in the shift register

    wire shift1, shift2; // For extra bits beyond 8

    // First OSERDESE2 instance — handles first 8 bits
    OSERDESE2 #(
        .DATA_RATE_OQ   ("DDR"),      // Double Data Rate
        .DATA_RATE_TQ   ("SDR"),      // Not used here
        .DATA_WIDTH     (10),         // 10 bits total
        .TRISTATE_WIDTH (1),
        .SERDES_MODE    ("MASTER")
    ) oserdes_master (
        .OQ     (tmds_serial),  // Output to pin/OBUFDS
        .OFB    (),
        .TQ     (),
        .CLK    (clk_serial),   // High-speed clock
        .CLKDIV (clk_pixel),    // Pixel clock
        .D1     (tmds_data[0]),
        .D2     (tmds_data[1]),
        .D3     (tmds_data[2]),
        .D4     (tmds_data[3]),
        .D5     (tmds_data[4]),
        .D6     (tmds_data[5]),
        .D7     (tmds_data[6]),
        .D8     (tmds_data[7]),
        .SHIFTIN1 (shift1),     // From slave
        .SHIFTIN2 (shift2),
        .SHIFTOUT1(),
        .SHIFTOUT2(),
        .OCE    (1'b1),         // Output clock enable
        .TCE    (1'b0),
        .RST    (1'b0),
        .T1     (1'b0),
        .T2     (1'b0),
        .T3     (1'b0),
        .T4     (1'b0)
    );

    // Second OSERDESE2 instance — handles last 2 bits
    OSERDESE2 #(
        .DATA_RATE_OQ   ("DDR"),
        .DATA_RATE_TQ   ("SDR"),
        .DATA_WIDTH     (10),
        .TRISTATE_WIDTH (1),
        .SERDES_MODE    ("SLAVE")
    ) oserdes_slave (
        .OQ     (),
        .OFB    (),
        .TQ     (),
        .CLK    (clk_serial),
        .CLKDIV (clk_pixel),
        .D1     (tmds_data[8]),
        .D2     (tmds_data[9]),
        .D3     (1'b0), // Unused
        .D4     (1'b0),
        .D5     (1'b0),
        .D6     (1'b0),
        .D7     (1'b0),
        .D8     (1'b0),
        .SHIFTIN1 (1'b0),
        .SHIFTIN2 (1'b0),
        .SHIFTOUT1(shift1),     // Send to master
        .SHIFTOUT2(shift2),
        .OCE    (1'b1),
        .TCE    (1'b0),
        .RST    (1'b0),
        .T1     (1'b0),
        .T2     (1'b0),
        .T3     (1'b0),
        .T4     (1'b0)
    );

endmodule
