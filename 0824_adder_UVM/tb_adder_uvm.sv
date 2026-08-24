`timescale 1ns / 1ps

`include "uvm_macros.svh"  // define : uvm_*macro
import uvm_pkg::*;  // import : UVM package

interface adder_if (
    input bit clk
);
    logic [7:0] a;
    logic [7:0] b;
    logic [8:0] y;  // result

endinterface

//transaction -> seq_item from uvm_sequence_item
class seq_item extends uvm_sequence_item;
    rand bit [7:0] a;
    rand bit [7:0] b;
    logic [8:0] y;

    function new(string name = "ADDER_Seq_item");
        super.new(name);
    endfunction

    `uvm_object_utils_begin(seq_item)
        `uvm_field_int(a, UVM_DEFAULT)
        `uvm_field_int(b, UVM_DEFAULT)
        `uvm_field_int(y, UVM_DEFAULT)
    `uvm_object_utils_end

endclass

module tb_adder_uvm ();
    logic clk = 0;
    always #5 clk = ~clk;
    adder_if a_if (clk);

endmodule
