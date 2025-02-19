import macro_pkg::*;
interface DP_SINK_if(clk);
    opcode_e ctl;
    modport DUT (
        input ctl
    );
endinterface