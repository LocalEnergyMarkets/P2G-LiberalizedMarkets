using Gurobi
using CSV
using DataFrames
using JuMP
using ProgressMeter
using ElectronDisplay

include("model/src/Sesam.jl")
using .Sesam

# Power plants
pp_df = CSV.read("data/test/power_plants.csv")
avail_con_df = CSV.read("data/test/avail_con.csv")
prices_df = CSV.read("data/test/prices.csv")

avail_pv = CSV.read("data/test/avail_pv.csv")
avail_windon = CSV.read("data/test/avail_windon.csv")
avail_windoff = CSV.read("data/test/avail_windoff.csv")

avail = Dict(:PV => avail_pv,
	:WindOnshore => avail_windon,
	:WindOffshore => avail_windoff,
	:global => avail_con_df)

pp = PowerPlants(pp_df, avail = avail_con_df, prices = prices_df)

res_df = CSV.read("data/test/res.csv")
res = RenewableEnergySource(res_df, avail)

# Load
load_df = CSV.read("data/test/load.csv") |>
    df -> sum.(eachrow(df))
load = load_df

T = collect(1:(24*7*10))
P = pp.id
R = res.id

# JuMP model
economic_dispatch = JuMP.Model(with_optimizer(Gurobi.Optimizer))

@variable(economic_dispatch, G[T, P] >= 0)
@variable(economic_dispatch, G_R[T, R] >= 0)

@constraint(economic_dispatch, MarketClearing[t = T],
    sum(G[t, p] for p in P) + sum(G_R[t, r] for r in R) == load[t]);

@constraint(economic_dispatch, MaxGenerationDisp[p = P, t = T],
    G[t, p] <= pp.capacity[p][t]);

@constraint(economic_dispatch, MaxGenerationDispR[r = R, t = T],
    G_R[t, r] <= res.infeed[r][t]);

@objective(economic_dispatch, Min,
    sum(pp.mc[p][t] * G[t, p] for p in P, t in T));

###
JuMP.optimize!(economic_dispatch)
JuMP.termination_status(economic_dispatch)
JuMP.primal_status(economic_dispatch)
JuMP.dual_status(economic_dispatch)

JuMP.objective_value(economic_dispatch)
JuMP.value.(G)
JuMP.value.(G_R)
value(G[1,"BNA0005"])

G[1,"LN"]

df = DataFrame(T=[],ID=[],P=[])
for t in T
	for p in P
		val = JuMP.value(G[t, p])
		push!(df, [t p val])
	end
end

CSV.write("output/dispatch.csv",df)

electrondisplay(df)

# Dual value of market clearing
has_duals(economic_dispatch)
JuMP.dual.(MarketClearing)
JuMP.shadow_price.(MarketClearing)
