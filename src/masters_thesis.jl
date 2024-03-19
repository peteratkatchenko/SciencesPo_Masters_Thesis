module masters_thesis

using CSV
using DataFrames
using Distributions
using Random 
using Query
using Plots
using Pipe 
using TabularDisplay
using PrettyTables
using Chain

# Generate a dataframe for each of the datasets needed for the analysis
# df: CIE data with firm identifiers and firm types
# df_asie_i: matched firms with patents + CIE firm identifiers (invention patents)
# df_asie_d: matched firms with patents + CIE firm identifiers (design patents)
# df_asie_u: matched firms with patents + CIE firm identifiers (utility patents)

df = CSV.read("C:\\Users\\peter\\.julia\\dev\\masters_thesis\\china.data\\data_firm_level_china_additional\\ciedata_additional.csv", DataFrame)
pretty_table(df)

df_asie_i = CSV.read("C:\\Users\\peter\\.julia\\dev\\masters_thesis\\china.data\\matched_chinese_firm_patent_data\\ASIE firms matched to invention patents.csv", DataFrame)
pretty_table(df_asie_i)

df_asie_d = CSV.read("C:\\Users\\peter\\.julia\\dev\\masters_thesis\\china.data\\matched_chinese_firm_patent_data\\ASIE firms matched to design patents.csv", DataFrame)
pretty_table(df_asie_d)

df_asie_u = CSV.read("C:\\Users\\peter\\.julia\\dev\\masters_thesis\\china.data\\matched_chinese_firm_patent_data\\ASIE firms matched to utility model patents.csv", DataFrame)
pretty_table(df_asie_u)

# Vertically concatenate the matched patent dataframes to obtain a single matched firm-patent dataframe 
# firm_patent: total firm-patent matches for all patent types 

firm_patent = vcat(df_asie_i, df_asie_d, df_asie_u)
pretty_table(firm_patent)

#df contains observations from 1998-2008 inclusive; firm_patent contains observations from 1998-2009
#Need to trim firm_patent so that it contains observations from 1998-2008

summary_stats_df = describe(df[!, :year]) #1998-2008

summary_stats_fp = describe(firm_patent[!, :year]) #1998-2009

firm_patent = filter(row -> row.year != 2009, firm_patent) #Removing obs with year == 2009
pretty_table(firm_patent)

rename!(firm_patent, "asie_id" => "id") #Renaming ASIE id variable to 'id' in both dataframes

#Checking both dataframes for missing values in the 'id','year' variables + others

missing_values_df_id = sum(ismissing.(df[!, "id"])) #103,414 missing values out of 2,718,430 total values

missing_values_df_year = sum(ismissing.(df[!, "year"])) #0 missing values

missing_values_df_ownership = sum(ismissing.(df[!, "ownership"])) #0 missing values 
###################################################################################
missing_values_fp_id = sum(ismissing.(firm_patent[!, "id"])) #151 missing values out of 876,554 total values

missing_values_fp_year = sum(ismissing.(firm_patent[!, "year"])) #0 missing values 
 
missing_values_fp_pt = sum(ismissing.(firm_patent[!, "patent_type"])) #0 missing values 

#What patent types are most associated with firms with missing id in firm_patent

filtered_fp = filter(row -> ismissing(row.id), firm_patent) #Isolating the obs with missing id: 151x25 df 

unique_patent_types = unique(filtered_fp.patent_type) #Quantity of unique patent_types: 3

freq_table_fp = combine(groupby(filtered_fp, "patent_type"), nrow) #Frequency of each unique patent_type 
    #i:66 d:39 u:46 - very small quantity of obs w/ missing values, evenly distributed 

#What firm types are most associated with firms with missing id in df 

filtered_df = filter(row -> ismissing(row.id), df) #Isolating the obs with missing id: 103,414x12

unique_firm_types = unique(filtered_df.ownership) #Quantity of unique firm types: 5

freq_table_df = combine(groupby(filtered_df, "ownership"), nrow)
println(freq_table_df)
#SOE:6722 Foreign:11581 Private:33854 Collective:9216 NotID:42041
#Out of those eliminated firms whose type is identified, most are Private 

summary_stats_filtered_df = describe(filtered_df[!, "output"]) #Mean output: 97,349.67
#Compare the mean output of eliminated firms to mean output of retained firms (in df)

#Remove obs with missing values for 'id' in firm_patent 

firm_patent = filter(row -> !ismissing(row.id), firm_patent) #Remove obs with missing id: 876,403x25 df 
#CSV.write("firm_patent.csv", firm_patent) 

#Remove obs with missing values for 'id' in df 

