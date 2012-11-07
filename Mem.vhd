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
PORT(
		Addr	:IN STD_LOGIC_VECTOR(31 downto 0);
		Data	:INOUT STD_LOGIC_VECTOR(31 downto 0); --高阻？？
		En,Rw	:IN STD_LOGIC;
		Done	:OUT STD_LOGIC;
		
		--TLB:TODO
		Tlb_missing	:OUT STD_LOGIC;
		
		clk,rst:IN STD_LOGIC;
		
		--管脚，顶层引入
		Ram1_addr,Ram2_addr:OUT STD_LOGIC_VECTOR(17 downto 0);
		Ram1_data,Ram2_data:INOUT STD_LOGIC_VECTOR(15 downto 0);
		Ram1_en,Ram1_oe,Ram1_rw:OUT STD_LOGIC;
		Ram2_en,Ram2_oe,Ram2_rw:OUT STD_LOGIC;
		
		Data_ready,Tbre,Tsre:IN STD_LOGIC;
		Rdn,Rst,Rxd,Wrn:OUT STD_LOGIC;
		
		Flash_addr:OUT STD_LOGIC_VECTOR(22 downto 0);
		Flash_data:INOUT STD_LOGIC_VECTOR(15 downto 0);
		Flash_byte,Flash_ce,Flash_ce1,Flash_ce2,
		Flash_oe,Flash_rp,Flash_sts,Flash_vpen,Flash_we:OUT STD_LOGIC
		--串口切换：rw,en,oe全1，rdn,wrn=1（InterConn3,6)
	);
end Mem;

architecture Behavioral of Mem is

signal working:STD_LOGIC;
signal count:STD_LOGIC_VECTOR(1 downto 0);
signal op:STD_LOGIC_VECTOR(2 downto 0); 
--000:RamRead,001:RamWrite
--010:serial read,011:w
--100:flash read,101:f w

--1FD003F8:串口数据。
--1FD003FC:串口状态。S&1=1可写，S&2=2可读。

begin
	working <= '0';

	Ram2_oe<='0';
	Ram2_oe<='0';
	Flash_ce<='0';
	Flash_ce1<='0';
	Flash_ce2<='0';		
	
	PROCESS(clk)
	begin		
		if working='0' and En='1' then
			working<='1';
			Done<='0';
			if Addr=x"1FD003F8" then
				--serial
				Ram1_en<='1';
				Ram1_oe<='1';
				Ram1_rw<='1';
				if Rw='0' then
					--read serial
					
				else
					--write serial
				end if;				
			elsif Addr=x"1FD003FC" then
				Data<="ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
				Data<=x"00000000" or (Tbre and Tsre) or (Data_ready sll 1);
				Done<=1;
			elsif Rw='0' then
				--read Ram
				Ram1_addr<=Addr(17 downto 0);
				Ram1_data<="ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
				Ram1_rw<='1';
				Ram2_addr<=Addr(17 downto 0);				
				Ram2_data<="ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
				Ram2_rw<='1';				
				op<="00";
			else
				--write
				Ram1_addr<=Addr(17 downto 0);		
				Ram1_data<=Data;
				Ram1_rw<='0';
				Ram2_addr<=Addr(17 downto 0);				
				Ram2_data<=Data;
				Ram2_rw<='0';							
			end if;			
		elsif working='1' then
			case op is
			when "00" => --prev ram read;
				case count is
				when "00" =>
					Data<="ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
					Done<='1';
					Data(31 downto 16)<=Ram1_data;
					Data(15 downto 0)<=Ram2_data;
					working<='0';
				when "01" =>
					count<="00";
				when "10" =>
					count<="01";
				when "11" =>
					count<="10";
				when others =>
					null;
				end case;
			when "01" => --prev ram write				
				case count is
				when "00" =>
					Done<='1';					
					working<='0';
				when "01" =>
					count<="00";
				when "10" =>
					count<="01";
				when "11" =>
					count<="10";
				when others =>
					null;
				end case;
			when "10" => --prev serial write
				null;
			when "11" => --prev flash op
				null;
			when others=>
				null;
			end case;
		end if;
	end PROCESS;	
end Behavioral;

