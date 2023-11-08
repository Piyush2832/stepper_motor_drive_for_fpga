
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name spi_using_3_axis_test -dir "D:/PIyuSH/4 - axis drive/spi_using_3_axis_test/planAhead_run_1" -part xc6slx9tqg144-2
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "D:/PIyuSH/4 - axis drive/spi_using_3_axis_test/SPI_Slave.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {D:/PIyuSH/4 - axis drive/spi_using_3_axis_test} }
set_property target_constrs_file "spi_96_bits_catn.ucf" [current_fileset -constrset]
add_files [list {spi_96_bits_catn.ucf}] -fileset [get_property constrset [current_run]]
link_design
