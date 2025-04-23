///////////////////////////////////////////////////////////////////////////////
// File:        dp_dpcd_reg_file_receiver_capability.svh
// Author:      Amira Atef
// Date:        22-03-2025
// Description: Receiver Capability Field Register File
///////////////////////////////////////////////////////////////////////////////
class dp_dpcd_reg_file_receiver_capability extends uvm_reg_file;
  `uvm_object_utils(dp_dpcd_reg_file_receiver_capability)

  // Declaring registers
  dp_dpcd_reg_dpcd_rev                                  DPCD_REV;                                         //0_00_00h
  dp_dpcd_reg_8b10b_max_link_rate                       _8b10b_MAX_LINK_RATE;                             //0_00_01h 
  dp_dpcd_reg_max_lane_count                            MAX_LANE_COUNT;                                   //0_00_02h  
  dp_dpcd_reg_max_downspread                            MAX_DOWNSPREAD;                                   //0_00_03h  
  dp_dpcd_reg_norp_dp_pwr_voltage_cap                   NORP_DP_PWR_VOLTAGE_CAP;                          //0_00_04h
  dp_dpcd_reg_down_stream_port_present                  DOWN_STREAM_PORT_PRESENT;                         //0_00_05h
  dp_dpcd_reg_main_link_channel_coding_cap              MAIN_LINK_CHANNEL_CODING_CAP;                     //0_00_06h
  dp_dpcd_reg_down_stream_port_count                    DOWN_STREAM_PORT_COUNT;                           //0_00_07h
  dp_dpcd_reg_receive_port0_cap_0                       RECEIVE_PORT0_CAP_0;                              //0_00_08h
  dp_dpcd_reg_receive_port0_cap_1                       RECEIVE_PORT0_CAP_1;                              //0_00_09h
  dp_dpcd_reg_receive_port1_cap_0                       RECEIVE_PORT1_CAP_0;                              //0_00_0Ah  
  dp_dpcd_reg_receive_port1_cap_1                       RECEIVE_PORT1_CAP_1;                              //0_00_0Bh      
  dp_dpcd_reg_i2c_speed_control_capabilities_bit_map    I2C_SPEED_CONTROL_CAPABILITIES_BIT_MAP;           //0_00_0Ch
  // 0_00_0Dh is RESERVED
  dp_dpcd_reg_8b10b_training_aux_rd_interval            _8b10b_TRAINING_AUX_RD_INTERVAL;                  //0_00_0Eh
  dp_dpcd_reg_adapter_cap                               ADAPTER_CAP;                                      //0_00_0Fh
  // 0_00_10h to 0_00_1Fh is RESERVED
  dp_dpcd_reg_sink_video_fallback_formats               SINK_VIDEO_FALLBACK_FORMATS;                      //0_00_20h  
  dp_dpcd_reg_mstm_cap                                  MSTM_CAP;                                         //0_00_21h  
  dp_dpcd_reg_number_of_audio_endpoints                 NUMBER_OF_AUDIO_ENDPOINTS;                        //0_00_22h
  dp_dpcd_reg_av_sync_data_block_av_granularity         AV_SYNC_DATA_BLOCK_AV_GRANULARITY;                //0_00_23h
  dp_dpcd_reg_av_sync_data_block                        AV_SYNC_DATA_BLOCK;                               //0_00_24h to 0_00_2Dh
  dp_dpcd_reg_receiver_alpm_capabilities                RECEIVER_ALPM_CAPABILITIES;                       //0_00_2Eh
  // 0_00_2Fh is RESERVED
  dp_dpcd_reg_guid                                      GUID;                                             //0_00_30h to 0_00_3Fh
  dp_dpcd_reg_guid_2                                    GUID_2;                                           //0_00_40h to 0_00_4Fh

  function new(string name = "dp_dpcd_reg_file_receiver_capability");
    super.new(name);
  endfunction

  virtual function void build();
    //  Get the parent register block
    uvm_reg_block blk_parent = get_block();

    // Create register instances
    DPCD_REV = dp_dpcd_reg_dpcd_rev::type_id::create(.name("DPCD_REV"),.parent(null),.contxt(get_full_name()));
    _8b10b_MAX_LINK_RATE = dp_dpcd_reg_8b10b_max_link_rate::type_id::create(.name("_8b10b_MAX_LINK_RATE"),.parent(null),.contxt(get_full_name()));
    MAX_LANE_COUNT = dp_dpcd_reg_max_lane_count::type_id::create(.name("MAX_LANE_COUNT"),.parent(null),.contxt(get_full_name()));
    MAX_DOWNSPREAD = dp_dpcd_reg_max_downspread::type_id::create(.name("MAX_DOWNSPREAD"),.parent(null),.contxt(get_full_name()));
    NORP_DP_PWR_VOLTAGE_CAP = dp_dpcd_reg_norp_dp_pwr_voltage_cap::type_id::create(.name("NORP_DP_PWR_VOLTAGE_CAP"),.parent(null),.contxt(get_full_name()));
    DOWN_STREAM_PORT_PRESENT = dp_dpcd_reg_down_stream_port_present::type_id::create(.name("MAX_LANEDOWN_STREAM_PORT_PRESENT_COUNT"),.parent(null),.contxt(get_full_name()));
    MAIN_LINK_CHANNEL_CODING_CAP = dp_dpcd_reg_main_link_channel_coding_cap::type_id::create(.name("MAIN_LINK_CHANNEL_CODING_CAP"),.parent(null),.contxt(get_full_name()));
    DOWN_STREAM_PORT_COUNT = dp_dpcd_reg_down_stream_port_count::type_id::create(.name("DOWN_STREAM_PORT_COUNT"),.parent(null),.contxt(get_full_name()));
    RECEIVE_PORT0_CAP_0 = dp_dpcd_reg_receive_port0_cap_0::type_id::create(.name("RECEIVE_PORT0_CAP_0"),.parent(null),.contxt(get_full_name()));
    RECEIVE_PORT0_CAP_1 = dp_dpcd_reg_receive_port0_cap_1::type_id::create(.name("RECEIVE_PORT0_CAP_1"),.parent(null),.contxt(get_full_name()));
    RECEIVE_PORT1_CAP_0 = dp_dpcd_reg_receive_port1_cap_0::type_id::create(.name("RECEIVE_PORT1_CAP_0"),.parent(null),.contxt(get_full_name()));
    RECEIVE_PORT1_CAP_1 = dp_dpcd_reg_receive_port1_cap_1::type_id::create(.name("RECEIVE_PORT1_CAP_1"),.parent(null),.contxt(get_full_name()));
    I2C_SPEED_CONTROL_CAPABILITIES_BIT_MAP = dp_dpcd_reg_i2c_speed_control_capabilities_bit_map::type_id::create(.name("I2C_SPEED_CONTROL_CAPABILITIES_BIT_MAP"),.parent(null),.contxt(get_full_name()));
    _8b10b_TRAINING_AUX_RD_INTERVAL = dp_dpcd_reg_8b10b_training_aux_rd_interval::type_id::create(.name("_8b10b_TRAINING_AUX_RD_INTERVAL"),.parent(null),.contxt(get_full_name()));
    ADAPTER_CAP = dp_dpcd_reg_adapter_cap::type_id::create(.name("ADAPTER_CAP"),.parent(null),.contxt(get_full_name()));
    SINK_VIDEO_FALLBACK_FORMATS = dp_dpcd_reg_sink_video_fallback_formats::type_id::create(.name("SINK_VIDEO_FALLBACK_FORMATS"),.parent(null),.contxt(get_full_name()));
    MSTM_CAP = dp_dpcd_reg_mstm_cap::type_id::create(.name("MSTM_CAP"),.parent(null),.contxt(get_full_name()));
    NUMBER_OF_AUDIO_ENDPOINTS = dp_dpcd_reg_number_of_audio_endpoints::type_id::create(.name("NUMBER_OF_AUDIO_ENDPOINTS"),.parent(null),.contxt(get_full_name()));
    AV_SYNC_DATA_BLOCK_AV_GRANULARITY = dp_dpcd_reg_av_sync_data_block_av_granularity::type_id::create(.name("AV_SYNC_DATA_BLOCK_AV_GRANULARITY"),.parent(null),.contxt(get_full_name()));
    AV_SYNC_DATA_BLOCK = dp_dpcd_reg_av_sync_data_block::type_id::create(.name("AV_SYNC_DATA_BLOCK"),.parent(null),.contxt(get_full_name()));
    RECEIVER_ALPM_CAPABILITIES = dp_dpcd_reg_receiver_alpm_capabilities::type_id::create(.name("RECEIVER_ALPM_CAPABILITIES"),.parent(null),.contxt(get_full_name()));
    GUID = dp_dpcd_reg_guid::type_id::create(.name("GUID"),.parent(null),.contxt(get_full_name()));
    GUID_2 = dp_dpcd_reg_guid_2::type_id::create(.name("GUID_2"),.parent(null),.contxt(get_full_name()));


    // Configure registers to belong to this register file
    DPCD_REV.configure(blk_parent, this, "");
    _8b10b_MAX_LINK_RATE.configure(blk_parent, this, "");
    MAX_LANE_COUNT.configure(blk_parent, this, "");
    MAX_DOWNSPREAD.configure(blk_parent, this, "");
    NORP_DP_PWR_VOLTAGE_CAP.configure(blk_parent, this, "");
    DOWN_STREAM_PORT_PRESENT.configure(blk_parent, this, "");
    MAIN_LINK_CHANNEL_CODING_CAP.configure(blk_parent, this, "");
    DOWN_STREAM_PORT_COUNT.configure(blk_parent, this, "");
    RECEIVE_PORT0_CAP_0.configure(blk_parent, this, "");
    RECEIVE_PORT0_CAP_1.configure(blk_parent, this, "");
    RECEIVE_PORT1_CAP_0.configure(blk_parent, this, "");
    RECEIVE_PORT1_CAP_1.configure(blk_parent, this, ""); 
    I2C_SPEED_CONTROL_CAPABILITIES_BIT_MAP.configure(blk_parent, this, "");
    _8b10b_TRAINING_AUX_RD_INTERVAL.configure(blk_parent, this, "");
    ADAPTER_CAP.configure(blk_parent, this, "");
    SINK_VIDEO_FALLBACK_FORMATS.configure(blk_parent, this, "");
    MSTM_CAP.configure(blk_parent, this, "");
    NUMBER_OF_AUDIO_ENDPOINTS.configure(blk_parent, this, "");
    AV_SYNC_DATA_BLOCK_AV_GRANULARITY.configure(blk_parent, this, "");
    AV_SYNC_DATA_BLOCK.configure(blk_parent, this, "");
    RECEIVER_ALPM_CAPABILITIES.configure(blk_parent, this, "");
    GUID.configure(blk_parent, this, "");
    GUID_2.configure(blk_parent, this, "");
  
    // Build registers
    DPCD_REV.build();
    _8b10b_MAX_LINK_RATE.build();
    MAX_LANE_COUNT.build();
    MAX_DOWNSPREAD.build();
    NORP_DP_PWR_VOLTAGE_CAP.build();
    DOWN_STREAM_PORT_PRESENT.build();
    MAIN_LINK_CHANNEL_CODING_CAP.build();
    DOWN_STREAM_PORT_COUNT.build();
    RECEIVE_PORT0_CAP_0.build();
    RECEIVE_PORT0_CAP_1.build();
    RECEIVE_PORT1_CAP_0.build();
    RECEIVE_PORT1_CAP_1.build();
    I2C_SPEED_CONTROL_CAPABILITIES_BIT_MAP.build();
    _8b10b_TRAINING_AUX_RD_INTERVAL.build();
    ADAPTER_CAP.build();
    SINK_VIDEO_FALLBACK_FORMATS.build();
    MSTM_CAP.build();
    NUMBER_OF_AUDIO_ENDPOINTS.build();
    AV_SYNC_DATA_BLOCK_AV_GRANULARITY.build();
    AV_SYNC_DATA_BLOCK.build();
    RECEIVER_ALPM_CAPABILITIES.build();
    GUID.build();
    GUID_2.build();

    // Configure the register file (Since it's inside a block, regfile_parent = null)
    //this.configure(blk_parent, null, "");

  endfunction

  // Assigning memory addresses in `map()`
  virtual function void map(uvm_reg_map mp, uvm_reg_addr_t offset);
    // Add registers to the register map
    mp.add_reg(DPCD_REV, offset + 20'h0_00_00, "RO");
    mp.add_reg(_8b10b_MAX_LINK_RATE, offset + 20'h0_00_01, "RO");
    mp.add_reg(MAX_LANE_COUNT, offset + 20'h0_00_02, "RO");
    mp.add_reg(MAX_DOWNSPREAD, offset + 20'h0_00_03, "RO");
    mp.add_reg(NORP_DP_PWR_VOLTAGE_CAP, offset + 20'h0_00_04, "RO");
    mp.add_reg(DOWN_STREAM_PORT_PRESENT, offset + 20'h0_00_05, "RO");
    mp.add_reg(MAIN_LINK_CHANNEL_CODING_CAP, offset + 20'h0_00_06, "RO");
    mp.add_reg(DOWN_STREAM_PORT_COUNT, offset + 20'h0_00_07, "RO");
    mp.add_reg(RECEIVE_PORT0_CAP_0, offset + 20'h0_00_08, "RO");
    mp.add_reg(RECEIVE_PORT0_CAP_1, offset + 20'h0_00_09, "RO");
    mp.add_reg(RECEIVE_PORT1_CAP_0, offset + 20'h0_00_0A, "RO");
    mp.add_reg(RECEIVE_PORT1_CAP_1, offset + 20'h0_00_0B, "RO");
    mp.add_reg(I2C_SPEED_CONTROL_CAPABILITIES_BIT_MAP, offset + 20'h0_00_0C, "RO");
    mp.add_reg(_8b10b_TRAINING_AUX_RD_INTERVAL, offset + 20'h0_00_0E, "RO");
    mp.add_reg(ADAPTER_CAP, offset + 20'h0_00_0F, "RO");
    mp.add_reg(SINK_VIDEO_FALLBACK_FORMATS, offset + 20'h0_00_20, "RO");
    mp.add_reg(MSTM_CAP, offset + 20'h0_00_21, "RO");
    mp.add_reg(NUMBER_OF_AUDIO_ENDPOINTS, offset + 20'h0_00_22, "RO");
    mp.add_reg(AV_SYNC_DATA_BLOCK_AV_GRANULARITY, offset + 20'h0_00_23, "RO");
    mp.add_reg(AV_SYNC_DATA_BLOCK, offset + 20'h0_00_24, "RO");
    mp.add_reg(RECEIVER_ALPM_CAPABILITIES, offset + 20'h0_00_2E, "RO");
    mp.add_reg(GUID, offset + 20'h0_00_30, "RO");
    mp.add_reg(GUID_2, offset + 20'h0_00_40, "RO");

  endfunction
endclass