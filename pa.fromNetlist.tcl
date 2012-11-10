
# PlanAhead Launch Script for Post-Synthesis pin planning, created by Project Navigator

create_project -name MIPS -dir "E:/Course/Junior1/CO/Final/Project/MIPS/planAhead_run_1" -part xc3s1200efg320-4
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "E:/Course/Junior1/CO/Final/Project/MIPS/Controller.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {E:/Course/Junior1/CO/Final/Project/MIPS} {ipcore_dir} }
add_files "ipcore_dir/bl_rom.ncf" "ipcore_dir/multiplier.ncf" "ipcore_dir/pro_rom.ncf" -fileset [get_property constrset [current_run]]
set_param project.pinAheadLayout  yes
set_param project.paUcfFile  "Controller.ucf"
add_files "Controller.ucf" -fileset [get_property constrset [current_run]]
open_netlist_design
