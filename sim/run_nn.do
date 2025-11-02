vlib work 
vlog ../src/neural_layer.v 
vlog tb_neural_layer.v 
vsim -gui work.tb_neural_layer 
add wave *
 run 1us 
