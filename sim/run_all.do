vlib work 
vlog ../src/matrix_mult_core.v 
vlog ../src/neural_layer.v 
vlog ../src/image_filter.v 
vlog ../src/matrix_transform.v 
vlog ../src/matrix_accelerator_top.v 
vlog tb_system.v 
vsim -gui work.tb_system 
add wave -noupdate /tb_system/* 
run 2us
