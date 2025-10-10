#!/usr/bin/env julia
# analyze_runtimes.jl
#
# Run your AC-UC wrapper `code1(...)` multiple times for ONE MIPGap value.
# Useful for HPC arrays: submit one job per gap, each doing N runs, appending to a CSV.

using ArgParse
using Dates
using CSV, DataFrames

# bring your code1 into scope
include("../scripts/simultaneous_acuc_benchmarking.jl")  # defines `code1`

# ---- helpers ----
getd(d::Dict, k, default) = haskey(d, k) ? d[k] : default
float_or_nan(x) = x isa Real ? Float64(x) : NaN

function extract_timing(solve_data)::NamedTuple
    t = getd(solve_data, "timing", Dict{String,Any}())
    return (
        load_initial_data               = float_or_nan(getd(t, "load_initial_data", NaN)),
        sim_setup                       = float_or_nan(getd(t, "simultaneous_acuc_setup", NaN)),
        sim_solve_wall                  = float_or_nan(getd(t, "simultaneous_acuc_solve_wall", NaN)),
        sim_solve_solver                = float_or_nan(getd(t, "simultaneous_acuc_solve_solver", NaN)),
        sim_extract                     = float_or_nan(getd(t, "simultaneous_acuc_extract", NaN)),
        sim_total                       = float_or_nan(getd(t, "simultaneous_acuc_total", NaN)),
        sim_legacy_total                = float_or_nan(getd(t, "simultaneous_acuc_run", NaN)), # fallback
        schedule_total                  = float_or_nan(getd(t, "schedule_total", NaN)),
        opf_total                       = float_or_nan(getd(t, "opf_total", NaN)),
        write_solution                  = float_or_nan(getd(t, "write_solution", NaN)),
    )
end

function parse_cli()
    s = ArgParseSettings()
    @add_arg_table! s begin
        "--case", "-c"
            help = "Path to input case .json"
            required = true
        "--out", "-o"
            help = "CSV to append results into"
            required = true
        "--gap"
            help = "Single MIPGap value (e.g., 0.01)"
            required = true
        "--runs", "-r"
            help = "Number of repeated runs for this gap"
            arg_type = Int
            default = 3
        "--time_limit", "-t"
            help = "Overall time_limit passed to code1(...)"
            arg_type = Int
            default = 1800 # 30 minutes
        "--model", "-m"
            help = "Model string passed to code1(...) (e.g. 00003)"
            default = "00003"
        "--switching", "-s"
            help = "Allow switching flag passed to code1(...) (0/1)"
            arg_type = Int
            default = 0
        "--feastol"
            help = "Optional Gurobi FeasibilityTol (e.g. 1e-6); omit to use default"
            default = ""
    end
    return parse_args(s)
end

function main()
    args = parse_cli()

    case_file   = String(args["case"])
    out_csv     = String(args["out"])
    gap         = parse(Float64, String(args["gap"]))
    runs        = Int(args["runs"])
    time_limit  = Int(args["time_limit"])
    division    = 1
    model       = String(args["model"])
    switching   = Int(args["switching"])
    feastol_str = String(args["feastol"])
    have_feastol = !isempty(feastol_str)
    feastol     = have_feastol ? parse(Float64, feastol_str) : nothing

    # Pre-create dataframe schema (so CSV append is stable)
    df = DataFrame(
        timestamp = String[],
        case_file = String[],
        gap       = Float64[],
        run_idx   = Int[],
        time_limit = Int[],
        division   = Int[],
        model      = String[],
        switching  = Int[],
        feas_tol   = Union{Missing,Float64}[],
        load_initial_data  = Float64[],
        sim_setup          = Float64[],
        sim_solve_wall     = Float64[],
        sim_solve_solver   = Float64[],
        sim_extract        = Float64[],
        sim_total          = Float64[],
        sim_legacy_total   = Float64[],
        schedule_total     = Float64[],
        opf_total          = Float64[],
        write_solution     = Float64[],
        solution_file      = Union{Missing,String}[],
        objective_value       = Union{Missing,Float64}[],
        obj_bound             = Union{Missing,Float64}[],
        rel_gap               = Union{Missing,Float64}[],
        termination_status    = Union{Missing,String}[],
        primal_status         = Union{Missing,String}[],
        gurobi_feasibility_tol  = Union{Missing,Float64}[],
        gurobi_max_constr_vio   = Union{Missing,Float64}[],
        gurobi_max_genconstr_vio= Union{Missing,Float64}[],
    )

    outdir = abspath(dirname(out_csv))
    mkpath(outdir)

    for k in 1:runs
        tag = replace(basename(case_file), '.' => '_')
        solpath = joinpath(outdir, "solution_$(tag)_gap$(gap)_run$(k).json")

        # Call your wrapper. We pass only the knobs your code1 accepts.
        solve_data = code1(
            case_file,
            time_limit,
            division,
            model,
            switching,
            solpath;
            gurobi_MIPGapTol = gap,
            gurobi_FeasibilityTol = feastol,
        )

        tm = extract_timing(solve_data)
        tstat    = getd(solve_data, "termination_status", missing)
        pstat    = getd(solve_data, "primal_status", missing)
        obj    = getd(solve_data, "objective_value", missing)
        bound  = getd(solve_data, "obj_bound", missing)
        rgap   = getd(solve_data, "rel_gap", missing)
        ftol   = getd(solve_data, "gurobi_feasibility_tol", missing)
        cvio   = getd(solve_data, "gurobi_max_constr_vio", missing)
        gcvio  = getd(solve_data, "gurobi_max_genconstr_vio", missing)

        push!(df, (; 
            timestamp = string(Dates.now()),
            case_file = case_file,
            gap = gap,
            run_idx = k,
            time_limit = time_limit,
            division = division,
            model = model,
            switching = switching,
            feas_tol = have_feastol ? feastol::Float64 : missing,
            load_initial_data = tm.load_initial_data,
            sim_setup = tm.sim_setup,
            sim_solve_wall = tm.sim_solve_wall,
            sim_solve_solver = tm.sim_solve_solver,
            sim_extract = tm.sim_extract,
            sim_total = tm.sim_total,
            sim_legacy_total = tm.sim_legacy_total,
            schedule_total = tm.schedule_total,
            opf_total = tm.opf_total,
            write_solution = tm.write_solution,
            objective_value = obj,
            solution_file = solpath,
            termination_status = string(tstat),
            primal_status = string(pstat),
            obj_bound = bound,
            rel_gap = rgap,
            gurobi_feasibility_tol = ftol,
            gurobi_max_constr_vio = cvio,
            gurobi_max_genconstr_vio = gcvio,
        ))

        println("✓ gap=$(gap), run=$(k) — sim_total=$(tm.sim_total) s → $(solpath)")
    end

    # Append or create CSV
    if isfile(out_csv)
        CSV.write(out_csv, df; append=true)
    else
        CSV.write(out_csv, df)
    end
    println("Appended results → $(out_csv)")
end

main()
