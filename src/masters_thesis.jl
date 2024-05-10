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
using LaTeXTables
using LatexPrint



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

extdf_head = select(extensive_df, :id, :year, :ownership, :ind4, :county, :output, :employee, :patent_type)
extdf_head = first(extdf_head, 5)

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

CSV.write("extensive_counts_2.csv", extensive_counts_2)


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

#=
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
model_1 = glm(@formula(patents_count ~ binary_own), extensive_counts_2, Poisson(), LogLink())

model_2 = glm(@formula(patents_count ~ binary_own + mean_output), extensive_counts_2, Poisson(), LogLink())

model_3 = glm(@formula(patents_count ~ binary_own + mean_employee), extensive_counts_2, Poisson(), LogLink())

model_4 = glm(@formula(patents_count ~ binary_own + binary_own*cat_pat), extensive_counts_2, Poisson(), LogLink())

model_5 = glm(@formula(patents_count ~ binary_own + mean_output + binary_own*cat_pat ), extensive_counts_2, Poisson(), LogLink())

model_6 = glm(@formula(patents_count ~ binary_own + mean_employee + binary_own*cat_pat ), extensive_counts_2, Poisson(), LogLink())


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
    result_i = glm(@formula(patents_count ~ binary_own + binary_own*cat_pat + mean_employee + ind4), i, Poisson(), LogLink())
    println(result_i)
 end 
 
 for i in groupby(extensive_counts_t3!, :time3)
     result_i = glm(@formula(patents_count ~ binary_own + binary_own*cat_pat + mean_employee + ind4), i, Poisson(), LogLink())
     println(result_i)
 end 
  
 for i in groupby(extensive_counts_t4!, :time4)
     result_i = glm(@formula(patents_count ~ binary_own + binary_own*cat_pat + mean_employee + ind4), i, Poisson(), LogLink())
     println(result_i)
 end
 
 for i in groupby(extensive_counts_t5!, :time5)
     result_i = glm(@formula(patents_count ~ binary_own + binary_own*cat_pat + mean_employee + ind4 ), i, Poisson(), LogLink()) 
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
=#

###########
#Bar Graphs
###########

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

############
#Line graphs
############
df = CSV.read("C:\\Users\\peter\\.julia\\dev\\masters_thesis\\china.data\\data_firm_level_china_additional\\ciedata_additional.csv", DataFrame)

df_year = groupby(df, :year)
totalfirms = combine(df_year, nrow => :total_firms, :employee => mean => :mean_employment, :output => (x -> mean(skipmissing(x))) => :mean_output)
year_vec = totalfirms.year
total_firms = totalfirms.total_firms

df_soe = filter(row -> row.ownership == "SOE", df)
dfsoeyear = groupby(df_soe, :year)
totalsoe = combine(dfsoeyear, nrow => :total_soe, :employee => mean => :mean_employment, :output => (x -> mean(skipmissing(x))) => :mean_output)
total_soe = totalsoe.total_soe 

df_priv = filter(row -> row.ownership == "Private", df)
dfprivyear = groupby(df_priv, :year)
totalpriv = combine(dfprivyear, nrow => :total_priv, :employee => mean => :mean_employment, :output => (x -> mean(skipmissing(x))) => :mean_output)
total_priv = totalpriv.total_priv

p1 = plot(year_vec, [total_firms total_soe total_priv],
xlabel = "Year", 
xlabelfontsize=8, ylabelfontsize=8, titlefontsize=10,
legendfontsize=6,
label = ["Both" "SOE" "DPE"],
linewidth = 2, 
color = [:black :red :blue],
title = "a. Total Quantity of Firms",
xticks = (1998:2:2008))

savefig(p1, "plot1.png")

rel_soe = (total_soe) ./ (total_firms)
rel_priv = (total_priv) ./ (total_firms)

p2 = plot(year_vec, [rel_soe rel_priv],
xlabel = "Year",
xlabelfontsize=8, ylabelfontsize=8, titlefontsize=10, 
legendfontsize=6,
label = ["SOE/Total" "Priv/Total"],
linewidth = 2,
color = [:red :blue],
title = "a. Firm Quantity Relative to Total",
xticks = (1998:2:2008))

