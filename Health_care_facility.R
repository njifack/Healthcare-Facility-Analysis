
# load libaries
library(dplyr)
library(tidyr)
library(tibble)
library(ggplot2)
library(DBI)
library(RSQLite)

# Data analysis & exploration

# load data tables
bed_fact_tab <- read.csv("bed_fact.csv")
bed_type_tab <- read.csv("bed_type.csv")
business_tab <- read.csv("business.csv")

# data summary
head(bed_fact_tab)
summary(bed_fact_tab)

head(bed_type_tab)
summary(bed_type_tab)

head(business_tab)
summary(business_tab)

# check outliers outliers 

boxplot(bed_fact_tab$license_beds, main="License Beds")
boxplot(bed_fact_tab$census_beds, main="Census Beds")
boxplot(bed_fact_tab$staffed_beds, main="Staffed Beds")

# remove outliers using interquatile range 

remove_outliers <- function(x) {
  Q1 <- quantile(x, 0.25)
  Q3 <- quantile(x, 0.75)
  IQR <- Q3 - Q1
  lower_bound <- Q1 - 1.5 * IQR
  upper_bound <- Q3 + 1.5 * IQR
  return(ifelse(x >= lower_bound & x <= upper_bound, x, NA))
}
# Remove outliers from license_beds, census_beds, and staffed_beds columns
bed_fact_tab_cleaned <- bed_fact_tab %>%
  mutate(
    license_beds = remove_outliers(license_beds),
    census_beds = remove_outliers(census_beds),
    staffed_beds = remove_outliers(staffed_beds)
  )

# Remove rows with NA values
bed_fact_tab_cleaned <- bed_fact_tab_cleaned %>%
  drop_na()

# Check the shape of the original and cleaned dataframe
cat("Shape of original dataframe (bed_fact_df):\n")
cat(dim(bed_fact_tab), "\n")
cat("Shape of cleaned dataframe (bed_fact_df_cleaned):\n")
cat(dim(bed_fact_tab_cleaned), "\n")

# Visualize boxplots after removing outliers
boxplot(bed_fact_tab_cleaned$license_beds, main="License Beds (No Outliers)")
boxplot(bed_fact_tab_cleaned$census_beds, main="Census Beds (No Outliers)")
boxplot(bed_fact_tab_cleaned$staffed_beds, main="Staffed Beds (No Outliers)")


# Identify the dimensions from each dimension table

For the bed_type table:  

- Fact: None     
- Dimensions: bed_id, bed_code, and bed_desc   

For the business_csv table:

- Dimensions: ims_org_id, business_name, and bed_cluster_id.  

# Identify the Facts variables from the single Fact Table 

For bed_fact table: 

- Facts: license_beds, census_beds and staffed_beds.    

# Analysis for Leadership

# Create SQLite connection and register data frames
con <- dbConnect(RSQLite::SQLite(), dbname = ":memory:")
dbWriteTable(con, "bed_fact_tab", bed_fact_tab)
dbWriteTable(con, "bed_type_tab", bed_type_tab)
dbWriteTable(con, "business_tab", business_tab)
dbWriteTable(con, "bed_fact_tab_cleaned", bed_fact_tab_cleaned)
dbWriteTable(con, "icu_sicu_beds", icu_sicu_beds)

# Identify which hospitals have an ICU bed  or a SICU bed.

query <- "
  SELECT bed_fact_tab_cleaned.*, 
    bed_type_tab.bed_code,
    bed_type_tab.bed_desc
  FROM bed_fact_tab_cleaned
  LEFT JOIN bed_type_tab ON bed_fact_tab_cleaned.bed_id = bed_type_tab.bed_id
"
icu_sicu_beds <- dbGetQuery(con, query)

icu_sicu_beds <- icu_sicu_beds[icu_sicu_beds$bed_id %in% c(4, 15), ]
icu_sicu_beds


# Perform left join between business_tab and icu_sicu_beds
query <- "
  SELECT business_tab.*,
    icu_sicu_beds.bed_id,
    license_beds,
    census_beds,
    staffed_beds,
    bed_code,
    bed_desc
  FROM business_tab 
  LEFT JOIN icu_sicu_beds ON business_tab.ims_org_id = icu_sicu_beds.ims_org_id
"
summary_data_icu_sicu_beds <- dbGetQuery(con, query)

# Remove duplicates 
summary_data_icu_sicu_beds <- summary_data_icu_sicu_beds[!duplicated(summary_data_icu_sicu_beds$business_name), ]

