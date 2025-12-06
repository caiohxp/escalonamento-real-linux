import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

INPUT_CSV = "dados_avancados.csv"

def gerar_graficos():
    try:
        df = pd.read_csv(INPUT_CSV)
    except:
        print("Erro: CSV não encontrado.")
        return

    sns.set_theme(style="whitegrid")

    # GRÁFICO 1: A Curva de Decaimento do Nice
    # Mostra como o desempenho cai exponencialmente com o Nice
    plt.figure(figsize=(10, 6))
    df_prop = df[df['Cenario'] == 'Proporcionalidade'].sort_values('Producao', ascending=False)
    if not df_prop.empty:
        sns.barplot(data=df_prop, x='Tipo', y='Producao', palette='rocket')
        plt.title('Validação dos Pesos do CFS: Nice 0 vs 10 vs 19')
        plt.ylabel('Primos Encontrados')
        plt.savefig('grafico_avancado_pesos.png')
        print("Gerado: grafico_avancado_pesos.png")

    # GRÁFICO 2: Stress Test (Fairness)
    # Compara o Baseline (Sozinho) vs Média do Stress (Dividido por 5)
    plt.figure(figsize=(8, 6))
    filtro = df['Tipo'].isin(['CPU Isolado', 'Processo Comum'])
    df_stress = df[filtro].copy()
    if not df_stress.empty:
        # Adiciona coluna de expectativa (Ideal)
        baseline = df_stress[df_stress['Tipo']=='CPU Isolado']['Producao'].max()
        plt.axhline(baseline/5, color='r', linestyle='--', label='Ideal Teórico (1/5)')
        
        sns.barplot(data=df_stress, x='Tipo', y='Producao', palette='Blues_d')
        plt.title('Eficiência do Escalonador sob Alta Carga (1 vs 5 Processos)')
        plt.legend()
        plt.savefig('grafico_avancado_stress.png')
        print("Gerado: grafico_avancado_stress.png")

    # GRÁFICO 3: Resiliência a I/O
    # Compara CPU Isolado vs CPU com 1 I/O vs CPU com 4 I/Os
    plt.figure(figsize=(10, 6))
    # Criamos um dataframe manual para essa comparação específica cruzando cenários
    val_base = df[df['Tipo']=='CPU Isolado']['Producao'].values[0]
    val_1v1 = df[(df['Cenario']=='CPU vs IO (1v1)') & (df['Tipo']=='CPU')]['Producao'].values[0]
    val_storm = df[df['Tipo']=='CPU (Alvo)']['Producao'].values[0] if not df[df['Tipo']=='CPU (Alvo)'].empty else 0
    
    comp_data = pd.DataFrame({
        'Ambiente': ['Sozinho', 'Com 1 I/O', 'Com 4 I/Os (Tempestade)'],
        'Performance': [val_base, val_1v1, val_storm]
    })
    
    sns.barplot(data=comp_data, x='Ambiente', y='Performance', palette='Spectral')
    plt.title('Robustez do Processo CPU-Bound contra Interrupções de I/O')
    plt.savefig('grafico_avancado_io_storm.png')
    print("Gerado: grafico_avancado_io_storm.png")

if __name__ == "__main__":
    gerar_graficos()