savefig(p2, "plot2.png")

totaloutput = combine(df_year, :output => (x -> sum(skipmissing(x))) => :total_output)
total_output = totaloutput.total_output

totaloutpriv = combine(dfprivyear, :output => (x -> sum(skipmissing(x))) => :total_outpriv)
total_outpriv = totaloutpriv.total_outpriv

totaloutsoe = combine(dfsoeyear, :output => (x -> sum(skipmissing(x))) => :total_outsoe)
total_outsoe = totaloutsoe.total_outsoe

p3 = plot(year_vec, [total_output total_outsoe total_outpriv],
xlabel = "Year",
xlabelfontsize=8, ylabelfontsize=8, titlefontsize=10,
legendfontsize=6,
label = ["Both" "SOE" "DPE"],
linewidth = 2, 
color = [:black :red :blue],
title = "b. Total Output",
xticks = (1998:2:2008))

savefig(p3, "plot3.png")

rel_soe_output = (total_outsoe) ./ (total_output)
rel_priv_output = (total_outpriv) ./ (total_output)

p4 = plot(year_vec, [rel_soe_output rel_priv_output],
xlabel = "Year",
xlabelfontsize=8, ylabelfontsize=8, titlefontsize=10, 
legendfontsize=6,
label = ["SOE/Total" "DPE/Total"],
linewidth = 2, 
color = [:red :blue],
title = "b. Output Relative to Total",
xticks = (1998:2:2008))

savefig(p4, "plot4.png")

output_per_firm = (total_output) ./ (total_firms)
output_per_soe = (total_outsoe) ./ (total_soe)
output_per_priv = (total_outpriv) ./ (total_priv)

p5 = plot(year_vec, [output_per_firm output_per_soe output_per_priv], 
xlabel = "Year",
xlabelfontsize=8, ylabelfontsize=8, titlefontsize=10,
legendfontsize=6,
label = ["Total Out/Firm" "SOE Out/SOE" "Priv Out/Priv"],
linewidth = 2, color = [:black :red :blue], 
title = "c. Output per Firm (Hundred Thousands)", 
xticks = (1998:2:2008),
yticks = (100000:100000:600000, [1, 2, 3, 4, 5, 6]))

savefig(p5, "plot5.png")

totalemployees = combine(df_year, :employee => sum => :total_employees)
total_employees = totalemployees.total_employees

totalemplsoe = combine(dfsoeyear, :employee => sum => :total_emplsoe)
total_emplsoe = totalemplsoe.total_emplsoe

totalemplpriv = combine(dfprivyear, :employee => sum => :total_emplpriv)
total_emplpriv = totalemplpriv.total_emplpriv

p6 = plot(year_vec, [total_employees total_emplsoe total_emplpriv],
xlabel = "Year", 
xlabelfontsize=8, ylabelfontsize=8, titlefontsize=10, 
legendfontsize=6,
label = ["Both" "SOE" "DPE"],
linewidth = 2, 
color = [:black :red :blue],
title = "c. Total Employment",
xticks = (1998:2:2008))

savefig(p6, "plot6.png")

rel_soe_empl = (total_emplsoe) ./ (total_employees)
rel_priv_empl = (total_emplpriv) ./ (total_employees)

p7 = plot(year_vec, [rel_soe_empl rel_priv_empl],
xlabel = "Year", 
xlabelfontsize=8, ylabelfontsize=8, titlefontsize=10, 
legendfontsize=6,
label = ["SOE/Total" "DPE/Total"],
linewidth = 2, 
color = [:red :blue],
title = "c. Employment Relative to Total", 
xticks = (1998:2:2008))

savefig(p7, "plot7.png")

empl_per_firm = (total_employees) ./ (total_firms)
empl_per_soe = (total_emplsoe) ./ (total_soe)
empl_per_priv = (total_emplpriv) ./ (total_priv)

