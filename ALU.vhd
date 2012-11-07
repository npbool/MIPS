library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity ALU is
    Port ( A,B : in STD_LOGIC_VECTOR(31 downto 0);
			  Code: in STD_LOGIC_VECTOR(3 downto 0);
			  Func: in STD_LOGIC_VECTOR(5 downto 0);
			  R : out STD_LOGIC_VECTOR(31 downto 0);
           Zero : out STD_LOGIC;
			  Sign : out STD_LOGIC);	 
end ALU;
architecture Behavioral of ALU is
	signal OP : STD_LOGIC_VECTOR(3 downto 0);
	signal result : STD_LOGIC_VECTOR(31 downto 0);
begin	
	PROCESS(Code,Func,A,B)
	begin
	
	case Code is
	when "0000" =>		
		with Func select
			OP <= "0000" when 33, --add
					"0010" when 42, --slt
					"0011" when 43, --sltu
					"0001" when 35, --sub
					"0100" when 36, --and
					"0101" when 39, --nor
					"0111" when 37, --or
					"0110" when 38, --xor
					"1000" when 0 | 4, --sll
					"1001" when 3 | 7, --sra
					"1010" when 2 | 6, --srl
					"1111" when others;
					
	when "1001" =>
		OP<="0000";
	when "1010" =>
		OP<="0010";
	when "1011" =>
		OP<="0011";
	when "0100" | "0001" | "0111" | "0110" | "0001" | "0101"=>
		OP<="0001";
	when "1100" =>
		OP<="0100";
	when "1101" =>
		OP<="0111";
	when "1110" =>
		OP<="0110";
	when others =>
		OP<="1111";						
	end case;
	
	
	case OP is
	when "0000" =>
		result<=A+B;	
	when "0001" =>
		result<=A-B;
	when "0010" => --slt
		if CONV_INTEGER(A)<CONV_INTEGER(B) then
			result<=1;
		else
			result<=0;
		end if;
	when "0011" => --sltu
		if CONV_UNSIGNED(A)<CONV_UNSIGNED(B) then
			result<=1;
		else
			result<=0;
		end if;
	when "0100" =>
		result<=A and B;
	when "0101" =>
		result<=A nor B;
	when "0110" =>
		result<=A xor B;
	when "0111" =>
		result<=A or B;					
	when "1000" =>					
		result<=TO_STDLOGICVECTOR(TO_BITVECTOR(A) sll CONV_INTEGER(B));
	when "1001" =>					
		result<=TO_STDLOGICVECTOR(TO_BITVECTOR(A) sra CONV_INTEGER(B));
	when "1010" =>
		result<=TO_STDLOGICVECTOR(TO_BITVECTOR(A) srl CONV_INTEGER(B));
	when others => 
		result <= A;
	end case;
	if(result=0) then
		Zero<='1';
	else
		Zero<='0';
	end if;
	Sign<=result(31);
	R <= result;
	
	end PROCESS;
end Behavioral;