using CSV
using DataFrames
using Distributions
using Random 
using Plots 
using TabularDisplay
using PrettyTables
using Chain
using GLM 
using Econometrics
using CategoricalArrays
using RegressionTables
using GLFixedEffectModels
using RCall

include("time_separators.jl")
import .time_separators: time2
import .time_separators: time3 
import .time_separators: time4 
import .time_separators: time5


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

#Renaming chinese variables to English ones 

rename!(firm_patent, 
"asie_id" => "id",
"公开公告日" => "publication_date", 
"申请日" => "application_date", 
"主分类号" => "primary_class",
"分类号" => "class",
"分案原申请号" => "divisional_application",
"优先权" => "priority",
"申请专利权人" => "patent_owner",
"地址" => "address",
"专利代理机构" => "patent_agency",
"代理人" => "patent_agent",
"页数" => "pages",
"国省代码" => "state_province_code",
"申请号" => "application_no",
"公开号" => "grant_date")


#df contains observations from 1998-2008 inclusive; firm_patent contains observations from 1998-2009
#Need to trim firm_patent so that it contains observations from 1998-2008

summary_stats_df = describe(df[!, :year]) #1998-2008

summary_stats_fp = describe(firm_patent[!, :year]) #1998-2009

firm_patent = filter(row -> row.year != 2009, firm_patent) #Removing obs with year == 2009
pretty_table(firm_patent)

#Checking both dataframes for missing values in the 'id','year' variables + others

missing_values_df_id = sum(ismissing.(df[!, "id"])) #103,414 missing values out of 2,718,430 total values

missing_values_df_year = sum(ismissing.(df[!, "year"])) #0 missing values

missing_values_df_ownership = sum(ismissing.(df[!, "ownership"])) #0 missing values 

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

#Are there any 'switcher' firms in df?

df_id = groupby(df, :id) #721,197 group

df_id = combine(df_id, :ownership => (c -> length(unique(c))) => :uniq_ownership) #721,1997 obs

df_switchers = filter(:uniq_ownership => x -> x > 1, df_id) #77,329 switchers in df 

#What were the ownership types of the switcher firms?

switcher_id = select(df_switchers, :id) #77,329 switcher id DataFrame

switcher_id = switcher_id[!, :id] #77,329 switcher id Vector 

# Identify the firm type for each observation in firm_patent 
merged_df = leftjoin(firm_patent, df, on = [:id, :year]) #876,415x35 (+12 rows?)
#CSV.write("merged_df.csv", merged_df)

##Creating database w/ extensive margin 
#Analyzing missing values in merged_df
missing_values_mg_id = sum(ismissing.(merged_df.id)) #0 obs w/ missing id

missing_values_mg_year = sum(ismissing.(merged_df.year)) #0 obs w/ missing year 

missing_values_mg_pt = sum(ismissing.(merged_df.patent_type)) #0 obs w/ missing patent type 

missing_values_mg_ownership = sum(ismissing.(merged_df.ownership)) #200,893 obs w/ missing ownership 
        
#If obs in merged_df are missing 'ownership', then there was no matching id and year in df 
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

find_id1(df, id_lastobs, year_lastobs) #No match found! 

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

#Creating binary indicator for patent filing
patent_filed = ones(Int, length(merged_df.id)) #876,415 ones
merged_df.patent_filed = patent_filed 
#Creating binary outcomes variable (0=Design/Utility, 1=Invention) 
merged_df.binary_pat = ifelse.(merged_df.patent_type .== "i", 1, 0)
merged_df.binary_own = ifelse.(merged_df.ownership .== "SOE", 1, 0) 
#Don't forget to filter out all rows with Foreign/Collective firms before running reg
#Otherwise, reg will count Foreign/Collective as part of Private  
function cat_dp(x)
    if x == "i"
        return 2
    elseif x == "u"
        return 1
    elseif x == "d"
        return 0 
    end 
end

merged_df.cat_pat = map(cat_dp, merged_df.patent_type)


didnt_file = antijoin(df, merged_df, on = [:id, :year]) #2,531,131
not_filed = zeros(Int, length(didnt_file.id))
didnt_file.patent_filed = not_filed
didnt_file.binary_own = ifelse.(didnt_file.ownership .== "SOE", 1, 0) 

