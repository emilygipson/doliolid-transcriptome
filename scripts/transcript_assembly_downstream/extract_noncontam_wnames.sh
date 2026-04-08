#!/bin/bash
#SBATCH --job-name=noncontam_reads
#SBATCH --partition=batch
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=64G
#SBATCH --time=04:00:00
#SBATCH --output=noncontam_reads.%j.out
#SBATCH --error=noncontam_reads.%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

###############################################################################
# Slurm script to extract classified contigs from Kraken2 output that are
# NOT contaminants, and get their sequences from the assembly FASTA.
#
# Fix: properly captures full taxon names even if they contain spaces.
#
# Inputs:
#   1) Kraken2 output file with names (kraken_full_out_classifications.txt)
#   2) contaminant taxid list (one per line)
#   3) original assembly FASTA
#
# Outputs:
#   - noncontaminant_classified_ids_with_names.txt  (contig ID <tab> full taxon name)
#   - noncontaminant_classified_sequences.fasta    (FASTA sequences)
###############################################################################

# ---------------------------- USER SETTINGS ----------------------------------
KRAKEN_OUT="/scratch/eeg37520/Sept2025_Trinity/9.22.25_TranscriptAssembly_downstream/kraken_out/4samp_trinity_out_kraken_full_out_classifications.txt"
CONTAM_TAXIDS="/scratch/eeg37520/Sept2025_Trinity/9.22.25_TranscriptAssembly_downstream/contam_taxids.txt"
ASSEMBLY="/scratch/eeg37520/Sept2025_Trinity/9.22.25_TranscriptAssembly_downstream/4samp_trinity_out.fasta"

OUTPUT_DIR="/scratch/eeg37520/Sept2025_Trinity/9.22.25_TranscriptAssembly_downstream/kraken_out"
mkdir -p "$OUTPUT_DIR"

NONCONTAM_IDS="$OUTPUT_DIR/noncontaminant_classified_ids_with_names.txt"
GOOD_IDS="$OUTPUT_DIR/noncontaminant_classified_ids.txt"
NONCONTAM_FASTA="$OUTPUT_DIR/noncontaminant_classified_sequences.fasta"
# -----------------------------------------------------------------------------

module load SeqKit/2.9.0

echo "### Extracting non-contaminant classified contigs at $(date)"

# Step 1: Extract contig IDs and full taxon names for classified contigs not in contaminant list
awk '
NR==FNR {contam[$1]=1; next}              # load contaminant taxids
$1=="C" {
  # extract numeric taxid from anywhere in the line
  match($0, /\(taxid[[:space:]]*([0-9]+)\)/, m)
  taxid = m[1]
  if (!(taxid in contam)) {
    # extract full taxon name: all columns after contig ID until first k-mer column (e.g., 0:56)
    name=""
    for(i=3;i<=NF;i++) {
      if($i ~ /^[0-9]+:[0-9]+$/) break
      name = name $i " "
    }
    gsub(/[[:space:]]+$/,"",name)  # remove trailing space
    print $2 "\t" name
  }
}' "$CONTAM_TAXIDS" "$KRAKEN_OUT" > "$NONCONTAM_IDS"

N=$(wc -l < "$NONCONTAM_IDS")
echo "Found $N non-contaminant classified contigs."

# Step 2: Extract just the contig IDs for seqkit
cut -f1 "$NONCONTAM_IDS" > "$GOOD_IDS"

# Step 3: Pull sequences from the assembly FASTA
seqkit grep -f "$GOOD_IDS" "$ASSEMBLY" -o "$NONCONTAM_FASTA"

echo "FASTA sequences written to $NONCONTAM_FASTA"
echo "### Done at $(date)"
