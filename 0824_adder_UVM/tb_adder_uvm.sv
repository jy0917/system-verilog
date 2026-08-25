`timescale 1ns / 1ps

`include "uvm_macros.svh"  // define : uvm_*macro
import uvm_pkg::*;  // import : UVM package

// 0 . interface
interface adder_if (
    input bit clk
);
    logic [7:0] a;
    logic [7:0] b;
    logic [8:0] y;  // result

endinterface

// 1. transaction -> seq_item from uvm_sequence_item
class seq_item extends uvm_sequence_item;
    rand bit [7:0] a;  // driver stimulus
    rand bit [7:0] b;  // driver stimulus
    logic [8:0] y;  // monitoring stimulus

    function new(string name = "ADDER_Seq_item");
        super.new(name);
    endfunction

    `uvm_object_utils_begin(seq_item)
        `uvm_field_int(a, UVM_DEFAULT)
        `uvm_field_int(b, UVM_DEFAULT)
        `uvm_field_int(y, UVM_DEFAULT)
    `uvm_object_utils_end

endclass

// 2. sequence, (generator)
// randomize, seq_item (transaction object)
class adder_sequence extends uvm_sequence;
    // factory registry
    `uvm_object_utils(adder_sequence)
    seq_item adder_seq_item;

    function new(string name = "ADDER_Sequence");
        super.new(name);
    endfunction

    task body();
        adder_seq_item =
            seq_item::type_id::create("SEQ_ITEM");  // transaction new()
        start_item(adder_seq_item);
        // randomize
        if (!adder_seq_item.randomize()) begin
            `uvm_fatal("SEQ", "adder_seq_item randomized fail")
        end
        // messeage output : to TCL console, log
        `uvm_info("SEQ", $sformatf(" a = %d, b = %d", adder_seq_item.a,
                                   adder_seq_item.b), UVM_MEDIUM)
        finish_item(adder_seq_item);
    endtask
endclass

// 3. driver
// from sequence with seq_item to drive to interface
class adder_driver extends uvm_driver #(seq_item);
    // factory registry : class uvm_driver
    `uvm_component_utils(adder_driver)
    // handler
    seq_item adder_seq_item;

    // virtual interface
    virtual adder_if a_vif;

    function new(string name = "ADDER_DRV", uvm_component c = null);
        super.new(name, c);
    endfunction

    // build phase configuration component
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // interface connect
        if (!uvm_config_db#(virtual adder_if)::get(
                this, "", "a_vif", a_vif
            )) begin
            `uvm_fatal(get_name(), "unable to access adder interface")
        end
    endfunction

    // run phase
    task run_phase(uvm_phase phase);
        // to drive to interface
        // get seq_item
        // handshake
        seq_item_port.get_next_item(adder_seq_item);

        @(posedge a_vif.clk);
        a_vif.a <= adder_seq_item.a;
        a_vif.b <= adder_seq_item.b;


        // done to use
        seq_item_port.item_done(adder_seq_item);

    endtask


endclass

// 4. monitor 
class adder_monitor extends uvm_monitor;
    `uvm_component_utils(adder_monitor)

    // broadcasting
    uvm_analysis_port #(seq_item) send;
    virtual adder_if a_vif;
    seq_item adder_seq_item;

    function new(string name = "ADDER_MON", uvm_component c = null);
        super.new(name, c);
        send = new("WRITE", this);
    endfunction

    // build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual adder_if)::get(
                this, "", "a_vif", a_vif
            )) begin
            `uvm_fatal(get_name(), "unable to access adder interface")
        end
    endfunction

    // run phase
    task run_phase(uvm_phase phase);
        // adder_seq_item new
        adder_seq_item = seq_item::type_id::create("SEQ_ITEM");

        @(posedge a_vif.clk);
        adder_seq_item.a = a_vif.a;
        adder_seq_item.b = a_vif.b;
        adder_seq_item.y = a_vif.y;
        send.write(adder_seq_item);
        `uvm_info("MON", $sformatf(" a = %d, b = %d", adder_seq_item.a,
                                   adder_seq_item.b), UVM_MEDIUM)
    endtask

endclass

// 5. scoreboard
class adder_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(adder_scoreboard)
    uvm_analysis_imp #(seq_item, adder_scoreboard) recv;

    function new(string name = "ADDER_SCB", uvm_component c = null);
        super.new(name, c);
        recv = new("READ", this);
    endfunction

    bit [8:0] expected_data = 0;
    int pass_cnt = 0, fail_cnt = 0;

    function void write(seq_item data);
        // pass/fail decition
        expected_data = data.a + data.b;
        if ((data.a + data.b) == data.y) begin
            `uvm_info("SCB", $sformatf(" PASS : a = %d, b = %d, y = %d",
                                       data.a, data.b, data.y), UVM_MEDIUM)
            pass_cnt++;
        end else begin
            `uvm_info("SCB", $sformatf(
                      " FAIL : a = %d, b = %d, y = %d", data.a, data.b, data.y),
                      UVM_MEDIUM)
            fail_cnt++;
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SCB", $sformatf(
                  "=== PASS : %d === \n === FAIL : %d", pass_cnt, fail_cnt),
                  UVM_MEDIUM)
        if (!(pass_cnt + fail_cnt))  // no transaction
            `uvm_error("SCB", "No transaction received !!!")
    endfunction
endclass

// adder_agent : driver + monitor + sequencer
class adder_agent extends uvm_agent;
    `uvm_component_utils(adder_agent)

    adder_driver adder_drv;
    adder_monitor adder_mon;
    uvm_sequencer #(seq_item) adder_sqr;

    function new(string name = "ADDER_AGT", uvm_component c = null);
        super.new(name, c);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        adder_drv = adder_driver::type_id::create("DRV", this);
        adder_mon = adder_monitor::type_id::create("MON", this);
        adder_sqr = uvm_sequencer#(seq_item)::type_id::create("SQR", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        adder_drv.seq_item_port.connect(adder_sqr.seq_item_export);
    endfunction

endclass

// environment : agent + scoreboard
class adder_environment extends uvm_env;
    `uvm_component_utils(adder_environment)

    adder_agent adder_agt;
    adder_scoreboard adder_scb;

    function new(string name = "ADDER_ENV", uvm_component c = null);
        super.new(name, c);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        adder_agt = adder_agent::type_id::create("AGT", this);
        adder_scb = adder_scoreboard::type_id::create("SCB", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        adder_agt.adder_mon.send.connect(adder_scb.recv);
    endfunction

endclass

// test : top sinario, run_test
class adder_test extends uvm_test;
    `uvm_component_utils(adder_test)

    adder_sequence adder_seq;
    adder_environment adder_env;

    function new(string name = "ADDER_TEST", uvm_component c = null);
        super.new(name, c);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        adder_seq = adder_sequence::type_id::create("SEQ", this);
        adder_env = adder_environment::type_id::create("ENV", this);
    endfunction

    task run_phase(uvm_phase phase);
        // start run phase
        phase.raise_objection(this);
        adder_seq.start(adder_env.adder_agt.adder_sqr);
        #100;
        // stop run phase
        phase.drop_objection(this);
    endtask

endclass

module tb_adder_uvm ();
    logic clk = 0;
    always #5 clk = ~clk;
    adder_if a_if (clk);

    adder dut (
        .a(a_if.a),
        .b(a_if.b),
        .y(a_if.y)
    );

    initial begin
        uvm_config_db#(virtual adder_if)::set(null, "*", "a_vif", a_if);
        run_test("adder_test");
    end

endmodule
