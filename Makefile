CC = gcc
CFLAGS = -O2 -Wall

all: cpu_bound io_bound

cpu_bound: cpu_bound.c
	$(CC) $(CFLAGS) cpu_bound.c -o cpu_bound

io_bound: io_bound.c
	$(CC) $(CFLAGS) io_bound.c -o io_bound

clean:
	rm -rf results cpu_bound io_bound

# Agora o make apenas chama o script bash
run_all: all
	chmod +x run_tests.sh
	sudo ./run_tests.sh