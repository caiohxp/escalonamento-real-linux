#!/bin/bash

# Configurações
RESULTS="results"
DURATION=20
mkdir -p $RESULTS

# Garante que temos permissão de execução nos binários
chmod +x cpu_bound io_bound

echo "=== INICIANDO BATERIA DE TESTES (Modo Explícito) ==="

# --- 1. BASELINE (Rodar isolado para referência) ---
echo ">>> [1/4] Rodando Baseline (Isolados)..."
# Aqui rodamos sequencialmente de propósito para pegar o máximo desempenho
taskset -c 0 /usr/bin/time -v ./cpu_bound $DURATION > $RESULTS/cpu_base.out 2> $RESULTS/cpu_base.time
taskset -c 0 /usr/bin/time -v ./io_bound $DURATION > $RESULTS/io_base.out 2> $RESULTS/io_base.time


# --- 2. COMPETIÇÃO NICE (High vs Low) ---
echo ">>> [2/4] Rodando Competição NICE (High vs Low)..."
# O '&' no final da linha joga para background. O 'wait' espera ambos.
taskset -c 0 /usr/bin/time -v nice -n -15 ./cpu_bound $DURATION > $RESULTS/cpu_nice_high.out 2> $RESULTS/cpu_nice_high.time &
PID1=$!
taskset -c 0 /usr/bin/time -v nice -n 15 ./cpu_bound $DURATION > $RESULTS/cpu_nice_low.out 2> $RESULTS/cpu_nice_low.time &
PID2=$!
wait $PID1 $PID2


# --- 3. REAL-TIME vs FIFO ---
echo ">>> [3/4] Rodando Real-Time (RR) vs FIFO..."
taskset -c 0 /usr/bin/time -v chrt -r 50 ./cpu_bound $DURATION > $RESULTS/cpu_rr.out 2> $RESULTS/cpu_rr.time &
PID3=$!
taskset -c 0 /usr/bin/time -v chrt -f 50 ./cpu_bound $DURATION > $RESULTS/cpu_fifo.out 2> $RESULTS/cpu_fifo.time &
PID4=$!
wait $PID3 $PID4


# --- 4. CPU vs IO ---
echo ">>> [4/4] Rodando CPU vs IO..."
taskset -c 0 /usr/bin/time -v nice -n -10 ./cpu_bound $DURATION > $RESULTS/cpu_vs_io_cpu.out 2> $RESULTS/cpu_vs_io_cpu.time &
PID5=$!
taskset -c 0 /usr/bin/time -v nice -n 5 ./io_bound $DURATION > $RESULTS/cpu_vs_io_io.out 2> $RESULTS/cpu_vs_io_io.time &
PID6=$!
wait $PID5 $PID6

echo "=== FIM DOS TESTES. Verifique a pasta $RESULTS ==="