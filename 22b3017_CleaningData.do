cd /Users/jastejsingh/Desktop/ramapal/newproject
clear all


***************************** Work with 2025 Data ******************************

use clean_data/25-data.dta, clear

keep if inlist(st, 28,36,22,33,21,29, 27)
keep if sex == 2
keep if age >=18 & age <=59

* CWS status
gen is_worker = 1 if acws >=11 & acws<=82 
replace is_worker = 0 if is_worker == .

tab is_worker

*** Controls
* Marital Status (marst)
* current education status (curr_att)

gen edu_status = 0 if inlist(curr_att, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15)
replace edu_status = 1 if edu_status == .

rename marst married
rename gedu_lvl edu
rename age age
rename sex sex
rename acws cws
rename st state
rename nss_reg nss_region

*** Make a time variable yq
gen year = 2025

gen quarter = .
replace quarter = 1 if qtr == "Q7" | qtr == "Q3"
replace quarter = 2 if qtr == "Q8" | qtr == "Q4"
replace quarter = 3 if qtr == "Q5" | qtr == "Q1"
replace quarter = 4 if qtr == "Q6"| qtr == "Q2"

gen yq = yq(year, quarter)
format yq %tq

*** Weights (from Readme file)
gen weight = mult / 100 

*** Merge with household data for MPCE
* 2025 merge keys: sec, state(renamed from st), mfsu, sss, ssu, qtr
preserve
use RawData/2025data/hh_2025.dta, clear
keep sec st mfsu sss ssu qtr hce_tot hh_size
rename st state
gen mpce = hce_tot / hh_size
keep sec state mfsu sss ssu qtr mpce hh_size
duplicates drop sec state mfsu sss ssu qtr, force
save clean_data/hh_2025_merge.dta, replace
restore

merge m:1 sec state mfsu sss ssu qtr using clean_data/hh_2025_merge.dta
tab _merge
drop if _merge == 2
drop _merge

* Keep only analysis variables + mpce
keep is_worker state nss_region age married edu cws yq weight edu_status mpce hh_size

label define laborforce_lbl 1 "In Labour Force" 0 "Not in Labour Force"
label values is_worker laborforce_lbl
label variable is_worker "1 if individual part of labour force"
label define married_lbl 1 "Never Married" 2 "Currently married" 3 "widowed" 4 "divorced/separated"
label values married married_lbl
label variable weight "Multiplier"
label variable yq "year and quarter"
label variable edu "General Education Level"
label define edu_status_lbl 1 "Currently attending" 0 "Currently not attending"
label values edu_status edu_status_lbl
label variable edu_status "Current education status"
label variable mpce "Monthly Per Capita Expenditure"
sort yq state nss_region 

save clean_data/2025data_clean.dta, replace


***************************** Work with 2024 Data ******************************

use clean_data/24-data.dta, clear

keep if inlist(state_ut_code, 28,36,22,33,21,29,27)
keep if sex == 2
keep if age >=18 & age <=59

* CWS status
gen is_worker = 1 if cws_status_code >=11 & cws_status_code<=82 
replace is_worker = 0 if is_worker == .

tab is_worker

*** Controls
gen edu_status = 0 if inlist(current_attendance_status, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15)
replace edu_status = 1 if edu_status == .

rename marital_status married
rename general_education_level edu
rename age age
rename sex sex
rename cws_status_code cws
rename state_ut_code state
rename nss_region nss_region
rename quarter qtr
rename sector sec
rename fsu mfsu

*** Make a time variable yq
gen year = 2024

gen quarter = .
replace quarter = 1 if qtr == "Q7" | qtr == "Q3"
replace quarter = 2 if qtr == "Q8" | qtr == "Q4"
replace quarter = 3 if qtr == "Q5" | qtr == "Q1"
replace quarter = 4 if qtr == "Q6" | qtr == "Q2"

gen yq = yq(year, quarter)
format yq %tq

*** Weights (from Readme file)
gen weight = subsample_multiplier / 100 

*** Merge with household data for MPCE
* 2024 merge keys: sec, state(renamed from state_ut_code), mfsu, 
*   second_stage_stratum_no, sample_household_number, qtr
preserve
use RawData/2024data/hh_2024.dta, clear
rename sector sec
rename fsu mfsu
rename quarter qtr 
rename state_ut_code state
rename household_size hh_size
rename monthly_consumer_expenditure hce_tot
keep sec state mfsu second_stage_stratum_no sample_household_number qtr hce_tot hh_size
gen mpce = hce_tot / hh_size
keep sec state mfsu second_stage_stratum_no sample_household_number qtr mpce hh_size
duplicates drop sec state mfsu second_stage_stratum_no sample_household_number qtr, force
save clean_data/hh_2024_merge.dta, replace
restore