p8 = plot(year_vec, [empl_per_firm empl_per_soe empl_per_priv], 
xlabel = "Year",  
xlabelfontsize=8, ylabelfontsize=8, titlefontsize=10,
legendfontsize=6,
label = ["Empl/Firm" "SOE Empl/SOE" "Priv Empl/Priv"],
linewidth = 2, color = [:black :red :blue], 
title = "a. Employment per Firm (Hundreds)", 
xticks = (1998:2:2008),
yticks = (200:100:800, [2, 3, 4, 5, 6, 7, 8]))

savefig(p8, "plot8.png")

mgdyear = groupby(merged_df, :year)
totalpatents = combine(mgdyear, nrow => :total_patents)
total_patents = totalpatents.total_patents

mgdsoe = filter(row -> row.ownership == "SOE", merged_df)
mgdsoeyear = groupby(mgdsoe, :year)
totalpatentsoe = combine(mgdsoeyear, nrow => :total_patentsoe)
total_patentsoe = totalpatentsoe.total_patentsoe

mgdpriv = filter(row -> row.ownership == "Private", merged_df)
mgdprivyear = groupby(mgdpriv, :year)
totalpatentpriv = combine(mgdprivyear, nrow => :total_patentpriv)
total_patentpriv = totalpatentpriv.total_patentpriv

p9 = plot(year_vec, [total_patents total_patentsoe total_patentpriv],
xlabel = "Year", 
xlabelfontsize=8, ylabelfontsize=8, titlefontsize=10,
legendfontsize=6,
title = "d. Total Patents",
linewidth = 2,
color = [:black :red :blue], 
label = ["Both" "SOE" "DPE"],
xticks = (1998:2:2008))

savefig(p9, "plot9.png")

rel_soe_patents = (total_patentsoe) ./ (total_patents)
rel_priv_patents = (total_patentpriv) ./ (total_patents)

p10 = plot(year_vec, [rel_soe_patents rel_priv_patents],
xlabel = "Year", 
xlabelfontsize=8, ylabelfontsize=8, titlefontsize=10, 
legendfontsize=6,
title = "d. Patent Count Relative to Total",
linewidth = 2, 
color = [:red :blue], 
label = ["SOE/Total" "DPE/Total"],
xticks = (1998:2:2008))

savefig(p10, "plot10.png")

patents_per_firm = (total_patents) ./ (total_firms)
patents_per_soe = (total_patentsoe) ./ (total_soe)
patents_per_priv = (total_patentpriv) ./ (total_priv)

p11 = plot(year_vec, [patents_per_firm patents_per_soe patents_per_priv],
xlabel = "Year",
xlabelfontsize=8, ylabelfontsize=8, titlefontsize=10,
legendfontsize=6,
label = ["Pat/Firm" "SOE Pat/SOE" "Priv Pat/Priv"],
linewidth = 2, 
color = [:black :red :blue],
title = "e. Patents per Firm",
xticks = (1998:2:2008))

savefig(p11, "plot11.png")

mgdinv = filter(row -> row.patent_type == "i", merged_df)
mgdinvyear = groupby(mgdinv, :year)
invpatents = combine(mgdinvyear, nrow => :invention_patents)
inv_patents = invpatents.invention_patents

mgdinvsoe = filter(row -> row.patent_type == "i" && row.ownership == "SOE", merged_df)
mgdinvsoeyear = groupby(mgdinvsoe, :year)
invpatentsoe = combine(mgdinvsoeyear, nrow => :invention_patentsoe)
inv_patentsoe = invpatentsoe.invention_patentsoe

mgdinvpriv = filter(row -> row.patent_type == "i" && row.ownership == "Private", merged_df)
mgdinvprivyear = groupby(mgdinvpriv, :year)
invpatentpriv = combine(mgdinvprivyear, nrow => :invention_patentpriv)
inv_patentpriv = invpatentpriv.invention_patentpriv

invpatents_per_firm = (inv_patents) ./ (total_firms)
invpatents_per_soe = (inv_patentsoe) ./ (total_soe)
invpatents_per_priv = (inv_patentpriv) ./ (total_priv)

