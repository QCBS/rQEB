#!/bin/bash
#SBATCH --account=def-pollock
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=02:00:00

PI_ACCOUNT=def-pollock
REPO_NAME=rQEB
PROJECT_DIR=~/links/projects/$PI_ACCOUNT/$USER

module load StdEnv/2023 gcc r/4.5.0 r-bundle-bioconductor/3.21
export R_LIBS=~/.local/R/$EBVERSIONR/
export PATH=$PROJECT_DIR/ollama/bin:$PATH

export OLLAMA_MODELS=$PROJECT_DIR/ollama/models
export OLLAMA_HOST=127.0.0.1:11434

# Start the server in the background
ollama serve > "$SLURM_SUBMIT_DIR/ollama-$SLURM_JOB_ID.log" 2>&1 &
OLLAMA_PID=$!

# Wait until it's ready (up to ~60s)
for i in $(seq 1 30); do
  curl -s http://127.0.0.1:11434/ > /dev/null && break
  sleep 2
done

cd "$PROJECT_DIR/$REPO_NAME"
Rscript 'P3_moteurs_changement/R/jaureguiberry2022/5_first_pass_filter.R' --args test

# Clean up
kill $OLLAMA_PID