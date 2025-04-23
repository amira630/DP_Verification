///////////////////////////////////////////////////////////////////////////////
// File:        dp_dpcd_reg_pkg.sv
// Author:      Amira Atef Ismaeil El-Komy
// Date:        19-03-2025
// Description: Package containing the register definitions for the Receiver Capability Field
//              in the DisplayPort Configuration Data (DPCD).
///////////////////////////////////////////////////////////////////////////////
package dp_dpcd_reg_file_receiver_capability_pkg;

    // Standard UVM import & include:
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Any further package imports:
    import test_parameters_pkg::*;

    // Includes:
    ////////////////////////////////// RECEIVER CAPABILITY FIELD REGISTERS //////////////////////////////////

    `include "dp_dpcd_reg_dpcd_rev.svh"                                 //0_00_00h
    `include "dp_dpcd_reg_8b10b_max_link_rate.svh"                      //0_00_01h
    `include "dp_dpcd_reg_max_lane_count.svh"                           //0_00_02h
    `include "dp_dpcd_reg_max_downspread.svh"                           //0_00_03h
    `include "dp_dpcd_reg_norp_dp_pwr_voltage_cap.svh"                  //0_00_04h
    `include "dp_dpcd_reg_down_stream_port_present.svh"                 //0_00_05h
    `include "dp_dpcd_reg_main_link_channel_coding_cap.svh"             //0_00_06h
    `include "dp_dpcd_reg_down_stream_port_count.svh"                   //0_00_07h
    `include "dp_dpcd_reg_receive_port0_cap_0.svh"                      //0_00_08h
    `include "dp_dpcd_reg_receive_port0_cap_1.svh"                      //0_00_09h
    `include "dp_dpcd_reg_receive_port1_cap_0.svh"                      //0_00_0Ah
    `include "dp_dpcd_reg_receive_port1_cap_1.svh"                      //0_00_0Bh
    `include "dp_dpcd_reg_i2c_speed_control_capabilities_bit_map.svh"   //0_00_0Ch
    // 0_00_0Dh is RESERVED
    `include "dp_dpcd_reg_8b10b_training_aux_rd_interval.svh"           //0_00_0Eh
    `include "dp_dpcd_reg_adapter_cap.svh"                              //0_00_0Fh
    // 0_00_10h to 0_00_1Fh is RESERVED
    `include "dp_dpcd_reg_sink_video_fallback_formats.svh"              //0_00_20h
    `include "dp_dpcd_reg_mstm_cap.svh"                                 //0_00_21h
    `include "dp_dpcd_reg_number_of_audio_endpoints.svh"                //0_00_22h
    `include "dp_dpcd_reg_av_sync_data_block_av_granularity.svh"        //0_00_23h
    `include "dp_dpcd_reg_av_sync_data_block.svh"                       //0_00_24h to 0_00_2Dh        
    `include "dp_dpcd_reg_receiver_alpm_capabilities.svh"               //0_00_2Eh
    // 0_00_2Fh is RESERVED
    `include "dp_dpcd_reg_guid.svh"                                     //0_00_30h to 0_00_3Fh
    `include "dp_dpcd_reg_guid_2.svh"                                   //0_00_40h to 0_00_4Fh

    `include "dp_dpcd_reg_file_receiver_capability.svh"
    ////////////////////////////////// RECEIVER CAPABILITY FIELD REGISTERS //////////////////////////////////


    // `include "dp_dpcd_reg_link_configuration.svh"
    // `include "dp_dpcd_reg_link_sink_device_status.svh"
    // `include "dp_dpcd_reg_source_device_specific.svh"
    // `include "dp_dpcd_reg_sink_device_specific.svh"
    // `include "dp_dpcd_reg_branch_device_specific.svh"
    // `include "dp_dpcd_reg_link_sink_device_power_control.svh"
    // `include "dp_dpcd_reg_edp_specific.svh"
    // `include "dp_dpcd_reg_arvr_configuration_specific.svh"
    // `include "dp_dpcd_reg_arvr_status_specific.svh"
    // `include "dp_dpcd_reg_sideband_msg_buffers.svh"
    // `include "dp_dpcd_reg_dprx_event_status_indicator.svh"
    // `include "dp_dpcd_reg_extended_receiver_capability.svh"
    // `include "dp_dpcd_reg_device_specific_receiver_parameters.svh"
    // `include "dp_dpcd_reg_protocol_converter_extension.svh"
    // `include "dp_dpcd_reg_dsc_encoder.svh"
    // `include "dp_dpcd_reg_multi_touch.svh"
    // `include "dp_dpcd_reg_hdcp_1_3_and_hdcp_2_x.svh"
    // `include "dp_dpcd_reg_dp_tunneling_over_usb4.svh"
    // `include "dp_dpcd_reg_lttpr.svh"
    // `include "dp_dpcd_reg_mydp_standard_specific.svh"

endpackage