`include "definitions.vh"

module complete_row(
    input logic                                   clk,
    input logic                                   pause,
    input logic [(`BLOCKS_WIDE*`BLOCKS_HIGH)-1:0] fallen_pieces,
    output logic [`BITS_Y_POS-1:0]                 row,
    output logic                                  enabled
    );

    initial begin
        row = 0;
    end

     assign enabled = &fallen_pieces[row*`BLOCKS_WIDE +: `BLOCKS_WIDE];

     always @ (posedge clk) begin
         if (!pause) begin
             if (row == `BLOCKS_HIGH - 1) begin
                 row <= 0;
             end else begin
                 row <= row + 1;
             end
         end
     end

endmodule
