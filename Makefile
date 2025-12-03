CC = gcc
CFLAGS = -O2 -Wall
RESULTS = results
DURATION = 20

all: cpu_bound io_bound

cpu_bound: cpu_bound.c
	$(CC) $(CFLAGS) cpu_bound.c -o cpu_bound

io_bound: io_bound.c
	$(CC) $(CFLAGS) io_bound.c -o io_bound

prepare:
	mkdir -p $(RESULTS)

# Regra principal para rodar tudo
run_all: prepare baseline nice_compare chrt_compare cpu_vs_io

baseline:
	@echo "--- 1. Baseline (Isolado) ---"
	taskset -c 0 ./cpu_bound $(DURATION) > $(RESULTS)/cpu_base.out 2> $(RESULTS)/cpu_base.time
	taskset -c 0 ./io_bound $(DURATION) > $(RESULTS)/io_base.out 2> $(RESULTS)/io_base.time

nice_compare:
	@echo "--- 2. Competição NICE (High vs Low) ---"
	# Iniciando simultaneamente com taskset no Core 0
	# O '&' coloca em background para rodarem juntos
	taskset -c 0 nice -n -15 ./cpu_bound $(DURATION) > $(RESULTS)/cpu_nice_high_c0.out 2> $(RESULTS)/cpu_nice_high_c0.time & \
	taskset -c 0 nice -n 15 ./cpu_bound $(DURATION) > $(RESULTS)/cpu_nice_low_c0.out 2> $(RESULTS)/cpu_nice_low_c0.time & \
	wait

chrt_compare:
	@echo "--- 3. Real-Time (RR) vs FIFO ---"
	taskset -c 0 chrt -r 50 ./cpu_bound $(DURATION) > $(RESULTS)/cpu_rr_c0.out 2> $(RESULTS)/cpu_rr_c0.time & \
	taskset -c 0 chrt -f 50 ./cpu_bound $(DURATION) > $(RESULTS)/cpu_fifo_c0.out 2> $(RESULTS)/cpu_fifo_c0.time & \
	wait

cpu_vs_io:
	@echo "--- 4. CPU vs IO ---"
	taskset -c 0 nice -n -10 ./cpu_bound $(DURATION) > $(RESULTS)/cpu_high_vs_io_low_cpu.out 2> $(RESULTS)/cpu_high_vs_io_low_cpu.time & \
	taskset -c 0 nice -n 5 ./io_bound $(DURATION) > $(RESULTS)/cpu_high_vs_io_low_io.out 2> $(RESULTS)/cpu_high_vs_io_low_io.time & \
	wait

clean:
	rm -rf $(RESULTS) cpu_bound io_bound