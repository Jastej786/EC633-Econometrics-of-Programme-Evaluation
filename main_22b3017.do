** ssc install estout, replace


cd /Users/jastejsingh/Desktop/ramapal/newproject


use complete_clean_data.dta, clear
//sort yq state nss_region mpce
gen year = year(dofq(yq))
keep if state == 28 |state ==36 
//drop if state == 28
//drop if yq == tq(2025q4)
gen mpce_q = .
levelsof yq, local(periods)
foreach p of local periods {
    xtile temp = mpce if yq == `p', nquantiles(8)
    replace mpce_q = temp if yq == `p'
    drop temp
}



** Define treatment variable
gen post_treat = 0 if yq <= tq(2023q4)
replace post_treat = 1 if post_treat == .

gen treat_state = 1 if state == 36
replace treat_state = 0 if treat_state == .

gen treat = treat_state*post_treat

label variable treat "Treatment/Policy"
label variable post_treat " 1. for post treatment Period, 0 otherwise"
label variable treat_state " 1. for treatment state, 0 otherwise"

* Generate a unique individual ID for the full panel (needed for merging later)
gen id = _n

* Log MPCE for regression (better behaved than levels)
gen ln_mpce = ln(mpce)

save complete_analysis_data.dta, replace
local covariates "age mpce hh_size"

///keep if mpce_q <=4

*=======================================================================
* PARALLEL TRENDS and TEST
*=======================================================================

preserve
collapse (mean) is_worker [pw=weight], by(yq treat_state)

twoway ///
    (connected is_worker yq if treat_state == 0, ///
        lcolor(blue) mcolor(blue) msymbol(circle) lwidth(medium)) ///
    (connected is_worker yq if treat_state == 1, ///
        lcolor(red) mcolor(red) msymbol(triangle) lwidth(medium) lpattern(dash)), ///
    xline(`=tq(2023q4)', lcolor(gs8) lpattern(dot) lwidth(medium)) ///
    legend(order(1 "Andhra Pradesh (Control)" 2 "Telangana (Treated)") position(6) rows(1)) ///
    title("Parallel Trends", size(medium)) ///
    subtitle("Average Labor Force Participation by Year-Quarter") ///
    xtitle("Year-Quarter") ///
    ytitle("Share in Labor Force") ///
    ylabel(, format(%9.2f)) ///
    graphregion(color(white)) plotregion(color(white))

graph export "graphs/parallel_trends_unmatched.png", replace

restore





preserve
keep if yq >tq(2022q3)
* Event time relative to 2023q4
gen event_time = yq - tq(2023q4)

* Pre-treatment dummies (omitting -1 as base)
foreach i in  4 3 2 {
    gen pre`i' = (event_time == -`i') * treat_state
}

* Period 0 (2023q4 - implementation period)
gen period0 = (event_time == 0) * treat_state

* Post-treatment dummies (2024q1 onwards)
foreach i in 1 2 3 4 5 6 7 8 {
    gen post`i' = (event_time == `i') * treat_state
}

* Event study regression
reg is_worker pre4 pre3 pre2 ///
    period0 post1 post2 post3 post4 post5 post6 post7 post8 ///
    age i.married edu edu_status  hh_size ///
    i.state i.yq [pw=weight], vce(robust)

* Test pre-trends jointly (should be insignificant)
testparm  pre4 pre3 pre2

* Test post-treatment jointly (period0 + post periods)
testparm period0 post1 post2 post3 post4 post5 post6 post7 post8

gen coef = .
gen ci_upper = .
gen ci_lower = .
gen period = .


