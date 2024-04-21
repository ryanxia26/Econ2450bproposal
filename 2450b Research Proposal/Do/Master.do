/* Runs all cleaning files and creates all graphics and tables in the Proposal */

clear all

******* Replace with your filepath *************
global topdir "FILEPATH GOES HERE"
************************************************

/// clean all the raw data ///
do "${topdir}/Do/Clean_employment"
do "${topdir}/Do/Clean_gasprices"
do "${topdir}/Do/Clean_transit"


/// create graph 1, oil price over time ///
use "${topdir}/Data/gasprices_cleaned", clear

line price_US price_New_England price_New_York price_West_Coast price_West_Coast price_Cleveland price_Denver price_Miami price_Texas price_Seattle month, ytitle(`"Fuel Price (Dollars)"') title(`"Gasoline Prices at the Pump"') legend(on order(1 "Average US" 2 "Boston" 3 "New York City" 4 "San Francisco" 5 "Los Angeles" 6 "Cleveland" 7 "Denver" 8 "Miami" 9 "Houston" 10 "Seattle"))

graph export "${topdir}/Outputs/gasprices.png", replace


/// merge with employment dataset ///
use "${topdir}/Data/gaspriceslong_cleaned", clear
drop if state == ""

merge 1:1 state month using "${topdir}/Data/employment_cleaned"
keep if _merge == 3 // drop before 2007 and for states we don't have gas prices for 
drop _merge

* create panel
egen state_id = group(state)
xtset state_id month


/// Create Table 1: Impact of Earnings on Gasoline Prices ///
gen log_earnings = log(earnings)
gen log_price = log(price)

regress D.log_price log_earnings L.log_earnings L2.log_earnings, vce(cluster state_id)
estadd scalar state_fixed_effects = 0
estimates store r1
regress D.log_price log_earnings L.log_earnings L2.log_earnings i.state_id, vce(cluster state_id)
estadd scalar state_fixed_effects = 1
estimates store r2
esttab r1 r2 using "${topdir}/Outputs/gasonemployment.tex", drop(*.state_id _cons) title("Impact of Earnings on Gasoline Prices") cells(b(star fmt(3)) se(par fmt(2))) stats(state_fixed_effects) legend style(tex) replace

* add residuals as a variable
predict resid_pricechange, residuals

/// merge with transport dataset ///
expand 2 if state == "California", gen(dupindicator) // for SF and LA
gen city = ""
replace city = "Boston" if state == "Massachusetts"
replace city = "New York" if state == "New York"
replace city = "Houston" if state == "Texas"
replace city = "Miami" if state == "Florida"
replace city = "Cleveland" if state == "Ohio"
replace city = "Chicago" if state == "Illinois"
replace city = "Seattle" if state == "Washington"
replace city = "Denver" if state == "Colorado"
replace city = "Los Angeles" if state == "California"
replace city = "San Francisco" if state == "California" && dupindicator == 1
drop dupindicator

merge 1:1 city month using "${topdir}/Data/transitbycityimp_cleaned"
drop if _merge == 2 // Transit data before 2007 will be dropped
drop _merge

* reset panel
egen city_id = group(city)
xtset city_id month


/// Create Table 2: Ridership on Residual Gasoline Price ///
gen date = dofm(month)
gen mofy = month(date) // Month of the year dummies
drop date

gen log_ridership = log(ridership)

regress D.log_ridership F.resid_pricechange resid_pricechange L.resid_pricechange i.mofy i.city_id, vce(cluster city_id)
estadd scalar City_FE = 1
estadd scalar MonthofYear_FE = 1
estimates store r1
regress D.log_ridership F.resid_pricechange resid_pricechange L.resid_pricechange i.mofy if city == "Boston"
estadd scalar City_FE = 0
estadd scalar MonthofYear_FE = 1
estimates store r2
regress D.log_ridership F.resid_pricechange resid_pricechange L.resid_pricechange i.mofy if city == "Chicago"
estadd scalar City_FE = 0
estadd scalar MonthofYear_FE = 1
estimates store r3
regress D.log_ridership F.resid_pricechange resid_pricechange L.resid_pricechange i.mofy if city == "San Francisco"
estadd scalar City_FE = 0
estadd scalar MonthofYear_FE = 1
estimates store r4

esttab r1 r2 r3 r4 using "${topdir}/Outputs/transitonprice.tex", drop(*.city_id *.mofy _cons) title("Impact of Gas Prices on Transit Ridership") cells(b(star fmt(3)) se(par fmt(2))) stats(City_FE MonthofYear_FE) legend style(tex) mtitle("All" "Boston" "Chicago" "San Francisco") replace