didnt_file[!, :binary_pat] = missings(nrow(didnt_file))
didnt_file[!, :cat_pat] = missings(nrow(didnt_file))
didnt_file[!, :fullname] = missings(nrow(didnt_file))
didnt_file[!, :stemname] = missings(nrow(didnt_file))
didnt_file[!, :patent_type] = missings(nrow(didnt_file))
didnt_file[!, :serial_no] = missings(nrow(didnt_file))
didnt_file[!, :assignee] = missings(nrow(didnt_file))
didnt_file[!, :assignee_full] = missings(nrow(didnt_file))
didnt_file[!, :assignee_stem] = missings(nrow(didnt_file))
didnt_file[!, :manual_check] = missings(nrow(didnt_file))
didnt_file[!, :true_match] = missings(nrow(didnt_file))
didnt_file[!, :publication_date] = missings(nrow(didnt_file))
didnt_file[!, :application_date] = missings(nrow(didnt_file))
didnt_file[!, :primary_class] = missings(nrow(didnt_file))
didnt_file[!, :class] = missings(nrow(didnt_file))
didnt_file[!, :divisional_application] = missings(nrow(didnt_file))
didnt_file[!, :priority] = missings(nrow(didnt_file))
didnt_file[!, :patent_owner] = missings(nrow(didnt_file))
didnt_file[!, :address] = missings(nrow(didnt_file))
didnt_file[!, :patent_agency] = missings(nrow(didnt_file))
didnt_file[!, :patent_agent] = missings(nrow(didnt_file))
didnt_file[!, :pages] = missings(nrow(didnt_file))
didnt_file[!, :state_province_code] = missings(nrow(didnt_file))
didnt_file[!, :application_no] = missings(nrow(didnt_file))
didnt_file[!, :grant_date] = missings(nrow(didnt_file))


extensive_df = vcat(merged_df, didnt_file) #2,934,441x39
CSV.write("extensive_df.csv", extensive_df)

#Deleting the Collective + Foreign firms 
extensive_df = filter(row -> (row.ownership == "SOE" || row.ownership == "Private"), 
extensive_df)

#All data - groups: id, ownership
extensive_grouped_1 = groupby(extensive_df, [:id, :ownership, :county, :ind4])
extensive_counts_1 = combine(extensive_grouped_1, 
:patent_filed => sum => :patents_count,
:employee => mean => :mean_employee,
:output => mean => :mean_output,
:binary_own => mean => :binary_own)
extensive_counts_1[!, :binary_own] = convert.(Int, extensive_counts_1[!, :binary_own])
extensive_counts_1.id = categorical(extensive_counts_1.id, ordered=false, compress=true)
extensive_counts_1.county = categorical(extensive_counts_1.county, ordered=false, compress=true)
extensive_counts_1.ind4 = categorical(extensive_counts_1.ind4, ordered=false, compress=true)

CSV.write("extensive_counts_1.csv", extensive_counts_1)

#All data - groups: id, ownership, time2 
extensive_df.time2 = map(time2, extensive_df.year)
extensive_grouped_t2 = groupby(extensive_df, [:id, :ownership, :county, :ind4, :time2])
extensive_counts_t2 = combine(extensive_grouped_t2,
:patent_filed => sum => :patents_count,
:employee => mean => :mean_employee,
:output => mean => :mean_output,
:binary_own => mean => :binary_own)
extensive_counts_t2.id = categorical(extensive_counts_t2.id, ordered=false, compress=true)
extensive_counts_t2.county = categorical(extensive_counts_t2.county, ordered=false, compress=true)
extensive_counts_t2.ind4 = categorical(extensive_counts_t2.ind4, ordered=false, compress=true)

first(extensive_counts_t2, 5)

#All data - groups: id, ownership, time3 
extensive_df.time3 = map(time3, extensive_df.year)
extensive_grouped_t3 = groupby(extensive_df, [:id, :ownership, :county, :ind4, :time3])
extensive_counts_t3 = combine(extensive_grouped_t3,
:patent_filed => sum => :patents_count,
:employee => mean => :mean_employee,
:output => mean => :mean_output,
:binary_own => mean => :binary_own)
extensive_counts_t3.id = categorical(extensive_counts_t3.id, ordered=false, compress=true)
extensive_counts_t3.county = categorical(extensive_counts_t3.county, ordered=false, compress=true)
extensive_counts_t3.ind4 = categorical(extensive_counts_t3.ind4, ordered=false, compress=true)

first(extensive_counts_t3, 5)

