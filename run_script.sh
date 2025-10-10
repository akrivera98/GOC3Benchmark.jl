#!/bin/bash
#SBATCH --job-name=acuc_gap
#SBATCH --output=logs/gap_%j.out
#SBATCH --error=logs/gap_%j.err
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=128G
#SBATCH --partition=mit_normal

module load julia/1.10

CASE_FILE="test/data/C3S0N00003D1_scenario_003.json"
OUT_CSV="results/results_uc.csv"
MODEL="C3E4N00073"
SWITCHING=1
TIME_LIMIT=1800
RUNS=3
PROJECT_FLAG="--project=."

mkdir -p logs results

# List of Gurobi MIPGap values
for GAP in 1e-2 1e-3 1e-4 1e-6; do
    echo "Submitting job for gap=${GAP}"
    sbatch <<EOF
#!/bin/bash
#SBATCH --job-name=acuc_${GAP}
#SBATCH --output=logs/gap_${GAP}_%j.out
#SBATCH --error=logs/gap_${GAP}_%j.err
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --partition=mit_normal

module load julia/1.10

echo "Running simultaneous AC-UC for GAP=${GAP}"
julia ${PROJECT_FLAG} analysis_scripts/analyze_runtimes.jl \
    -c "${CASE_FILE}" \
    -o "${OUT_CSV}" \
    --gap "${GAP}" \
    -r "${RUNS}" \
    -t "${TIME_LIMIT}" \
    -m "${MODEL}" \
    -s "${SWITCHING}"

echo "Done GAP=${GAP}"
EOF
done