merge m:1 sec state mfsu second_stage_stratum_no sample_household_number qtr ///
    using clean_data/hh_2024_merge.dta
tab _merge
drop if _merge == 2
drop _merge

* Keep only analysis variables + mpce
keep is_worker state nss_region age married edu cws yq weight edu_status mpce hh_size

label values is_worker laborforce_lbl
label variable is_worker "1 if individual part of labour force"
label values married married_lbl
label variable weight "Multiplier"
label variable yq "year and quarter"
label variable edu "General Education Level"
label values edu_status edu_status_lbl
label variable edu_status "Current education status"
label variable mpce "Monthly Per Capita Expenditure"
sort yq state nss_region 

save clean_data/2024data_clean.dta, replace


***************************** Work with 2023 Data ******************************

use RawData/mergednew202324.dta, clear

keep if visit == "V1"
keep if inlist(state, 28,36,22,33,21,29,27)
keep if b4q5 == 2
keep if b4q6 >=18 & b4q6 <=59

* Create indicator for labour force (b6q5 in 11-82)
gen is_worker = 1 if b6q5 >=11 & b6q5<=82 
replace is_worker = 0 if is_worker == .

tab is_worker
tab b6q5

/*****
Individual level control varying over time/not varying- (We cannot include individual fixed effects)

Marital Status- b4q7
education status - b4q11
*/
gen edu_status = 0 if inlist(b4q11, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15)
replace edu_status = 1 if edu_status == .

rename b4q6 age
rename b4q7 married
rename b4q8 edu
rename b6q5 cws

*** Make a time variable yq
gen year = 2023
replace year = 2024 if qtr == "Q3" | qtr == "Q4"

gen quarter = .
replace quarter = 1 if qtr == "Q7" | qtr == "Q3"
replace quarter = 2 if qtr == "Q8" | qtr == "Q4"
replace quarter = 3 if qtr == "Q5" | qtr == "Q1"
replace quarter = 4 if qtr == "Q6" | qtr == "Q2"

drop if year == 2024 // eariler dataset has 2024 data

gen yq = yq(year, quarter)
format yq %tq

*** Weights (from Readme file)
gen weight = mult / 100 if NSS == NSC
replace weight = mult / 200 if NSS != NSC

*** Merge with household data for MPCE
* 2023-24 merge keys: b1q3(sec), state, b1q1(fsu), b1q14(sss), b1q15(ssu), qtr
preserve
use RawData/2023data/hh_202324.dta, clear
rename *_hhv1 *
rename b3q5pt6 hce_tot
rename b3q1 hh_size
destring _all, replace
keep b1q3 state b1q1 b1q14 b1q15 qtr hce_tot hh_size
gen mpce = hce_tot / hh_size
keep b1q3 state b1q1 b1q14 b1q15 qtr mpce hh_size
duplicates drop b1q3 state b1q1 b1q14 b1q15 qtr, force
save clean_data/hh_2023_merge.dta, replace
restore

merge m:1 b1q3 state b1q1 b1q14 b1q15 qtr using clean_data/hh_2023_merge.dta
tab _merge
drop if _merge == 2
drop _merge

* Keep only analysis variables + mpce
keep is_worker state nss_region age married edu cws yq weight edu_status mpce hh_size

label values is_worker laborforce_lbl
label variable is_worker "1 if individual part of labour force"
label values married married_lbl
label variable weight "Multiplier"
label variable yq "year and quarter"
label variable edu "Years of Formal education"
label values edu_status edu_status_lbl
label variable edu_status "Current education status"
label variable mpce "Monthly Per Capita Expenditure"
sort yq state nss_region 

save clean_data/2023data_clean.dta, replace


***************************** Work with 2022 Data ******************************

use RawData/mergednew202223.dta, clear

keep if visit == "V1"
keep if inlist(state, 28,36,22,33,21,29,27)
keep if b4q5 == 2
keep if b4q6 >=18 & b4q6 <=59

* Create indicator for labour force (b6q5 in 11-82)
gen is_worker = 1 if b6q5 >=11 & b6q5<=82 
replace is_worker = 0 if is_worker == .

tab is_worker
tab b6q5

