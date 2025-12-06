#!/bin/bash

# Configurações
RESULTS="results"
DURATION=20
mkdir -p $RESULTS

# Garante permissões
chmod +x cpu_bound io_bound

echo "=== INICIANDO BATERIA DE TESTES AVANÇADA (NÍVEL HARD) ==="

# --- CENÁRIOS BÁSICOS (MANTIDOS) ---
echo ">>> [1/7] Baseline (Isolados)..."
taskset -c 0 /usr/bin/time -v ./cpu_bound $DURATION > $RESULTS/base_cpu.out 2> $RESULTS/base_cpu.time
taskset -c 0 /usr/bin/time -v ./io_bound $DURATION > $RESULTS/base_io.out 2> $RESULTS/base_io.time

echo ">>> [2/7] Competição Simples (Nice -15 vs 15)..."
taskset -c 0 /usr/bin/time -v nice -n -15 ./cpu_bound $DURATION > $RESULTS/nice_high.out 2> $RESULTS/nice_high.time &
pid1=$!
taskset -c 0 /usr/bin/time -v nice -n 15 ./cpu_bound $DURATION > $RESULTS/nice_low.out 2> $RESULTS/nice_low.time &
pid2=$!
wait $pid1 $pid2

echo ">>> [3/7] Real-Time (RR vs FIFO)..."
taskset -c 0 /usr/bin/time -v chrt -r 50 ./cpu_bound $DURATION > $RESULTS/rt_rr.out 2> $RESULTS/rt_rr.time &
pid3=$!
taskset -c 0 /usr/bin/time -v chrt -f 50 ./cpu_bound $DURATION > $RESULTS/rt_fifo.out 2> $RESULTS/rt_fifo.time &
pid4=$!
wait $pid3 $pid4

echo ">>> [4/7] CPU vs IO (1v1)..."
taskset -c 0 /usr/bin/time -v nice -n -10 ./cpu_bound $DURATION > $RESULTS/mix_1v1_cpu.out 2> $RESULTS/mix_1v1_cpu.time &
pid5=$!
taskset -c 0 /usr/bin/time -v nice -n 5 ./io_bound $DURATION > $RESULTS/mix_1v1_io.out 2> $RESULTS/mix_1v1_io.time &
pid6=$!
wait $pid5 $pid6

# --- NOVOS CENÁRIOS AVANÇADOS ---

echo ">>> [5/7] Proporcionalidade (Nice 0 vs 10 vs 19)..."
# Testa se a CPU divide conforme os pesos: 1024 vs 110 vs 15
taskset -c 0 /usr/bin/time -v nice -n 0 ./cpu_bound $DURATION > $RESULTS/prop_n0.out 2> $RESULTS/prop_n0.time &
pA=$!
taskset -c 0 /usr/bin/time -v nice -n 10 ./cpu_bound $DURATION > $RESULTS/prop_n10.out 2> $RESULTS/prop_n10.time &
pB=$!
taskset -c 0 /usr/bin/time -v nice -n 19 ./cpu_bound $DURATION > $RESULTS/prop_n19.out 2> $RESULTS/prop_n19.time &
pC=$!
wait $pA $pB $pC

echo ">>> [6/7] Stress Test (5 CPU Bounds idênticos)..."
# Testa a capacidade de manter 20% para cada um sem perdas
for i in {1..5}; do
    taskset -c 0 /usr/bin/time -v ./cpu_bound $DURATION > $RESULTS/stress_$i.out 2> $RESULTS/stress_$i.time &
    pids[$i]=$!
done
wait ${pids[*]}

echo ">>> [7/7] Tempestade de I/O (1 CPU vs 4 I/O)..."
# Testa se o CPU bound consegue rodar no meio de muitas interrupções
taskset -c 0 /usr/bin/time -v ./cpu_bound $DURATION > $RESULTS/storm_cpu.out 2> $RESULTS/storm_cpu.time &
s1=$!
for i in {1..4}; do
    taskset -c 0 /usr/bin/time -v ./io_bound $DURATION > $RESULTS/storm_io_$i.out 2> $RESULTS/storm_io_$i.time &
    spids[$i]=$!
done
wait $s1 ${spids[*]}

echo "=== FIM DOS TESTES AVANÇADOS ==="