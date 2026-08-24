`timescale 1ns / 1ps

module tb_practice_oop_ex2 ();

    // parent class
    class base_packet;
        int id;

        function new(int id);
            this.id = id;
        endfunction

        virtual function void print();
            $display(" 1) base_packet (id=%d)", id);
        endfunction
    endclass

    // child
    class eth_packet extends base_packet;
        bit [47:0] mac_da;
        function new(int id, bit [47:0] da);
            super.new(id);  // parent class init
            mac_da = da;
        endfunction

        virtual function void print();
            super.print();
            $display(" 2) eth_packet (da = %012d)", mac_da);
        endfunction
    endclass

    // child
    class bad_packet extends base_packet;
        function new(int id);
            super.new(id);
        endfunction

        virtual function void print();
            $display(" 3) bad_packet where did id go?");
        endfunction
    endclass

    eth_packet e;
    bad_packet b;

    initial begin
        $display("[ex02] with super.print() vs without it");
        e = new(7, 48'haabbccddeeff);
        b = new(9);
        $display(" A) e.print() --- calls super.print()");
        e.print();
        $display(" B) b.print() --- calls super.print()");
        b.print();

        $finish;
    end

endmodule
