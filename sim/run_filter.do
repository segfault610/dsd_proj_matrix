vlib work 
vlog ../src/image_filter.v 
vlog tb_image_filter.v 
vsim -gui work.tb_image_filter 
add wave *
 run 2us
