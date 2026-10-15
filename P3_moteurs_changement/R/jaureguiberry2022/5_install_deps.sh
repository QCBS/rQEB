PI_ACCOUNT=def-pollock
module load StdEnv/2023 gcc r/4.5.0 r-bundle-bioconductor/3.21

Rscript -e 'install.packages(c(
  "ollamar"
))'

mkdir -p ~/links/projects/$PI_ACCOUNT/$USER/ollama && cd ~/links/projects/$PI_ACCOUNT/$USER/ollama
curl -L https://ollama.com/download/ollama-linux-amd64.tar.zst -o ollama-linux-amd64.tar.zst
tar --use-compress-program=unzstd -xf ollama-linux-amd64.tar.zst
export OLLAMA_MODELS=~/links/projects/$PI_ACCOUNT/$USER/ollama/models
export PATH=~/links/projects/$PI_ACCOUNT/$USER/ollama/bin:$PATH
ollama serve > /dev/null 2>&1 &
sleep 5
ollama pull nimble      # use your actual model tag
kill %1
# sbatch slurm_first_pass.sh

