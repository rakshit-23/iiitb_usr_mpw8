// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    wire clk;
    wire rst;

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;
    wire [7:0] data_in,data_out;
    wire sl_ser,sr_ser;
    wire [1:0] select;
    iiitb_usr usr1(data_in,data_out,clk,rst,select,sl_ser,sr_ser);

    // IO
    assign clk = wb_clk_i;
    assign rst = wb_rst_i;
    assign {data_in,select,sl_ser,sr_ser}= io_in[37:26];
    assign io_out[37:30] = data_out;
    assign io_oeb = 0;

    // IRQ
    assign irq = 3'b000;	// Unused

    

endmodule

    module iiitb_usr  (data_in,data_out,clock,reset,select,sl_ser,sr_ser);
    input [7:0] data_in;
    output reg [7:0] data_out;
    input reset,clock,sl_ser,sr_ser;
    input [1:0] select;
    
    always@(posedge clock)
    begin
        if(reset==1'b1)
            data_out<=8'b00000000;
        else
        begin 
            if(select==2'b00)   //Shift left
                data_out<={data_out[6:0],sl_ser};
            else if(select==2'b01)  //Shift right
                data_out<={sr_ser,data_out[7:1]}; 
            else if(select==2'b10)  // Parallel load
                data_out<=data_in;
            else
                data_out<=data_out; //Temporary storage
         end
    end
    
endmodule

`default_nettype wire
