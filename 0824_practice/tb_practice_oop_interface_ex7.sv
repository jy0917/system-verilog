`timescale 1ns / 1ps

interface bus_if (
    input logic clk
);

    logic        valid;
    logic        we;
    logic [ 7:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;

    clocking cb @(posedge clk);
        default input #1step output #1ns;
        output valid, addr, wdata, we;
        input rdata;
    endclocking

    modport DUT(input clk, valid, we, addr, wdata, output rdata);

endinterface

module reg_file (
    bus_if.DUT b 
);
    logic [31:0] mem[0:255];
    always_ff @(posedge b.clk)
        if (b.valid) begin
            $display(
                " [dut] = %t: got we = %d, adder = %d, wdata = %d, rdata = %d",
                $time, b.we, b.addr, b.wdata, b.rdata);
            if (b.we) mem[b.addr] <= b.wdata;
            b.rdata <= b.wdata; // mem[b.addr];
        end

endmodule

module tb_practice_oop_interface_ex7 ();
    logic clk = 0;
    always #5 clk = ~clk;

    bus_if bif (clk);
    reg_file dut (bif.DUT);

    initial begin
        $display("[ex7] interface instance connects TB and DUT");
        bif.valid = 0;

        @(bif.cb);  // event of clocking block : posedge clk
        bif.cb.valid <= 1'b1;
        bif.cb.we <= 1'b1;
        bif.cb.addr <= 8'h10;
        bif.cb.wdata <= 32'h01234567;
        $display("[TB] %t : drive schedule ", $time);
        @(bif.cb);  // event of clocking block : posedge clk
        bif.cb.valid <= 1'b1;
        bif.cb.we <= 1'b1;
        bif.cb.addr <= 8'h11;
        bif.cb.wdata <= 32'h01234567;
        $display("[TB] %t : drive schedule ", $time);

        @(bif.cb);  // event of clocking block : posedge clk
        bif.cb.valid <= 0;

        @(bif.cb);  // event of clocking block : posedge clk
        $display("[TB] %t : bif.cb.rdata = %d ", $time, bif.cb.rdata);
        @(bif.cb);  // event of clocking block : posedge clk
        $finish;
    end
endmodule
