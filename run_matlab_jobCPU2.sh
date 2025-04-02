#!/bin/bash

#SBATCH --job-name=matlab_job          # Job name
#SBATCH --output=matlab_output.log     # Output file
#SBATCH --error=matlab_error.log       # Error file
#SBATCH --ntasks=1                     # Number of tasks
#SBATCH --cpus-per-task=48             # Number of CPUs per task
#SBATCH --mem=4G                       # Total memory
#SBATCH --time=48:00:00                # Max time (hh:mm:ss) set to 48 hours
#SBATCH --partition=cpu2               # Desired partition
#SBATCH --account=cfmmimo              # Project account (mandatory)

# Load MATLAB module
module load MATLAB/2023b

# Define directories for checking the existence of files
dir_resT="resT"  # Directory where the file will be checked
dir_temp="temp"  # Directory where the temporary files are checked

# Define the vectors for sd and se
sd_values=(1 2 3 4 5 25 26 27 28 29 41 42 43 44 45 51 52 53 54 55 91 92 93 94 95 101 102 103 104 105)
se_values=$(seq 0.25 0.25 4)  # Values of se from 0.25 to 4 with an increment of 0.25

# Start loop for iterating over sd and se values
for sd in "${sd_values[@]}"  # For each value in sd_values
do
    for se in $se_values    # For each value in se_values
    do
        # Format se to always have two decimal places (e.g., 0.50 instead of 0.5)
        se_formatted=$(printf "%.2f" $se)
        
        # Construct the file name to check based on the sd and formatted se values
        file_resT="${dir_resT}/MIPsim${sd}_SE_${se_formatted}.mat"
        file_temp="${dir_temp}/MIPsim${sd}_SE_${se_formatted}.mat"
        
        # Check if the file already exists in resT/
        if [ -f "$file_resT" ]; then
            echo "The file $file_resT already exists in resT/. Moving to the next se value."
            continue  # Move to the next se value
        fi

        # Check if the file already exists in temp/
        if [ -f "$file_temp" ]; then
            echo "The file $file_temp already exists in temp/. Moving to the next se value."
            continue  # Move to the next se value
        fi

        # If the file does not exist in either directory, run the simulation
        echo "Running simulation for sd=${sd} and se=${se_formatted}..."
        
        # Run the MATLAB script without the graphical interface
        matlab -nodisplay -nosplash -r "genFig3($sd, $se); exit;"
    done
done

