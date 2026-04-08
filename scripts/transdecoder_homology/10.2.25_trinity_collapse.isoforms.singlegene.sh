#!/bin/bash
#SBATCH --job-name=one_per_gene
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=04:00:00
#SBATCH --output=one_per_gene_%j.out
#SBATCH --error=one_per_gene_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

# -----------------------------------------------------------------------------
# Collapse isoforms: choose one protein (longest) per Trinity gene, extract CDS
# -----------------------------------------------------------------------------
# Inputs (edit if needed)
PROT_IN="/scratch/eeg37520/transdecoder_homology/cdhit/final_ref.proteins.nr95.pep"
CDS_IN="/scratch/eeg37520/transdecoder_homology/cdhit/final_ref.cds"

OUTDIR="/scratch/eeg37520/transdecoder_homology/cdhit/one_per_gene"
mkdir -p "$OUTDIR"
TMP="$OUTDIR/tmp"
mkdir -p "$TMP"

MODULES="SeqKit/2.9.0 seqtk/1.4-GCC-13.3.0"
module purge
module load SeqKit/2.9.0
module load seqtk/1.4-GCC-13.3.0 2>/dev/null || true

LOG="$OUTDIR/one_per_gene.log"
echo "one_per_gene run: $(date)" > "$LOG"
echo "PROT_IN = $PROT_IN" >> "$LOG"
echo "CDS_IN  = $CDS_IN" >> "$LOG"

# sanity
if [[ ! -s "$PROT_IN" ]]; then echo "[ERROR] protein input missing"; exit 1; fi
if [[ ! -s "$CDS_IN" ]];  then echo "[ERROR] cds input missing"; exit 1; fi

# 1) make table of protein id and length
echo "1) Computing protein lengths..." | tee -a "$LOG"
# seqkit fx2tab prints: name <tab> seq_len <tab> seq (we keep name and len)
seqkit fx2tab -n -l "$PROT_IN" > "$TMP/prot_len.tab"
# file format: ID<TAB>length

# 2) map each protein ID to a Trinity gene id (remove .pN and trailing _iN)
#    Example transformation:
#      TRINITY_DN0_c2_g1_i10.p1  -> base id TRINITY_DN0_c2_g1_i10  -> gene id TRINITY_DN0_c2_g1
echo "2) Mapping protein IDs to Trinity gene IDs..." | tee -a "$LOG"
awk -F'\t' '{
  id=$1;
  # strip .pN suffix
  sub(/\.[pP][0-9]+$/,"",id);
  base=id;
  # remove trailing _iN to get gene id
  sub(/_i[0-9]+$/,"",base);
  print base "\t" $2 "\t" $1;
}' "$TMP/prot_len.tab" > "$TMP/gene_len_id.tab"
# columns: gene_id<TAB>len<TAB>full_prot_id

# 3) pick longest protein per gene
echo "3) Selecting longest protein per gene..." | tee -a "$LOG"
awk -F'\t' '
{ gene=$1; len=$2; id=$3;
  if (!(gene in max) || len+0 > max[gene]) { max[gene]=len+0; best[gene]=id }
}
END {
  for (g in best) print g "\t" best[g] "\t" max[g]
}' "$TMP/gene_len_id.tab" > "$TMP/selected_per_gene.tsv"
# columns: gene<TAB>selected_protein_id<TAB>length

# 4) produce IDs list and counts
awk -F'\t' '{print $2}' "$TMP/selected_per_gene.tsv" > "$OUTDIR/selected_ids.txt"
num_genes=$(wc -l < "$OUTDIR/selected_ids.txt")
num_proteins_total=$(grep -c '^>' "$PROT_IN")

echo "Selected (one per gene) count: $num_genes" | tee -a "$LOG"
echo "Original protein count: $num_proteins_total" | tee -a "$LOG"

# 5) extract proteins (fast)
echo "5) Extracting chosen proteins to FASTA..." | tee -a "$LOG"
if command -v seqtk >/dev/null 2>&1; then
  seqtk subseq "$PROT_IN" "$OUTDIR/selected_ids.txt" > "$OUTDIR/final_ref.proteins.onePerGene.pep"
  seqtk_exit=$?
