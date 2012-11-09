
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

create_project -name MIPS -dir "E:/Course/Junior1/CO/Final/Project/MIPS/planAhead_run_1" -part xc3s1200efg320-4
set_param project.pinAheadLayout yes
set srcset [get_property srcset [current_run -impl]]
set_property top Controller $srcset
set_param project.paUcfFile  "Controller.ucf"
set hdlfile [add_files [list {Mem.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ALU.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {Controller.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
add_files "Controller.ucf" -fileset [get_property constrset [current_run]]
open_rtl_design -part xc3s1200efg320-4