df = filter(row -> !ismissing(row.id), df) #Remove obs with missing id: 2,615,016x12 df 
#CSV.write("df_cleaned.csv", df)

summary_stats_df = describe(df[!, "output"]) #Mean output: 85,426.51
#Mean output of retained df firms is less than mean output of eliminated df firms
#Possible implication: retained firms are smaller in size compared to eliminated firms 
#Can't determine the firm type of larger eliminated firms - no firm id for matching 

# Identify the firm type for each observation in firm_patent by matching dataframes
# using firm identifier and patent application year 

merged_df = leftjoin(firm_patent, df, on = [:id, :year]) #876,415x35 (+12 rows?)
#CSV.write("merged_df.csv", merged_df)

missing_values_mg_id = sum(ismissing.(merged_df.id)) #0 obs w/ missing id

missing_values_mg_year = sum(ismissing.(merged_df.year)) #0 obs w/ missing year 

missing_values_mg_pt = sum(ismissing.(merged_df.patent_type)) #0 obs w/ missing patent type 

missing_values_mg_ownership = sum(ismissing.(merged_df.ownership)) #200,893 obs w/ missing ownership 
        
#If obs in merged_df are missing 'ownership', then there was no matching id in df 
#Therefore: shouldn't be able to find obs with id in df 

#Checking condition by hand with one merged_df obs 
last_obs = last(merged_df, 1)

last_obs_owner = last_obs.ownership 

println(last_obs_owner) #Ownership indeed missing for last obs of merged_df 

id_lastobs = last_obs.id #X02645195 
year_lastobs = last_obs.year #2008

function find_id1(dataframe, id, year)
    for row in eachrow(dataframe)
        if row.id == id && row.year == year 
            return row.ownership 
        end 
    end 
    return "No match found"
end 

find_id1(df, id_lastobs, year_lastobs) #No match found 

#Checking condition with algorithm for N=1000 merged_df obs 
#Isolating merged_df obs w/o ownership
no_owner = merged_df[675524:876415, :] #200,892 obs w/o ownership 
sample_noowner = no_owner[sample(1:nrow(no_owner), 1000, replace=false), :]
id_sample = sample_noowner.id 
year_sample = sample_noowner.year

function find_id2(dataframe, id_sample, year_sample) #Finding matching obs in df 
    matches_found = String[]
    for i in 1:length(id_sample)
        for row in eachrow(dataframe)
            if id_sample[i] == row.id && year_sample[i] == row.year
            push!(matches_found, row.ownership)
            end 
        end 
    end 
    if isempty(matches_found)
        return "No matches found"
    else 
        return matches_found 
    end
end 
        
#matched_id = find_id2(df, id_sample, year_sample) #No matches found!  

#Isolating merged_df obs w/o ownership info 
filtered_mg = filter(row -> ismissing(row.ownership), merged_df) #200,893x35 

#Removing the obs in merged_df w/o 'ownership'
merged_df = filter(row -> !ismissing(row.ownership), merged_df) #675,522x35 
#CSV.write("merged_df.csv", merged_df)

#Generating bar graph for merged_df 

@chain merged_df begin 
select(:ownership)
ownership_df = unique(_)
ownership = _[!, :ownership]
end 

println(ownership) #SOE;Foreign;Collective;Private

inv_df = filter(row -> row.patent_type == "i", merged_df)
grouped_inv = groupby(inv_df, :ownership)
patents_inv = combine(grouped_inv, nrow)
num_patents_inv = patents_inv[!, :nrow]

des_df = filter(row -> row.patent_type == "d", merged_df)
grouped_des = groupby(des_df, :ownership)
patents_des = combine(grouped_des, nrow)
num_patents_des = patents_des[!, :nrow]

uti_df = filter(row -> row.patent_type == "u", merged_df)
grouped_uti = groupby(uti_df, :ownership)
patents_uti = combine(grouped_uti, nrow)
num_patents_uti = patents_uti[!, :nrow]
 
   

bar_inv = bar(ownership, num_patents_inv, labels=false, xlabel="Ownership", ylabel="Number of Patents",
title="Invention Patents",
titlefont=font(12),
labelfont=font(12)
) #Invention patents

bar_des = bar(ownership, num_patents_des, labels=true, xlabel="Ownership", ylabel="Number of Patents",
title="Design Patents",
titlefont=font(12),
labelfont=font(12)
) #Design patents 

bar_uti = bar(ownership, num_patents_uti, labels=true, xlabel="Ownership", ylabel="Number of Patents",
title="Utility Patents",
titlefont=font(12),
labelfont=font(12)
) #Utility patents 

plot(bar_inv, bar_des, bar_uti, layout=(3), legend=false)


























end # module masters_thesis