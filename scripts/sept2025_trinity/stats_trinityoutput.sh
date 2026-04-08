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

# ==== USER SETTINGS ====
ASSEMBLY="/scratch/eeg37520/Sept2025_Trinity/trinity_coassembly_4samp/trinity_all_samples_out.Trinity.fasta"
BUSCO_LINEAGE="metazoa_odb10"     # or choose your lineage
QC_DIR="/scratch/eeg37520/Sept2025_Trinity/trinity_coassembly_4samp/trinity_initial_qc"

# ==== SETUP ====
module load Trinity   # adjust to your environment
module load BUSCO     # adjust if you run BUSCO via conda etc.

mkdir -p "$QC_DIR"

# 1. Copy assembly to QC dir
cp "$ASSEMBLY" "$QC_DIR/Trinity.fasta"

# 2. Trinity stats
echo "Running TrinityStats..."
$TRINITY_HOME/util/TrinityStats.pl "$QC_DIR/Trinity.fasta" > "$QC_DIR/TrinityStats.txt"

# 3. BUSCO completeness
echo "Running BUSCO..."
busco -i "$QC_DIR/Trinity.fasta" \
      -l "$BUSCO_LINEAGE" \
      -m transcriptome \
      -c $SLURM_CPUS_PER_TASK \
      -o "$QC_DIR/busco_out"

# 4. Record date and md5
date > "$QC_DIR/QC_done.txt"
md5sum "$QC_DIR/Trinity.fasta" >> "$QC_DIR/QC_done.txt"

echo "QC finished. Results in $QC_DIR"
