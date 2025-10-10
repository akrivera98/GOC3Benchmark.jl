#!/usr/bin/env bash
set -euo pipefail

module purge || true
module load community-modules
module load julia/1.9.1
module load gurobi/12.0.3

export LD_LIBRARY_PATH="${GUROBI_HOME}/lib:${LD_LIBRARY_PATH:-}"
export JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 OMP_NUM_THREADS=1

julia --project=. -e 'using Pkg; Pkg.build("Gurobi"); using Gurobi; const MOI=Gurobi.MOI; println(MOI.get(Gurobi.Optimizer(), MOI.SolverVersion()))'