#All data - groups: id, ownership, time4 
extensive_df.time4 = map(time4, extensive_df.year)
extensive_grouped_t4 = groupby(extensive_df, [:id, :ownership, :county, :ind4, :time4])
extensive_counts_t4 = combine(extensive_grouped_t4,
:patent_filed => sum => :patents_count,
:employee => mean => :mean_employee,
:output => mean => :mean_output,
:binary_own => mean => :binary_own)
extensive_counts_t4.id = categorical(extensive_counts_t4.id, ordered=false, compress=true)
extensive_counts_t4.county = categorical(extensive_counts_t4.county, ordered=false, compress=true)
extensive_counts_t4.ind4 = categorical(extensive_counts_t4.ind4, ordered=false, compress=true)

first(extensive_counts_t4, 5)

#All data - groups: id, ownership, time5 
extensive_df.time5 = map(time5, extensive_df.year)
extensive_grouped_t5 = groupby(extensive_df, [:id, :ownership, :county, :ind4, :time5])
extensive_counts_t5 = combine(extensive_grouped_t5,
:patent_filed => sum => :patents_count,
:employee => mean => :mean_employee,
:output => mean => :mean_output,
:binary_own => mean => :binary_own)
extensive_counts_t5.id = categorical(extensive_counts_t5.id, ordered=false, compress=true)
extensive_counts_t5.county = categorical(extensive_counts_t5.county, ordered=false, compress=true)
extensive_counts_t5.ind4 = categorical(extensive_counts_t5.ind4, ordered=false, compress=true)

first(extensive_counts_t5, 5)

#All data - groups: id, ownership, patent_type
extensive_grouped_2 = groupby(extensive_df, [:id, :ownership, :patent_type, :county, :ind4])
extensive_counts_2 = combine(extensive_grouped_2,
:patent_filed => sum => :patents_count,
:employee => mean => :mean_employee,
:output => mean => :mean_output,
:binary_own => mean => :binary_own,
:cat_pat => mean => :cat_pat) 
extensive_counts_2[!, :binary_own] = convert.(Int, extensive_counts_2[!, :binary_own])
extensive_counts_2[!, :cat_pat] = convert.(Union{Int, Missing}, extensive_counts_2[!, :cat_pat])
extensive_counts_2.cat_pat = categorical(extensive_counts_2.cat_pat, ordered = false, compress = true)
extensive_counts_2.cat_pat = categorical(extensive_counts_2.cat_pat, ordered = true, compress = true)
extensive_counts_2.id = categorical(extensive_counts_2.id, ordered=false, compress=true)
extensive_counts_2.county = categorical(extensive_counts_2.county, ordered=false, compress=true)
extensive_counts_2.ind4 = categorical(extensive_counts_2.ind4, ordered=false, compress=true)



#All data - groups: id, ownership, patent_type, time2 
extensive_grouped_t2! = groupby(extensive_df, [:id, :ownership, :patent_type, :county, :ind4, :time2])
extensive_counts_t2! = combine(extensive_grouped_t2!,
:patent_filed => sum => :patents_count,
:employee => mean => :mean_employee,
:output => mean => :mean_output,
:binary_own => mean => :binary_own,
:cat_pat => mean => :cat_pat) 
extensive_counts_t2![!, :binary_own] = convert.(Int, extensive_counts_t2![!, :binary_own])
extensive_counts_t2![!, :cat_pat] = convert.(Union{Int, Missing}, extensive_counts_t2![!, :cat_pat])
extensive_counts_t2!.cat_pat = categorical(extensive_counts_t2!.cat_pat, ordered = false, compress = true)
extensive_counts_t2!.cat_pat = categorical(extensive_counts_t2!.cat_pat, ordered = true, compress = true)
extensive_counts_t2!.id = categorical(extensive_counts_t2!.id, ordered=false, compress=true)
extensive_counts_t2!.county = categorical(extensive_counts_t2!.county, ordered=false, compress=true)
extensive_counts_t2!.ind4 = categorical(extensive_counts_t2!.ind4, ordered=false, compress=true)



