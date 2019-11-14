# This is a sample Julia/JuMP script to help you understand its syntax
# The script is based on the Dartboard 2.0 case and associated data files
# Parts of the script can help you complete the case
# However, it solves for a different problem than the one you need to solve in the case
# The problem we will solve is:
#   how to determine which counties to serve with each of the *** three existing DCs *** during 2012-2013
#   in order to minimize transportation costs
# Note that we use a different planning horizon: *** January 2012 to December 2013 ***
# We base our analysis on actual sales (not predicted sales)

# Next, you need to setup your working directory (just like in Rstudio)
# To set your working directory, go to the toolbar and select
# Packages -> Juno -> Working Directory -> Select...
# Then, select the desired folder for your working directory
# Make sure that the folder contains your data files

# In this script we will use the DataFrames and Geodesy packages
# (along with the JuMP and Gurobi packages, which we have already used)
# We will use the DataFrames and CSV packages to read in the csv file and
# data wrangling. We will use the Geodesy package to compute distances.
# Use the following commands to install DataFrames and Geodesy:
Pkg.add("CSV")
Pkg.add("DataFrames")
Pkg.add("Geodesy")

# If you receieve the error:
# Unsatisfiable requirements detected for package ASTInterpreter2 [e6d88f4b]:
# Then run the following command
# Pkg.update()
# This will update all of your packages
# If you end up needing to run this line of code, then you will
# need to use slightly different syntax when you construct your model (we
# will walk you through this) because the line of code updated
# JuMP to the newest version

using CSV
using DataFrames
using Geodesy
using JuMP
using Gurobi

# Loading the historical data file as a dataframe
df = CSV.read("Dartboard_historical.csv"; header=true);
df = df[:,[:FIPS_Code,:Latitude,:Longitude,:Week_Num,:Sales]]
# Loading DC data
dc = CSV.read("Dartboard_DCs.csv"; header=true);
# Selecting only the three existing DCs
#dc = dc[1:3,:];

##### Wrangling
# Extracting data for the period 2012 to 2013 only (i.e weeks 1 to 104).
# *** This is a different planning horizon from the one described in the case ***
df_1to104 = df[(df.Week_Num .<= 104),:];
# Extracting data for the last 8 weeks in 2013 - the "peak" demand
df_97to104 = df_1to104[(df_1to104.Week_Num .> 96),:];

# Summarizing bt County (while keeping Latitude and Longitude info)
df_1to104_county = by(df_1to104, [:FIPS_Code, :Latitude, :Longitude], :Sales => sum)
df_97to104_county = by(df_97to104, [:FIPS_Code, :Latitude, :Longitude], :Sales => sum)

##### Defining parameters
num_dc = size(dc,1);
num_counties = size(df_1to104_county,1);

# We'll work everything in terms of pallets
# dividing by 1000 converts dollars to pallets
# (You can equivalently work in terms of dollar sales or SQF)

demand_1to104 = df_1to104_county[:,:Sales_sum] / 1000;
demand_97to104 = df_97to104_county[:,:Sales_sum] / 1000;

dc_cap_max = dc[:,:Current_Size] * 5 / 13.5;

distances = zeros(num_dc, num_counties) #distance between DCs (rows) and counties, in miles
for i=1:num_dc, j=1:num_counties
    distances[i,j] = distance(LLA(dc[i,:Latitude], dc[i,:Longitude],0.0),
                              LLA(df_1to104_county[j,:Latitude], df_1to104_county[j,:Longitude],0.0))/1609.34 # meters per mile
end

distances

# TO BE DONE

v #cost per square foot for DC
trans_cost = 1.55/20; # cost per pallet mile
fixed_cost_DC = 25000000; # is this the right unit 

# End TO BE DONE

##### Optimization Model

model0 = Model(solver=GurobiSolver(MIPGap=0.0001));
# If you ran Pkg.update(), then this line of code wil not
# work and you must instead run:
# model0 = Model(with_optimizer(Gurobi.Optimizer))

# The allocation decision of of DCs to counties
# Note: This decision variable determines whether DC i (row) serves county j (column)
# NOte: This decision variable is binary, because we assumed that all the demand from one county is served by the same DC
@variable(model0, x[1:num_dc,1:num_counties], Bin); #if DC i serves county j
@variable(model0, cc[1:num_dc]); # actually built DC size
@variable(model0, z[1:num_dc], Bin); #bool if DC i is built

# Minimize the sum of transportation costs over the 2012-2013 period
#@objective(model0, Min, trans_cost*sum(demand_1to104[c]*sum(distances[i,c]*x[i,c] for i=1:num_dc) for c=1:num_counties));
@objective(model0, Min, trans_cost*sum(demand_1to104[c]*sum(distances[i,c]*x[i,c] for i=1:num_dc) for c=1:num_counties) +  fixed_cost_DC *sum(z[i] for i=4:num_dc) + sum(z[i] *v[i] * cc[i]   for i=1:num_dc)   );

# Top 3 DCs already built
@constraint(model0, [i in 1:3], z[i] ==1);
@constraint(model0, [i in 1:3], cc[i] == dc_cap_max[i]);

# Capacity can't be bigger than max cap
@constraint(model0, [i in 1:3], cc[i] <= dc_cap_max[i]);

# Each county should use one and only one DC
@constraint(model0, nosplit[c=1:num_counties], sum(x[i,c] for i=1:num_dc) == 1);

# Keep peak 8-week period inventory below DC capacityC
@constraint(model0, dc_capacity[i=1:num_dc], sum(demand_97to104[c]*x[i,c] for c=1:num_counties) <= cc[i]);

show(model0)

solve(model0)
# If you ran Pkg.update(), then this line of code wil not
# work and you must instead run:
# optimize!(model0)

println("Objective value: ", getobjectivevalue(model0))
# Objective value: $137,838,585
# If you ran Pkg.update(), then this line of code might
# work. If not, you must instead run:
# println("Objective value: ", objective_value(model0))

# Can also use getvalue(x) to inspect the allocation solution
x_model0 = getvalue(x);
# If you ran Pkg.update(), then this line of code will not
# work and you must instead run:
# value.(x)

# Finally, you can export your solution as a csv file using the CSV.write function
# This can be helpful if you prefer doing the post-processing in Excel, R, etc.
CSV.write("x_model0.csv",DataFrame(x_model0))
