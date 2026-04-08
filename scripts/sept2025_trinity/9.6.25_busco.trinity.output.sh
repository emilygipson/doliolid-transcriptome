#!/bin/bash
#SBATCH --job-name=busco_trinity
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G
#SBATCH --time=48:00:00
#SBATCH --output=busco_trinity_%j.out
#SBATCH --error=busco_trinity_%j.err
#SBATCH --mail-user=eeg37520@uga.edu
#SBATCH --mail-type=BEGIN,END,FAIL


# Load BUSCO (adjust version if needed)
module load BUSCO/5.8.3-foss-2023a

# Run BUSCO on Trinity assembly
busco -i Trinity.tmp.fasta \
      -l metazoa_odb10 \
      -o busco_trinity_out \
      -m transcriptome \
      --cpu 32
