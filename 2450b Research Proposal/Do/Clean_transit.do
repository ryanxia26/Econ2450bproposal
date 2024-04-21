/* Cleans the transit data and compiles to Commuter Zone aggregates */

import excel using "${topdir}\Data\Raw\DOT_transitridership.xlsx", sheet("UPT") clear

foreach v of varlist * {
   local vname = strtoname(`v'[1])
   rename `v' `vname'
}
drop in 1
drop if NTD_ID == ""
drop if NTD_ID == "N/A"
drop if UACE_CD == "N/A"
destring UACE_CD, replace

quietly ds
local varlist `r(varlist)'
local toexclude "NTD_ID Legacy_NTD_ID Agency Mode_Type_of_Service_Status Reporter_Type UACE_CD UZA_Name Mode TOS _3_Mode"
local dates : list varlist - toexclude
destring `dates', replace

/* aggregate by whether transit outsourced or not (Unneeded if next section uncommented, only if want to disaggregate by service type)
drop TOS
foreach date of varlist `dates'{
	egen `date'_all = sum(`date'), by(NTD_ID Mode)
}
drop `dates'
foreach date in `dates'{
	rename `date'_all `date'
}

sort NTD_ID Mode
quietly by NTD_ID Mode: gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup */

* aggregate by total ridership for each city
foreach date of varlist `dates'{
	egen `date'_all = sum(`date'), by(UACE_CD)
}
drop `dates'
foreach date in `dates'{
	rename `date'_all ridership`date'
}

drop NTD_ID Legacy_NTD_ID Agency Mode_Type_of_Service_Status Reporter_Type Mode TOS _3_Mode

sort UACE_CD
quietly by UACE_CD: gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup

* reshape long and convert dates
reshape long ridership_, i(UACE_CD) j(month) string
rename ridership_ ridership

gen month2 = monthly(month, "MY")
format month2 %tm
drop month
rename month2 month

save "${topdir}\Data\transitbycityall_cleaned", replace

* create city variable for the 10 cities we care about
gen city = ""
replace city = "Boston" if UACE_CD == 9271
replace city = "New York" if UACE_CD == 63217
replace city = "Houston" if UACE_CD == 40429
replace city = "Miami" if UACE_CD == 56602
replace city = "Cleveland" if UACE_CD == 17668
replace city = "Chicago" if UACE_CD == 16264
replace city = "Seattle" if UACE_CD == 80389
replace city = "Denver" if UACE_CD == 23527
replace city = "Los Angeles" if UACE_CD == 51445
replace city = "San Francisco" if UACE_CD == 78904

drop if city == ""
save "${topdir}\Data\transitbycityimp_cleaned", replace



