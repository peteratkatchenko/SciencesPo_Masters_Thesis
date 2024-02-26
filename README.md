# Master's Thesis

## The following page contains the daily record of the research conducted for my master's thesis

### Plain headings are daily entries - highlighted headings are entries specific to supervisory meetings

***

## Feb 24, 2024 (24/02/2024)
I have at my disposal two datasets: the manufacturing firm data given to me by a previous researcher (dataset.1) and the matched firm-patent data downloaded from the Harvard Dataverse (dataset.2). Dataset.2 is tab delimited and has entires with Chinese characters that are garbled. I need to convert dataset.2 into a .csv form and also find a way to ungarble the entries with Chinese characters.

On further research, it might be better to simply read the two delimited files into separate dataframes and then process the Chinese characters once both data sets are in their final format. I'll need to use the CSV package.

## Feb. 26, 2024 (02/26/2024)
Harvard data does not contain an ownership type variable; I need to find this information elsewhere and match it to the Harvard data.

+ First: Sort Yi's data and confirm if identifiers are applicable to Harvard data; send an email to Yi asking if he has ASIE firm identifiers for the firms in his data set. 
    + On further inspection: the data provided by Yi may be (at least a subset of) the ASIE data that's also found in the Harvard database, in which case the 'fnid' found in Yi's data could match the firm identifiers in the Harvard database. Awaiting reply on the email.

+ Second: if Yi's data is not comparable to the Harvard dataset, then I have to look for other ways of identifying the ownership types of the firms.
    + Option 1: Go back to the ASIE data - it should have the firm identifiers and the ownership type; I had to contact Prof. Zheng for further information on the original ASIE dataset.

I need to be able to differentiate the patents as products of either basic or applied scientific research.    
+ The Harvard dataset is split into invention, design, and utility patents, but it also contains information on the technology classes of the patents; maybe these technology classes can provide a finer granularity for identifying the type of the patent
+ To use this technology class information, I need further information identifying the technology class for each associated code.




