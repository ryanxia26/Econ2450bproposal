/* Cleans the employment dataset */ 

import delimited using "${topdir}\Data\Raw\BOE_weeklyearnings.csv"

quietly ds
local varlist `r(varlist)'

foreach v of varlist `varlist' {
	local a : variable label `v'
	local a: subinstr local a "-" "_"
	local a: subinstr local a "-" "_"
	rename `v' earnings`a'
}

rename earningsGeography state

reshape long earnings, i(state) j(month) string

gen month2 = date(month, "YMD")
gen month3 = mofd(month2)
format month3 %tm
drop month month2
rename month3 month

save "${topdir}\Data\employment_cleaned", replace
