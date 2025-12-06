import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

INPUT_CSV = "dados_finais_validos.csv"

def plotar_graficos():
    try:
        df = pd.read_csv(INPUT_CSV)
    except FileNotFoundError:
        print("Erro: CSV não encontrado. Rode o script de analise.py primeiro.")
        return

    sns.set_theme(style="whitegrid")
    
    # --- GRÁFICO 1: O Efeito do NICE (Starvation) ---
    plt.figure(figsize=(8, 6))
    df_nice = df[df['Cenario'] == 'Prioridade (Nice)']
    if not df_nice.empty:
        ax = sns.barplot(data=df_nice, x='Processo', y='Producao', palette='viridis')
        plt.title('Impacto Crítico da Prioridade (Nice) - Competição no Core 0')
        plt.ylabel('Primos Encontrados')
        plt.xlabel('')
        # Adiciona os números nas barras
        for i in ax.containers: ax.bar_label(i, fmt='%d')
        plt.savefig('grafico_nice.png')
        print("Gerado: grafico_nice.png")

    # --- GRÁFICO 2: Real Time (FIFO vs RR) ---
    plt.figure(figsize=(8, 6))
    df_rt = df[df['Cenario'] == 'Real-Time']
    if not df_rt.empty:
        ax = sns.barplot(data=df_rt, x='Processo', y='Producao', palette='magma')
        plt.title('Políticas Real-Time: FIFO vs Round Robin (Mesma Prioridade)')
        plt.ylabel('Primos Encontrados')
        plt.xlabel('')
        for i in ax.containers: ax.bar_label(i, fmt='%d')
        plt.savefig('grafico_realtime.png')
        print("Gerado: grafico_realtime.png")

    # --- GRÁFICO 3: Baseline vs Misto ---
    # Compara o desempenho do CPU Bound: Sozinho vs Com IO
    plt.figure(figsize=(8, 6))
    filtro = df['Processo'].isin(['Isolado', 'Processo CPU'])
    df_mix = df[filtro].copy()
    
    if not df_mix.empty:
        ax = sns.barplot(data=df_mix, x='Cenario', y='Producao', color='royalblue')
        plt.title('Impacto da Concorrência: CPU Isolada vs Concorrendo com IO')
        plt.ylabel('Primos Encontrados')
        plt.xlabel('')
        plt.ylim(0, df_mix['Producao'].max() * 1.2) # Dá um espaço extra em cima
        for i in ax.containers: ax.bar_label(i, fmt='%d')
        plt.savefig('grafico_cpu_io.png')
        print("Gerado: grafico_cpu_io.png")

if __name__ == "__main__":
    plotar_graficos()