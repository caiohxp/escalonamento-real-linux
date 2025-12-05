#!/bin/bash

# Configurações
RESULTS="results"
DURATION=20
mkdir -p $RESULTS

# Garante permissões
chmod +x cpu_bound io_bound

echo "=== INICIANDO BATERIA DE TESTES (Estratégia de Afinidade Pai) ==="

# Função para rodar competição forçada no Core 0
run_competition() {
    NAME=$1
    CMD1=$2
    OUT1=$3
    CMD2=$4
    OUT2=$5
    
    echo ">>> Rodando: $NAME..."
    
    # TRUQUE: Usamos 'taskset -c 0 sh -c ...' para criar um ambiente onde 
    # TUDO o que roda lá dentro é obrigado a ficar no Core 0.
    taskset -c 0 sh -c "
        /usr/bin/time -v $CMD1 > $RESULTS/$OUT1.out 2> $RESULTS/$OUT1.time &
        /usr/bin/time -v $CMD2 > $RESULTS/$OUT2.out 2> $RESULTS/$OUT2.time &
        wait
    "
    echo "   Concluído."
}

# 1. BASELINE (Rodar isolado)
echo ">>> [1/4] Baseline..."
# Rodamos um de cada vez
taskset -c 0 /usr/bin/time -v ./cpu_bound $DURATION > $RESULTS/cpu_base.out 2> $RESULTS/cpu_base.time
taskset -c 0 /usr/bin/time -v ./io_bound $DURATION > $RESULTS/io_base.out 2> $RESULTS/io_base.time

# 2. COMPETIÇÃO NICE
# Note que tiramos o 'taskset' de dentro dos comandos, pois o pai já segura o Core 0
run_competition "Nice High vs Low" \
    "nice -n -15 ./cpu_bound $DURATION" "cpu_nice_high" \
    "nice -n 15 ./cpu_bound $DURATION" "cpu_nice_low"

# 3. REAL-TIME
run_competition "Real-Time (RR) vs FIFO" \
    "chrt -r 50 ./cpu_bound $DURATION" "cpu_rr" \
    "chrt -f 50 ./cpu_bound $DURATION" "cpu_fifo"

# 4. CPU vs IO
run_competition "CPU vs IO" \
    "nice -n -10 ./cpu_bound $DURATION" "cpu_vs_io_cpu" \
    "nice -n 5 ./io_bound $DURATION" "cpu_vs_io_io"

echo "=== FIM DOS TESTES ==="