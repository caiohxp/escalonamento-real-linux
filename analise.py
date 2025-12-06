import os
import re
import pandas as pd

# Diretório onde estão os arquivos
DIR_RESULTS = "results"
OUTPUT_CSV = "dados_finais_validos.csv"

# Mapeamento: Nome do arquivo -> (Cenário, Tipo de Processo)
FILES_MAP = {
    'cpu_base.out':       ('Baseline', 'Isolado'),
    'cpu_nice_high.out':  ('Prioridade (Nice)', 'Alta Prio (-15)'),
    'cpu_nice_low.out':   ('Prioridade (Nice)', 'Baixa Prio (15)'),
    'cpu_fifo.out':       ('Real-Time', 'FIFO'),
    'cpu_rr.out':         ('Real-Time', 'Round Robin'),
    'cpu_vs_io_cpu.out':  ('CPU vs IO', 'Processo CPU'),
    'cpu_vs_io_io.out':   ('CPU vs IO', 'Processo IO')
}

def ler_metricas(filepath):
    """Extrai primes_found ou io_ops e o tempo de CPU"""
    dados = {'valor': 0, 'cpu_user': 0.0}
    
    # 1. Ler valor de produção (primos ou io_ops) do .out
    if os.path.exists(filepath):
        with open(filepath, 'r') as f:
            content = f.read()
            match = re.search(r'(primes_found|io_ops)=(\d+)', content)
            if match:
                dados['valor'] = int(match.group(2))

    # 2. Ler tempo de uso do .time (arquivo de mesmo nome com extensão trocada)
    path_time = filepath.replace('.out', '.time')
    if os.path.exists(path_time):
        with open(path_time, 'r') as f:
            content = f.read()
            # Tenta pegar "User time" ou "Percent of CPU"
            match_cpu = re.search(r'User time \(seconds\): ([\d\.]+)', content)
            if match_cpu:
                dados['cpu_user'] = float(match_cpu.group(1))
            
            # Pega percentual para validar
            match_pct = re.search(r'Percent of CPU this job got: (\d+)%', content)
            if match_pct:
                dados['cpu_percent'] = int(match_pct.group(1))
                
    return dados

def main():
    registros = []
    print(f"Lendo arquivos em '{DIR_RESULTS}'...")

    for filename, (cenario, tipo) in FILES_MAP.items():
        path = os.path.join(DIR_RESULTS, filename)
        infos = ler_metricas(path)
        
        # Se não achou o arquivo, avisa
        if infos['valor'] == 0 and infos['cpu_user'] == 0:
            print(f"⚠️ Aviso: Arquivo {filename} vazio ou ausente.")
            continue

        registros.append({
            'Cenario': cenario,
            'Processo': tipo,
            'Producao': infos['valor'],
            'Tempo_User': infos.get('cpu_user', 0),
            'CPU_Percent': infos.get('cpu_percent', 0)
        })

    df = pd.DataFrame(registros)
    df.to_csv(OUTPUT_CSV, index=False)
    print("\n✅ Sucesso! Tabela salva em:", OUTPUT_CSV)
    print(df[['Cenario', 'Processo', 'Producao', 'CPU_Percent']])

if __name__ == "__main__":
    main()