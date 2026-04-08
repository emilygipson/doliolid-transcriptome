#!/bin/bash
#SBATCH --job-name=cdhit_cluster
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --output=cdhit_%j.out
#SBATCH --error=cdhit_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

module purge
module load CD-HIT/4.8.1-GCC-12.3.0

# Input protein FASTA
PROT="/scratch/eeg37520/transdecoder_homology/high_conf/both_supported.proteins.pep"
OUTDIR="/scratch/eeg37520/transdecoder_homology/high_conf/cdhit"
mkdir -p "$OUTDIR"

echo "Running CD-HIT clustering at $(date)..."

cd-hit -i "$PROT" \
  -o "$OUTDIR/final_ref.proteins.pep" \
  -c 0.95 -n 5 \
  -aS 0.9 -T 8 -M 32000

echo "CD-HIT finished at $(date)."
echo "Clustered protein FASTA: $OUTDIR/final_ref.proteins.pep"
echo "Cluster report:          $OUTDIR/final_ref.proteins.pep.clstr"
