//-------------------------------------------------------------------------
//    mb_usb_hdmi_top.sv                                                 --
//    Zuofu Cheng                                                        --
//    2-29-24                                                            --
//                                                                       --
//                                                                       --
//    Spring 2024 Distribution                                           --
//                                                                       --
//    For use with ECE 385 USB + HDMI                                    --
//    University of Illinois ECE Department                              --
//-------------------------------------------------------------------------
`include "definitions.vh"

module mb_usb_hdmi_top(
    input logic Clk,
    input logic reset_rtl_0,
    input logic sw_pause,
    
    //USB signals
    input logic [0:0] gpio_usb_int_tri_i,
    output logic gpio_usb_rst_tri_o,
    input logic usb_spi_miso,
    output logic usb_spi_mosi,
    output logic usb_spi_sclk,
    output logic usb_spi_ss,
    
    //UART
    input logic uart_rtl_0_rxd,
    output logic uart_rtl_0_txd,
    
    //HDMI
    output logic hdmi_tmds_clk_n,
    output logic hdmi_tmds_clk_p,
    output logic [2:0]hdmi_tmds_data_n,
    output logic [2:0]hdmi_tmds_data_p,
        
    //HEX displays
    output logic [7:0] hex_segA,
    output logic [3:0] hex_gridA,
    output logic [7:0] hex_segB,
    output logic [3:0] hex_gridB
);
    
    logic [31:0] keycode0_gpio, keycode1_gpio;
    logic clk_25MHz, clk_125MHz, clk, clk_100MHz;
    logic locked;
    logic [9:0] drawX, drawY, ballxsig, ballysig, ballsizesig;

    logic hsync, vsync, vde;
    logic [3:0] red, green, blue;
    logic reset_ah;
    logic [11:0] rgb;
    assign reset_ah = reset_rtl_0;
    assign red = rgb [11:8];
    assign green = rgb [7:4];
    assign blue = rgb [3:0];
    
    logic [31:0] drop_timer;
    initial begin
        drop_timer = 0;
    end
    
    logic [`BITS_PER_BLOCK-1:0] random_piece;
    logic [(`BLOCKS_WIDE*`BLOCKS_HIGH)-1:0] fallen_pieces;
    logic [`BITS_PER_BLOCK-1:0] cur_piece;
    logic [`BITS_X_POS-1:0] cur_pos_x;
    logic [`BITS_Y_POS-1:0] cur_pos_y;
    logic [`BITS_ROT-1:0] cur_rot;
    logic [`BITS_BLK_POS-1:0] cur_blk_1;
    logic [`BITS_BLK_POS-1:0] cur_blk_2;
    logic [`BITS_BLK_POS-1:0] cur_blk_3;
    logic [`BITS_BLK_POS-1:0] cur_blk_4;
    logic [`BITS_BLK_SIZE-1:0] cur_width;
    logic [`BITS_BLK_SIZE-1:0] cur_height;
    logic [7:0] kb_debounced;
    logic [7:0] kb_disabled;
    randomizer randomizer_ (
        .clk(Clk),
        .random(random_piece)
    );
    
    debouncer debouncer_sw_pause_ (
        .raw(sw_pause),
        .clk(clk_25MHz),
        .enabled(sw_pause_en),
        .disabled(sw_pause_dis)
    );
    kb_debouncer kb (
        .raw(keycode0_gpio [7:0]),
        .clk(clk_125MHz),
        .enabled(kb_debounced),
        .disabled(kb_disabled)
    );
    
    logic sw_pause_en;
    logic sw_pause_dis;
    
    calc_cur_blk calc_cur_blk_ (
        .piece(cur_piece),
        .pos_x(cur_pos_x),
        .pos_y(cur_pos_y),
        .rot(cur_rot),
        .blk_1(cur_blk_1),
        .blk_2(cur_blk_2),
        .blk_3(cur_blk_3),
        .blk_4(cur_blk_4),
        .width(cur_width),
        .height(cur_height)
    );
    
    vga_display display (
        .clk(clk_25MHz),
        .cur_piece(cur_piece),
        .cur_blk_1(cur_blk_1),
        .cur_blk_2(cur_blk_2),
        .cur_blk_3(cur_blk_3),
        .cur_blk_4(cur_blk_4),
        .fallen_pieces(fallen_pieces),
        .rgb(rgb),
        .hsync(hsync),
        .vsync(vsync),
        .active_nblank (vde)
    );
    
    logic [`MODE_BITS-1:0] mode;
    logic [`MODE_BITS-1:0] old_mode;
    // The game clock
    logic game_clk;
    // The game clock reset
    logic game_clk_rst;
    
    //Keycode HEX drivers
    hex_driver HexA (
        .clk(Clk),
        .reset(reset_ah),
        .in({score_4, score_3, score_2, score_1}),
        .hex_seg(hex_segA),
        .hex_grid(hex_gridA)
    );
    
    hex_driver HexB (
        .clk(Clk),
        .reset(reset_ah),
        .in({keycode0_gpio[15:12], keycode0_gpio[11:8], keycode0_gpio[7:4], keycode0_gpio[3:0]}),
        .hex_seg(hex_segB),
        .hex_grid(hex_gridB)
    );
    
    mb_usb mb_block_i (
        .clk_100MHz(clk_125MHz),
        .gpio_usb_int_tri_i(gpio_usb_int_tri_i),
        .gpio_usb_keycode_0_tri_o(keycode0_gpio),
        .gpio_usb_keycode_1_tri_o(keycode1_gpio),
        .gpio_usb_rst_tri_o(gpio_usb_rst_tri_o),
        .reset_rtl_0(~reset_ah), //Block designs expect active low reset, all other modules are active high
        .uart_rtl_0_rxd(uart_rtl_0_rxd),
        .uart_rtl_0_txd(uart_rtl_0_txd),
        .usb_spi_miso(usb_spi_miso),
        .usb_spi_mosi(usb_spi_mosi),
        .usb_spi_sclk(usb_spi_sclk),
        .usb_spi_ss(usb_spi_ss)
    );
        
    //clock wizard configured with a 1x and 5x clock for HDMI
    clk_wiz_0 clk_wiz (
        .clk_out1(clk_25MHz),
        .clk_out2(clk_125MHz),
        .reset(reset_ah),
        .locked(locked),
        .clk_in1(Clk)
    );
    
    //VGA Sync signal generator
