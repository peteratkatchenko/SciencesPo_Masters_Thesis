module masters_thesis

using CSV
using DataFrames
using Plots
using Pipe 
using TabularDisplay
using PrettyTables

# Generate a dataframe for each of the datasets needed for the analysis
# df: CIE data with firm identifiers and firm types
# df_asie_i: matched firms with patents + CIE firm identifiers (invention patents)
# df_asie_d: matched firms with patents + CIE firm identifiers (design patents)
# df_asie_u: matched firms with patents + CIE firm identifiers (utility patents)

df = DataFrame(CSV.File("C:\\Users\\peter\\.julia\\dev\\masters_thesis\\china.data\\additional_firm_id\\ciedata_additional.csv"))
pretty_table(df)

df_asie_i = DataFrame(CSV.File("C:\\Users\\peter\\.julia\\dev\\masters_thesis\\china.data\\matched_chinese_firm_patent_data\\ASIE firms matched to invention patents.csv"))
pretty_table(df_asie_i)

df_asie_d = DataFrame(CSV.File("C:\\Users\\peter\\.julia\\dev\\masters_thesis\\china.data\\matched_chinese_firm_patent_data\\ASIE firms matched to design patents.csv"))
pretty_table(df_asie_d)

df_asie_u = DataFrame(CSV.File("C:\\Users\\peter\\.julia\\dev\\masters_thesis\\china.data\\matched_chinese_firm_patent_data\\ASIE firms matched to utility model patents.csv"))
pretty_table(df_asie_u)

# Vertically concatenate the matched patent dataframes to obtain a single matched firm-patent dataframe 
# firm_patent: total firm-patent matches for all patent types 

firm_patent = vcat(df_asie_i, df_asie_d, df_asie_u)

# Identify the firm type for each observation by matching CIE observations to firm-patent observations 
# using firm identifier




































end # module masters_thesis
