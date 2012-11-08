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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Controller is
end Controller;

architecture Behavioral of Controller is
  type state_type is (init_state, prepare_fetch_state, fetch_state, decode_state, alu_wb_reg_state, wb_reg_state,  
						branch_e_ne_decide_state, branch_ge_lt_decide_state, branch_gt_le_decide_state);
	signal state: state_type;
	
-- PC registers
	signal PC: std_logic_vector(31 downto 0);


-- Registers
	signal IR: std_logic_vector(31 downto 0); -- instruction register
	signal R_a: std_logic_vector(31 downto 0);
	signal R_b: std_logic_vector(31 downto 0);
	signal R_d_idx: std_logic_vector(4 downto 0);
	signal reg_hi: std_logic_vector(31 downto 0);
	signal reg_lo: std_logic_vector(31 downto 0);

-- Register File
	type reg_file is array (0 to 31) of std_logic_vector(31 downto 0);
	signal registers: reg_file;

-- Addr Registers
	signal mem_addr: std_logic_vector(31 downto 0);
	signal mem_data: std_logic_vector(31 downto 0);
	signal mem_op: std_logic;
	signal mem_done: std_logic;
	
-- ALU Results
	signal alu_out: std_logic_vector(31 downto 0);
	signal alu_sign: std_logic;
	signal alu_zero: std_logic;

--	Component Mem is
--	PORT(
--			Addr	:IN STD_LOGIC_VECTOR(31 downto 0);
--			DataIn	:IN STD_LOGIC_VECTOR(31 downto 0);
--			DataOut	:OUT STD_LOGIC_VECTOR(31 downto 0);
--			MemRd,MemWr:STD_LOGIC;
--			Done: OUT STD_LOGIC;
--			--TLB:TODO
--			clk,rst:IN STD_LOGIC;
--
--			--1ü??￡??￥2?òyè?
--			Ram1_addr,Ram2_addr:OUT STD_LOGIC_VECTOR(17 downto 0);
--			Ram1_data,Ram2_data:INOUT STD_LOGIC_VECTOR(15 downto 0);
--			Ram1_en,Ram1_oe,Ram1_rw:OUT STD_LOGIC;
--			Ram2_en,Ram2_oe,Ram2_rw:OUT STD_LOGIC;
--
--			Data_ready,Tbre,Tsre:IN STD_LOGIC;
--			Rdn,Rst,Rxd,Wrn:OUT STD_LOGIC;
--
--			Flash_addr:OUT STD_LOGIC_VECTOR(22 downto 0);
--			Flash_data:INOUT STD_LOGIC_VECTOR(15 downto 0);
--			Flash_byte,Flash_ce,Flash_ce1,Flash_ce2,
--			Flash_oe,Flash_rp,Flash_sts,Flash_vpen,Flash_we:OUT STD_LOGIC
--		);
--	end Component Mem;

	Component ALU is
		 Port ( A,B : in STD_LOGIC_VECTOR(31 downto 0);
				  Code: in STD_LOGIC_VECTOR(3 downto 0);
				  Func: in STD_LOGIC_VECTOR(5 downto 0);
				  R : out STD_LOGIC_VECTOR(31 downto 0);
				  Zero : out STD_LOGIC;
				  Sign : out STD_LOGIC);	
	end Component ALU;