else
  seqkit grep -n -f "$OUTDIR/selected_ids.txt" "$PROT_IN" > "$OUTDIR/final_ref.proteins.onePerGene.pep"
  seqtk_exit=$?
fi
if [[ $seqtk_exit -ne 0 ]]; then
  echo "[WARN] protein extraction returned non-zero ($seqtk_exit)" | tee -a "$LOG"
fi
proteins_written=$(grep -c '^>' "$OUTDIR/final_ref.proteins.onePerGene.pep" || echo 0)
echo "Proteins written: $proteins_written" | tee -a "$LOG"

# 6) extract CDS for these proteins
#    Try direct exact-match extraction first (protein IDs are the first token)
echo "6) Extracting matching CDS sequences..." | tee -a "$LOG"
if command -v seqtk >/dev/null 2>&1; then
  seqtk subseq "$CDS_IN" "$OUTDIR/selected_ids.txt" > "$OUTDIR/final_ref.cds.onePerGene.fasta"
  extract_exit=$?
else
  seqkit grep -n -f "$OUTDIR/selected_ids.txt" "$CDS_IN" > "$OUTDIR/final_ref.cds.onePerGene.fasta"
  extract_exit=$?
fi

# 7) fallback: if CDS extraction produced zero or much fewer sequences, try base-id fallback
cds_written=$(grep -c '^>' "$OUTDIR/final_ref.cds.onePerGene.fasta" || echo 0)
if [[ $cds_written -lt $num_genes ]]; then
  echo "[INFO] CDS extraction yielded $cds_written / $num_genes. Trying fallback by base transcript ID..." | tee -a "$LOG"
  # Build mapping of CDS headers (first token) -> full header
  grep '^>' "$CDS_IN" | sed 's/^>//' | awk '{print $1}' > "$TMP/cds_headers.firsttoken.txt"
  # Now map selected IDs by base (strip .pN) to first matching CDS header
  awk 'NR==FNR { cds[$1]=1; base=$1; sub(/\.[pP][0-9]+$/,"",base); if(!(base in first)) first[base]=$1; next }
       { sel=$1; if(sel in cds) { print sel } else { base=sel; sub(/\.[pP][0-9]+$/,"",base); if(base in first) print first[base] } }' \
       "$TMP/cds_headers.firsttoken.txt" "$OUTDIR/selected_ids.txt" \
       > "$TMP/full_cds_ids_fallback.txt"
  sort -u "$TMP/full_cds_ids_fallback.txt" > "$TMP/full_cds_ids_fallback.uniq.txt"
  # extract these
  if command -v seqtk >/dev/null 2>&1; then
    seqtk subseq "$CDS_IN" "$TMP/full_cds_ids_fallback.uniq.txt" > "$OUTDIR/final_ref.cds.onePerGene.fasta"
  else
    seqkit grep -n -f "$TMP/full_cds_ids_fallback.uniq.txt" "$CDS_IN" > "$OUTDIR/final_ref.cds.onePerGene.fasta"
  fi
  cds_written=$(grep -c '^>' "$OUTDIR/final_ref.cds.onePerGene.fasta" || echo 0)
  echo "[INFO] After fallback, CDS written: $cds_written" | tee -a "$LOG"
fi

# 8) write mapping and summary files (traceability)
cp "$TMP/selected_per_gene.tsv" "$OUTDIR/selected_per_gene.tsv"
echo "" >> "$LOG"
echo "Final summary:" | tee -a "$LOG"
echo "  proteins: original=$num_proteins_total selected=$proteins_written" | tee -a "$LOG"
echo "  cds:      original=$(grep -c '^>' "$CDS_IN") extracted=$cds_written" | tee -a "$LOG"
echo "Mapping (gene -> selected_protein_id -> length) at: $OUTDIR/selected_per_gene.tsv" | tee -a "$LOG"
echo "Script log: $LOG"
echo "Done at $(date)" | tee -a "$LOG"

# End
