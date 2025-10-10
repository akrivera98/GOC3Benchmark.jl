#!/bin/bash
#SBATCH --job-name=acuc_gap_array_73bus
#SBATCH --output=logs/gap_%A_%a.out
#SBATCH --error=logs/gap_%A_%a.err
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --partition=mit_normal
#SBATCH --array=0-2   # 3 gaps -> indices 0,1,2

module load julia/1.9
# module load gurobi/12.0.3         # adjust to your site’s version

# define your gaps as a bash array

GAPS=(1e-6 1e-5 1e-4)
GAP=${GAPS[$SLURM_ARRAY_TASK_ID]}

CASE_FILE="data/S0/inputs/C3S0N00073D1_scenario_003.json"
OUT_CSV="results/results_uc.csv"
MODEL="C3E4N00073"
SWITCHING=0
TIME_LIMIT=1800
RUNS=3
PROJECT_FLAG="--project=."

mkdir -p logs results

echo "Running GAP=${GAP} (task ${SLURM_ARRAY_TASK_ID})"
julia ${PROJECT_FLAG} analysis_scripts/analyze_runtimes.jl \
  -c "${CASE_FILE}" \
  -o "${OUT_CSV}" \
  --gap "${GAP}" \
  -r "${RUNS}" \
  -t "${TIME_LIMIT}" \
  -m "${MODEL}" \
  -s "${SWITCHING}"
