`timescale 1ns / 1ps

module top
(
    input  logic SysRefClk_p,
    input  logic SysRefClk_n,
    input  logic cpu_resetn,
    input  logic btnc,

    output logic led0,
    output logic led1,
    output logic led2,
    output logic led3,

    // ADC Data Interface
    input  logic DCLK_p_pin,
    input  logic DCLK_n_pin,
    input  logic FCLK_p_pin,
    input  logic FCLK_n_pin,
    input  logic [11:0] DATA_p_pin,
    input  logic [11:0] DATA_n_pin,

    // UART
    input  logic usb_uart_rxd,
    output logic usb_uart_txd,

    // SPI
    output logic CSB1,
    output logic CSB2,
    inout  logic SDIO,
    output logic SCLK,

    // Gigabit Ethernet
    output logic [3:0] eth_txd,
    output logic ETH_TX_EN,
    output logic eth_txck,
    output logic ETH_PHYRST_N,

    input logic eth_rxck,
    input logic eth_rxctl,
    input logic [3:0] eth_rxd
);

    // MMCM signals
    logic clk_100m, clk_50m, clk_125m, clk_125m90, clk_200m;
    logic dcm_locked;

    // ADC Signals
    logic adc_clk, aligned, en_synced;
    logic [15:0] adc1, adc2, adc3, adc4, adc7, adc8;
    logic [7:0] frmData;

    // Microblaze Signals
    logic [31:0] MB_O;

    // Buffering Signals
    logic  eth_valid, tick, eth_data_tlast;
    logic [7:0] eth_data;

    // Input signals
    logic btnc_db;

    // Reset Signals
    logic adc_rst_n, rst_125m_n, rst_125m;

    // IODELAY elements for RGMII interface to PHY
    logic [3:0] eth_rxd_delay;
    logic       eth_rxctl_delay;

    logic sendAdcData;

    assign led0 = dcm_locked;
    assign led1 = 0;
    assign led2 = MB_O[0];
    assign led3 = MB_O[1];
    assign ETH_PHYRST_N = rst_125m_n;

    clk_wiz_0 MMCM
    (
        // Clock out ports
        .clk_100m(clk_100m),        // output clk_100m
        .clk_50m(clk_50m),          // output clk_50m
        .clk_125m(clk_125m),        // output clk_125m
        .clk_125m90(clk_125m90),    // output clk_125m90
        .clk_200m(clk_200m),        // output clk_200m

        // Status signal
        .locked(dcm_locked),        // output locked

        // Clock in ports
        .clk_in1_p(SysRefClk_p),    // input clk_in1_p
        .clk_in1_n(SysRefClk_n)     // input clk_in1_n
    );

    db_fsm debouncer
    (
        .clk(clk_125m),
        .reset(rst_125m),
        .sw(btnc),
        .db(btnc_db)
    );

    edge_detect_moore edge_detector
    (
        .clk(clk_125m),
        .reset(rst_125m),
        .level(btnc_db),
        .tick(tick)
    );

    simpleCDC enCDC
    (
        .sourceClk(clk_100m),
        .destClk(adc_clk),
        .d_in(MB_O[0]),
        .d_out(en_synced)
    );

    rstBridge cdcReset
    (
        .clk(adc_clk),
        .asyncrst_n(cpu_resetn),
        .rst_n(adc_rst_n)
    );

    rstBridge rst_cross_125m
    (
        .clk(clk_125m),
        .asyncrst_n(cpu_resetn),
        .rst_n(rst_125m_n)
    );

    IDELAYCTRL
    idelayctrl_inst
    (
        .REFCLK(clk_200m),
        .RST(rst_125m),
        .RDY()
    );

    assign rst_125m = ~rst_125m_n;

    ADC_Control_wrapper MB
    (
        .clk_100m(clk_100m),
        .clk_50m(clk_50m),
        .dcm_locked(dcm_locked),
        .cpu_resetn(cpu_resetn),

        .ADC_CSB1(CSB1),
        .ADC_CSB2(CSB2),
        .ADC_SCLK(SCLK),
        .ADC_SDIO(SDIO),

        .usb_uart_rxd(usb_uart_rxd),
        .usb_uart_txd(usb_uart_txd),

        .O(MB_O)
    );

    adc_interface adc_inst
    (
        .DCLK_p_pin(DCLK_p_pin),
        .DCLK_n_pin(DCLK_n_pin),
        .FCLK_p_pin(FCLK_p_pin),
        .FCLK_n_pin(FCLK_n_pin),

        .rst_n(cpu_resetn),
        .adc_en(en_synced),

        // ADC 1
        .d0a1_p(DATA_p_pin[6]),
        .d0a1_n(DATA_n_pin[6]),
        .d1a1_p(DATA_p_pin[7]),
        .d1a1_n(DATA_n_pin[7]),

        // ADC 3
        .d0b1_p(DATA_p_pin[8]),
        .d0b1_n(DATA_n_pin[8]),
        .d1b1_p(DATA_p_pin[9]),
        .d1b1_n(DATA_n_pin[9]),

        // ADC 2
        .d0a2_p(DATA_p_pin[0]),
        .d0a2_n(DATA_n_pin[0]),
        .d1a2_p(DATA_p_pin[1]),
        .d1a2_n(DATA_n_pin[1]),

        // ADC 4
        .d0b2_p(DATA_p_pin[2]),
        .d0b2_n(DATA_n_pin[2]),
        .d1b2_p(DATA_p_pin[3]),
        .d1b2_n(DATA_n_pin[3]),

        // ADC 7
        .d0d1_p(DATA_p_pin[10]),
        .d0d1_n(DATA_n_pin[10]),
        .d1d1_p(DATA_p_pin[11]),
        .d1d1_n(DATA_n_pin[11]),

        // ADC 8
        .d0d2_p(DATA_p_pin[4]),
        .d0d2_n(DATA_n_pin[4]),
        .d1d2_p(DATA_p_pin[5]),
        .d1d2_n(DATA_n_pin[5]),

        // Deserialized output
        .adc1(adc1),
        .adc2(adc2),
        .adc3(adc3),
        .adc4(adc4),
        .adc7(adc7),
        .adc8(adc8),

        // Clocks and Status Outputs
        .divclk_o(adc_clk),
        .frmData(frmData),

        .aligned(aligned)
    );

    logic eth_tready, udp_hdr_valid, tx_done;

    adc_buffer adc_buffer (
        .start_buff(aligned & sendAdcData),
        //.start_buff(aligned & tick),
        //.start_buff(aligned),

        .din_clk(adc_clk),
        .din_rst_n(adc_rst_n),
        .din_valid(aligned),

        .adc1(adc1),
        .adc2(adc2),
        .adc3(adc3),
        .adc4(adc4),
        .adc7(adc7),
        .adc8(adc8),

        .dout_clk(clk_125m),
        .dout_rst_n(rst_125m_n),

        .dout(eth_data),
        .dout_valid(eth_valid),
        .tx_done(tx_done),
        .axis_tlast(eth_data_tlast),
        .axis_tready(eth_tready),
        .axis_tvalid_hdr(udp_hdr_valid)
    );

    IDELAYE2 #(
        .IDELAY_TYPE("FIXED")
    )
    phy_rxd_idelay_0
    (
        .IDATAIN(eth_rxd[0]),
        .DATAOUT(eth_rxd_delay[0]),
        .DATAIN(1'b0),
        .C(1'b0),
        .CE(1'b0),
        .INC(1'b0),
        .CINVCTRL(1'b0),
        .CNTVALUEIN(5'd0),
        .CNTVALUEOUT(),
        .LD(1'b0),
        .LDPIPEEN(1'b0),
        .REGRST(1'b0)
    );

    IDELAYE2 #(
        .IDELAY_TYPE("FIXED")
    )
    phy_rxd_idelay_1
    (
        .IDATAIN(eth_rxd[1]),
        .DATAOUT(eth_rxd_delay[1]),
        .DATAIN(1'b0),
        .C(1'b0),
        .CE(1'b0),
        .INC(1'b0),
        .CINVCTRL(1'b0),
        .CNTVALUEIN(5'd0),
        .CNTVALUEOUT(),
        .LD(1'b0),
        .LDPIPEEN(1'b0),
        .REGRST(1'b0)
    );

    IDELAYE2 #(
        .IDELAY_TYPE("FIXED")
    )
    phy_rxd_idelay_2
    (
        .IDATAIN(eth_rxd[2]),
        .DATAOUT(eth_rxd_delay[2]),
        .DATAIN(1'b0),
        .C(1'b0),
        .CE(1'b0),
        .INC(1'b0),
        .CINVCTRL(1'b0),
        .CNTVALUEIN(5'd0),
        .CNTVALUEOUT(),
        .LD(1'b0),
        .LDPIPEEN(1'b0),
        .REGRST(1'b0)
    );

    IDELAYE2 #(
        .IDELAY_TYPE("FIXED")
    )
    phy_rxd_idelay_3
    (
        .IDATAIN(eth_rxd[3]),
        .DATAOUT(eth_rxd_delay[3]),
        .DATAIN(1'b0),
        .C(1'b0),
        .CE(1'b0),
        .INC(1'b0),
        .CINVCTRL(1'b0),
        .CNTVALUEIN(5'd0),
        .CNTVALUEOUT(),
        .LD(1'b0),
        .LDPIPEEN(1'b0),
        .REGRST(1'b0)
    );

    IDELAYE2 #(
        .IDELAY_TYPE("FIXED")
    )
    phy_rx_ctl_idelay
    (
        .IDATAIN(eth_rxctl),
        .DATAOUT(eth_rxctl_delay),
        .DATAIN(1'b0),
        .C(1'b0),
        .CE(1'b0),
        .INC(1'b0),
        .CINVCTRL(1'b0),
        .CNTVALUEIN(5'd0),
        .CNTVALUEOUT(),
        .LD(1'b0),
        .LDPIPEEN(1'b0),
        .REGRST(1'b0)
    );


    logic m_udp_hdr_valid, m_udp_payload_axis_tvalid, m_udp_payload_axis_tlast, m_udp_payload_axis_tuser;
    logic [15:0] m_udp_source_port, m_udp_dest_port, m_udp_length, m_udp_checksum;
    logic [7:0] m_udp_payload_axis_tdata;
    logic [1:0] link_speed;
    logic rx_error_bad_frame;

    eth i_eth (
        .gtx_clk                   (clk_125m),
        .gtx_clk90                 (clk_125m90),
        .gtx_rst                   (rst_125m),
        .logic_clk                 (clk_125m),
        .logic_rst                 (rst_125m),

        .rgmii_rx_clk              (eth_rxck),
        .rgmii_rxd                 (eth_rxd_delay),
        .rgmii_rx_ctl              (eth_rxctl_delay),
        .rgmii_tx_clk              (eth_txck),
        .rgmii_txd                 (eth_txd),
        .rgmii_tx_ctl              (ETH_TX_EN),
        .link_speed                (link_speed),

        .local_mac                 (48'hde_ad_be_ef_01_23),
        .local_ip                  ({8'd192, 8'd168, 8'd1,  8'd128}),
        .gateway_ip                ({8'd192, 8'd168, 8'd1,  8'd1}),
        .subnet_mask               ({8'd255, 8'd255, 8'd255, 8'd0}),
        .clear_arp_cache           (1'b0),

        .tx_udp_hdr_valid          (udp_hdr_valid),
        .tx_udp_hdr_ready          (),
        .tx_udp_ip_dscp            (6'b001110),
        .tx_udp_ip_ecn             (2'b00),
        .tx_udp_ip_ttl             (8'h40),
        .tx_udp_ip_source_ip       ({8'd192, 8'd168, 8'd1,  8'd128}),
        .tx_udp_ip_dest_ip         ({8'd192, 8'd168, 8'd1,  8'd100}),
        .tx_udp_source_port        (16'h1000),
        .tx_udp_dest_port          (16'h1000),
        .tx_udp_length             (16'h0408),
        .tx_udp_checksum           (16'h0000),
        .tx_done                   (tx_done),

        .tx_udp_payload_axis_tdata (eth_data),
        .tx_udp_payload_axis_tvalid(eth_valid),
        .tx_udp_payload_axis_tready(eth_tready),
        .tx_udp_payload_axis_tlast (eth_data_tlast),
        .tx_udp_payload_axis_tuser (1'b0),

        .udp_rx_ready              (1'b1),
        .udp_hdr_valid             (),
        .udp_source_port           (m_udp_source_port),
        .udp_dest_port             (m_udp_dest_port),
        .udp_length                (m_udp_length),
        .udp_checksum              (m_udp_checksum),

        .rx_udp_payload_axis_tdata (m_udp_payload_axis_tdata ),
        .rx_udp_payload_axis_tvalid(m_udp_payload_axis_tvalid),
        .rx_udp_payload_axis_tlast (m_udp_payload_axis_tlast ),
        .rx_udp_payload_axis_tuser (m_udp_payload_axis_tuser ),

        .tx_error_underflow        (),
        .tx_fifo_overflow          (),
        .tx_fifo_bad_frame         (),
        .tx_fifo_good_frame        (),
        .rx_error_bad_frame        (rx_error_bad_frame),
        .rx_error_bad_fcs          (),
        .rx_fifo_overflow          (),
        .rx_fifo_bad_frame         (),
        .rx_fifo_good_frame        (),

        .tx_eth_busy               (),
        .rx_eth_busy               ()
    );

    logic data_ready, full, empty, rd_en;
    logic [31:0] data;

    udpDetector udpDetector_i
    (
        .clk(clk_125m),
        .rst(rst_125m),

        .dest_port(m_udp_dest_port),
        .axis_tdata(m_udp_payload_axis_tdata),
        .axis_tvalid(m_udp_payload_axis_tvalid),
        .axis_tlast(m_udp_payload_axis_tlast),
        .rd_en(rd_en),

        .data_ready(data_ready),
        .data(data),
        .full(full),
        .empty(empty)
    );

    udpCommandParser udpCommandParser_i
    (
        .clk(clk_125m),
        .rst(rst_125m),

        .data_ready(data_ready),
        .data(data),

        .rd_en(rd_en),
        .sendAdcData(sendAdcData)
    );

    ila_0 ila_i
    (
        .clk(clk_125m),      // input wire clk

        .probe0(data),       // input wire [31:0]  probe0
        .probe1(data_ready), // input wire [0:0]  probe1
        .probe2(sendAdcData),       // input wire [0:0]  probe2
        .probe3(rd_en),      // input wire [0:0]  probe3
        .probe4(m_udp_payload_axis_tvalid), // input wire [0:0]  probe4
        .probe5(m_udp_dest_port), // input wire [15:0]  probe5
        .probe6(m_udp_payload_axis_tdata) // input wire [7:0]  probe6
    );
endmodule