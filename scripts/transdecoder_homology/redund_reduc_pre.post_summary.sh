#!/bin/bash
#SBATCH --job-name=seqcount_summary
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=00:10:00
#SBATCH --output=seqcount_summary_%j.out
#SBATCH --error=seqcount_summary_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

# -----------------------------
# Variables
# -----------------------------
ORIG_PROT="/scratch/eeg37520/transdecoder_homology/high_conf/both_supported.proteins.pep"
REDUCED_PROT="/scratch/eeg37520/transdecoder_homology/final_ref/clean_transcriptome_assembly.fasta.transdecoder.pep"

ORIG_CDS="/scratch/eeg37520/transdecoder_homology/final_ref/clean_transcriptome_assembly.fasta.transdecoder_dir/longest_orfs.cds"
REDUCED_CDS="/scratch/eeg37520/transdecoder_homology/final_ref/clean_transcriptome_assembly.fasta.transdecoder.cds"

OUTFILE="/scratch/eeg37520/transdecoder_homology/sequence_count_summary.txt"

# -----------------------------
# Count sequences
# -----------------------------
echo "Generating sequence count summary..." > "$OUTFILE"
echo "----------------------------------------" >> "$OUTFILE"

echo "Protein FASTA counts:" >> "$OUTFILE"
echo "Original proteins: $(grep -c '^>' $ORIG_PROT)" >> "$OUTFILE"
echo "Non-redundant proteins: $(grep -c '^>' $REDUCED_PROT)" >> "$OUTFILE"
echo "" >> "$OUTFILE"

echo "CDS FASTA counts:" >> "$OUTFILE"
echo "Original CDS: $(grep -c '^>' $ORIG_CDS)" >> "$OUTFILE"
echo "Non-redundant CDS: $(grep -c '^>' $REDUCED_CDS)" >> "$OUTFILE"

echo "----------------------------------------" >> "$OUTFILE"
echo "Summary written to $OUTFILE"
