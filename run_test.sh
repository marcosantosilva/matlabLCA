#!/bin/bash

#SBATCH --job-name=matlab_job          # Job name
#SBATCH --output=matlab_output.log     # Output file
#SBATCH --error=matlab_error.log       # Error file
#SBATCH --ntasks=1                     # Number of tasks
#SBATCH --cpus-per-task=8             # Number of CPUs per task
#SBATCH --mem=4G                       # Total memory
#SBATCH --time=48:00:00                # Max time (hh:mm:ss) set to 48 hours
#SBATCH --partition=cpu1               # Desired partition
#SBATCH --account=cfmmimo              # Project account (mandatory)

# Load MATLAB module
module load MATLAB/2023b

matlab -nodisplay -nosplash -r "run('test.m'); exit;"