begin
	-- to implement
	--MemUnit: Mem()
	alu_unit: ALU port map(R_a, R_b, IR(29 downto 26), IR(5 downto 0), alu_out, alu_zero, alu_sign);

	process (reset, clk)
	
	begin
		if reset = '0' then
			state <= init_state;
		elsif clk'event and clk='1' then
			case state is 
				when init_state =>
					-- do something initialization
					PC <= (others=>'0');
					state <= prepare_fetch_state;
				when prepare_fetch_state =>
					-- prepare for addr and data and memread and memwrite
					
				when fetch => 
					memRead <= 1;
					memWrite <= 0;
				-- todo
				-- get instruction from memory
				-- IR <= memory(PC);
					PC <= PC + 4;
					
					state <= decode_state;
				when decode_state =>
					case IR(31 downto 26) is
						when "000000" => -- special
							case IR(5 downto 0) is 
								-- ADDU SLT SLTU SUBU AND OR SLLV SRAV SRL SRLV XOR NOR
								when "100001" | "101010" | "101011" | "100011" | "100100" | "100101" | "000100" | "000111" | "000010" | "000110" | "100110" | "100111" => -- 33 42 43 35 36 37 4 7 2 6 38 39, (s t d)
									R_a <= registers(IR(25 downto 21));
									R_b <= registers(IR(20 downto 16));
									R_d_idx <= IR(15 downto 11);
									state <= alu_wb_reg_state;
								when "000000" | "000011" => -- SLL SRA
									R_a <= registers(IR(20 downto 16));
									R_b <= IR(10 downto 6);
									R_d_idx <= IR(15 downto 11);
									
									state <= alu_wb_reg_state;								
								when "010000" =>	-- MFHI d
									registers(IR(15 downto 11)) <= reg_hi;
									state <= prepare_fetch_state;
								when "010001" => -- MTHI d
									reg_hi <= registers(IR(25 downto 21));
									state <= prepare_fetch_state;
								when "010010" => -- MFLO d
									registers(IR(15 downto 11)) <= reg_lo;
									state <= prepare_fetch_state;
								when "010011" => -- MTLO d
									reg_lo <= registers(IR(25 downto 21));
									state <= prepare_fetch_state;
								when "001001" => -- JALR
									registers(IR(15 downto 11)) <= PC;
									PC <= registers(IR(25 downto 21));
									state <= prepare_fetch_state;
								when "001000" => -- JR 
									PC <= registers(IR(25 downto 21));
									state <= prepare_fetch_state;
							end case;
						when "001100" | "001101" | "001110" => -- ANDI ORI XORI
							R_a <= registers(IR(25 downto 21));
							R_b <= IR(15 downto 0);
							R_d_idx <= IR(20 downto 16);
							state <= alu_wb_reg_state;
						when "000010" => -- J tar
							PC(27 downto 2) <= IR(25 downto 0); --PC <= PC(31 downto 28) & IR(25 downto 0) & "00";
							state <= prepare_fetch_state;
						when "000011" => -- JAL tar
							reg_file(31) <= PC;
							PC(27 downto 2) <= IR(25 downto 0);
							state <= prepare_fetch_state;
						when "001001" | "001010" | "001011" => -- ADDIU SLTI SLTIU
							R_a <= registers(IR(25 downto 21));
							R_b <= SXT(IR(15 downto 0), 32);
							R_d_idx <= IR(20 downto 16);
							state <= alu_wb_reg_state;
						when "000111" | "000110" => -- BGTZ BLEZ 
							R_a <= registers(IR(25 downto 21));
							R_b <= (others => '0');
							state <= branch_gt_le_decide_state;
						when "000001" => -- BGEZ BLTZ
							R_a <= registers(IR(25 downto 21));
							R_b <= (others => '0');
							state <= branch_ge_lt_decide_state;
						when "000100" | "000101" => -- BEQ BNE
							R_a <= registers(IR(25 downto 21));
							R_b <= (others => '0');
							state <= branch_e_ne_decide_state;
					end case;
				when alu_wb_reg_state =>
					Registers(R_d_idx) <= alu_out;
					state <= wb_reg_state;
				when wb_reg_state =>
					registers(R_d_idx) <= alu_out;
					state <= prepare_fetch_state;
				when branch_gt_le_decide_state =>
					if (IR(26) = '1' and (alu_sign = '0' and alu_zero = '0')) or (IR(26) = '0' and (alu_sign = '1' or alu_zero = '1')) then 
						PC <= PC + (SXT(IR(15 downto 0), 32) sll 2);
					end if;
					state <= prepare_fetch_state;
				when branch_ge_lt_decide_state =>
					if (IR(16) = '1' and (alu_sign = '0' or alu_zero = '1')) or (IR(16) = '0' and (alu_sign ='1' and alu_zero = '0')) then -- BGEZ BLTZ
						PC <= PC + (SXT(IR(15 downto 0), 32) sll 2);
					end if;
					state <= prepare_fetch_state;
				when branch_e_ne_decide_state =>
					if (IR(26) = '1' and alu_zero = '0') or (IR(26) = '0' and alu_zero = '1') then -- BNE BEQ
						PC <= PC + (SXT(IR(15 downto 0), 32) sll 2);
					end if;
					state <= prepare_fetch_state;
			end case;
		end if;
	end process;
end Behavioral;