#All data - groups: id, ownership, patent_type, time3
extensive_grouped_t3! = groupby(extensive_df, [:id, :ownership, :patent_type, :county, :ind4, :time3])
extensive_counts_t3! = combine(extensive_grouped_t3!,
:patent_filed => sum => :patents_count,
:employee => mean => :mean_employee,
:output => mean => :mean_output,
:binary_own => mean => :binary_own,
:cat_pat => mean => :cat_pat) 
extensive_counts_t3![!, :binary_own] = convert.(Int, extensive_counts_t3![!, :binary_own])
extensive_counts_t3![!, :cat_pat] = convert.(Union{Int, Missing}, extensive_counts_t3![!, :cat_pat])
extensive_counts_t3!.cat_pat = categorical(extensive_counts_t3!.cat_pat, ordered = false, compress = true)
extensive_counts_t3!.cat_pat = categorical(extensive_counts_t3!.cat_pat, ordered = true, compress = true)
extensive_counts_t3!.id = categorical(extensive_counts_t3!.id, ordered=false, compress=true)
extensive_counts_t3!.county = categorical(extensive_counts_t3!.county, ordered=false, compress=true)
extensive_counts_t3!.ind4 = categorical(extensive_counts_t3!.ind4, ordered=false, compress=true)


#All data - groups: id, ownership, patent_type, time4
extensive_grouped_t4! = groupby(extensive_df, [:id, :ownership, :patent_type, :county, :ind4, :time4])
extensive_counts_t4! = combine(extensive_grouped_t4!,
:patent_filed => sum => :patents_count,
:employee => mean => :mean_employee,
:output => mean => :mean_output,
:binary_own => mean => :binary_own,
:cat_pat => mean => :cat_pat) 
extensive_counts_t4![!, :binary_own] = convert.(Int, extensive_counts_t4![!, :binary_own])
extensive_counts_t4![!, :cat_pat] = convert.(Union{Int, Missing}, extensive_counts_t4![!, :cat_pat])
extensive_counts_t4!.cat_pat = categorical(extensive_counts_t4!.cat_pat, ordered = false, compress = true)
extensive_counts_t4!.cat_pat = categorical(extensive_counts_t4!.cat_pat, ordered = true, compress = true)
extensive_counts_t4!.id = categorical(extensive_counts_t4!.id, ordered=false, compress=true)
extensive_counts_t4!.county = categorical(extensive_counts_t4!.county, ordered=false, compress=true)
extensive_counts_t4!.ind4 = categorical(extensive_counts_t4!.ind4, ordered=false, compress=true)


#All data - groups: id, ownership, patent_type, time5
extensive_grouped_t5! = groupby(extensive_df, [:id, :ownership, :patent_type, :county, :ind4, :time5])
extensive_counts_t5! = combine(extensive_grouped_t5!,
:patent_filed => sum => :patents_count,
:employee => mean => :mean_employee,
:output => mean => :mean_output,
:binary_own => mean => :binary_own,
:cat_pat => mean => :cat_pat) 
extensive_counts_t5![!, :binary_own] = convert.(Int, extensive_counts_t5![!, :binary_own])
extensive_counts_t5![!, :cat_pat] = convert.(Union{Int, Missing}, extensive_counts_t5![!, :cat_pat])
extensive_counts_t5!.cat_pat = categorical(extensive_counts_t5!.cat_pat, ordered = false, compress = true)
extensive_counts_t5!.cat_pat = categorical(extensive_counts_t5!.cat_pat, ordered = true, compress = true)
extensive_counts_t5!.id = categorical(extensive_counts_t5!.id, ordered=false, compress=true)
extensive_counts_t5!.county = categorical(extensive_counts_t5!.county, ordered=false, compress=true)
extensive_counts_t5!.ind4 = categorical(extensive_counts_t5!.ind4, ordered=false, compress=true)


#Merged df with groupings 
merged_grouped_1 = groupby(merged_df, [:id, :ownership])
merged_counts_1 = combine(merged_grouped_1,
:patent_filed => sum => :patents_count,
:employee => mean => :mean_employee,
:output => mean => :mean_output,
:binary_own => mean => :binary_own)
merged_counts_1[!, :binary_own] = convert.(Int, merged_counts_1[!, :binary_own])

#Merged df with groupings 
merged_grouped_2 = groupby(merged_df, [:id, :ownership, :patent_type])
merged_counts_2 = combine(merged_grouped_2,
:patent_filed => sum => :patents_count,
:employee => mean => :mean_employee,
:output => mean => :mean_output,
:binary_own => mean => :binary_own,
:cat_pat => mean => :cat_pat)
merged_counts_2[!, :binary_own] = convert.(Int, merged_counts_2[!, :binary_own])