//    vga_controller vga (
//        .pixel_clk(clk_25MHz),
//        .reset(reset_ah),
//        .hs(hsync),
//        .vs(vsync),
//        .active_nblank(vde),
//        .drawX(drawX),
//        .drawY(drawY)
//    );    

    //Real Digital VGA to HDMI converter
    hdmi_tx_0 vga_to_hdmi (
        //Clocking and Reset
        .pix_clk(clk_25MHz),
        .pix_clkx5(clk_125MHz),
        .pix_clk_locked(locked),
        //Reset is active LOW
        .rst(reset_ah),
        //Color and Sync Signals
        .red(red),
        .green(green),
        .blue(blue),
        .hsync(hsync),
        .vsync(vsync),
        .vde(vde),
        
        //aux Data (unused)
        .aux0_din(4'b0),
        .aux1_din(4'b0),
        .aux2_din(4'b0),
        .ade(1'b0),
        
        //Differential outputs
        .TMDS_CLK_P(hdmi_tmds_clk_p),          
        .TMDS_CLK_N(hdmi_tmds_clk_n),          
        .TMDS_DATA_P(hdmi_tmds_data_p),         
        .TMDS_DATA_N(hdmi_tmds_data_n)          
    );

    logic [`BITS_X_POS-1:0] test_pos_x;
    logic [`BITS_Y_POS-1:0] test_pos_y;
    logic [`BITS_ROT-1:0] test_rot;

    game_clock game_clock_ (
        .clk(clk_25MHz),
        .rst(game_clk_rst),
        .pause(mode != `MODE_PLAY),
        .game_clk(game_clk)
    );
    
   calc_test_pos_rot calc_test_pos_rot_ (
        .mode(mode),
        .game_clk_rst(game_clk_rst),
        .game_clk(game_clk),
        .cur_pos_x(cur_pos_x),
        .cur_pos_y(cur_pos_y),
        .cur_rot(cur_rot),
        .test_pos_x(test_pos_x),
        .test_pos_y(test_pos_y),
        .test_rot(test_rot)
    ); 
    
    logic [`BITS_BLK_POS-1:0] test_blk_4;
    logic [`BITS_BLK_POS-1:0] test_blk_3;
    logic [`BITS_BLK_POS-1:0] test_blk_2;
    logic [`BITS_BLK_POS-1:0] test_blk_1;
    logic [`BITS_BLK_SIZE-1:0] test_height;
    logic [`BITS_BLK_SIZE-1:0] test_width;
    calc_cur_blk calc_test_block_ (
        .piece(cur_piece),
        .pos_x(test_pos_x),
        .pos_y(test_pos_y),
        .rot(test_rot),
        .blk_1(test_blk_1),
        .blk_2(test_blk_2),
        .blk_3(test_blk_3),
        .blk_4(test_blk_4),
        .width(test_width),
        .height(test_height)
    );
    
    function intersects_fallen_pieces;
        input logic [7:0] blk4;
        input logic [7:0] blk3;
        input logic [7:0] blk2;
        input logic [7:0] blk1;
        begin
            intersects_fallen_pieces = fallen_pieces[blk1] ||
                                       fallen_pieces[blk2] ||
                                       fallen_pieces[blk3] ||
                                       fallen_pieces[blk4];
        end
    endfunction
    logic test_intersects = intersects_fallen_pieces(test_blk_1, test_blk_2, test_blk_3, test_blk_4);
    
    
    task move_left;
        begin
            if (cur_pos_x > 0 && !test_intersects) begin
                cur_pos_x <= cur_pos_x - 1;
            end
        end
    endtask

    
    task move_right;
        begin
            if (cur_pos_x + cur_width < `BLOCKS_WIDE && !test_intersects) begin
                cur_pos_x <= cur_pos_x + 1;
            end
        end
    endtask

    task rotate;
        begin
            if (cur_pos_x + test_width <= `BLOCKS_WIDE &&
                cur_pos_y + test_height <= `BLOCKS_HIGH &&
                !test_intersects) begin
                cur_rot <= cur_rot + 1;
            end
        end
    endtask

    task add_to_fallen_pieces;
        begin
            fallen_pieces[cur_blk_1] <= 1;
            fallen_pieces[cur_blk_2] <= 1;
            fallen_pieces[cur_blk_3] <= 1;
            fallen_pieces[cur_blk_4] <= 1;
        end
    endtask

    task get_new_block;
        begin
            drop_timer <= 0;
            cur_piece <= random_piece;
            cur_pos_x <= (`BLOCKS_WIDE / 2) - 1;
            cur_pos_y <= 0;
            cur_rot <= 0; 
            game_clk_rst <= 1;
        end
    endtask

    task move_down;
        begin
            if (cur_pos_y + cur_height < `BLOCKS_HIGH && !test_intersects) begin
                cur_pos_y <= cur_pos_y + 1;
            end else begin
                add_to_fallen_pieces();
                get_new_block();
            end
        end
    endtask

    
    task drop_to_bottom;
        begin
            mode <= `MODE_DROP;
        end
    endtask

    
    logic [3:0] score_1; 
    logic [3:0] score_2; 
    logic [3:0] score_3; 
    logic [3:0] score_4; 
    
   
    logic [`BITS_Y_POS-1:0] remove_row_y;
    logic remove_row_en;
    complete_row complete_row_ (
        .clk(clk_25MHz),
        .pause(mode != `MODE_PLAY),
        .fallen_pieces(fallen_pieces),
        .row(remove_row_y),
        .enabled(remove_row_en)
    );

    
    logic [`BITS_Y_POS-1:0] shifting_row;
    task remove_row;
        begin
            
            mode <= `MODE_SHIFT;
            shifting_row <= remove_row_y;
            
            if (score_1 == 9) begin
                if (score_2 == 9) begin
                    if (score_3 == 9) begin
                        if (score_4 != 9) begin
                            score_4 <= score_4 + 1;
                            score_3 <= 0;
                            score_2 <= 0;
                            score_1 <= 0;
                        end
                    end else begin
                        score_3 <= score_3 + 1;
                        score_2 <= 0;
                        score_1 <= 0;
                    end
                end else begin
                    score_2 <= score_2 + 1;
                    score_1 <= 0;
                end
            end else begin
                score_1 <= score_1 + 1;
            end
        end
    endtask

    
    initial begin
        mode = `MODE_IDLE;
        fallen_pieces = 0;
        cur_piece = `EMPTY_BLOCK;
        cur_rot = 0;
        cur_pos_x = 0;
        cur_pos_y = 0;
        score_4 = 0;
        score_3 = 0;
        score_2 = 0;
        score_1 = 0;
        counter = 0;
    end

   
    task start_game;
        begin
            mode <= `MODE_PLAY;
            fallen_pieces <= 0;
            score_1 <= 0;
            score_2 <= 0;
            score_3 <= 0;
            score_4 <= 0;
            get_new_block();
        end
    endtask

   
    logic game_over = cur_pos_y == 0 && intersects_fallen_pieces(cur_blk_1, cur_blk_2, cur_blk_3, cur_blk_4);
    logic [31:0] counter;
   
    // Main game logic
    always @ (posedge clk_25MHz) begin
        if (drop_timer < `DROP_TIMER_MAX) begin
            drop_timer <= drop_timer + 1;
        end
        game_clk_rst <= 0;
        if (mode == `MODE_IDLE && (sw_pause_en || sw_pause_dis)) begin
            
            start_game();
        end else if (reset_ah || game_over) begin
            
            mode <= `MODE_IDLE;
            add_to_fallen_pieces();
            cur_piece <= `EMPTY_BLOCK;
        end else if (keycode0_gpio [7:0] == 8'h2c && mode == `MODE_PLAY) begin
            
            if (counter >= 5000000) begin 
                    mode <= `MODE_PAUSE;
                    old_mode <= mode;
                    counter <= 0;
                end
                else begin 
                    counter <= counter +1;
                end 
        end else if (keycode0_gpio [7:0] == 8'h2c && mode == `MODE_PAUSE) begin
            
            if (counter >= 5000000) begin 
                    mode <= old_mode;
                    counter <= 0;
                end
                else begin 
                    counter <= counter +1;
                end
        end else if (mode == `MODE_PLAY) begin
            
            if (keycode0_gpio [7:0] == 8'h04) begin
                if (counter >= 5000000) begin 
                    move_left();
                    counter <= 0;
                end
                else begin 
                    counter <= counter +1;
                end 
            end else if (keycode0_gpio [7:0] == 8'h07) begin
                if (counter >= 5000000) begin 
                    move_right();
                    counter <= 0;
                end
                else begin 
                    counter <= counter +1;
                end 
            end else if (keycode0_gpio [7:0] == 8'h1A) begin
                if (counter >= 5000000) begin 
                    rotate();
                    counter <= 0;
                end
                else begin 
                    counter <= counter +1;
                end 
                
            end else if (keycode0_gpio [7:0] == 8'h16) begin
                if (counter >= 5000000) begin 
                    move_down();
                    counter <= 0;
                end
                else begin 
                    counter <= counter +1;
                end 
            end 
            else if (game_clk) begin
                move_down();
            end 
            else if (drop_timer == `DROP_TIMER_MAX) begin
                drop_to_bottom();
            end else if (remove_row_en) begin
                remove_row();
            end
        end else if (mode == `MODE_DROP) begin
            // We are dropping the block until we hit respawn
            // at the top
            if (game_clk_rst && !(keycode0_gpio [7:0] == 8'h2c)) begin
                mode <= `MODE_PLAY;
            end else begin
                move_down();
            end
        end else if (mode == `MODE_SHIFT) begin
            
            if (shifting_row == 0) begin
                fallen_pieces[0 +: `BLOCKS_WIDE] <= 0;
                mode <= `MODE_PLAY;
            end else begin
                fallen_pieces[shifting_row*`BLOCKS_WIDE +: `BLOCKS_WIDE] <= fallen_pieces[(shifting_row - 1)*`BLOCKS_WIDE +: `BLOCKS_WIDE];
                shifting_row <= shifting_row - 1;
            end
        end
    end
    
    
    
    
endmodule
    