library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.numeric_std.all;
entity ALU is
    Port ( A,B : in STD_LOGIC_VECTOR(31 downto 0);
			  Code: in STD_LOGIC_VECTOR(5 downto 0);
			  Func: in STD_LOGIC_VECTOR(5 downto 0);
			  R : out STD_LOGIC_VECTOR(31 downto 0);
           Zero : out STD_LOGIC;
			  Sign : out STD_LOGIC);	 
end ALU;
architecture Behavioral of ALU is	
	
	begin	
		PROCESS(Code,Func,A,B)
		variable OP : STD_LOGIC_VECTOR(3 downto 0);
		variable result : STD_LOGIC_VECTOR(31 downto 0);
		begin

		if Code(5 downto 4)="00" then 
			case Code(3 downto 0) is
			when "0000" =>		
				case Func is 
					when "100001" => --add
						OP:= "0000";
					when "101010" => --slt
						OP:= "0010"; 
					when "101011" => --sltu
						OP:= "0011";
					when "100011" => --sub
						OP:= "0001";
					when "100100" => --and
						OP:= "0100";
					when "100111" => --nor
						OP:= "0101";
					when "100101" => --or
						OP:= "0111";
					when "100110" => --xor
						OP:= "0110";
					when "000000" | "000100" => --sll
						OP:= "1000";
					when "000011" | "000111" => --sra
						OP:= "1001";
					when "000010" | "000110" => --srl
						OP:= "1010";
					when others =>
						OP:= "1111";
				end case;					
			when "1001" =>
				OP:="0000";
			when "1010" =>
				OP:="0010";
			when "1011" =>
				OP:="0011";
			when "0100" | "0001" | "0111" | "0110" | "0101"=>
				OP:="0001";
			when "1100" =>
				OP:="0100";
			when "1101" =>
				OP:="0111";
			when "1110" =>
				OP:="0110";
			when others =>
				OP:="1111";						
			end case;
		else
			OP:="0000";
		end if;
		
		case OP is
			when "0000" =>
				result:=A+B;	
			when "0001" =>
				result:=A-B;
			when "0010" => --slt
				if CONV_INTEGER(A)<CONV_INTEGER(B) then
					result:=x"00000001";
				else
					result:=x"00000000";
				end if;
			when "0011" => --sltu
				result:=A-B; --special
				if (A(31)='0' and B(31)='1') or ( A(31)=B(31) and result(31)='1') then
					result:=x"00000001";
				else
					result:=x"00000000";			
				end if;
			when "0100" =>
				result:=A and B;
			when "0101" =>
				result:=A nor B;
			when "0110" =>
				result:=A xor B;
			when "0111" =>
				result:=A or B;					
			when "1000" =>					
				result:=TO_STDLOGICVECTOR(TO_BITVECTOR(A) sll CONV_INTEGER(B));
			when "1001" =>					
				result:=TO_STDLOGICVECTOR(TO_BITVECTOR(A) sra CONV_INTEGER(B));
			when "1010" =>
				result:=TO_STDLOGICVECTOR(TO_BITVECTOR(A) srl CONV_INTEGER(B));
			when others => 
				result := A;
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