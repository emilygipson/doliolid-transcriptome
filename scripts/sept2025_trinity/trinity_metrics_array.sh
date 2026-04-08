#!/bin/bash
#SBATCH --job-name=trinity_metrics
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --array=1-133
#SBATCH --output=trinity_metrics_%A_%a.out
#SBATCH --error=trinity_metrics_%A_%a.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

set -euo pipefail
module purge
module load SAMtools

cd /scratch/eeg37520/Sept2025_Trinity

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" trinity_samples.txt)
BAM="/scratch/eeg37520/triage_batch_bams/${SAMPLE}.trinity.sorted.bam"
OUT="/scratch/eeg37520/triage_metrics/${SAMPLE}.metrics.tsv"

# reference length (sum of FAI lengths)
REFLEN=$(awk '{sum+=$2} END{print sum}' 4samp_Trinity.longest_isoform.fasta.fai)

# mapped bases (cigar)
MAPPED=$(samtools stats "$BAM" | awk -F'\t' '$1=="SN" && $2 ~ /bases mapped \(cigar\)/ {gsub(/ /,"",$3); print $3}')


# breadth + covbases + transcripts_hit at MAPQ>=30, BQ>=20
COV_LINE=$(samtools coverage -q 30 -Q 20 "$BAM" | awk 'NR>1{cov+=$6; len+=$3; if($6>0) t++} END{printf "%.0f\t%.0f\t%d", cov, len, t}')
COVBASES=$(echo -e "$COV_LINE" | cut -f1)
LEN=$(echo -e "$COV_LINE" | cut -f2)
TRANSCRIPTS=$(echo -e "$COV_LINE" | cut -f3)

EFF=$(awk -v m="$MAPPED" -v r="$REFLEN" 'BEGIN{printf "%.6f", m/r}')
BREADTH=$(awk -v c="$COVBASES" -v r="$REFLEN" 'BEGIN{printf "%.8f", c/r}')

echo -e "sample\tref_bp\tmapped_bases_cigar\teff_cov_x\tcovbases\tbreadth_frac\ttranscripts_hit" > "$OUT"
echo -e "${SAMPLE}\t${REFLEN}\t${MAPPED}\t${EFF}\t${COVBASES}\t${BREADTH}\t${TRANSCRIPTS}" >> "$OUT"
