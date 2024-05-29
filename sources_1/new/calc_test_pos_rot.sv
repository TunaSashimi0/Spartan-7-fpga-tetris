`include "definitions.vh"

module calc_test_pos_rot(
    input logic [`MODE_BITS-1:0]  mode,
    input logic                   game_clk_rst,
    input logic                   game_clk,

    input logic [`BITS_X_POS-1:0] cur_pos_x,
    input logic [`BITS_Y_POS-1:0] cur_pos_y,
    input logic [`BITS_ROT-1:0]   cur_rot,
    output logic [`BITS_X_POS-1:0] test_pos_x,
    output logic [`BITS_Y_POS-1:0] test_pos_y,
    output logic [`BITS_ROT-1:0]   test_rot
    );

    always @ (*) begin
        if (mode == `MODE_PLAY) begin
            if (game_clk) begin
                test_pos_x = cur_pos_x;
                test_pos_y = cur_pos_y + 1; 
                test_rot = cur_rot;
                end

            else begin
                
                test_pos_x = cur_pos_x;
                test_pos_y = cur_pos_y;
                test_rot = cur_rot;
            end
        end else if (mode == `MODE_DROP) begin
            if (game_clk_rst) begin
               
                test_pos_x = cur_pos_x;
                test_pos_y = cur_pos_y;
                test_rot = cur_rot;
            end else begin
                test_pos_x = cur_pos_x;
                test_pos_y = cur_pos_y + 1; 
                test_rot = cur_rot;
            end
        end else begin
           
            test_pos_x = cur_pos_x;
            test_pos_y = cur_pos_y;
            test_rot = cur_rot;
        end
    end

endmodule
