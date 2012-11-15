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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

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

COMPONENT bl_rom
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;
COMPONENT pro_rom
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;
signal bl_addr,pro_addr:STD_LOGIC_VECTOR(9 DOWNTO 0);
signal bl_data,pro_data:STD_LOGIC_VECTOR(31 DOWNTO 0);

signal count:STD_LOGIC_VECTOR(2 downto 0);

--1FD003F8:串口数据。
--1FD003FC:串口状态。S&1=1可写，S&2=2可读。

--RAM右移两位
--ROM地址右移两位
--flash地址右移1位
	type mem_state is (idle,working,finished);
	signal state:mem_state;
	type op_type is (read_ram,write_ram,
							pre_write_serial,write_serial,pre_read_serial,read_serial,
							read_rom,
							read_flash,write_flash
							);
	signal op: op_type;
begin		
	bl : bl_rom
	PORT MAP (
    clka => clk,
    addra => bl_addr,
    douta => bl_data
  );
	pro : pro_rom
	PORT MAP (
    clka => clk,
    addra => pro_addr,
    douta => pro_data
  );
	Ram2_en<='0';
	Ram2_oe<='0';
	Flash_ce<='0';
	Flash_ce1<='0';
	Flash_ce2<='0';
	Flash_rp<='1';
	Flash_byte<='1';
	Flash_vpen<='1';	
	
	Seg7_out(6)<=Data_ready;

	
	--Seg7_out(6)<= Rw;
	
	PROCESS(clk)
	begin
		case state is 
		when idle =>
			Seg7_out(4 to 5) <= "00";		
		when working=>
			Seg7_out(4 to 5) <="10";
		when finished=>
			Seg7_out(4 to 5) <= "11";
		when others => null;
		end case;
	end process;
	--Seg7_out <= "0000000" when working='0' else op & "0000";
	PROCESS(clk, rst)
	variable actual_addr:STD_LOGIC_VECTOR(31 downto 0);
	variable tmp:STD_LOGIC_VECTOR(1 downto 0);
	begin
		if rst = '0' then
			-- todo 			
			state<=idle;		
			Rdn<='1';
			Wrn<='1';
			Done<='0';
		elsif clk'event and clk='1' then 
			if En='0' then
				Done<='0';
				state<=idle;						
			else
				case state is
				when idle =>												
					--清零
					if En='1' then
						if Addr(31 downto 29)="100" or Addr(31 downto 29)="101" then
							actual_addr := "000" & Addr(28 downto 0);
						else 
							actual_addr := Addr;
						end if;					
						
						if actual_addr(31 downto 12)=x"1FC00" then
							--ROM						
							bl_addr<=actual_addr(11 downto 2);
							pro_addr<=actual_addr(11 downto 2);
							op<=read_rom;						
							count<="001";
							state<=working;
						elsif actual_addr=x"1FD003F8" then
							--串口
							
							Ram1_en<='1';
							Ram1_oe<='1';
							Ram1_rw<='1';
							if Rw='0' then
								--read serial
								Seg7_out(0 to 3)<="0110";
								if Data_ready='1' then							
									Ram1_data<="ZZZZZZZZZZZZZZZZ";
									op<=pre_read_serial;
									state<=working;
									count<="000";
								end if;
							else
								--write serial
								Seg7_out(0 to 3)<="1001";
								if Tbre='1' and Tsre='1' then							
									Ram1_data<=DataIn(15 downto 0);
									op<=pre_write_serial;
									state<=working;
									count<="000";
								end if;
							end if;				
						elsif actual_addr=x"1FD003FC" then
							--串口状态				
							tmp:="00";
							if Data_ready='1' then
								tmp:= tmp or "10";
							end if;
							if (Tbre and Tsre)='1' then
								tmp:= tmp or "01";
							end if;
							DataOut<="000000000000000000000000000000"&tmp;			
							state<=finished;
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
						elsif Rw='0' then
							--read Ram 3
							--Seg7_out<="0000011";
							Ram1_en<='0';
							Ram1_oe<='0';
							Ram1_rw<='1';
							Ram2_rw<='1';
							Rdn<='1';
							Wrn<='1';
							Ram1_addr<=Addr(19 downto 2);
							Ram1_data<="ZZZZZZZZZZZZZZZZ";					
							Ram2_addr<=Addr(19 downto 2);				
							Ram2_data<="ZZZZZZZZZZZZZZZZ";					
							state<=working;
							op<=read_ram;
							count<="000";
						else
							--write Ram		4
							--Seg7_out<="0000100";
							Ram1_en<='0';
							Ram1_oe<='0';
							Ram1_rw<='0';
							Ram2_rw<='0';
							Rdn<='1';
							Wrn<='1';
							Ram1_addr<=Addr(19 downto 2);		
							Ram1_data<=DataIn(31 downto 16);					
							Ram2_addr<=Addr(19 downto 2);				
							Ram2_data<=DataIn(15 downto 0);					
							state<=working;
							op<=write_ram;
							count<="000";					
						end if;	
					end if;
				when working =>
					if count="000" then									
						case op is
						when read_rom =>
							--prev rom				
							if Rom_switch = '0' then
								DataOut <= bl_data;
							else
								DataOut <= pro_data;
							end if;
							state<=finished;
							Done <= '1';
						when pre_read_serial =>
							Rdn<='0';
							Wrn<='1';
							op<=read_serial;
							count<="001";
						when pre_write_serial =>
							Rdn<='1';
							Wrn<='0';
							op<=write_serial;
							count<="001";				
						when read_serial => --prev serial read						
							DataOut<=x"0000"&Ram1_data;
							Rdn<='1';
							Wrn<='1';
							state<=finished;
							Done<='1';
						when write_serial => --prev serial write
							Rdn<='1';
							Wrn<='1';
							state<=finished;
							Done<='1';
						when read_flash => --prev flash read
							null;
						when write_flash => --prev flash write
							null;
						when read_ram => --prev ram read;					
							Done<='1';
							DataOut(31 downto 16)<=Ram1_data;
							DataOut(15 downto 0)<=Ram2_data;
							state<=finished;					
						when write_ram => --prev ram write				
							Done<='1';
							state<=finished;
						when others =>
							null;
						end case;						
					else
						count <= count-1;
					end if;
				when others =>
					null;
				end case;
			end if;
		end if;
	end PROCESS;	
end Behavioral;