#########################################
# GLM with Extensive Margin + Merged Data
#########################################

#1.1: Ownership => Overall Patent Count (extensive_counts_1)
glm(@formula(patents_count ~ binary_own), extensive_counts_1, Poisson(), LogLink())
    
glm(@formula(patents_count ~ binary_own + mean_output), extensive_counts_1, Poisson(), LogLink())

glm(@formula(patents_count ~ binary_own + mean_employee), extensive_counts_1, Poisson(), LogLink())

#1.2: Ownership => Overall Patent Count over Time w/o Controls 
for i in groupby(extensive_counts_t2, :time2)
    result_i = glm(@formula(patents_count ~ binary_own), i, Poisson(), LogLink()) 
    println(result_i)
end 

for i in groupby(extensive_counts_t3, :time3)
    result_i = glm(@formula(patents_count ~ binary_own), i, Poisson(), LogLink())
    println(result_i)
end 

for i in groupby(extensive_counts_t4, :time4)
    result_i = glm(@formula(patents_count ~ binary_own), i, Poisson(), LogLink())
    println(result_i)
end 

for i in groupby(extensive_counts_t5, :time5)
    result_i = glm(@formula(patents_count ~ binary_own), i, Poisson(), LogLink())
    println(result_i)
end

#1.3 Ownership => Overall Patent Count w/ Controls 
for i in groupby(extensive_counts_t2, :time2)
    result_i = glm(@formula(patents_count ~ binary_own + mean_output), i, Poisson(), LogLink()) 
    println(result_i)
end 

for i in groupby(extensive_counts_t2, :time2)
    result_i = glm(@formula(patents_count ~ binary_own + mean_employee), i, Poisson(), LogLink()) 
    println(result_i)
end 


for i in groupby(extensive_counts_t3, :time3)
    result_i = glm(@formula(patents_count ~ binary_own + mean_output), i, Poisson(), LogLink())
    println(result_i)
end 

for i in groupby(extensive_counts_t3, :time3)
    result_i = glm(@formula(patents_count ~ binary_own + mean_employee), i, Poisson(), LogLink())
    println(result_i)
end 


for i in groupby(extensive_counts_t4, :time4)
    result_i = glm(@formula(patents_count ~ binary_own + mean_output), i, Poisson(), LogLink())
    println(result_i)
end 

for i in groupby(extensive_counts_t4, :time4)
    result_i = glm(@formula(patents_count ~ binary_own + mean_employee), i, Poisson(), LogLink())
    println(result_i)
end 

for i in groupby(extensive_counts_t5, :time5)
    result_i = glm(@formula(patents_count ~ binary_own + mean_output), i, Poisson(), LogLink())
    println(result_i)
end

for i in groupby(extensive_counts_t5, :time5)
    result_i = glm(@formula(patents_count ~ binary_own + mean_employee), i, Poisson(), LogLink())
    println(result_i)
end


#2.1: Ownership => Specific Patent Count
glm(@formula(patents_count ~ binary_own), extensive_counts_2, Poisson(), LogLink())
    
glm(@formula(patents_count ~ binary_own + mean_output), extensive_counts_2, Poisson(), LogLink())

glm(@formula(patents_count ~ binary_own + mean_employee), extensive_counts_2, Poisson(), LogLink())

glm(@formula(patents_count ~ binary_own + binary_own*cat_pat), extensive_counts_2, Poisson(), LogLink())

glm(@formula(patents_count ~ binary_own + binary_own*cat_pat + mean_output), extensive_counts_2, Poisson(), LogLink())
    
glm(@formula(patents_count ~ binary_own + binary_own*cat_pat + mean_employee), extensive_counts_2, Poisson(), LogLink())
    
#2.2: Ownership => Specific Patent Count over Time w/o Controls
for i in groupby(extensive_counts_t2!, :time2)
   result_i = glm(@formula(patents_count ~ binary_own), i, Poisson(), LogLink())
   println(result_i)
end 

for i in groupby(extensive_counts_t3!, :time3)
    result_i = glm(@formula(patents_count ~ binary_own), i, Poisson(), LogLink())
    println(result_i)
end 
 
for i in groupby(extensive_counts_t4!, :time4)
    result_i = glm(@formula(patents_count ~ binary_own), i, Poisson(), LogLink())
    println(result_i)
end

