----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:20:20 11/07/2012 
-- Design Name: 
-- Module Name:    Controller - Behavioral 
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Controller is 
	port( 
		std_clk, reset: in std_logic;
		rom_switch: in std_logic;	-- the most right switch
		ram1_addr,ram2_addr:OUT STD_LOGIC_VECTOR(17 downto 0);
		ram1_data,ram2_data:INOUT STD_LOGIC_VECTOR(15 downto 0);
		ram1_en,ram1_oe,ram1_rw:OUT STD_LOGIC;
		ram2_en,ram2_oe,ram2_rw:OUT STD_LOGIC;
		data_ready,tbre,tsre:IN STD_LOGIC;
		rdn,wrn:OUT STD_LOGIC;
		flash_addr:OUT STD_LOGIC_VECTOR(22 downto 0);
		flash_data:INOUT STD_LOGIC_VECTOR(15 downto 0);
		flash_byte,flash_ce,flash_ce1,flash_ce2,flash_oe,flash_rp,flash_sts,flash_vpen,flash_we:OUT STD_LOGIC;
		
		switches: in std_logic_vector(0 to 14);
		LEDS: out std_logic_vector(15 downto 0);
		seg7_out_1: out std_logic_vector(0 to 6);
		seg7_out_2: out std_logic_vector(0 to 6)
	);
end entity Controller;

architecture Behavioral of Controller is
   type state_type is (init_state, prepare_fetch_state, fetch_state, decode_state, alu_wb_reg_state, 
						branch_e_ne_decide_state, branch_ge_lt_decide_state, branch_gt_le_decide_state, 
						visit_memory_word_state, visit_memory_byte_state, store_memory_byte_state, 
						wait_memory_word_state, wait_memory_byte_state, multi_wait_state);
	signal state: state_type;
	
	signal counter: STD_LOGIC_VECTOR(3 downto 0);

-- clk
	signal clk: std_logic;


-- Registers
	signal R_a: std_logic_vector(31 downto 0);
	signal R_b: std_logic_vector(31 downto 0);
	signal R_d_idx: std_logic_vector(4 downto 0);
	signal reg_hi: std_logic_vector(31 downto 0);
	signal reg_lo: std_logic_vector(31 downto 0);

-- Register File
	type reg_file is array (0 to 31) of std_logic_vector(31 downto 0);
	signal registers: reg_file;

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
	
	Component Mem is
	PORT(
			Addr	:IN STD_LOGIC_VECTOR(31 downto 0);
			DataIn	:IN STD_LOGIC_VECTOR(31 downto 0);
			DataOut	:Out STD_LOGIC_VECTOR(31 downto 0);
			En,Rw	:IN STD_LOGIC;
			Done	:OUT STD_LOGIC;
			
			--TLB:TODO
			Tlb_missing	:OUT STD_LOGIC;			
			
			clk, rst:IN STD_LOGIC;
			
			Seg7_out: OUT STD_LOGIC_VECTOR(0 to 6);
			
			--管脚，顶层引�
			Rom_switch:IN STD_LOGIC;
			bl_addr,pro_addr:OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
			bl_data,pro_data:IN STD_LOGIC_VECTOR(31 DOWNTO 0);
			Ram1_addr,Ram2_addr:OUT STD_LOGIC_VECTOR(17 downto 0);
			Ram1_data,Ram2_data:INOUT STD_LOGIC_VECTOR(15 downto 0);
			Ram1_en,Ram1_oe,Ram1_rw:OUT STD_LOGIC;
			Ram2_en,Ram2_oe,Ram2_rw:OUT STD_LOGIC;
			
			Data_ready,Tbre,Tsre:IN STD_LOGIC;
			Rdn,Wrn:OUT STD_LOGIC;
			
			--串口切换：rw,en,oe�，rdn,wrn=1（InterConn3,6)	
			
			Flash_addr:OUT STD_LOGIC_VECTOR(22 downto 0);
			Flash_data:INOUT STD_LOGIC_VECTOR(15 downto 0);
			Flash_byte,Flash_ce,Flash_ce1,Flash_ce2,Flash_oe,Flash_rp,Flash_sts,Flash_vpen,Flash_we:OUT STD_LOGIC
		);
	end Component Mem;

