#!/bin/bash
#SBATCH --job-name=high_conf_summary
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=00:30:00
#SBATCH --output=high_conf_summary_%j.out
#SBATCH --error=high_conf_summary_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

module purge
module load SeqKit/2.9.0

# Paths
PEP="/scratch/eeg37520/Sept2025_Trinity/9.22.25_TranscriptAssembly_downstream/clean_transcriptome_assembly.fasta.transdecoder_dir/longest_orfs.pep"
CDS="/scratch/eeg37520/Sept2025_Trinity/9.22.25_TranscriptAssembly_downstream/clean_transcriptome_assembly.fasta.transdecoder_dir/longest_orfs.cds"
OUTDIR="/scratch/eeg37520/transdecoder_homology/high_conf_debug"

BLAST_IDS="$OUTDIR/blast.ids"
PFAM_IDS="$OUTDIR/pfam.ids"
BOTH_IDS="$OUTDIR/both_supported.ids"

PROTEINS="$OUTDIR/both_supported.proteins.pep"
CDS_SUBSET="$OUTDIR/both_supported.cds"

LOG="$OUTDIR/high_conf_summary.txt"
mkdir -p "$OUTDIR"

echo "High-confidence sequence summary: $(date)" > "$LOG"

# Total ORFs
total_orfs=$(grep -c '^>' "$PEP")
echo -e "Total predicted ORFs\t$total_orfs" >> "$LOG"

# Counts from BLAST and Pfam IDs
blast_count=$(wc -l < "$BLAST_IDS")
pfam_count=$(wc -l < "$PFAM_IDS")
both_count=$(wc -l < "$BOTH_IDS")

echo -e "BLAST-supported ORFs\t$blast_count" >> "$LOG"
echo -e "Pfam-supported ORFs\t$pfam_count" >> "$LOG"
echo -e "ORFs with BOTH support\t$both_count" >> "$LOG"

# Count sequences actually extracted
proteins_count=$(grep -c '^>' "$PROTEINS")
cds_count=$(grep -c '^>' "$CDS_SUBSET")

echo -e "Protein sequences extracted\t$proteins_count" >> "$LOG"
echo -e "CDS sequences extracted\t$cds_count" >> "$LOG"

echo "Summary written to $LOG"
