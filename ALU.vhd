library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity ALU is
    Port ( A,B : in STD_LOGIC_VECTOR(31 downto 0);           
			  OP	: in STD_LOGIC_VECTOR(3 downto 0);
			  ALU_OUT : out STD_LOGIC_VECTOR(31 downto 0);
           ALU_ZERO : out STD_LOGIC);	 
end ALU;
architecture Behavioral of ALU is
	signal result : STD_LOGIC_VECTOR(31 downto 0);
begin
	case OP is
	when "0000" =>
		result<=A+B;	
	when "0001" =>
		result<=A-B;
	when "0100" =>
		result<=A and B;
	when "0101" =>
		result<=A nor B;
	when "0110" =>
		result<=A or B;
	when "0111" =>
		result<=not A;					
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
		ALU_ZERO<='1';
	else
		ALU_ZERO<='0';
	end if;
	ALU_OUT <= result;
end Behavioral;