-- mem signals
	signal mem_addr, mem_data_in, mem_data_out: std_logic_vector(31 downto 0);
	signal mem_op, mem_done, mem_en, mem_rw: std_logic:='0';
	signal tlb_missing: std_logic;
	
	signal rom_bl_addr, rom_pro_addr: std_logic_vector(9 downto 0);
	signal rom_bl_data, rom_pro_data: std_logic_vector(31 downto 0);

	Component ALU is
		 Port ( A,B : in STD_LOGIC_VECTOR(31 downto 0);
				  Code: in STD_LOGIC_VECTOR(5 downto 0);
				  Func: in STD_LOGIC_VECTOR(5 downto 0);
				  R : out STD_LOGIC_VECTOR(31 downto 0);
				  Zero : out STD_LOGIC;
				  Sign : out STD_LOGIC);	
	end Component ALU;
	COMPONENT multiplier
		PORT (
				 a : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
				 b : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
				 p : OUT STD_LOGIC_VECTOR(63 DOWNTO 0)
				);
	END COMPONENT;
	
-- ALU Signals
	signal alu_out: std_logic_vector(31 downto 0);
	signal alu_sign: std_logic;
	signal alu_zero: std_logic;
	
-- MULTIPLIER Signals
	signal multi_wait_counter: std_logic_vector(1 downto 0);
	signal multi_out : std_logic_vector(63 downto 0);
-- Instruction register
	signal IR: std_logic_vector(31 downto 0); -- instruction register
	signal PC: std_logic_vector(31 downto 0); -- PC registers
	signal current_PC: std_logic_vector(31 downto 0); -- the register to store PC
	
	signal LED_display_data: std_logic_vector(31 downto 0);

begin
	--MemUnit: Mem()
	
	alu_unit: ALU port map(A=>R_a,B=> R_b,Code=> IR(31 downto 26),Func=> IR(5 downto 0),R=> alu_out,Zero=> alu_zero,Sign=> alu_sign);
--	multiplier_unit: multiplier(R_a=>a, R_b=>b, reg_hi=>p(63 downto 32), reg_lo=>p(31 downto 0));
	multiplier_unit: multiplier port map(a=>R_a, b=> R_b,p=>multi_out);

--	mem_unit: Mem port map(mem_addr=>Addr, mem_data_in=>DataIn, mem_data_out=>DataOut, mem_en=>En, mem_rw=>Rw, mem_done=>Done, tlb_missing=>Tlb_missing, clk=>clk, reset=>rst, rom_switch=>Rom_switch, rom_bl_addr=>bl_addr, rom_pro_addr=>pro_addr, rom_bl_data=>bl_data, rom_pro_data=>pro_data, ram1_addr=>Ram1_addr, ram2_addr=>Ram2_addr, ram1_data=>Ram1_data, ram2_data=>Ram2_data, ram1_en=>Ram1_en, ram1_oe=>Ram1_oe, ram1_rw=>Ram1_rw, ram2_en=>Ram2_en, ram2_oe=>Ram2_oe, ram2_rw=>Ram2_rw, data_ready=>Data_ready, tbre=>Tbre, tsre=>Tsre, rdn=>Rdn, wrn=>Wrn, flash_addr=>Flash_addr, flash_data=>Flash_data, flash_byte=>Flash_byte, flash_ce=>Flash_ce, flash_ce1=>Flash_ce1, flash_ce2=>Flash_ce2, flash_oe=>Flash_oe, flash_rp=>Flash_rp, flash_sts=>Flash_sts, flash_vpen=>Flash_vpen, flash_we=>Flash_we);
	mem_unit: Mem port map(Seg7_out=>seg7_out_1,Addr=>mem_addr,DataIn=> mem_data_in,DataOut=> mem_data_out,En=> mem_en,Rw=> mem_rw,Done=> mem_done,Tlb_missing=> tlb_missing,clk=> clk,rst=> reset,Rom_switch=> rom_switch,bl_addr=> rom_bl_addr,pro_addr=> rom_pro_addr,bl_data=> rom_bl_data,pro_data=> rom_pro_data,Ram1_addr=> ram1_addr,Ram2_addr=> ram2_addr,Ram1_data=> ram1_data,Ram2_data=> ram2_data,Ram1_en=> ram1_en,Ram1_oe=> ram1_oe,Ram1_rw=> ram1_rw,Ram2_en=> ram2_en,Ram2_oe=> ram2_oe,Ram2_rw=> ram2_rw,Data_ready=> data_ready,Tbre=> tbre,Tsre=> tsre,Rdn=> rdn,Wrn=> wrn,Flash_addr=> flash_addr,Flash_data=> flash_data,Flash_byte=> flash_byte,Flash_ce=> flash_ce,Flash_ce1=> flash_ce1,Flash_ce2=> flash_ce2,Flash_oe=> flash_oe,Flash_rp=> flash_rp,Flash_sts=> flash_sts,Flash_vpen=> flash_vpen,Flash_we=> flash_we);
