vlib work 
vlog ../src/matrix_transform.v 
vlog tb_matrix_transform.v 
vsim -gui work.tb_matrix_transform 
add wave *
 run 2us