p12 = plot(year_vec, [invpatents_per_firm invpatents_per_soe invpatents_per_priv],
xlabel = "Year", titlefontsize=10, xlabelfontsize=8,
legendfontsize=6, 
label = ["Inv/Firm" "SOE Inv/SOE" "Priv Inv/Priv"],
linewidth = 2, 
color = [:black :red :blue],
title = "b. Invention Patents per Firm",
xticks = (1998:2:2008))

savefig(p12, "plot12.png")

mgduti = filter(row -> row.patent_type == "u", merged_df)
mgdutiyear = groupby(mgduti, :year)
utilitypatents = combine(mgdutiyear, nrow => :utility_patents)
uti_patents = utilitypatents.utility_patents

mgdutisoe = filter(row -> row.patent_type == "u" && row.ownership == "SOE", merged_df)
mgdutisoeyear = groupby(mgdutisoe, :year)
utilitypatentsoe = combine(mgdutisoeyear, nrow => :utility_patentsoe)
uti_patentsoe = utilitypatentsoe.utility_patentsoe

mgdutipriv = filter(row -> row.patent_type == "u" && row.ownership == "Private", merged_df)
mgdutiprivyear = groupby(mgdutipriv, :year)
utilitypatentpriv = combine(mgdutiprivyear, nrow => :utility_patentpriv)
uti_patentpriv = utilitypatentpriv.utility_patentpriv

utipatents_per_firm = (uti_patents) ./ (total_firms)
utipatents_per_soe = (uti_patentsoe) ./ (total_soe)
utipatents_per_priv = (uti_patentpriv) ./ (total_priv)

p13 = plot(year_vec, [utipatents_per_firm utipatents_per_soe utipatents_per_priv],
xlabel = "Year", xlabelfontsize=8, titlefontsize=10,
legendfontsize=6,
label = ["Uti/Firm" "SOE Uti/SOE" "Priv Uti/Priv"],
linewidth = 2, 
color = [:black :red :blue],
title = "d. Utility Patents per Firm", 
xticks = (1998:2:2008))

savefig(p13, "plot13.png")

mgddes = filter(row -> row.patent_type == "d", merged_df)
mgddesyear = groupby(mgddes, :year)
designpatents = combine(mgddesyear, nrow => :design_patents)
des_patents = designpatents.design_patents

mgddessoe = filter(row -> row.patent_type == "d" && row.ownership == "SOE", merged_df)
mgddessoeyear = groupby(mgddessoe, :year)
designpatentsoe = combine(mgddessoeyear, nrow => :design_patentsoe)
des_patentsoe = designpatentsoe.design_patentsoe

mgddespriv = filter(row -> row.patent_type == "d" && row.ownership == "Private", merged_df)
mgddesprivyear = groupby(mgddespriv, :year)
despatentpriv = combine(mgddesprivyear, nrow => :design_patentpriv)
des_patentpriv = despatentpriv.design_patentpriv

despatents_per_firm = (des_patents) ./ (total_firms)
despatents_per_soe = (des_patentsoe) ./ (total_soe)
despatents_per_priv = (des_patentpriv) ./ (total_priv)

p14 = plot(year_vec, [despatents_per_firm despatents_per_soe despatents_per_priv],
xlabel = "Year", xlabelfontsize=8, titlefontsize=10,
legendfontsize=6, 
label = ["Des/Firm" "SOE Des/SOE" "Priv Des/Priv"],
linewidth = 2, 
color = [:black :red :blue],
title = "f. Design Patents per Firm", 
xticks = (1998:2:2008))

savefig(p14, "plot14.png")


p15 = plot(year_vec, [total_patents des_patents uti_patents inv_patents],
xlabel = "Year",
ylabel = "Total Patent Quantity",
title = "Total Quantity of Patents",
linewidth = 2,
color = [:black :green :blue :red], 
label = ["Total Patents" "Total Design Patents" "Total Utility Patents" "Total Invention Patents"],
xticks = (1998:1:2008))

savefig(p15, "plot15.png")

