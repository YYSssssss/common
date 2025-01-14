
`timescale 1ps/1ps
module torwave #(

    parameter integer C_S_AXI_ADDR_WIDTH     = 16,
    parameter integer memory_word_depth      = 1024,
    parameter integer clocks_for_10ms        = 4000000,
    parameter integer clocks_for_1ms         = 400000,
    parameter integer count_init_for_sim     = 96130,
    parameter integer start_to_offset_cycles = 109408,
    parameter integer ps_per_clock           = 6400

  ) (
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 mas_0 TDATA"      *) output wire [63:0] m0_data_tdata  ,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 mas_0 TKEEP"      *) output wire  [7:0] m0_data_tkeep  ,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 mas_0 TVALID"     *) output wire        m0_data_tvalid ,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 mas_0 TLAST"      *) output wire        m0_data_tlast  ,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 mas_0 TUSER"      *) output wire        m0_data_tuser  ,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 mas_0 TREADY"     *) input  wire        m0_data_tready ,

  input                                  s_axi_aresetn,
  input       [C_S_AXI_ADDR_WIDTH-1:0]   s_axi_awaddr,
  input                                  s_axi_awvalid,
  output                                 s_axi_awready,
  input       [31:0]                     s_axi_wdata,
  input                                  s_axi_wvalid,
  output                                 s_axi_wready,
  output      [1:0]                      s_axi_bresp,
  output                                 s_axi_bvalid,
  input                                  s_axi_bready,
  input       [C_S_AXI_ADDR_WIDTH-1:0]   s_axi_araddr,
  input                                  s_axi_arvalid,
  output                                 s_axi_arready,
  output      [31:0]                     s_axi_rdata,
  output      [1:0]                      s_axi_rresp,
  output                                 s_axi_rvalid,
  input                                  s_axi_rready,

  output wire                            radio_start_one_pps       ,
  output wire                            radio_start_10ms_stretch  ,
  output wire                            radio_start_10ms          ,
  output wire                            radio_offset_10ms_stretch ,
  output wire                            radio_offset_10ms         ,

  input  wire                            radio_start_10ms_toggle_in,
  output wire                            radio_start_10ms_retimed  ,

  output wire [7:0]                      dip_status ,
  output wire                            error_flag ,

  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axis_aresetn RST" *)
  input  wire                            s_axis_aresetn           ,
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axis_aclk CLK" *)
  (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF mas_0" *)
  input  wire                            s_axis_aclk,
  
  input  wire                            s_axi_aclk

);

//-----------------------------------------------------------------------------
// Instance the SV logic.
//-----------------------------------------------------------------------------
torwave_v2sv #(
    .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
    .memory_word_depth (memory_word_depth ),
    .clocks_for_10ms   (clocks_for_10ms   ),
    .clocks_for_1ms    (clocks_for_1ms    ),
    .ps_per_clock      (ps_per_clock      )
) tw_v2sv (

  .m0_data_tdata             (m0_data_tdata             ),
  .m0_data_tkeep             (m0_data_tkeep             ),
  .m0_data_tvalid            (m0_data_tvalid            ),
  .m0_data_tlast             (m0_data_tlast             ),
  .m0_data_tuser             (m0_data_tuser             ),
  .m0_data_tready            (m0_data_tready            ),

  .radio_start_one_pps       (radio_start_one_pps       ),
  .radio_start_10ms_stretch  (radio_start_10ms_stretch  ),
  .radio_start_10ms          (radio_start_10ms          ),
  .radio_offset_10ms_stretch (radio_offset_10ms_stretch ),
  .radio_offset_10ms         (radio_offset_10ms         ),

  .radio_start_10ms_toggle_in(radio_start_10ms_toggle_in),
  .radio_start_10ms_retimed  (radio_start_10ms_retimed  ),

  .dip_status                (dip_status                ),
  .error_flag                (error_flag                ),

  .s_axis_aresetn            (s_axis_aresetn            ),
  .s_axis_aclk               (s_axis_aclk               ),
  .s_axi_aresetn             (s_axi_aresetn             ),
  .s_axi_aclk                (s_axi_aclk                ),

  .s_axi_awaddr              (s_axi_awaddr              ),
  .s_axi_awvalid             (s_axi_awvalid             ),
  .s_axi_awready             (s_axi_awready             ),
  .s_axi_wdata               (s_axi_wdata               ),
  .s_axi_wvalid              (s_axi_wvalid              ),
  .s_axi_wready              (s_axi_wready              ),
  .s_axi_bresp               (s_axi_bresp               ),
  .s_axi_bvalid              (s_axi_bvalid              ),
  .s_axi_bready              (s_axi_bready              ),
  .s_axi_araddr              (s_axi_araddr              ),
  .s_axi_arvalid             (s_axi_arvalid             ),
  .s_axi_arready             (s_axi_arready             ),
  .s_axi_rdata               (s_axi_rdata               ),
  .s_axi_rresp               (s_axi_rresp               ),
  .s_axi_rvalid              (s_axi_rvalid              ),
  .s_axi_rready              (s_axi_rready              )

);

endmodule

//-----------------------------------------------------------------------------
// Radio Start recover module. IPI Verilog Wrapper
//-----------------------------------------------------------------------------
module radio_start_recover_v  #(

   parameter integer setup_cnt       = 10000,
   parameter integer clocks_for_1ms  = 156250,
   parameter integer guard_cycles    = 6400

) (
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK" *)
  input  wire                clk                      ,
  input  wire                radio_start_10ms_stretch ,

  output wire                radio_start_10ms_toggle  ,
  output wire                radio_start_1ms_toggle   ,

  output wire                radio_start_10ms         ,
  output wire                radio_start_1ms         
);

localparam filter_w        = 16; // 
localparam cnt_w           = 16; //   

//-----------------------------------------------------------------------------
// Instance the SV logic.
//-----------------------------------------------------------------------------
radio_start_recover  #(
   .setup_cnt     (setup_cnt     ),
   .clocks_for_1ms(clocks_for_1ms),
   .filter_w      (filter_w      ),
   .guard_cycles  (guard_cycles  ),
   .cnt_w         (cnt_w         )
) rec10ms_i(
  .clk                      (clk                       ),
  .radio_start_10ms_stretch (radio_start_10ms_stretch  ),
  .radio_start_10ms_toggle  (radio_start_10ms_toggle   ),
  .radio_start_1ms_toggle   (radio_start_1ms_toggle    ),
  .radio_start_10ms         (radio_start_10ms          ),
  .radio_start_1ms          (radio_start_1ms           )
);

endmodule