for i in groupby(extensive_counts_t5!, :time5)
    result_i = glm(@formula(patents_count ~ binary_own), i, Poisson(), LogLink()) 
    println(result_i)
end

#2.3: Ownership => Specific Patent Count over Time w/ Controls
for i in groupby(extensive_counts_t2!, :time2)
    result_i = glm(@formula(patents_count ~ binary_own + binary_own*cat_pat), i, Poisson(), LogLink())
    println(result_i)
 end 
 
 for i in groupby(extensive_counts_t3!, :time3)
     result_i = glm(@formula(patents_count ~ binary_own + binary_own*cat_pat), i, Poisson(), LogLink())
     println(result_i)
 end 
  
 for i in groupby(extensive_counts_t4!, :time4)
     result_i = glm(@formula(patents_count ~ binary_own + binary_own*cat_pat), i, Poisson(), LogLink())
     println(result_i)
 end
 
 for i in groupby(extensive_counts_t5!, :time5)
     result_i = glm(@formula(patents_count ~ binary_own + binary_own*cat_pat), i, Poisson(), LogLink()) 
     println(result_i)
 end

 #2.4: Ownership => Specific Patent Count over Time w/ More Controls
 for i in groupby(extensive_counts_t2!, :time2)
    result_i = glm(@formula(patents_count ~ binary_own + binary_own*cat_pat + mean_output), i, Poisson(), LogLink())
    println(result_i)
 end 
 
 for i in groupby(extensive_counts_t3!, :time3)
     result_i = glm(@formula(patents_count ~ binary_own + binary_own*cat_pat + mean_output), i, Poisson(), LogLink())
     println(result_i)
 end 
  
 for i in groupby(extensive_counts_t4!, :time4)
     result_i = glm(@formula(patents_count ~ binary_own + binary_own*cat_pat + mean_output), i, Poisson(), LogLink())
     println(result_i)
 end
 
 for i in groupby(extensive_counts_t5!, :time5)
     result_i = glm(@formula(patents_count ~ binary_own + binary_own*cat_pat + mean_output), i, Poisson(), LogLink()) 
     println(result_i)
 end

#3.1: Ownership => Type of Patent Produced (merged_df, binary dep var)
merged_df = filter(row -> (row.ownership =="SOE" || row.ownership =="Private"), merged_df)
 
glm(@formula(binary_pat ~ binary_own), merged_df, Bernoulli(), LogitLink()) 
 
glm(@formula(binary_pat ~ binary_own + output), merged_df, Bernoulli(), LogitLink())
 
#3.2 Ownership => Type of Patent Produced (merged_df, ordered response model - proportional odds logit) 
merged_df.patent_type = levels!(categorical(merged_df.patent_type, ordered = true, compress = true), ["d", "u", "i"])  
merged_df.patent_type = levels!(categorical(merged_df.patent_type, ordered = true, compress = true), ["u", "d", "i"])

fit(EconometricModel, @formula(patent_type ~ binary_own), merged_df)  
 
#3.3 Ownership => Type of Patent Produced (merged_df, nominal response model - multinomial logit, base d) 
merged_df.patent_type = categorical(merged_df.patent_type, ordered = false, compress = true)  

fit(EconometricModel, @formula(patent_type ~ binary_own), merged_df) 
 
fit(EconometricModel, @formula(patent_type ~ binary_own + output), merged_df) 
 
#3.4: Ownership => Type of Patent Produced over Time (merged_df, binary dep var)
merged_df.time2 = map(time2, merged_df.year)
for i in groupby(merged_df, :time2)
    result_i = glm(@formula(binary_pat ~ binary_own), i, Bernoulli(), LogitLink())  
    println(result_i)
end 

merged_df.time3 = map(time3, merged_df.year)
for i in groupby(merged_df, :time3)
    result_i = glm(@formula(binary_pat ~ binary_own), i, Bernoulli(), LogitLink())
    println(result_i)
end 

merged_df.time4 = map(time4, merged_df.year)
for i in groupby(merged_df, :time4)
    result_i = glm(@formula(binary_pat ~ binary_own), i, Bernoulli(), LogitLink()) 
    println(result_i)
end 

merged_df.time5 = map(time5, merged_df.year)
for i in groupby(merged_df, :time5)
    result_i = glm(@formula(binary_pat ~ binary_own), i, Bernoulli(), LogitLink())
    println(result_i)
end 

