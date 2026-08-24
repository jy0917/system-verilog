`timescale 1ns / 1ps


module tb_parctice_oop_ex3 ();

    class packet;
        static int num_created = 0;
        int my_serial;
        function new();
            num_created++;
            my_serial = num_created;
        endfunction
    endclass

    packet p1, p2, p3;

    initial begin
        $display("[ex03] static member vs pre-object member");
        $display(" before creating any object : packet::num_created = %d",
                packet::num_created);
        p1 = new();
        p2 = new();
        p3 = new();

        $display("p1.my_serial = %d", p1.my_serial);
        $display("p2.my_serial = %d", p2.my_serial);
        $display("p3.my_serial = %d", p3.my_serial);

        $display(" packet::num_created = %d <- no_object", packet::num_created);
        $display(" packet::num_created = %d <- p1_object", p1.num_created);
    end

endmodule