--	bl_rom_unit: bl_rom port map(clk=>clka, rom_bl_addr=>addra, rom_bl_data=>douta);
	bl_rom_unit: bl_rom port map(clka=>clk,addra=> rom_bl_addr,douta=> rom_bl_data);
	pro_rom_unit: pro_rom port map(clka=>clk,addra=> rom_pro_addr,douta=> rom_pro_data);
	
	--clock divided
	--clk<=counter(2);
	clk<=std_clk;
	
	process (reset, clk)
	
	begin
		if reset = '0' then
			registers(0)<=(others => '0');
			mem_en<='0';
			state <= init_state;
		elsif clk'event and clk='1' then
			case state is 
				when init_state =>
					-- do something initialization
					-- PC <= (others >= '0');
					PC <= x"1FC00000";
					state <= prepare_fetch_state;
				when prepare_fetch_state =>
					current_PC <= PC;
					mem_addr <= PC;
					mem_rw <= '0';
					mem_en <= '1';
					state <= fetch_state;					
				when fetch_state => 
					if mem_done = '1' then
						mem_en <= '0';
						IR <= mem_data_out;
						PC <= PC + 4;
						state <= decode_state;
					end if;
				when decode_state =>
					case IR(31 downto 30) is
						when "00" => -- non-memory instruction
							case IR(29 downto 26) is
								when "0000" => -- special
									case IR(5 downto 0) is 
										-- ADDU SLT SLTU SUBU AND OR SLLV SRAV SRL SRLV XOR NOR										
										when "100001" | "101010" | "101011" | "100011" | "100100" | "100101" | "000100" | "000111" | "000010" | "000110" | "100110" | "100111" => -- 33 42 43 35 36 37 4 7 2 6 38 39, (s t d)
											R_a <= registers(CONV_INTEGER(IR(25 downto 21)));
											R_b <= registers(CONV_INTEGER(IR(20 downto 16)));
											R_d_idx <= IR(15 downto 11);
											state <= alu_wb_reg_state;										
										when "000000" | "000011" => -- SLL SRA
											R_a <= registers(CONV_INTEGER(IR(20 downto 16)));
											R_b <= EXT(IR(10 downto 6),32);
											R_d_idx <= IR(15 downto 11);
											
											state <= alu_wb_reg_state;
										when "011000" => -- todo  -- multiplier
											R_a <= registers(CONV_INTEGER(IR(25 downto 21)));
											R_b <= registers(CONV_INTEGER(IR(20 downto 16)));											
											multi_wait_counter <= "00";
											state <= multi_wait_state;
											-- TODO
										when "010000" =>	-- MFHI d
											registers(CONV_INTEGER(IR(15 downto 11))) <= reg_hi;
											state <= prepare_fetch_state;
										when "010001" => -- MTHI d
											reg_hi <= registers(CONV_INTEGER(IR(25 downto 21)));
											state <= prepare_fetch_state;
										when "010010" => -- MFLO d
											registers(CONV_INTEGER(IR(15 downto 11))) <= reg_lo;
											state <= prepare_fetch_state;
										when "010011" => -- MTLO d
											reg_lo <= registers(CONV_INTEGER(IR(25 downto 21)));
											state <= prepare_fetch_state;
										when "001001" => -- JALR
											registers(CONV_INTEGER(IR(15 downto 11))) <= PC;
											PC <= registers(CONV_INTEGER(IR(25 downto 21)));
											state <= prepare_fetch_state;
										when "001000" => -- JR 
											PC <= registers(CONV_INTEGER(IR(25 downto 21)));
											state <= prepare_fetch_state;
										when others =>
											null;
									end case;
								when "1100" | "1101" | "1110" => -- ANDI ORI XORI
									R_a <= registers(CONV_INTEGER(IR(25 downto 21)));
									R_b <= EXT(IR(15 downto 0), 32);
									R_d_idx <= IR(20 downto 16);
									state <= alu_wb_reg_state;
								when "0010" => -- J tar
									PC(27 downto 2) <= IR(25 downto 0); --PC <= PC(31 downto 28) & IR(25 downto 0) & "00";
									state <= prepare_fetch_state;
								when "0011" => -- JAL tar
									registers(31) <= PC;
									PC(27 downto 2) <= IR(25 downto 0);
									state <= prepare_fetch_state;
								when "1001" | "1010" | "1011" => -- ADDIU SLTI SLTIU
									R_a <= registers(CONV_INTEGER(IR(25 downto 21)));
									R_b <= SXT(IR(15 downto 0), 32);
									R_d_idx <= IR(20 downto 16);
									state <= alu_wb_reg_state;
								when "0111" | "0110" => -- BGTZ BLEZ 
									R_a <= registers(CONV_INTEGER(IR(25 downto 21)));
									R_b <= (others => '0');
									state <= branch_gt_le_decide_state;
								when "0001" => -- BGEZ BLTZ
									R_a <= registers(CONV_INTEGER(IR(25 downto 21)));
									R_b <= (others => '0');
									state <= branch_ge_lt_decide_state;
								when "0100" | "0101" => -- BEQ BNE
									R_a <= registers(CONV_INTEGER(IR(25 downto 21)));
									R_b <= (others => '0');
									state <= branch_e_ne_decide_state;
								when others =>
									null;
							end case;
						when "10" => -- memory instructions
							R_a <= registers(CONV_INTEGER(IR(25 downto 21)));
							R_b <= SXT(IR(15 downto 0), 32);
							case IR(27 downto 26) is
								when "11" => -- Word visit
									state <= visit_memory_word_state;
								when "00" => -- Byte visit
									state <= visit_memory_byte_state;
								when others =>
									null;
							end case;
						when others =>
							null;
					end case;
				when multi_wait_state =>
					if multi_wait_counter = "11" then						
						reg_hi <= multi_out(63 downto 32);
						reg_lo <= multi_out(31 downto 0);
						state <= prepare_fetch_state;
					else 
						multi_wait_counter <= multi_wait_counter +1;
					end if;
				when visit_memory_word_state =>
					mem_addr <= alu_out; 
					case IR(29 downto 28) is
						when "00" => -- LW 100011
							mem_rw <= '0';
						when "10" => -- SW
							mem_data_in <= registers(CONV_INTEGER(IR(20 downto 16)));
							mem_rw <= '1';
						when others =>
							null;
					end case;
					mem_en <= '1';
					state <= wait_memory_word_state;
				when visit_memory_byte_state =>
					-- align the addr
					mem_addr <= alu_out(31 downto 2) & "00";
					case IR(29 downto 28) is
						when "00" | "01" => -- LB LBU
							mem_rw <= '0';
						when "10" => -- SB 101000
							mem_rw <= '1';
						when others =>
							null;
					end case;
					mem_en <= '1';
					state <= wait_memory_byte_state;
				when wait_memory_word_state =>
					-- see whether finished
					if mem_done = '1' then
						mem_en <= '0';
						case IR(31 downto 26) is 
							when "100011" => -- lw
								registers(CONV_INTEGER(IR(20 downto 16))) <= mem_data_out;
								state <= prepare_fetch_state;
							when "101011" | "101000" => -- sw sb
								state <= prepare_fetch_state;
							when others =>
								null;								
						end case;
					end if;
				when wait_memory_byte_state =>
					if mem_done = '1' then 
						mem_en <= '0';
						case IR(29 downto 28) is -- 00 lb 01 lbu 10 sb
							when "00" =>  -- lb
								case alu_out(1 downto 0) is
									when "00" =>
										registers(CONV_INTEGER(IR(20 downto 16))) <= SXT(mem_data_out(7 downto 0), 32);
									when "01" =>
										registers(CONV_INTEGER(IR(20 downto 16))) <= SXT(mem_data_out(15 downto 8), 32);
									when "10" =>
										registers(CONV_INTEGER(IR(20 downto 16))) <= SXT(mem_data_out(23 downto 16), 32);
									when "11" =>
										registers(CONV_INTEGER(IR(20 downto 16))) <= SXT(mem_data_out(31 downto 24), 32);
									when others =>
										null;
								end case;
								registers(CONV_INTEGER(IR(20 downto 16))) <= mem_data_out;
								state <= prepare_fetch_state;
							when "01" =>  -- lbu
								case alu_out(1 downto 0) is
									when "00" =>
										registers(CONV_INTEGER(IR(20 downto 16))) <= EXT(mem_data_out(7 downto 0), 32);
									when "01" =>
										registers(CONV_INTEGER(IR(20 downto 16))) <= EXT(mem_data_out(15 downto 8), 32);
									when "10" =>
										registers(CONV_INTEGER(IR(20 downto 16))) <= EXT(mem_data_out(23 downto 16), 32);
									when "11" =>
										registers(CONV_INTEGER(IR(20 downto 16))) <= EXT(mem_data_out(31 downto 24), 32);
									when others =>
										null;
								end case;
								state <= prepare_fetch_state;
							when "10" =>  -- sb
								mem_data_in <= mem_data_out;
								state <= store_memory_byte_state;
							when others =>
								null;
						end case;
					end if;
				when store_memory_byte_state =>
					case alu_out(1 downto 0) is
						when "00" =>
							mem_data_in(7 downto 0) <= registers(CONV_INTEGER(IR(20 downto 16)))(7 downto 0);
						when "01" =>
							mem_data_in(15 downto 8) <= registers(CONV_INTEGER(IR(20 downto 16)))(7 downto 0);
						when "10" =>
							mem_data_in(23 downto 16) <= registers(CONV_INTEGER(IR(20 downto 16)))(7 downto 0);
						when "11" =>
							mem_data_in(31 downto 24) <= registers(CONV_INTEGER(IR(20 downto 16)))(7 downto 0);
						when others =>
							null;
					end case;
					mem_rw <= '1';
					mem_en <= '1';
					state <= wait_memory_word_state;
				when alu_wb_reg_state =>
					registers(CONV_INTEGER(R_d_idx)) <= alu_out;
					state <= prepare_fetch_state;
				when branch_gt_le_decide_state =>
					if (IR(26) = '1' and (alu_sign = '0' and alu_zero = '0')) or (IR(26) = '0' and (alu_sign = '1' or alu_zero = '1')) then 
						PC <= PC + (SXT(IR(15 downto 0), 30) & "00");
					end if;
					state <= prepare_fetch_state;
				when branch_ge_lt_decide_state =>
					if (IR(16) = '1' and (alu_sign = '0' or alu_zero = '1')) or (IR(16) = '0' and (alu_sign ='1' and alu_zero = '0')) then -- BGEZ BLTZ
						PC <= PC + (SXT(IR(15 downto 0), 30) & "00");
					end if;
					state <= prepare_fetch_state;
				when branch_e_ne_decide_state =>
					if (IR(26) = '1' and alu_zero = '0') or (IR(26) = '0' and alu_zero = '1') then -- BNE BEQ
						PC <= PC + (SXT(IR(15 downto 0), 32) & "00");
					end if;
					state <= prepare_fetch_state;
			end case;
		end if;
	end process;
	
	process(std_clk)
	begin
		counter<=counter+1;
	end process;

