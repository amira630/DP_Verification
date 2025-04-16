class dp_tl_coverage extends uvm_component;
    `uvm_component_utils(dp_tl_coverage)

    uvm_analysis_export #(dp_tl_sequence_item) cov_export;
    uvm_tlm_analysis_fifo #(dp_tl_sequence_item) cov_fifo;
    dp_tl_sequence_item cov_tl_seq_item;

    // covergroup
    covergroup tl_cvr_grp;
    // SPM signals
        rst_spm_c:              coverpoint cov_tl_seq_item.spm.rst_n;
        spm_add_c:              coverpoint cov_tl_seq_item.spm.SPM_Address;
        spm_len_c:              coverpoint cov_tl_seq_item.spm.SPM_LEN;
        spm_cmd_c:              coverpoint cov_tl_seq_item.spm.SPM_CMD;
        spm_data_c:             coverpoint cov_tl_seq_item.spm.SPM_Data;
        spm_vld_c:              coverpoint cov_tl_seq_item.spm.SPM_Transaction_VLD;
        spm_reply_ack_c:        coverpoint cov_tl_seq_item.spm.SPM_Reply_ACK;
        spm_reply_ack_vld_c:    coverpoint cov_tl_seq_item.spm.SPM_Reply_ACK_VLD;
        spm_reply_data_c:       coverpoint cov_tl_seq_item.spm.SPM_Reply_Data;
        spm_reply_data_vld_c:   coverpoint cov_tl_seq_item.spm.SPM_Reply_Data_VLD;
        spm_native_i2c_c:       coverpoint cov_tl_seq_item.spm.SPM_NATIVE_I2C;
        spm_hpd_detect_c:       coverpoint cov_tl_seq_item.spm.HPD_Detect;
        spm_ctrl_i2c_failed_c:  coverpoint cov_tl_seq_item.spm.CTRL_I2C_Failed;

    // LPM signals
        rst_lpm_c:              coverpoint cov_tl_seq_item.lpm.rst_n;
        lpm_add_c:              coverpoint cov_tl_seq_item.lpm.LPM_Address;
        lpm_len_c:              coverpoint cov_tl_seq_item.lpm.LPM_LEN;
        lpm_cmd_c:              coverpoint cov_tl_seq_item.lpm.LPM_CMD;
        lpm_data_c:             coverpoint cov_tl_seq_item.lpm.LPM_Data;
        lpm_vld_c:              coverpoint cov_tl_seq_item.lpm.LPM_Transaction_VLD;
        lpm_reply_ack_c:        coverpoint cov_tl_seq_item.lpm.LPM_Reply_ACK;
        lpm_reply_ack_vld_c:    coverpoint cov_tl_seq_item.lpm.LPM_Reply_ACK_VLD;
        lpm_reply_data_c:       coverpoint cov_tl_seq_item.lpm.LPM_Reply_Data;
        lpm_reply_data_vld_c:   coverpoint cov_tl_seq_item.lpm.LPM_Reply_Data_VLD;
        lpm_native_i2c_c:       coverpoint cov_tl_seq_item.lpm.LPM_NATIVE_I2C;
        lpm_hpd_detect_c:       coverpoint cov_tl_seq_item.lpm.HPD_Detect;
        lpm_hpd_irq_c:          coverpoint cov_tl_seq_item.lpm.HPD_IRQ;
        lpm_time_out_c:         coverpoint cov_tl_seq_item.lpm.Timer_Timeout;
        lpm_ctrl_native_failed_c: coverpoint cov_tl_seq_item.lpm.CTRL_Native_Failed;
        lpm_eq_final_adj_bw_c:  coverpoint cov_tl_seq_item.lpm.EQ_Final_ADJ_BW;
        lpm_eq_final_adj_lc_c:  coverpoint cov_tl_seq_item.lpm.EQ_Final_ADJ_LC;
        lpm_fsm_cr_failed_c:    coverpoint cov_tl_seq_item.lpm.FSM_CR_Failed;
        lpm_eq_fsm_cr_failed_c: coverpoint cov_tl_seq_item.lpm.EQ_FSM_CR_Failed;
        lpm_eq_failed_c:        coverpoint cov_tl_seq_item.lpm.EQ_Failed;
        lpm_eq_lt_pass_c:       coverpoint cov_tl_seq_item.lpm.EQ_LT_Pass;
        lpm_lane_c:             coverpoint cov_tl_seq_item.lpm.Lane_Align;
        lpm_max_vtg_c:          coverpoint cov_tl_seq_item.lpm.MAX_VTG;
        lpm_max_pre_c:          coverpoint cov_tl_seq_item.lpm.MAX_PRE;
        lpm_eq_rd_value_c:      coverpoint cov_tl_seq_item.lpm.EQ_RD_Value;
        lpm_pre_c:              coverpoint cov_tl_seq_item.lpm.PRE;
        lpm_vtg_c:              coverpoint cov_tl_seq_item.lpm.VTG;
        lpm_link_bw_cr_c:      coverpoint cov_tl_seq_item.lpm.Link_BW_CR;
        lpm_CR_DONE_c:          coverpoint cov_tl_seq_item.lpm.CR_DONE;
        lpm_CR_DONE_vld_c:      coverpoint cov_tl_seq_item.lpm.CR_DONE_VLD;
        lpm_cr_completed_c:     coverpoint cov_tl_seq_item.lpm.CR_Completed;
        lpm_eq_cr_dn_c:         coverpoint cov_tl_seq_item.lpm.EQ_CR_DN;
        lpm_channel_eq_c:       coverpoint cov_tl_seq_item.lpm.Channel_EQ;
        lpm_symbol_lock_c:      coverpoint cov_tl_seq_item.lpm.Symbol_Lock;
        lpm_max_tps_supported_c: coverpoint cov_tl_seq_item.lpm.MAX_TPS_SUPPORTED;
        lpm_link_lc_cr_c:       coverpoint cov_tl_seq_item.lpm.Link_LC_CR;
        lpm_eq_data_vld_c:      coverpoint cov_tl_seq_item.lpm.EQ_Data_VLD;
        lpm_driving_param_vld_c: coverpoint cov_tl_seq_item.lpm.Driving_Param_VLD;
        lpm_config_param_vld_c: coverpoint cov_tl_seq_item.lpm.Config_Param_VLD;
        lpm_lpm_start_cr_c:     coverpoint cov_tl_seq_item.lpm.LPM_Start_CR;
        lpm_max_tps_supported_vld_c: coverpoint cov_tl_seq_item.lpm.MAX_TPS_SUPPORTED_VLD;
    endgroup
 

    function new(string name = "dp_tl_coverage", uvm_component parent = null);
        super.new(name, parent);
        tl_cvr_grp = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cov_export = new("cov_export", this);
        cov_fifo = new("cov_fifo", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        cov_export.connect(cov_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            cov_fifo.get(cov_tl_seq_item);
            tl_cvr_grp.sample();
        end
    endtask

endclass
