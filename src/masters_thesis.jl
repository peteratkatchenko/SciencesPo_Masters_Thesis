module masters_thesis

using CSV
using DataFrames
using Plots
using Pipe 
using TabularDisplay
using PrettyTables

df = DataFrame(CSV.File("C:\\Users\\peter\\.julia\\environments\\masters_thesis\\china_data\\data_firm_level_china\\ciedata.csv"))
pretty_table(df)


df_asie_i = DataFrame(CSV.File("C:\\Users\\peter\\.julia\\environments\\masters_thesis\\china_data\\matched_chinese_firm_patent_data\\ASIE firms matched to invention patents.csv"))
pretty_table(df_asie_i)

df_asie_d = DataFrame(CSV.File("C:\\Users\\peter\\.julia\\environments\\masters_thesis\\china_data\\matched_chinese_firm_patent_data\\ASIE firms matched to design patents.csv"))
pretty_table(df_asie_d)

df_asie_u = DataFrame(CSV.File("C:\\Users\\peter\\.julia\\environments\\masters_thesis\\china_data\\matched_chinese_firm_patent_data\\ASIE firms matched to utility model patents.csv"))
pretty_table(df_asie_u)






end # module masters_thesis
