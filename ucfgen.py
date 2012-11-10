# std_clk, reset: in std_logic;
# rom_switch: in std_logic;	-- the most right switch
# ram1_addr,ram2_addr:OUT STD_LOGIC_VECTOR(17 downto 0);
# ram1_data,ram2_data:INOUT STD_LOGIC_VECTOR(15 downto 0);
# ram1_en,ram1_oe,ram1_rw:OUT STD_LOGIC;
# ram2_en,ram2_oe,ram2_rw:OUT STD_LOGIC;
# data_ready,tbre,tsre:IN STD_LOGIC;
# rdn,wrn:OUT STD_LOGIC;
# flash_addr:OUT STD_LOGIC_VECTOR(22 downto 0);
# flash_data:INOUT STD_LOGIC_VECTOR(15 downto 0);
# flash_byte,flash_ce,flash_ce1,flash_ce2,flash_oe,flash_rp,flash_sts,flash_vpen,flash_we:OUT STD_LOGIC


# NET "Y[1]" LOC = E10;
def print_ucf(net, port):
	outfile.write('NET \"%s\" LOC = %s;\n' %(net, port));

file = open('raw_ucf.txt', 'r');
outfile = open('Controller.ucf', 'w');
outfile.write('\n' + r'#Python Generated Constraints' + '\n\n');

lines = file.readlines();
for line in lines:
	line = line.split();
	print_ucf(line[0], line[1]);

outfile.write('\n');
