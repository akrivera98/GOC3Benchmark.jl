using Pkg
Pkg.activate(".")

using Debugger
# include("MyJulia1.jl")
include("scripts/simultaneous_acuc_benchmarking.jl")

# Debugger.@enter MyJulia1("test/data/C3S0N00003D1_scenario_003.json", 600, 1, "C3E4N00073", 0)

code1("test/data/C3S0N00003D1_scenario_003.json", 600, 1, "C3E4N00073", 0, "solution.json")
