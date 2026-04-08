#!/bin/bash
#SBATCH --job-name=kraken2_LI.transcriptome         # Job name
#SBATCH --partition=batch                       # Partition (queue) name
#SBATCH --ntasks=1                              # Number of tasks
#SBATCH --cpus-per-task=4                       # Number of CPUs (adjust as needed)
#SBATCH --mem=400gb                             # Job memory request
#SBATCH --time=48:00:00                          # Time limit hrs:min:sec
#SBATCH --output=kraken2_LI.transcriptome.%j.out   # Standard output log (%j for job ID)
#SBATCH --error=kraken2_LI.transcriptome.%j.err    # Standard error log
#SBATCH --mail-type=BEGIN,END,FAIL              # Mail events
#SBATCH --mail-user=eeg37520@uga.edu            # Where to send mail 

# Move to the directory where the job was submitted
cd $SLURM_SUBMIT_DIR

module load Kraken2

# Paths
ASSEMBLY=/scratch/eeg37520/Sept2025_Trinity/9.18.25_trinity_downstream/LI.Trinity.fasta  # your transcriptome assembly file
DB=/db/kraken2/20250814/core_nt                                               # Kraken2 database
OUTPUT_DIR=/scratch/eeg37520/Sept2025_Trinity/9.18.25_trinity_downstream/LI_kraken_out
mkdir -p "$OUTPUT_DIR"

# Output filenames (strip .fasta)
BASENAME=$(basename "$ASSEMBLY" .fasta)

# Run Kraken2 on the transcriptome assembly
kraken2 \
  --db "$DB" \
  --threads $SLURM_CPUS_PER_TASK \
  --use-names \
  --output "$OUTPUT_DIR/${BASENAME}_kraken2_classifications.txt" \
  --unclassified-out "$OUTPUT_DIR/${BASENAME}_unclassified#.fa" \
  --classified-out "$OUTPUT_DIR/${BASENAME}_classified#.fa" \
  --report "$OUTPUT_DIR/${BASENAME}_kraken2_report.txt" \
  "$ASSEMBLY"
