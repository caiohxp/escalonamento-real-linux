import os
import re
import pandas as pd

DIR_RESULTS = "results"
OUTPUT_CSV = "dados_avancados.csv"

# Mapeia arquivos para categorias. Usamos regex para capturar os grupos.
# (Cenário, Tipo)
def classificar_arquivo(filename):
    if 'base_cpu' in filename: return 'Baseline', 'CPU Isolado'
    if 'base_io' in filename:  return 'Baseline', 'IO Isolado'
    
    if 'nice_high' in filename: return 'Competição (Nice)', 'Alta Prio (-15)'
    if 'nice_low' in filename:  return 'Competição (Nice)', 'Baixa Prio (15)'
    
    if 'rt_rr' in filename:   return 'Real-Time', 'Round Robin'
    if 'rt_fifo' in filename: return 'Real-Time', 'FIFO'
    
    if 'mix_1v1_cpu' in filename: return 'CPU vs IO (1v1)', 'CPU'
    if 'mix_1v1_io' in filename:  return 'CPU vs IO (1v1)', 'IO'
    
    if 'prop_n0' in filename:  return 'Proporcionalidade', 'Nice 0 (Base)'
    if 'prop_n10' in filename: return 'Proporcionalidade', 'Nice 10 (Médio)'
    if 'prop_n19' in filename: return 'Proporcionalidade', 'Nice 19 (Min)'
    
    if 'stress_' in filename: return 'Stress Test (5x)', 'Processo Comum'
    
    if 'storm_cpu' in filename: return 'Tempestade I/O', 'CPU (Alvo)'
    if 'storm_io_' in filename: return 'Tempestade I/O', 'IO (Ruído)'
    
    return None, None

def ler_metricas(filepath):
    dados = {'valor': 0}
    if os.path.exists(filepath):
        with open(filepath, 'r') as f:
            content = f.read()
            match = re.search(r'(primes_found|io_ops)=(\d+)', content)
            if match: dados['valor'] = int(match.group(2))
    return dados

def main():
    registros = []
    print(f"Lendo pasta '{DIR_RESULTS}'...")

    for filename in os.listdir(DIR_RESULTS):
        if not filename.endswith('.out'): continue
        
        cenario, tipo = classificar_arquivo(filename)
        if not cenario: continue
        
        path = os.path.join(DIR_RESULTS, filename)
        infos = ler_metricas(path)
        
        registros.append({
            'Cenario': cenario,
            'Tipo': tipo,
            'Producao': infos['valor']
        })

    df = pd.DataFrame(registros)
    # Tira a média dos grupos repetidos (ex: stress test tem 5 arquivos iguais)
    df_final = df.groupby(['Cenario', 'Tipo'], as_index=False).mean()
    
    df_final.to_csv(OUTPUT_CSV, index=False)
    print("Análise completa. Dados salvos em:", OUTPUT_CSV)
    print(df_final)

if __name__ == "__main__":
    main()