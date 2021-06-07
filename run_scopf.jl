###################
# Packages ########
###################

using CSV
using DataFrames
using JuMP
using Gurobi
using ProgressMeter
using ElectronDisplay

# Loading the project module, containing essential functions and structs
include("model/src/Sesam.jl")
using .Sesam

###################
# SETS, PARAMS ####
###################

# time T
# T = collect(1)
time = collect(1)
data = "ieee_case5"


# Read nodes and load from .csv
nodes_df = CSV.read(string("data/", data, "/nodes.csv"))
load_df = CSV.read(string("data/", data, "/load.csv"))

# Create set of nodes
nodes = Nodes(nodes_df, load_df)

# Read power plants from .csv
powerplants_df = CSV.read(string("data/", data, "/powerplants.csv"))

# Create set of power plants
pp = PowerPlants(powerplants_df)

# Read renewables and availabilities from .csv
renewables_df = CSV.read(string("data/", data, "/renewables.csv"))
avail_solar_df = CSV.read(string("data/", data, "/avail_solar.csv"))
avail_wind_df = CSV.read(string("data/", data, "/avail_wind.csv"))

# Create set of renewables
res = Renewables(renewables_df, avail_solar_df, avail_wind_df)

# Read lines from .csv
lines_df = CSV.read(string("data/", data, "/lines.csv"))
lines = Lines(lines_df)

###################
# Run DCOPF #######
###################

DCOPF_mod, P_opt, Θ_opt, P_inj_opt, P_flow_opt =
	DCOPF(time, nodes, lines, pp)

# Optimisation status
JuMP.termination_status(DCOPF_mod)
JuMP.primal_status(DCOPF_mod)
JuMP.dual_status(DCOPF_mod)

# Results
JuMP.objective_value(DCOPF_mod)
P_opt
Θ_opt
P_inj_opt
P_flow_opt

###################
# Run SCOPF #######
###################

SCOPF_mod, P_opt_s, Θ_opt_s, P_inj_opt_s, P_flow_opt_s =
	SCOPF(time, nodes, lines, pp)

# Optimisation status
JuMP.termination_status(SCOPF_mod)
JuMP.primal_status(SCOPF_mod)
JuMP.dual_status(SCOPF_mod)

# Results
JuMP.objective_value(SCOPF_mod)
P_opt_s
Θ_opt_s
P_inj_opt_s
P_flow_opt_s
