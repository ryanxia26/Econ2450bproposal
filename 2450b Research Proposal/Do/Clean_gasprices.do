/* Cleans the Oil Price dataset and aggregates to Monthly */

import excel using "${topdir}/Data/Raw/DOE_gasprices.xls", sheet("Data 1") clear

drop if A == "Back to Contents" || A == "Sourcekey"
drop V

foreach v of varlist * {
   local vname = strtoname(`v'[1])
   rename `v' `vname'
}
drop in 1

gen date = date(Date, "DMY")
format date %td
drop Date
drop if date < mdy(1, 1, 2000)

rename Weekly_U_S__Regular_Conventional US
rename Weekly_East_Coast_Regular_Conven East_Coast
rename Weekly_New_England__PADD_1A__Reg New_England
rename Weekly_Central_Atlantic__PADD_1B Ceneral_Atlantic
rename Weekly_Lower_Atlantic__PADD_1C__ Lower_Atlantic
rename Weekly_Midwest_Regular_Conventio Midwest
rename Weekly_Rocky_Mountain_Regular_Co Rocky_Mountains
rename Weekly_West_Coast_Regular_Conven West_Coast
rename Weekly_Colorado_Regular_Conventi Colorado
rename Weekly_Florida_Regular_Conventio Florida
rename Weekly_New_York_Regular_Conventi New_York
rename Weekly_Minnesota_Regular_Convent Minnesota
rename Weekly_Ohio_Regular_Conventional Ohio
rename Weekly_Texas_Regular_Conventiona Texas
rename Weekly_Washington_Regular_Conven Washington
rename Weekly_Cleveland__OH_Regular_Con Cleveland
rename Weekly_Denver__CO_Regular_Conven Denver
rename Weekly_Miami__FL_Regular_Convent Miami
rename Weekly_Seattle__WA_Regular_Conve Seattle
rename Weekly_Gulf_Coast_Regular_Conven Gulf_Coast

destring *, replace

local varlist "US East_Coast New_England Ceneral_Atlantic Lower_Atlantic Midwest Rocky_Mountains West_Coast Colorado Florida New_York Minnesota Ohio Texas Washington Cleveland Denver Miami Seattle Gulf_Coast"

* Crudely aggregate by month
gen month = mofd(date)
format month %tm 

foreach var of varlist `varlist'{
	egen `var'_month = mean(`var'), by(month)
}

drop `varlist'
foreach var in `varlist'{
	rename `var'_month price_`var'
}

sort month
quietly by month: gen dup = cond(_N==1,0,_n)
drop if dup>1

drop dup
drop date

save "${topdir}\Data\gasprices_cleaned", replace

* reshape long
reshape long price_, i(month) j(region) string
rename price_ price

gen state = ""
replace state = "Massachusetts" if region == "New_England"
replace state = "California" if region == "West_Coast"
replace state = "Washington" if region == "Seattle"
replace state = "Florida" if region == "Miami"
replace state = "New York" if region == "New_York"
replace state = "Texas" if region == "Texas"
replace state = "Ohio" if region == "Cleveland"
replace state = "Colorado" if region == "Denver"
replace state = "Illinois" if region == "Midwest"

save "${topdir}/Data/gaspriceslong_cleaned", replace
