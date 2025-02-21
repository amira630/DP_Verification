// Any further package imports:
import macro_pkg::*;

interface dp_sink_if(clk);
    opcode_e ctl;
    modport DUT (
        input ctl
    );
endinterface
