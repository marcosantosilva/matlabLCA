#!/bin/bash

#SBATCH --job-name=matlab_job          # Nome do job
#SBATCH --output=matlab_output.log     # Arquivo de saída
#SBATCH --error=matlab_error.log       # Arquivo de erro
#SBATCH --ntasks=1                     # Número de tarefas
#SBATCH --cpus-per-task=64             # Número de CPUs por tarefa
#SBATCH --mem=64G                      # Memória total
#SBATCH --time=02:00:00                # Tempo máximo (hh:mm:ss)
#SBATCH --partition=cpu2               # Partição desejada
#SBATCH --account=cfmmimo        # Conta do projeto (obrigatório)

# Carregar o módulo MATLAB
module load MATLAB/2023b

# Executar o script MATLAB sem interface gráfica
matlab -nodisplay -nosplash -r "run('main.m'); exit;"

