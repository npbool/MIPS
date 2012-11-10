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
		DataIn	:IN STD_LOGIC_VECTOR(31 downto 0);
		DataOut	:Out STD_LOGIC_VECTOR(31 downto 0);
		En,Rw	:IN STD_LOGIC;
		Done	:OUT STD_LOGIC;
		
		--TLB:TODO
		Tlb_missing	:OUT STD_LOGIC;
		
		clk,rst:IN STD_LOGIC;
		
		--debug 
		Seg7_out: OUT STD_LOGIC_VECTOR(0 to 6);
		--管脚，顶层引入
		Rom_switch:IN STD_LOGIC;
		bl_addr,pro_addr:OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
		bl_data,pro_data:IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		Ram1_addr,Ram2_addr:OUT STD_LOGIC_VECTOR(17 downto 0);
		Ram1_data,Ram2_data:INOUT STD_LOGIC_VECTOR(15 downto 0);
		Ram1_en,Ram1_oe,Ram1_rw:OUT STD_LOGIC;
		Ram2_en,Ram2_oe,Ram2_rw:OUT STD_LOGIC;
		
		Data_ready,Tbre,Tsre:IN STD_LOGIC;
		Rdn,Wrn:OUT STD_LOGIC;
		
		--串口切换：rw,en,oe全1，rdn,wrn=1（InterConn3,6)	
		
		Flash_addr:OUT STD_LOGIC_VECTOR(22 downto 0);
		Flash_data:INOUT STD_LOGIC_VECTOR(15 downto 0);
		Flash_byte,Flash_ce,Flash_ce1,Flash_ce2,Flash_oe,Flash_rp,Flash_sts,Flash_vpen,Flash_we:OUT STD_LOGIC		
		
	);
	
end Mem;

architecture Behavioral of Mem is

signal working:STD_LOGIC:='0';
signal count:STD_LOGIC_VECTOR(2 downto 0);
signal op:STD_LOGIC_VECTOR(2 downto 0); 
signal actual_addr:STD_LOGIC_VECTOR(31 downto 0);
signal tmp:STD_LOGIC_VECTOR(1 downto 0);
--000:RamRead,001:RamWrite
--010:ROM
--100:serial read,101:w
--110:flash read,111:f w

--1FD003F8:串口数据。
--1FD003FC:串口状态。S&1=1可写，S&2=2可读。

--RAM右移两位
--ROM地址右移两位
--flash地址右移1位

begin	
	--working<='0';
	Ram2_en<='0';
	Ram2_oe<='0';
	Flash_ce<='0';
	Flash_ce1<='0';
	Flash_ce2<='0';
	Flash_rp<='1';
	Flash_byte<='1';
	Flash_vpen<='1';
	
	PROCESS(clk)
	begin		
		if working='0' and En='1' then
			--当前空闲
			
			--清零
			if Addr(31 downto 29)="100" or Addr(31 downto 29)="101" then
				actual_addr <= "000" & Addr(28 downto 0);
			else 
				actual_addr <= Addr;
			end if;	
			
			Done<='0';
			if actual_addr(31 downto 12)=x"1FC00" then
				--ROM
				bl_addr<=actual_addr(11 downto 2);
				pro_addr<=actual_addr(11 downto 2);
				op<="010";
				count<="011";
				working<='1';
			elsif actual_addr=x"1FD003F8" then
				--串口
				Ram1_en<='1';
				Ram1_oe<='1';
				Ram1_rw<='1';
				if Rw='0' then
					--read serial
					if Data_ready='1' then
						Rdn<='1';
						Wrn<='0';
						Ram1_data<="ZZZZZZZZZZZZZZZZ";
						op<="100";
						working<='1';
						count<="111";	
					end if;
				else
					--write serial
					if Tbre='1' and Tsre='1' then
						Rdn<='0';
						Wrn<='1';
						Ram1_data<=DataIn(15 downto 0);
						op<="101";
						working<='1';
						count<="111";
					end if;
				end if;				
			elsif actual_addr=x"1FD003FC" then
				--串口状态				
				tmp<="00";
				if Data_ready='1' then
					tmp<= tmp or "10";
				end if;
				if (Tbre and Tsre)='1' then
					tmp<= tmp or "01";
				end if;
				DataOut<="000000000000000000000000000000"&tmp;			
				
				Done<='1';
			elsif actual_addr(31 downto 24)=x"1E" then
				--Flash
				if Rw='0' then
					--read
					Flash_data<="ZZZZZZZZZZZZZZZZ";
					Flash_we<='1';
					Flash_oe<='0';					
					
				else
					--write
					Flash_we<='1';
					Flash_oe<='0';
					
				end if;
				null;
			elsif Rw='0' then
				--read Ram
				Ram1_en<='0';
				Ram1_oe<='0';
				Ram1_rw<='1';
				Ram2_rw<='1';
				Rdn<='1';
				Wrn<='1';
				Ram1_addr<=Addr(19 downto 2);
				Ram1_data<="ZZZZZZZZZZZZZZZZ";
				Ram1_rw<='1';
				Ram2_addr<=Addr(19 downto 2);				
				Ram2_data<="ZZZZZZZZZZZZZZZZ";
				Ram2_rw<='1';	
				working<='1';
				op<="000";
				count<="011";
			else
				--write Ram		
				Ram1_en<='0';
				Ram1_oe<='0';
				Ram1_rw<='0';
				Ram2_rw<='0';
				Rdn<='1';
				Wrn<='1';
				Ram1_addr<=Addr(19 downto 2);		
				Ram1_data<=DataIn(31 downto 16);
				Ram1_rw<='0';
				Ram2_addr<=Addr(19 downto 2);				
				Ram2_data<=DataIn(15 downto 0);
				Ram2_rw<='0';		
				working<='1';
				op<="001";
				count<="011";
			end if;			
		elsif working='1' then
			case count is
			when "000" =>
				--done
				case op is
				when "010" =>
					--prev rom				
					if Rom_switch='0' then
						DataOut<= bl_data;
					else
						DataOut<= pro_data;
					end if;
					working<='0';
					Done<='1';
				when "100" => --prev serial read
					DataOut<=x"0000"&Ram1_data;
					Rdn<='0';
					working<='0';
					Done<='1';
				when "101" => --prev serial write
					Wrn<='0';
					working<='0';
					Done<='1';
				when "110" => --prev flash read
					null;
				when "111" => --prev flash write
					null;
				when "000" => --prev ram read;					
					Done<='1';
					DataOut(31 downto 16)<=Ram1_data;
					DataOut(15 downto 0)<=Ram2_data;
					working<='0';					
				when "001" => --prev ram write				
					Done<='1';
					working<='0';
				when others=>
					null;
				end case;
			when "001" =>
				count<="000";
			when "010" =>
				count<="001";
			when "011" =>
				count<="010";
			when "100" =>
				count<="011";
			when "101" =>
				count<="100";
			when "110" =>
				count<="101";
			when "111" =>
				count<="110";
			when others => null;
			end case;
		end if;
	end PROCESS;	
	
	PROCESS(working,op)
	begin
		if working='0' then
			Seg7_out <= "0000000";
		else
			Seg7_out <= op & "0000";
		end if;
	end process;
end Behavioral;