#3.5: Ownership => Type of Patent Produced over Time (merged_df, binary dep var + controls)
for i in groupby(merged_df, :time2)
    result_i = glm(@formula(binary_pat ~ binary_own + output), i, Bernoulli(), LogitLink())
    println(result_i)
end 

for i in groupby(merged_df, :time3)
    result_i = glm(@formula(binary_pat ~ binary_own + output), i, Bernoulli(), LogitLink())  
    println(result_i)
end 

for i in groupby(merged_df, :time4)
    result_i = glm(@formula(binary_pat ~ binary_own + output), i, Bernoulli(), LogitLink()) 
    println(result_i)
end 

for i in groupby(merged_df, :time5)
    result_i = glm(@formula(binary_pat ~ binary_own + output), i, Bernoulli(), LogitLink())
    println(result_i)
end 

#3.6: Ownership => Type of Patent Produced over Time (merged_df, ordered dep var - proportional odds logit)
merged_df.patent_type = levels!(categorical(merged_df.patent_type, ordered = true, compress = true), ["d", "u", "i"])  
merged_df.patent_type = levels!(categorical(merged_df.patent_type, ordered = true, compress = true), ["u", "d", "i"])

for i in groupby(merged_df, :time2)
    result_i = fit(EconometricModel, @formula(patent_type ~ binary_own), i)  
    println(result_i)
end 

for i in groupby(merged_df, :time3)
    result_i = fit(EconometricModel, @formula(patent_type ~ binary_own), i)   
    println(result_i)
end 

for i in groupby(merged_df, :time4)
    result_i = fit(EconometricModel, @formula(patent_type ~ binary_own), i)  
    println(result_i)
end 

for i in groupby(merged_df, :time5)
    result_i = fit(EconometricModel, @formula(patent_type ~ binary_own), i)  
    println(result_i)
end 

#3.6: Ownership => Type of Patent Produced over Time (merged_df, ordered dep var + controls)
#N/A

#3.7: Ownership => Type of Patent Produced over Time (merged_df, unordered dep var - nominal response model)
merged_df.patent_type = categorical(merged_df.patent_type, ordered = false, compress = true)  

for i in groupby(merged_df, :time2)
    result_i = fit(EconometricModel, @formula(patent_type ~ binary_own), merged_df) 
    println(result_i)
end 

for i in groupby(merged_df, :time3)
    result_i = fit(EconometricModel, @formula(patent_type ~ binary_own), i)   
    println(result_i)
end 

for i in groupby(merged_df, :time4)
    result_i = fit(EconometricModel, @formula(patent_type ~ binary_own), i)   
    println(result_i)
end 

for i in groupby(merged_df, :time5)
    result_i = fit(EconometricModel, @formula(patent_type ~ binary_own), i)   
    println(result_i)
end 

#3.8: Ownership => Type of Patent Produced over Time (merged_df, unordered dep var + controls)
merged_df.patent_type = categorical(merged_df.patent_type, ordered = false, compress = true)  

for i in groupby(merged_df, :time2)
result_i = fit(EconometricModel, @formula(patent_type ~ binary_own + output), merged_df) 
println(result_i)
end

for i in groupby(merged_df, :time3)
    result_i = fit(EconometricModel, @formula(patent_type ~ binary_own + output), merged_df) 
    println(result_i)
end

for i in groupby(merged_df, :time4)
    result_i = fit(EconometricModel, @formula(patent_type ~ binary_own + output), merged_df) 
    println(result_i)
end
    
for i in groupby(merged_df, :time5)
    result_i = fit(EconometricModel, @formula(patent_type ~ binary_own + output), merged_df) 
    println(result_i)
end
    

#######
#Graphs
#######

#Generating bar graphs for merged_df 
@chain merged_df begin 
groupby(:ownership)
combine(nrow)
select(:nrow)
num_firms = _[!, :nrow]
end 

println(num_firms) 
#[SOE, Foreign, Collective, Private] 
#[157,325; 223,075; 49,137; 245,985]

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
 
bar_firms = bar(ownership, num_firms, 
labels=false, 
xlabel="Ownership",
ylabel="Number of Patents",
title="Types of Firms",
titlefont=font(12),
labelfont=font(12)
)
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

#Estimating probit/logit with binary dep. & ind. variables 
merged_df1 = filter!(row -> row.ownership != "Foreign" && row.ownership != "Collective", 
merged_df)

unique_values = unique(merged_df1.ownership) #Only SOE + Private firms 