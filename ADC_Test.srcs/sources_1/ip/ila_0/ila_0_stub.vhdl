-- Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
-- Date        : Wed Jul 17 15:21:36 2019
-- Host        : DESKTOP-N3U7HNE running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               C:/Users/xtjac/Documents/ADC_Test/ADC_Test.srcs/sources_1/ip/ila_0/ila_0_stub.vhdl
-- Design      : ila_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7k325tffg900-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ila_0 is
  Port ( 
    clk : in STD_LOGIC;
    probe0 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe1 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe2 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe3 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe4 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe5 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    probe6 : in STD_LOGIC_VECTOR ( 7 downto 0 )
  );

end ila_0;

architecture stub of ila_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk,probe0[31:0],probe1[0:0],probe2[0:0],probe3[0:0],probe4[0:0],probe5[15:0],probe6[7:0]";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "ila,Vivado 2019.1";
begin
end;
