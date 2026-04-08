#!/bin/bash
#SBATCH --job-name=busco_longest
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=48:00:00
#SBATCH --output=busco_longest_%j.out
#SBATCH --error=busco_longest_%j.err
#SBATCH --mail-user=eeg37520@uga.edu
#SBATCH --mail-type=BEGIN,END,FAIL

# Load Python (for Biopython) and BUSCO
module load Python/3.11.3-GCCcore-12.3.0
module load BUSCO/5.8.3-foss-2023a

# Ensure Biopython is available
pip install --user biopython

# Step 1: Extract longest isoforms
cat << 'EOF' > extract_longest_isoforms.py
from Bio import SeqIO

input_fasta = "Trinity.tmp.fasta"
output_fasta = "4samp_Trinity.longest_isoform.fasta"

longest = {}
for record in SeqIO.parse(input_fasta, "fasta"):
    gene_id = record.id.split("_i")[0]  # up to isoform number
    if gene_id not in longest or len(record.seq) > len(longest[gene_id].seq):
        longest[gene_id] = record

SeqIO.write(longest.values(), output_fasta, "fasta")
print(f"Wrote {len(longest)} longest isoforms to {output_fasta}")
EOF

python extract_longest_isoforms.py


