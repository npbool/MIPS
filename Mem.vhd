----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:44:09 11/07/2012 
-- Design Name: 
-- Module Name:    Mem - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Mem is
end Mem;

architecture Behavioral of Mem is
PORT(
		Addr	:IN STD_LOGIC_VECTOR(31 downto 0);
		DataIn	:IN STD_LOGIC_VECTOR(31 downto 0);
		DataOut	:OUT STD_LOGIC_VECTOR(31 downto 0);
		MemRd,MemWr:STD_LOGIC;
		Done	:OUT STD_LOGIC:
		--TLB:TODO
		clk,rst:IN STD_LOGIC;
		
		--π‹Ω≈£¨∂•≤„“˝»Î
		Ram1_addr,Ram2_addr:OUT STD_LOGIC_VECTOR(17 downto 0);
		Ram1_data,Ram2_data:INOUT STD_LOGIC_VECTOR(15 downto 0);
		Ram1_en,Ram1_oe,Ram1_rw:OUT STD_LOGIC;
		Ram2_en,Ram2_oe,Ram2_rw:OUT STD_LOGIC;
		
		Data_ready,Tbre,Tsre:IN STD_LOGIC;
		Rdn,Rst,Rxd,Wrn:OUT STD_LOGIC;
		
		Flash_addr:OUT STD_LOGIC_VECTOR(22 downto 0);
		Flash_data:INOUT STD_LOGIC_VECTOR(15 downto 0);
		Flash_byte,Flash_ce,Flash_ce1,Flash_ce2,
		Flash_oe,Flash_rp,Flash_sts,Flash_vpen,Flash_we:OUT STD_LOGIC;		
	);

begin

end Behavioral;

