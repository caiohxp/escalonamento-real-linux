CC=gcc
CFLAGS=-O2 -Wall
RESULTS=results

all: cpu_bound io_bound

cpu_bound: cpu_bound.c
	$(CC) $(CFLAGS) cpu_bound.c -o cpu_bound

io_bound: io_bound.c
	$(CC) $(CFLAGS) io_bound.c -o io_bound

prepare:
	mkdir -p $(RESULTS)

#########################################
# BASELINES — sem afinidade (comportamento natural)
#########################################

baseline: prepare
	/usr/bin/time -v ./cpu_bound 20 \
		> $(RESULTS)/cpu_base.out \
		2> $(RESULTS)/cpu_base.time

	/usr/bin/time -v ./io_bound 20 \
		> $(RESULTS)/io_base.out \
		2> $(RESULTS)/io_base.time


#########################################
# NICE — testes comparativos (mesmo núcleo)
#########################################

nice_compare: prepare
	# CPU-bound high priority
	sudo sh -c "/usr/bin/time -v taskset -c 0 nice -n -10 ./cpu_bound 20" \
		> $(RESULTS)/cpu_nice_high_c0.out \
		2> $(RESULTS)/cpu_nice_high_c0.time &

	# CPU-bound low priority
	/usr/bin/time -v taskset -c 0 nice -n 10 ./cpu_bound 20 \
		> $(RESULTS)/cpu_nice_low_c0.out \
		2> $(RESULTS)/cpu_nice_low_c0.time &

	wait


#########################################
# CPU-bound vs IO-bound (mesmo núcleo)
#########################################

cpu_vs_io: prepare
	sudo sh -c "/usr/bin/time -v taskset -c 0 nice -n -10 ./cpu_bound 20" \
		> $(RESULTS)/cpu_high_vs_io_low_cpu.out \
		2> $(RESULTS)/cpu_high_vs_io_low_cpu.time &

	/usr/bin/time -v taskset -c 0 nice -n 5 ./io_bound 20 \
		> $(RESULTS)/cpu_high_vs_io_low_io.out \
		2> $(RESULTS)/cpu_high_vs_io_low_io.time &

	wait


#########################################
# CHRT — real-time scheduling (mesmo núcleo)
#########################################

chrt_compare: prepare
	sudo sh -c "/usr/bin/time -v taskset -c 0 chrt -r 50 ./cpu_bound 20" \
		> $(RESULTS)/cpu_rr_c0.out \
		2> $(RESULTS)/cpu_rr_c0.time &

	sudo sh -c "/usr/bin/time -v taskset -c 0 chrt -f 50 ./cpu_bound 20" \
		> $(RESULTS)/cpu_fifo_c0.out \
		2> $(RESULTS)/cpu_fifo_c0.time &

	wait

#########################################
# Limpar
#########################################

clean:
	rm -rf $(RESULTS) cpu_bound io_bound
