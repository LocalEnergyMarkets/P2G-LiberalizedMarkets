###################
## Packages ########
###################

using CSV
using DataFrames
using JuMP
using Gurobi
using ProgressMeter
using ElectronDisplay
using Dates

# Loading the project module, containing essential functions and structs
include("model/src/Sesam.jl")
using .Sesam

###################
# SETS, PARAMS ####
###################

# Case
case = "ieee_rts_24_sesam_2019"

# Time frame
t_winter = collect(1:168)
t_spring = collect(3025:3192)
t_summer = collect(5593:5760)
t_autumn = collect(7225:7392)

time = t_summer	# Select time frame

# Read nodes and load from .csv
nodes_df = CSV.read(string("data/", case, "/nodes.csv"))
load_df = CSV.read(string("data/", case, "/load.csv"))

# Create set of nodes
nodes = Nodes(nodes_df, load_df)

# Read power plants from .csv
powerplants_df = CSV.read(string("data/", case, "/powerplants.csv"))

# Read fuel costs from .csv
fuelcost_df = CSV.read(string("data/", case, "/fuelcost.csv"))

# Create set of power plants
pp = PowerPlants(powerplants_df, fuelcost_df)

# Read renewables and availabilities from .csv
renewables_df = CSV.read(string("data/", case, "/renewables.csv"))
avail_solar_df = CSV.read(string("data/", case, "/avail_solar.csv"))
avail_wind_df = CSV.read(string("data/", case, "/avail_wind.csv"))

# Create set of renewables
res = Renewables(renewables_df, avail_solar_df, avail_wind_df)

# Read lines from .csv
lines_df = CSV.read(string("data/", case, "/lines.csv"))
lines = Lines(lines_df)

### With renewables
###################
# Run DCOPF #######
###################

DCOPF_mod, DCOPF_P_opt, DCOPF_P_R_opt, DCOPF_Θ_opt, DCOPF_P_inj_opt,
	DCOPF_P_flow_opt = DCOPF(time, nodes, lines, pp, res)

# Optimisation status
JuMP.termination_status(DCOPF_mod)
JuMP.primal_status(DCOPF_mod)
JuMP.dual_status(DCOPF_mod)

# Results
JuMP.objective_value(DCOPF_mod)
DCOPF_P_opt
DCOPF_P_R_opt
DCOPF_Θ_opt
DCOPF_P_inj_opt
DCOPF_P_flow_opt

###################
# Run ED ##########
###################

ED_mod, ED_P_opt, ED_P_R_opt, ED_P_R_opt_dist, ED_price = EconomicDispatch(time, nodes, pp, res)

# Optimisation status
JuMP.termination_status(ED_mod)
JuMP.primal_status(ED_mod)
JuMP.dual_status(ED_mod)

# Results
JuMP.objective_value(ED_mod)
ED_P_opt
ED_P_R_opt
ED_P_R_opt_dist
ED_price

###################
# Run CM ##########
###################

CM_mod, CM_ΔP_up_opt, CM_ΔP_dn_opt, CM_ΔP_R_up_opt, CM_ΔP_R_dn_opt, CM_Θ_opt,
	CM_P_inj_opt, CM_P_flow_opt, CM_price =
	CongestionManagement(time, nodes, lines, ED_price, ED_P_opt, pp,
	res, ED_P_R_opt_dist)

# Optimisation status
JuMP.termination_status(CM_mod)
JuMP.primal_status(CM_mod)
JuMP.dual_status(CM_mod)

# Results
JuMP.objective_value(CM_mod)
sum(CM_ΔP_up_opt)
sum(CM_ΔP_dn_opt)
sum(CM_ΔP_R_up_opt)
sum(CM_ΔP_R_dn_opt)
CM_Θ_opt
CM_P_inj_opt
CM_P_flow_opt

###################
# Run CM + PtG ####
###################

CM_PtG_mod, CM_PtG_ΔP_up_opt, CM_PtG_ΔP_dn_opt, CM_PtG_ΔP_R_up_opt,
	CM_PtG_ΔP_R_dn_opt, CM_PtG_Θ_opt, CM_PtG_P_inj_opt, CM_PtG_P_flow_opt,
	CM_PtG_P_syn_opt, CM_PtG_D_PtG_opt, CM_PtG_L_syn_opt =
	CongestionManagementPtG(time, nodes, lines, ED_price, ED_P_opt, pp,
	res, ED_P_R_opt_dist)

# Optimisation status
JuMP.termination_status(CM_PtG_mod)
JuMP.primal_status(CM_PtG_mod)
JuMP.dual_status(CM_PtG_mod)

# Results
JuMP.objective_value(CM_PtG_mod)

sum(CM_PtG_ΔP_up_opt)
sum(CM_PtG_ΔP_dn_opt)

sum(CM_PtG_ΔP_R_up_opt)
sum(CM_PtG_ΔP_R_dn_opt)

sum(CM_PtG_P_syn_opt)
sum(CM_PtG_D_PtG_opt)
sum(CM_PtG_L_syn_opt)
