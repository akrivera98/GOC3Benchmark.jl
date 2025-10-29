#!/usr/bin/env bash

# --- Inputs ---
CASE_FILE="data/S0/inputs/C3S0N00014D1_scenario_003.json"
OUT_CSV="results/results_uc.csv"
MODEL="C3E4N00073"
SWITCHING=0
TIME_LIMIT=1800
RUNS=1
PROJECT_FLAG="--project=."
GAP=1e-4

mkdir -p logs results

# Optional: verify we’re using the intended Gurobi
julia $PROJECT_FLAG -e 'using Gurobi; const MOI=Gurobi.MOI; println("Gurobi = ", MOI.get(Gurobi.Optimizer(), MOI.SolverVersion()))'

# --- Run ---
julia $PROJECT_FLAG analysis_scripts/analyze_runtimes.jl \
  -c "$CASE_FILE" \
  -o "$OUT_CSV" \
  --gap "$GAP" \
  -r "$RUNS" \
  -t "$TIME_LIMIT" \
  -m "$MODEL" \
  -s "$SWITCHING"