--   type state_type is (init_state, prepare_fetch_state, fetch_state, decode_state, alu_wb_reg_state, 
--						branch_e_ne_decide_state, branch_ge_lt_decide_state, branch_gt_le_decide_state, 
--						visit_memory_word_state, visit_memory_byte_state, store_memory_byte_state, 
--						wait_memory_word_state, wait_memory_byte_state, multi_wait_state);
	
	process(state)
	begin
		case state is 
			when prepare_fetch_state => 
				seg7_out_2 <= "0110000"; 
			when fetch_state =>
				seg7_out_2 <= "1101101";
			when decode_state =>
				seg7_out_2 <= "1111001";
			when branch_e_ne_decide_state | branch_ge_lt_decide_state | branch_gt_le_decide_state =>
				seg7_out_2 <= "0110011";
			when visit_memory_byte_state | visit_memory_word_state =>
				seg7_out_2 <= "1011011";
			when store_memory_byte_state =>
				seg7_out_2 <= "1011111";
			when wait_memory_byte_state | wait_memory_word_state =>
				seg7_out_2 <= "1110000";
			when multi_wait_state =>
				seg7_out_2 <= "1111111";
			when alu_wb_reg_state =>
				seg7_out_2 <= "1110111";
			when others => 
				seg7_out_2 <= "0000000";
		end case;
	end process;
	
	process(switches)
	begin
		case switches(8 to 9) is 
			when "00" => 
				LED_display_data <= alu_out;
			when "01" =>
				case switches(5 to 6) is
					when "00" =>  --general
						LED_display_data <= registers(CONV_INTEGER(switches(0 to 4)));
					when "01" => --CP0
						null;
					when "10" => --PC/IR
						if switches(0)='1' then
							LED_display_data<=PC;
						else
							LED_display_data <= IR;
						end if;
					when "11" => --HI/LO
						if switches(0)='1' then
							LED_display_data<=reg_hi;
						else
							LED_display_data<=reg_lo;
						end if;							
					when others =>
						null;
--				LED_display_data <= ...
				end case;
--			when "10" =>
--				LED_display_data <= mem_data_out;				
			when others =>
				null;
		end case;
		if switches(7) = '0' then
			LEDS <= LED_display_data(15 downto 0);
		else 
			LEDS <= LED_display_data(31 downto 16);
		end if;
	end process;
end Behavioral;
