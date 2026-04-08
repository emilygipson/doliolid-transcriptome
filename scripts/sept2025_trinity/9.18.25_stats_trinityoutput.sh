#!/bin/bash
#SBATCH --job-name=4samp_trinity_qc
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --time=4:00:00
#SBATCH --mem=16G
#SBATCH --output=trinity_qc_%j.log
#SBATCH --error=trinity_qc_%j.err
#SBATCH --mail-user=eeg37520@uga.edu
#SBATCH --mail-type=BEGIN,END,FAIL

# ==== USER SETTINGS ====
ASSEMBLY="/scratch/eeg37520/Sept2025_Trinity/9.18.25_trinity_downstream/whole.Trinity.fasta"
QC_DIR="/scratch/eeg37520/Sept2025_Trinity/9.18.25_trinity_downstream/trinity_stats"

# ==== SETUP ====
module load Trinity   # adjust to your environment

mkdir -p "$QC_DIR"


# 2. Trinity stats
echo "Running TrinityStats..."
$TRINITY_HOME/util/TrinityStats.pl "$QC_DIR/whole.Trinity.fasta" > "$QC_DIR/TrinityStats.txt"

# 4. Record date and md5
date > "$QC_DIR/QC_done.txt"
md5sum "$QC_DIR/whole.Trinity.fasta" >> "$QC_DIR/QC_done.txt"

echo "QC finished. Results in $QC_DIR"