local j = 1
foreach var in  pre4 pre3 pre2 period0 post1 post2 post3 post4 post5 post6 post7 post8 {
    replace coef     = _b[`var']                    in `j'
    replace ci_upper = _b[`var'] + 1.96*_se[`var'] in `j'
    replace ci_lower = _b[`var'] - 1.96*_se[`var'] in `j'
    local j = `j' + 1
}

local j = 1
foreach t in  -4 -3 -2 0 1 2 3 4 5 6 7 8 {
    replace period = `t' in `j'
    local j = `j' + 1
}
twoway ///
    (rcap ci_upper ci_lower period, lcolor(gray)) ///
    (scatter coef period, mcolor(navy) msize(medium)) ///
    (line coef period, lcolor(navy)) ///
    , yline(0, lpattern(dash) lcolor(red)) ///
    xline(-0, lpattern(dash) lcolor(black)) ///
    xlabel(-5(1)8) ///
    xtitle("Periods Relative to Treatment (2023q4)") ///
    ytitle("Coefficient") ///
    title("Event Study — Effect on Labour Force Participation") ///
    legend(off)
	
	
graph export "graphs/event_study.png", replace


restore



*=======================================================================
* REGRESSION RESULTS
*=======================================================================
* Without controls 
preserve
keep if yq >tq(2022q3)
use complete_analysis_data.dta, replace
reg is_worker treat i.yq i.state [pw=weight], vce(cluster nss_region) 
eststo m1
estadd local state_fe "Yes"
estadd local time_fe "Yes"
estadd local age_ctrl "No"
estadd local edu_ctrl "No"

* With MPCE as additional control
reg is_worker treat i.state i.yq age i.married i.edu i.edu_status hh_size ///
    [pw=weight], vce(robust)
	
eststo m2
estadd local state_fe "Yes"
estadd local time_fe "Yes"
estadd local age_ctrl "Yes"
estadd local edu_ctrl "Yes"	

reg is_worker treat i.state i.yq age i.married i.edu i.edu_status hh_size ///
    [pw=weight] if mpce_q == 1, vce( robust)
eststo m3
estadd local state_fe "Yes"
estadd local time_fe "Yes"
estadd local age_ctrl "Yes"
estadd local edu_ctrl "Yes"	


esttab m1 m2 using results.tex, ///
    replace ///
    se ///
    booktabs ///
    label ///
    keep(treat age ln_mpce 2.married 3.married 4.married hh_size) ///
    mtitle("Base" "Full") ///
    varlabels(2.married "Currently Married" ///
              3.married "Widowed" ///
              4.married "Divorced/Separated" ///
              _cons "Constant", ///
              prefix(\multicolumn{1}{l}{) suffix(}) ///
              blist(2.married "\midrule \emph{Marital Status (base = Never Married)} & & \\ ")) ///
    stats(state_fe time_fe age_ctrl edu_ctrl N r2, ///
          labels("State FE" "Time FE" "Age Controls" "Education Controls" "Observations" "R-squared")) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Effect on Labour Force Participation")

restore

preserve
keep if state == 36

reg is_worker mpce i.yq age i.married i.edu i.edu_status ln_mpce hh_size, vce(robust)
eststo m4

reg  is_worker ib8.mpce_q i.yq age i.married i.edu i.edu_status hh_size , vce(robust)
eststo m5

reg  is_worker ib8.mpce_q##c.hh_size i.yq age i.married i.edu i.edu_status , vce(robust)

esttab m4 m5 using results_mpce.tex, ///
    replace ///
    se ///
    booktabs ///
    label ///
    keep(ln_mpce age hh_size 1.mpce_q 2.mpce_q 3.mpce_q 4.mpce_q 5.mpce_q 6.mpce_q 7.mpce_q ///
          1.edu_status ///
         2.married 3.married 4.married) ///
    mtitle("Continuous MPCE" "MPCE Quantiles") ///
    varlabels(ln_mpce "Log MPCE" ///
              1.mpce_q "1st Quantile (Poorest)" ///
              2.mpce_q "2nd Quantile" ///
              3.mpce_q "3rd Quantile" ///
              4.mpce_q "4th Quantile" ///
              5.mpce_q "5th Quantile" ///
              6.mpce_q "6th Quantile" ///
              7.mpce_q "7th Quantile" ///
              1.edu_status "Currently Attending Education" ///
              2.married "Currently Married" ///
              3.married "Widowed" ///
              4.married "Divorced/Separated" ///
              _cons "Constant", ///
              prefix(\multicolumn{1}{l}{) suffix(}) ///
              blist(1.mpce_q "\midrule \emph{MPCE Quantile (base = Richest/8th Quantile)} & & \\ " ///
                    age "\midrule" ///
                    1.edu_status "\midrule" ///
                    2.married "\midrule \emph{Marital Status (base = Never Married)} & & \\ ")) ///
    stats(N r2, ///
          labels("Observations" "R-squared")) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Effect of MPCE on Labour Force Participation — Telangana")
restore


****** DiD using did_multiplegt_dyn
preserve
keep if yq >=tq(2022q3)

	did_multiplegt_dyn is_worker state yq treat ///
	, controls(age edu edu_status hh_size) ///
	effects(8) placebo(8)
restore



*=======================================================================
* DESCRIPTIVE STATS
*=======================================================================	

local vars "age mpce hh_size edu edu_status married is_worker"

* -------------------------------------------------------
* COLUMN 1: Full sample
* -------------------------------------------------------
eststo all: estpost tabstat `vars' [aw=weight], ///
    statistics(mean sd n) columns(statistics)

* -------------------------------------------------------
* COLUMN 2: Control
* -------------------------------------------------------
eststo control: estpost tabstat `vars' [aw=weight] if treat_state == 0, ///
    statistics(mean sd n) columns(statistics)

* -------------------------------------------------------
* COLUMN 3: Treatment
* -------------------------------------------------------
eststo treatment: estpost tabstat `vars' [aw=weight] if treat_state == 1, ///
    statistics(mean sd n) columns(statistics)

* -------------------------------------------------------
* COLUMN 4: Difference (Treatment - Control) with SE
* -------------------------------------------------------
eststo diff: estpost ttest `vars', by(treat_state)

* -------------------------------------------------------
* EXPORT TABLE
* -------------------------------------------------------
esttab all control treatment diff using "balance_table.tex", ///
    replace label booktabs nonum fragment ///
    cells("mean(pattern(1 1 1 0) fmt(3)) sd(pattern(1 1 1 0) par([ ]) fmt(3)) b(pattern(0 0 0 1) fmt(3)) se(pattern(0 0 0 1) par fmt(3))") ///
    mtitle("All" "Control" "Treatment" "Diff. (3)-(2)") ///
    title("Descriptive Statistics and Covariate Balance") ///
    addnotes("Standard deviations in brackets." ///
             "Standard errors in parentheses for difference column." ///
             "*** p<0.01, ** p<0.05, * p<0.1") ///
    star(* 0.1 ** 0.05 *** 0.01) ///
    obslast