p16 = plot(year_vec, [total_patentsoe des_patentsoe uti_patentsoe inv_patentsoe],
xlabel = "Year", 
ylabel = "Patent Quantity",
title = "SOE Patents by Type", 
linewidth = 2, 
color = [:black :green :blue :red], 
label = ["Total Patents" "Design Patents" "Utility Patents" "Invention Patents"],
xticks = (1998:1:2008))

savefig(p16, "plot16.png")

p17 = plot(year_vec, [total_patentpriv des_patentpriv uti_patentpriv inv_patentpriv],
xlabel = "Year", 
ylabel = "Patent Quantity",
title = "Private Patents by Type", 
linewidth = 2, 
color = [:black :green :blue :red], 
label = ["Total Patents" "Design Patents" "Utility Patents" "Invention Patents"],
xticks = (1998:1:2008))

savefig(p17, "plot17.png")

p18 = plot(year_vec, [inv_patents inv_patentsoe inv_patentpriv],
xlabel = "Year",
ylabel = "Patent Quantity",
title = "Invention Patents by Ownership",
linewidth = 2,
color = [:black :red :blue],
label = ["Total Inv Patents" "SOE Inv Patents" "Priv Inv Patents"],
xticks = (1998:1:2008))

savefig(p18, "plot18.png")

figure_1 = plot(p1, p3, p6, p9, layout=(2,2))
savefig(figure_1, "figure_1.png")

figure_2 = plot(p2, p4, p7, p10, layout=(2,2))
savefig(figure_2, "figure_2.png")

figure_3 = plot(p8, p5, p11, layout=(3,1), size=(450,700))
savefig(figure_3, "figure_3.png")

figure_4 = plot(p12, p13, p14, layout=(3,1), size=(450,700))
savefig(figure_4, "figure_4.png")

figure_5 = plot(p8, p12, p5, p13, p11, p14, layout=(3,2), size=(600,800))
savefig(figure_5, "figure_5.png")


##################
#Descriptive Table
##################
#=
dftable = vcat(dfyear, dfsoe, dfpriv)
dftable = filter(row -> row.year == 1998 || row.year == 2008, dftable)

mgdyear = groupby(merged_df, :year)
mgdyear = combine(mgdyear, nrow => :total_patents)

mgdsoe = filter(row -> row.ownership == "SOE", merged_df)
mgdsoe = groupby(mgdsoe, :year)
mgdsoe = combine(mgdsoe, nrow => :total_patents)

mgdpriv = filter(row -> row.ownership == "Private", merged_df)
mgdpriv = groupby(mgdpriv, :year)
mgdpriv = combine(mgdpriv, nrow => :total_patents)

dftable2 = vcat(mgdyear, mgdsoe, mgdpriv)
dftable2 = filter(row -> row.year == 1998 || row.year == 2008, dftable2)
dftable = hcat(dftable, dftable2, makeunique = true)

mgdyear = groupby(merged_df, :year)
mgdyear = combine(mgdyear, :id => (x -> length(unique(x))) => :total_rdfirms)

mgdsoe = filter(row -> row.ownership == "SOE", merged_df)
mgdsoe = groupby(mgdsoe, :year)
mgdsoe = combine(mgdsoe, :id => (x -> length(unique(x))) => :total_rdfirms)

mgdpriv = filter(row -> row.ownership == "Private", merged_df)
mgdpriv = groupby(mgdpriv, :year)
mgdpriv = combine(mgdpriv, :id => (x -> length(unique(x))) => :total_rdfirms)

dftable3 = vcat(mgdyear, mgdsoe, mgdpriv)
dftable3 = filter(row -> row.year == 1998 || row.year == 2008, dftable3)
dftable = hcat(dftable, dftable3, makeunique = true)
dftable = select(dftable, :year, :total_firms, :total_rdfirms, :mean_employment, :mean_output, :total_patents)
rename!(dftable, "year" => "Year", "total_firms" => "Total Firms", "total_rdfirms" => "Total RD Firms", 
"mean_employment" => "Mean Employment", "mean_output" => "Mean Output", "total_patents" => "Total Patents")

pretty_table(dftable, backend = Val(:latex), alignment = :c)
=#