/*****
Individual level control varying over time/not varying- (We cannot include individual fixed effects)

Marital Status- b4q7
*/
gen edu_status = 0 if inlist(b4q11, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15)
replace edu_status = 1 if edu_status == .

rename b4q6 age
rename b4q7 married
rename b4q8 edu
rename b6q5 cws

*** Make a time variable yq
gen year = 2022
replace year = 2023 if qtr == "Q7" | qtr == "Q8"

gen quarter = .
replace quarter = 1 if qtr == "Q7" | qtr == "Q3"
replace quarter = 2 if qtr == "Q8" | qtr == "Q4"
replace quarter = 3 if qtr == "Q5" | qtr == "Q1"
replace quarter = 4 if qtr == "Q6"| qtr == "Q2"

gen yq = yq(year, quarter)
format yq %tq

*** Weights (from Readme file)
gen weight = mult / 100 if NSS == NSC
replace weight = mult / 200 if NSS != NSC

*** Merge with household data for MPCE
* 2022-23 merge keys: b1q3(sec), state, b1q1(fsu), b1q14(sss), b1q15(ssu), qtr
preserve
use RawData/2022data/hh_202223.dta, clear
rename *_hhv1 *
rename b3q5pt6 hce_tot
rename b3q1 hh_size
destring _all, replace
keep b1q3 state b1q1 b1q14 b1q15 qtr hce_tot hh_size
gen mpce = hce_tot / hh_size
keep b1q3 state b1q1 b1q14 b1q15 qtr mpce hh_size
duplicates drop b1q3 state b1q1 b1q14 b1q15 qtr, force
save clean_data/hh_2022_merge.dta, replace
restore

merge m:1 b1q3 state b1q1 b1q14 b1q15 qtr using clean_data/hh_2022_merge.dta
tab _merge
drop if _merge == 2
drop _merge

* Keep only analysis variables + mpce
keep is_worker state nss_region age married edu cws yq weight edu_status mpce hh_size

label values is_worker laborforce_lbl
label variable is_worker "1 if individual part of labour force"
label values married married_lbl
label variable weight "Multiplier"
label variable yq "year and quarter"
label variable edu "General Education Level"
label values edu_status edu_status_lbl
label variable edu_status "Current education status"
label variable mpce "Monthly Per Capita Expenditure"
sort yq state nss_region 

save clean_data/2022data_clean.dta, replace

***************************** Work with 2022 Data q1 q2 ************************


use RawData/2022data/cperv1_clean.dta, clear
recast int state_cperv1
rename *_cperv1 *
destring _all, replace

drop if qtr == "Q5" 
drop if qtr == "Q6" 


keep if visit == "V1"
keep if inlist(state, 26,34,21,31,20,27,25)
recode state (34 = 36) (26 = 28) (21=22) (31=33) (20=21) (27=29) (25 = 27)

keep if b4q5 == 1
keep if b4q6 >=18 & b4q6 <=59

* Create indicator for labour force (b6q5 in 11-82)
gen is_worker = 1 if b6q5 >=11 & b6q5<=82 
replace is_worker = 0 if is_worker == .

tab is_worker
tab b6q5

/*****
Individual level control varying over time/not varying- (We cannot include individual fixed effects)

Marital Status- b4q7
*/
gen edu_status = 0 if inlist(b4q11, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15)
replace edu_status = 1 if edu_status == .

rename b4q6 age
rename b4q7 married
rename b4q8 edu
rename b6q5 cws

*** Make a time variable yq
gen year = 2022

gen quarter = .
replace quarter = 1 if qtr == "Q7" | qtr == "Q3"
replace quarter = 2 if qtr == "Q8" | qtr == "Q4"
replace quarter = 3 if qtr == "Q5" | qtr == "Q1"
replace quarter = 4 if qtr == "Q6"| qtr == "Q2"

gen yq = yq(year, quarter)
format yq %tq

*** Weights (from Readme file)
gen weight = mult / 100 if nss == nsc
replace weight = mult / 200 if nss != nsc

*** Merge with household data for MPCE
* 2022-23 merge keys: b1q3(sec), state, b1q1(fsu), b1q14(sss), b1q15(ssu), qtr
preserve
use RawData/2022data/hh_202223.dta, clear
rename *_hhv1 *
destring _all, replace
rename b3q5pt6 hce_tot
rename b3q1 hh_size
recode state (34 = 36) (26 = 28) (21=22) (31=33) (20=21) (27=29) (25 = 27)
keep b1q3 state b1q1 b1q14 b1q15 qtr hce_tot hh_size
gen mpce = hce_tot / hh_size
keep b1q3 state b1q1 b1q14 b1q15 qtr mpce hh_size
duplicates drop b1q3 state b1q1 b1q14 b1q15 qtr, force
save clean_data/hh_2022q12_merge.dta, replace
restore