dbWriteTable(con, "summary_data_icu_sicu_beds", summary_data_icu_sicu_beds)

# 1.License beds:
query <- "
SELECT business_name, ttl_license_beds
FROM summary_data_icu_sicu_beds
ORDER BY ttl_license_beds DESC
LIMIT 10;
"
license_beds_hospitals <- dbGetQuery(con, query)
license_beds_hospitals

# 2.Census beds:
query <- "
SELECT business_name, ttl_census_beds
FROM summary_data_icu_sicu_beds
ORDER BY ttl_census_beds DESC
LIMIT 10;
"
census_beds_hospitals <- dbGetQuery(con, query)
census_beds_hospitals

# 3.Staffed beds:

query <-"SELECT business_name, ttl_staffed_beds
FROM summary_data_icu_sicu_beds
ORDER BY ttl_staffed_beds DESC
LIMIT 10;
"
staffed_beds_hospitals <- dbGetQuery(con, query)
staffed_beds_hospitals

# Close the SQLite connection
dbDisconnect(con)


#Interpretation of Findings 

#Florida State Hospital has the highest number of licensed beds among all hospitals.  

#Patton State Hospital has the highest number of census beds and staffed beds.   

#Florida State Hospital, Jackson Memorial Hospital, and The Cleveland Clinic Foundation are among the top 10 
#hospitals with the highest number of licensed beds, census beds, and staffed beds.  

# Drill down investigation 

# Create SQLite connection and register data frames
con <- dbConnect(RSQLite::SQLite(), dbname = ":memory:")
dbWriteTable(con, "bed_fact_tab", bed_fact_tab)
dbWriteTable(con, "bed_type_tab", bed_type_tab)
dbWriteTable(con, "business_tab", business_tab)
dbWriteTable(con, "bed_fact_tab_cleaned", bed_fact_tab_cleaned)
dbWriteTable(con, "hospitals_with_both_icu_sicu", hospitals_with_both_icu_sicu)
dbWriteTable(con, "summary_data_both_icu_sicu", summary_data_both_icu_sicu)

# Identify hospitals with both ICU and SICU beds
query <- "
  SELECT ims_org_id
  FROM bed_fact_tab_cleaned
  WHERE bed_id IN (4, 15)
  GROUP BY ims_org_id
  HAVING COUNT(DISTINCT bed_id) = 2
"
hospitals_with_both_icu_sicu <- dbGetQuery(con, query)

# Perform left join between business_tab and hospitals_with_both_icu_sicu
query <- "
  SELECT business_tab.*,
    bed_fact_tab_cleaned.bed_id,
    license_beds,
    census_beds,
    staffed_beds
  FROM business_tab 
  LEFT JOIN bed_fact_tab_cleaned ON business_tab.ims_org_id = bed_fact_tab_cleaned.ims_org_id
  WHERE bed_fact_tab_cleaned.ims_org_id IN (SELECT ims_org_id FROM hospitals_with_both_icu_sicu)
"
summary_data_both_icu_sicu <- dbGetQuery(con, query)

# Remove duplicates 
summary_data_both_icu_sicu <- summary_data_both_icu_sicu[!duplicated(summary_data_both_icu_sicu$business_name), ]

# Summary report for License beds
query <- "
  SELECT business_name, SUM(license_beds) AS total_license_beds
  FROM summary_data_both_icu_sicu
  GROUP BY business_name
  ORDER BY total_license_beds DESC
  LIMIT 10
"
license_beds_both_icu_sicu <- dbGetQuery(con, query)
license_beds_both_icu_sicu
# Summary report for Census beds
query <- "
  SELECT business_name, SUM(census_beds) AS total_census_beds
  FROM summary_data_both_icu_sicu
  GROUP BY business_name
  ORDER BY total_census_beds DESC
  LIMIT 10
"
census_beds_both_icu_sicu <- dbGetQuery(con, query)
census_beds_both_icu_sicu
# Summary report for Staffed beds
query <- "
  SELECT business_name, SUM(staffed_beds) AS total_staffed_beds
  FROM summary_data_both_icu_sicu
  GROUP BY business_name
  ORDER BY total_staffed_beds DESC
  LIMIT 10
"
staffed_beds_both_icu_sicu <- dbGetQuery(con, query)
staffed_beds_both_icu_sicu

# Close the SQLite connection
dbDisconnect(con)


