# Master's Thesis

## The following page contains the daily record of the research conducted for my master's thesis

### Plain headings are daily entries - highlighted headings are entries specific to supervisory meetings

***

## Feb 24, 2024 (24/02/2024)
I have at my disposal two datasets: the manufacturing firm data given to me by a previous researcher (dataset.1) and the matched firm-patent data downloaded from the Harvard Dataverse (dataset.2). Dataset.2 is tab delimited and has entires with Chinese characters that are garbled. I need to convert dataset.2 into a .csv form and also find a way to ungarble the entries with Chinese characters.

On further research, it might be better to simply read the two delimited files into separate dataframes and then process the Chinese characters once both data sets are in their final format. I'll need to use the CSV package.