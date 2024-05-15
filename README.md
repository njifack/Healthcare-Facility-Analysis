# Healthcare Facility Analysis

This project aims to analyze and explore data related to healthcare facilities, including bed capacities and business information. The analysis involves data cleaning, summary statistics, and outlier detection.

## Libraries Used

The following R libraries are used for data manipulation, visualization, and database interaction:

- dplyr
- tidyr
- tibble
- ggplot2
- DBI
- RSQLite

## Data Analysis & Exploration

### Loading Data Tables

The project starts by loading three data tables:

- `bed_fact_tab`: Facts about bed capacities in healthcare facilities.
- `bed_type_tab`: Information about bed types in healthcare facilities.
- `business_tab`: Business-related data for healthcare facilities.

### Summary Statistics

Summary statistics are generated for each data table to understand the data distribution and characteristics.

### Outlier Detection

Outliers in the `bed_fact_tab` table are identified using boxplots and the interquartile range (IQR) method. Outliers are removed from the columns `license_beds`, `census_beds`, and `staffed_beds`.

### Data Cleaning

Rows containing NA values after outlier removal are dropped to ensure data integrity.

### Visualization

Boxplots are generated to visualize the distribution of bed capacities (`license_beds`, `census_beds`, `staffed_beds`) after outlier removal.

## How to Use

1. **Requirements**: Ensure you have R installed on your system.
2. **Setup Environment**: Install the required libraries listed in the "Libraries Used" section.
3. **Run the Code**: Execute the R script to load the data, perform analysis, and visualize the results.

