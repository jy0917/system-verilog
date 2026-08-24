`timescale 1ns / 1ps

module tb_practice_oop_ex5 ();

    class base_packet;
        static string KIND = "BASE";
        int id;
        function new(int id);
            this.id = id;
        endfunction

        function string info();
            return $sformatf("%s#%d", KIND, id);
        endfunction

        virtual function string info_virtual();
            return $sformatf("%s#%d", KIND, id);
        endfunction

    endclass

    class eth_packet extends base_packet;
        static string KIND = "ETH";

        function new(int id);
            super.new(id);
        endfunction

        virtual function string info_virtual;
            //overriding
            return $sformatf("%s#%d", KIND, id);
        endfunction

    endclass

    eth_packet e;

    initial begin
        $display(" [ex5] asking the child object e (actual type = eth_packet)");

        e = new(2);

        $display(" base_packet::KIND = %s", base_packet::KIND);
        // child
        $display(" eth_packet::KIND = %s", eth_packet::KIND);

        $display(" e.info() = %s", e.info());
        $display(" e.info_virtual() = %s", e.info_virtual());

        $finish;
    end

endmodule
