#!/bin/bash
#SBATCH --job-name=filter_high_conf
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --output=filter_high_conf_%j.out
#SBATCH --error=filter_high_conf_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

module purge
module load SeqKit/2.9.0

# Input files
PEP="/scratch/eeg37520/Sept2025_Trinity/9.22.25_TranscriptAssembly_downstream/clean_transcriptome_assembly.fasta.transdecoder_dir/longest_orfs.pep"
CDS="/scratch/eeg37520/Sept2025_Trinity/9.22.25_TranscriptAssembly_downstream/clean_transcriptome_assembly.fasta.transdecoder_dir/longest_orfs.cds"
BLAST="/scratch/eeg37520/transdecoder_homology/all_chunks.blastp.out"
PFAM="/scratch/eeg37520/transdecoder_homology/pfam_all.domtblout"

# Output directory
OUTDIR="/scratch/eeg37520/transdecoder_homology/high_conf"
mkdir -p "$OUTDIR"

echo "Extracting ORF IDs from BLAST and Pfam at $(date)..."

# BLAST hits (query IDs are in col 1)
awk '{print $1}' "$BLAST" | sort -u > "$OUTDIR/blast.ids"

# Pfam hits (query IDs are in col 1, skipping comments)
grep -v '^#' "$PFAM" | awk '{print $1}' | sort -u > "$OUTDIR/pfam.ids"

# Intersection: ORFs with both BLAST and Pfam support
comm -12 "$OUTDIR/blast.ids" "$OUTDIR/pfam.ids" > "$OUTDIR/both_supported.ids"

echo "Number of BLAST-supported ORFs: $(wc -l < $OUTDIR/blast.ids)"
echo "Number of Pfam-supported ORFs: $(wc -l < $OUTDIR/pfam.ids)"
echo "Number with BOTH support: $(wc -l < $OUTDIR/both_supported.ids)"

# Subset protein FASTA
seqkit grep -f "$OUTDIR/both_supported.ids" "$PEP" > "$OUTDIR/both_supported.proteins.pep"

# Subset CDS FASTA (nucleotides)
seqkit grep -f "$OUTDIR/both_supported.ids" "$CDS" > "$OUTDIR/both_supported.cds"

echo "Done."
echo "High-confidence protein FASTA: $OUTDIR/both_supported.proteins.pep"
echo "High-confidence CDS FASTA:     $OUTDIR/both_supported.cds"
echo "Finished at $(date)"
