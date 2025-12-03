#!/bin/bash

# Configurações
RESULTS="results"
DURATION=20
mkdir -p $RESULTS

echo "=== INICIANDO BATERIA DE TESTES (Paralelismo Forçado) ==="

# Função auxiliar para rodar pares de processos
run_pair() {
    NAME=$1
    CMD1=$2
    OUT1=$3
    CMD2=$4
    OUT2=$5
    
    echo ">>> Rodando Cenário: $NAME..."
    
    # Lança o primeiro processo em background
    $CMD1 > $RESULTS/$OUT1.out 2> $RESULTS/$OUT1.time &
    PID1=$!
    
    # Lança o segundo processo em background IMEDIATAMENTE
    $CMD2 > $RESULTS/$OUT2.out 2> $RESULTS/$OUT2.time &
    PID2=$!
    
    # Espera ambos terminarem
    wait $PID1 $PID2
    echo "   Concluído."
}

# 1. BASELINE (Rodar isolado para referência)
echo ">>> Rodando Baseline (Isolados)..."
taskset -c 0 ./cpu_bound $DURATION > $RESULTS/cpu_base.out 2> $RESULTS/cpu_base.time
taskset -c 0 ./io_bound $DURATION > $RESULTS/io_base.out 2> $RESULTS/io_base.time

# 2. COMPETIÇÃO NICE (High vs Low)
# Aqui a mágica acontece: ambos brigam pelo Core 0
run_pair "Nice High vs Low" \
    "taskset -c 0 nice -n -15 ./cpu_bound $DURATION" "cpu_nice_high_c0" \
    "taskset -c 0 nice -n 15 ./cpu_bound $DURATION" "cpu_nice_low_c0"

# 3. REAL-TIME vs FIFO
# O processo RT deve ganhar quase tudo
run_pair "Real-Time (RR) vs FIFO" \
    "taskset -c 0 chrt -r 50 ./cpu_bound $DURATION" "cpu_rr_c0" \
    "taskset -c 0 chrt -f 50 ./cpu_bound $DURATION" "cpu_fifo_c0"

# 4. CPU vs IO
run_pair "CPU vs IO" \
    "taskset -c 0 nice -n -10 ./cpu_bound $DURATION" "cpu_high_vs_io_low_cpu" \
    "taskset -c 0 nice -n 5 ./io_bound $DURATION" "cpu_high_vs_io_low_io"

echo "=== FIM DOS TESTES ==="