#!/bin/bash
#SBATCH --job-name=filter_high_conf_debug
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --output=filter_high_conf_debug_%j.out
#SBATCH --error=filter_high_conf_debug_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

module purge
module load SeqKit/2.9.0

# Input files
PEP="/scratch/eeg37520/Sept2025_Trinity/9.22.25_TranscriptAssembly_downstream/clean_transcriptome_assembly.fasta.transdecoder_dir/longest_orfs.pep"
CDS="/scratch/eeg37520/Sept2025_Trinity/9.22.25_TranscriptAssembly_downstream/clean_transcriptome_assembly.fasta.transdecoder_dir/longest_orfs.cds"
BLAST="/scratch/eeg37520/transdecoder_homology/all_chunks.blastp.out"
PFAM="/scratch/eeg37520/transdecoder_homology/pfam_all.domtblout"

OUTDIR="/scratch/eeg37520/transdecoder_homology/high_conf_debug"
mkdir -p "$OUTDIR"

LOG="$OUTDIR/filter_high_conf.log"
echo "Starting high-confidence sequence extraction: $(date)" > "$LOG"

# Extract ORF IDs
echo "Extracting ORF IDs from BLAST and Pfam..." | tee -a "$LOG"
awk '{sub(/\.p[0-9]+$/,"",$1); print $1}' "$BLAST" | sort -u > "$OUTDIR/blast.ids"
grep -v '^#' "$PFAM" | awk '{sub(/\.p[0-9]+$/,"",$4); print $4}' | sort -u > "$OUTDIR/pfam.ids"

# Intersection
comm -12 "$OUTDIR/blast.ids" "$OUTDIR/pfam.ids" > "$OUTDIR/both_supported.ids"

echo "Number of BLAST-supported ORFs: $(wc -l < $OUTDIR/blast.ids)" | tee -a "$LOG"
echo "Number of Pfam-supported ORFs:  $(wc -l < $OUTDIR/pfam.ids)" | tee -a "$LOG"
echo "Number with BOTH support:      $(wc -l < $OUTDIR/both_supported.ids)" | tee -a "$LOG"

# Test: count how many of these IDs appear in the PEP FASTA headers
echo "Checking matches in protein FASTA..." | tee -a "$LOG"
matched=$(grep -Ff "$OUTDIR/both_supported.ids" "$PEP" | wc -l)
echo "Number of matching header lines in original FASTA: $matched" | tee -a "$LOG"

# Create subset using regex matching (-r) to handle extra description after ID
echo "Subsetting protein FASTA..." | tee -a "$LOG"
seqkit grep -r -f "$OUTDIR/both_supported.ids" "$PEP" > "$OUTDIR/both_supported.proteins.pep" 2>>"$LOG"
echo "Protein sequences extracted: $(grep -c '^>' $OUTDIR/both_supported.proteins.pep)" | tee -a "$LOG"

# Subset CDS FASTA
echo "Subsetting CDS FASTA..." | tee -a "$LOG"
seqkit grep -r -f "$OUTDIR/both_supported.ids" "$CDS" > "$OUTDIR/both_supported.cds" 2>>"$LOG"
echo "CDS sequences extracted: $(grep -c '^>' $OUTDIR/both_supported.cds)" | tee -a "$LOG"

echo "Done. High-confidence sequences are in $OUTDIR" | tee -a "$LOG"
echo "Finished at $(date)" | tee -a "$LOG"
