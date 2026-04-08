#!/bin/bash
#SBATCH --job-name=trinity_test       # Job name
#SBATCH --partition=batch_30d             # Partition (queue) name
#SBATCH --ntasks=1                    # ?
#SBATCH --cpus-per-task=16           # Number of CPUs (cores)
#SBATCH --mem=100gb                     # Job memory request
#SBATCH --time=169:00:00               # Time limit hrs:min:sec
#SBATCH --output=trinity_test.%j.out    # Standard output log
#SBATCH --error=trinity_test.%j.err     # Standard error log

#SBATCH --mail-type=BEGIN,END,FAIL          # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=eeg37520@uga.edu  # Where to send mail

module load Trinity/2.15.2-foss-2023a

#start
Trinity --seqType fq --max_memory 100G \
--left DL5_15_R1_trimmed.fastq.gz \
--right DL5_15_R2_trimmed.fastq.gz \
--CPU 16 --output trinity_out