preserve
use clean_data/hh_2022q12_merge.dta, clear
describe b1q3 state b1q1 b1q14 b1q15 qtr
restore
describe b1q3 state b1q1 b1q14 b1q15 qtr

merge m:1 b1q3 state b1q1 b1q14 b1q15 qtr using clean_data/hh_2022q12_merge.dta
tab _merge
drop if _merge == 2
drop _merge

* Keep only analysis variables + mpce
keep is_worker state nss_region age married edu cws yq weight edu_status mpce hh_size

label values is_worker laborforce_lbl
label variable is_worker "1 if individual part of labour force"
label values married married_lbl
label variable weight "Multiplier"
label variable yq "year and quarter"
label variable edu "General Education Level"
label values edu_status edu_status_lbl
label variable edu_status "Current education status"
label variable mpce "Monthly Per Capita Expenditure"
sort yq state nss_region 

save clean_data/2022data_cleanq12.dta, replace

***************************** Work with 2021 Data ************************

use RawData/2021data/cperv1.dta, clear

rename *_cperv1 *
destring _all, replace


keep if visit == "V1"
keep if inlist(state, 28,36,22,33,21,29,27)
keep if b4q5 == 2
keep if b4q6 >=18 & b4q6 <=59

* Create indicator for labour force (b6q5 in 11-82)
gen is_worker = 1 if b6q5 >=11 & b6q5<=82 
replace is_worker = 0 if is_worker == .

tab is_worker
tab b6q5

/*****
Individual level control varying over time/not varying- (We cannot include individual fixed effects)

Marital Status- b4q7
*/


rename b4q6 age
rename b6q5 cws

*** Make a time variable yq
gen year = 2021

gen quarter = .
replace quarter = 1 if qtr == "Q7" | qtr == "Q3"
replace quarter = 2 if qtr == "Q8" | qtr == "Q4"
replace quarter = 3 if qtr == "Q5" | qtr == "Q1"
replace quarter = 4 if qtr == "Q6"| qtr == "Q2"

gen yq = yq(year, quarter)
format yq %tq

*** Weights (from Readme file)
gen weight = mult / 100 if nss == nsc
replace weight = mult / 200 if nss != nsc

*** Merge with household data for MPCE
* 2022-23 merge keys: b1q3(sec), state, b1q1(fsu), b1q14(sss), b1q15(ssu), qtr
preserve
use RawData/2021data/hhv1.dta, clear
rename *_chhv1 *
rename b3q5pt6 hce_tot
rename b3q1 hh_size
destring _all, replace
keep b1q3 state b1q1 b1q14 b1q15 qtr hce_tot hh_size
gen mpce = hce_tot / hh_size
keep b1q3 state b1q1 b1q14 b1q15 qtr mpce hh_size
duplicates drop b1q3 state b1q1 b1q14 b1q15 qtr, force
save clean_data/hh_2022_merge.dta, replace
restore

merge m:1 b1q3 state b1q1 b1q14 b1q15 qtr using clean_data/hh_2022_merge.dta
tab _merge
drop if _merge == 2
drop _merge

* Keep only analysis variables + mpce
keep is_worker state nss_region age   cws yq weight mpce hh_size

label values is_worker laborforce_lbl
label variable is_worker "1 if individual part of labour force"
//label values married married_lbl
label variable weight "Multiplier"
label variable yq "year and quarter"
//label variable edu "General Education Level"
//label values edu_status edu_status_lbl
//label variable edu_status "Current education status"
label variable mpce "Monthly Per Capita Expenditure"
sort yq state nss_region 

save clean_data/2021data_clean.dta, replace


****************************** Merging 4 years Data ****************************

use clean_data/2021data_clean.dta, clear 

append using clean_data/2022data_cleanq12.dta
append using clean_data/2022data_clean.dta
append using clean_data/2023data_clean.dta
append using clean_data/2024data_clean.dta
append using clean_data/2025data_clean.dta

* Check MPCE merge success
tab yq if mpce == ., missing
sum mpce, detail

save clean_data/complete_clean_data.dta, replace


***************** End of Data Cleaning Process *********************************
********************************************************************************
