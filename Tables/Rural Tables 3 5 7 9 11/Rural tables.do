local folderpath "/Users/wyattwyatt/Documents/Study - Now/Summer Research/NEW/Rural Tables 3 5 7 9 11"
local filename "Rural tables"
local datapath "/Users/wyattwyatt/Documents/Study - Now/Summer Research/NEW/20240716 Rural Chip2018 and Instrumental Statistics and Inflation.dta"


local xlspath "`folderpath'/`filename'.xls"
log using "`folderpath'/`filename'.log", replace
use "`datapath'", clear


*Step Zero: A New Dataset for Merging

gen headsecedu = .
gen headhighedu = .
gen spousesecedu = .
gen spousehighedu = .
gen headparty = .
gen spouseparty = .
gen spouseparentsecedu = .
gen spouseparenthighedu = .
gen spouseparentparty = .
gen headparentsecedu = .
gen headparenthighedu = .
gen headparentparty = .
replace headsecedu = 1 if A02 == 1 & inrange(A13_1, 4, 9)
replace headsecedu = 0 if A02 == 1 & inrange(A13_1, 1, 3)
replace headhighedu = 1 if A02 == 1 & inrange(A13_1, 7, 9)
replace headhighedu = 0 if A02 == 1 & inrange(A13_1, 1, 6)
replace spousesecedu = 1 if A02 == 2 & inrange(A13_1, 4, 9)
replace spousesecedu = 0 if A02 == 2 & inrange(A13_1, 1, 3)
replace spousehighedu = 1 if A02 == 2 & inrange(A13_1, 7, 9)
replace spousehighedu = 0 if A02 == 2 & inrange(A13_1, 1, 6)
replace headparty = 1 if A02 == 1 & A07_1 == 1
replace headparty = 0 if A02 == 1 & inrange(A07_1, 2, 4)
replace spouseparty = 1 if A02 == 2 & A07_1 == 1
replace spouseparty = 0 if A02 == 2 & inrange(A07_1, 2, 4)
replace spouseparentsecedu = 0 if A02 == 5 & inrange(A13_1, 1, 3)
replace spouseparentsecedu = 1 if A02 == 5 & inrange(A13_1, 4, 9)
replace spouseparenthighedu = 0 if A02 == 5 & inrange(A13_1, 1, 6)
replace spouseparenthighedu = 1 if A02 == 5 & inrange(A13_1, 7, 9)
replace spouseparentparty = 0 if A02 == 5 & inrange(A07_1, 2, 4)
replace spouseparentparty = 1 if A02 == 5 & A07_1 == 1
replace headparentsecedu = 0 if A02 == 4 & inrange(A13_1, 1, 3)
replace headparentsecedu = 1 if A02 == 4 & inrange(A13_1, 4, 9)
replace headparenthighedu = 0 if A02 == 4 & inrange(A13_1, 1, 6)
replace headparenthighedu = 1 if A02 == 4 & inrange(A13_1, 7, 9)
replace headparentparty = 0 if A02 == 4 & inrange(A07_1, 2, 4)
replace headparentparty = 1 if A02 == 4 & A07_1 == 1
collapse (max) headsecedu headhighedu spousesecedu spousehighedu headparty spouseparty spouseparentsecedu spouseparenthighedu spouseparentparty headparentsecedu headparenthighedu headparentparty, by(hhcode)

save "`folderpath'/`filename'.dta", replace

*Step One: Variables and Data Processing (See Selmlog Rural Basics for more info)

use "`datapath'", clear

gen annualearning = C05_1 if C05_1!=-99 & C05_1!=-88
gen workmonths=C01_1 if C01_1!=-99
gen monthlyearning = annualearning/workmonths
gen log_monthlyearning = ln(monthlyearning)
gen male=1 if A03==1
replace male=0 if A03==2
gen birthyear = A04_1 if A04_1!=-88 & A04_1!=-99
gen age = 2018-birthyear
gen agesqr = age*age
gen exp = age-A13_3-6 if A13_3>=0
replace exp=0 if exp<0
gen expsqr = exp*exp
gen secvocedu=1 if A14==5
replace secvocedu =0 if A14!=5
replace secvocedu=1 if inrange(A13_1, 5, 6) & A13_2==1
replace secvocedu=0 if (inrange(A13_1,4,6) & A13_2>1) | A13_1<4
gen voc_log_monthlyearning = log_monthlyearning if secvocedu==1
gen secgenedu = 1 if A14!=-99 & A14!=-88 & A14!=5
replace secgenedu =0 if A14==-99 | A14==-88 | A14==5
replace secgenedu =0 if (A13_1==4 & A13_2>1) | inrange(A13_1, 5, 6) | A13_1<4
gen gen_log_monthlyearning = log_monthlyearning if secgenedu==1
gen secjun = 1 if (A13_1 ==3 & A13_2 ==1) | (inrange(A13_1, 4, 6) & A13_2>1) 
replace secjun = 0 if secjun!=1
gen jun_log_monthlyearning = log_monthlyearning if secjun == 1
gen educat=1 if secvocedu==1
replace educat=2 if secgenedu==1
replace educat=3 if secjun==1
gen highvocedu =1 if A13_1==7 & A13_2==1
replace highvocedu=0 if highvocedu!=1
replace highvocedu=0 if A15_7==6
gen highgenedu =1 if (A13_1==8 & A13_2==1) | A13_1==9
replace highgenedu =0 if highgenedu!=1
replace highgenedu=0 if A15_7==6
gen adultedu = 1 if A15_7 == 6
replace adultedu = 0 if A15_7!=6
replace adultedu = 0 if ((A13_1==7 | A13_1==8) & A13_2!=1) | A13_1<=6
gen higheredu=1 if highvocedu==1 | highgenedu==1 | adultedu==1
replace higheredu=0 if higheredu!=1
gen yearat15 = birthyear+15
local obsnum = _N
forval i =  1/`obsnum' {
	qui sum yearat15  in `i'
	local yearvalue = round(mod(r(mean),100))
	if inrange(`yearvalue', 0, 9) {
		local czgrad_year = "czgrad0`yearvalue'"
		local gzgrad_year = "gzgrad0`yearvalue'"
	}
	else {
		local czgrad_year = "czgrad`yearvalue'"
		local gzgrad_year = "gzgrad`yearvalue'"
	}
	if inrange(`yearvalue'+1, 0, 9) {
		local gzentrant_year = "gzentrant0`=`yearvalue'+1'"
		local gxentrant_year = "gxentrant0`=`yearvalue'+1'"
		local vsentrant_year = "vsentrant0`=`yearvalue'+1'"
		local tsentrant_year = "tsentrant0`=`yearvalue'+1'"
	}
	else{
		if `yearvalue' == 99 {
		local gzentrant_year = "gzentrant00"
		local gxentrant_year = "gxentrant00"
		local vsentrant_year = "vsentrant00"
		local tsentrant_year = "tsentrant00"
		}
	else {
		local gzentrant_year = "gzentrant`=`yearvalue'+1'"
		local gxentrant_year = "gxentrant`=`yearvalue'+1'"
		local vsentrant_year = "vsentrant`=`yearvalue'+1'"
		local tsentrant_year = "tsentrant`=`yearvalue'+1'"
	}
	}
	capture ds `czgrad_year' `gzgrad_year' `gzentrant_year' `gxentrant_year'
	if _rc == 0 {
		capture ds ins1_secgen_entrant_relative ins2_highedu_entrant_relative
		if _rc!=0 {
			qui gen ins1_secgen_entrant_relative = `gzentrant_year'/`czgrad_year' if _n == `i'
			qui gen ins2_highedu_entrant_relative = `gxentrant_year'/`gzgrad_year' if _n == `i'
		
		}
		else {
			qui replace ins1_secgen_entrant_relative = `gzentrant_year'/`czgrad_year' if _n == `i'
			qui replace ins2_highedu_entrant_relative = `gxentrant_year'/`gzgrad_year' if _n == `i'
		}
	}
	capture ds `czgrad_year' `vsentrant_year'
	if _rc == 0 {
		capture ds ins3_vs_entrant_relative
		if _rc!=0 {
			qui gen ins3_vs_entrant_relative = `vsentrant_year'/`czgrad_year' if _n == `i'
		}
		else {
			qui replace ins3_vs_entrant_relative = `vsentrant_year'/`czgrad_year' if _n == `i'
		}
	}
}
destring hhcode, generate(province_code) force float
replace province_code = floor(province_code/1000000000000) if province_code<100000000000000
replace province_code = floor(province_code/10000000000000) if province_code>=100000000000000 & province_code<1000000000000000
replace province_code = floor(province_code/1000000000000000) if province_code>=10000000000000000
tab province_code, gen(provincedum)
merge m:1 hhcode using "`folderpath'/`filename'.dta"
gen parent_secedu = 0 if (A02==1 & (inrange(H03_R1, 1, 3) | inrange(H03_R2, 1, 3))) | (A02==2 & (inrange(H03_R3, 1, 3) | inrange(H03_R4, 1, 3)))
replace parent_secedu = 0 if A02 ==3 & (headsecedu == 0 | spousesecedu == 0)
replace parent_secedu = 0 if (A02 == 2 & spouseparentsecedu == 0) | (A02 == 1 & headparentsecedu == 0)
replace parent_secedu=1 if (A02==1 & (inrange(H03_R1, 4, 9) | inrange(H03_R2, 4, 9)))|(A02==2 & (inrange(H03_R3, 4, 9) | inrange(H03_R4, 4, 9)))
replace parent_secedu = 1 if A02 ==3 & (headsecedu == 1 | spousesecedu == 1)
replace parent_secedu = 1 if (A02 == 2 & spouseparentsecedu == 1) | (A02 == 1 & headparentsecedu == 1)
tab parent_secedu
gen parent_highedu = 0 if (A02==1 & (inrange(H03_R1, 1, 6) | inrange(H03_R2, 1, 6))) | (A02==2 & (inrange(H03_R3, 1, 6) | inrange(H03_R4, 1, 6)))
replace parent_highedu = 0 if A02 == 3 & (headhighedu == 0 | spousehighedu == 0)
replace parent_highedu = 0 if (A02 == 2 & spouseparenthighedu == 0) | (A02 == 1 & headparenthighedu == 0)
replace parent_highedu=1 if (A02==1 & (inrange(H03_R1, 7, 9) | inrange(H03_R2, 7, 9)))|(A02==2 & (inrange(H03_R3, 7, 9) | inrange(H03_R4, 7, 9)))
replace parent_highedu = 1 if A02 == 3 & (headhighedu == 1 | spousehighedu == 1)
replace parent_highedu = 1 if (A02 == 2 & spouseparenthighedu == 1) | (A02 == 1 & headparenthighedu == 1)
tab parent_highedu
gen parent_partymember = 0 if ((A02==1 & (inrange(H07_R1, 2, 4) | inrange(H07_R2, 2, 4))) | (A02==2 & (inrange(H07_R3, 2, 4) | inrange(H07_R4, 2, 4))))
replace parent_partymember = 0 if A02 == 3 & (headparty == 0 | spouseparty == 0)
replace parent_partymember = 0 if (A02 == 2 & spouseparentparty == 0) | (A02 == 1 & headparentparty == 0)
replace parent_partymember=1 if (A02==1 & (H07_R1 == 1 | H07_R2 == 1)) | (A02==2 & (H07_R3 == 1 | H07_R4 == 1))
replace parent_partymember = 1 if A02 == 3 & (headparty == 1 | spouseparty == 1)
replace parent_partymember = 1 if (A02 == 2 & spouseparentparty == 1) | (A02 == 1 & headparentparty == 1)
tab parent_partymember
gen Keyschool = 0 if A14 != .
replace Keyschool = 1 if inrange(A14, 1, 3)
gen TakeGaoKao = 1 if A15_1 == 1
replace TakeGaoKao = 0 if A15_1 == 2
tab TakeGaoKao
tab TakeGaoKao educat
tab TakeGaoKao educat if male==1
tab TakeGaoKao educat if male==0
gen unemp_A20_5 = 1 if A20 == 5
replace unemp_A20_5 = 0 if inrange(A20, 1, 4) | inrange(A20, 6, 9)
gen voc_unemp_A20_5 = unemp_A20_5 if educat == 1
gen gen_unemp_A20_5 = unemp_A20_5 if educat == 2
gen unemp_A20_59 = unemp_A20_5
replace unemp_A20_59 = 1 if A20 == 9
gen voc_unemp_A20_59 = unemp_A20_59 if educat == 1
gen gen_unemp_A20_59 = unemp_A20_59 if educat == 2
gen highocc = 1 if C03_4 == 1 | C03_4 == 2
replace highocc = 0 if inrange(C03_4, 3, 8)
gen voc_highocc = highocc if educat == 1
gen gen_highocc = highocc if educat == 2
gen longtermcontract = 1 if C07_1 == 1 | C07_1 == 2
replace longtermcontract = 0 if inrange(C07_1, 3, 5)
gen voc_longtermcontract= longtermcontract if educat == 1
gen gen_longtermcontract = longtermcontract if educat == 2
sum unemp_A20_5, d
sum unemp_A20_59, d
sum highocc, d
sum longtermcontract, d
gen bornafter79=1 if birthyear>=1980 & birthyear<=2018
replace bornafter79=0 if birthyear<1980 & birthyear>0
gen highvocafter79=highvocedu*bornafter79
gen highgenafter79=highgenedu*bornafter79
gen adulteduafter79=adultedu*bornafter79
gen highereduafter79=higheredu*bornafter79

***To label used variables (m1 m2 m3 need to be labelled afterwords, before generating tables again, because we drop m1 m2 m3 during regressing)
local variablenames male exp expsqr higheredu highvocedu highgenedu adultedu highereduafter79 TakeGaoKao parent_secedu parent_highedu parent_partymember
local variablelabels ""Sex (male=1)" "Experience (years)" "Experience squared (years)" "Any higher ed degree (yes=1)" "Higher voc ed degree (yes=1)" "University degree (yes=1)" "Adult continuing ed degree (yes=1)" "Any higher ed degree * born after 1979 birth cohort" "University entrance exam (took exam=1)" "Parent with upper secondary degree (yes=1)" "Parent with higher ed degree (yes=1)" "Parent party member (yes=1)""

local count 0
foreach labels in `variablelabels' {
	local count = `count' + 1
	local varname : word `count' of `variablenames'
	label var `varname' "`labels'"
}



*Step Two: Graphing Regressions & Output

***Table 3 with sequence: Two_tracks > Higher_edu Combined/Seperated > Gender(s), 2*2*3=12 columns in total.


local folderpath "/Users/wyattwyatt/Documents/Study - Now/Summer Research/NEW/Rural Tables 3 5 7 9 11"
local filename "Rural tables"
local datapath "/Users/wyattwyatt/Documents/Study - Now/Summer Research/NEW/20240716 Rural Chip2018 and Instrumental Statistics and Inflation.dta"


local xlspath "`folderpath'/`filename'.xls"

eststo clear

**Below are columns 1-3

selmlog voc_log_monthlyearning male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), vce(robust)
eststo 
sum voc_log_monthlyearning male exp expsqr higheredu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", replace ctitle(Sec Voc, All Gender, Non-specified Higheredu, Province Dum) pvalue
drop m1 m2 m3

selmlog voc_log_monthlyearning exp expsqr higheredu provincedum2-provincedum15 if male==1 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if male==1 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), vce(robust)
eststo 
sum voc_log_monthlyearning exp expsqr higheredu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Voc, Male, Non-specified Higheredu, Province Dum) pvalue
drop m1 m2 m3

selmlog voc_log_monthlyearning exp expsqr higheredu provincedum2-provincedum15 if male==0 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if male==0 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), vce(robust)
eststo 
sum voc_log_monthlyearning male exp expsqr higheredu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Voc, Female, Non-specified Higheredu, Province Dum) pvalue
drop m1 m2 m3

**Below are columns 4-6

selmlog voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), vce(robust)
eststo
sum voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Voc, All Gender, Specified Higheredu, Province Dum) pvalue
drop m1 m2 m3

selmlog voc_log_monthlyearning exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if male==1 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if male==1 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), vce(robust)
eststo
sum voc_log_monthlyearning exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Voc, Male, Specified Higheredu, Province Dum) pvalue
drop m1 m2 m3

selmlog voc_log_monthlyearning exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if male==0 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if male==0 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), vce(robust)
eststo
sum voc_log_monthlyearning exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Voc, Female, Specified Higheredu, Province Dum) pvalue
drop m1 m2 m3

**Below are columns 7-9

selmlog gen_log_monthlyearning male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), vce(robust)
eststo
sum gen_log_monthlyearning male exp expsqr higheredu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Gen, All Gender, Non-specified Higheredu, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_log_monthlyearning exp expsqr higheredu provincedum2-provincedum15 if male==1 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if male==1 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), vce(robust)
eststo
sum gen_log_monthlyearning male exp expsqr higheredu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Gen, Male, Non-specified Higheredu, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_log_monthlyearning exp expsqr higheredu provincedum2-provincedum15 if male==0 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if male==0 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), vce(robust)
eststo
sum gen_log_monthlyearning exp expsqr higheredu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Gen, Female, Non-specified Higheredu, Province Dum) pvalue
drop m1 m2 m3

**Below are columns 10-12

selmlog gen_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), vce(robust)
eststo
sum gen_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Gen, All Gender, Specified Higheredu, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_log_monthlyearning exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if male==1 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if male==1 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), vce(robust)
eststo
sum gen_log_monthlyearning exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Gen, Male, Specified Higheredu, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_log_monthlyearning exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if male==0 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if male==0 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), vce(robust)
eststo
sum gen_log_monthlyearning exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Gen, Female, Specified Higheredu, Province Dum) pvalue

***Table 3 Generation

local variablenames m1 m2 m3
local variablelabels ""Upper secondary vocational track selection correction" "Upper secondary general track selection correction" "No upper secondary degree selection correction""

local count 0
foreach labels in `variablelabels' {
	local count = `count' + 1
	local varname : word `count' of `variablenames'
	label var `varname' "`labels'"
}

local estlist est1 est2 est3 est4 est5 est6 est7 est8 est9 est10 est11 est12

outreg2 [`estlist'] using "Table 3/Table3.xls", excel replace pvalue adjr2 drop(provincedum*) dec(3) sortvar(male exp expsqr higheredu) title("Table 3 (Sec Voc 1-6, Sec Gen 7-10; Non-specified 1-3 & 7-9, Specified 4-6 & 10-12; Genders repeat under for every 3 columns)") ctitle(" ") addnote("More notes") label






***Table 5 with sequence: Gaokao indicator / Parent indicator > Two_tracks > Higher_edu Combined/Seperated, 2*2*2=8 columns in total.

*Prepare

drop m1 m2 m3
local folderpath "/Users/wyattwyatt/Documents/Study - Now/Summer Research/NEW/Rural Tables 3 5 7 9 11"
local filename "Rural tables"
local datapath "/Users/wyattwyatt/Documents/Study - Now/Summer Research/NEW/20240716 Rural Chip2018 and Instrumental Statistics and Inflation.dta"


local xlspath "`folderpath'/`filename'.xls"

eststo clear

*columns 1-4

selmlog voc_log_monthlyearning  male exp expsqr higheredu TakeGaoKao provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr higheredu TakeGaoKao provincedum2-provincedum15  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), vce(robust)
eststo
sum voc_log_monthlyearning male exp expsqr higheredu TakeGaoKao provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Voc, Higheredu Together, Province Dum) pvalue
drop m1 m2 m3

selmlog voc_log_monthlyearning  male exp expsqr highvocedu highgenedu adultedu TakeGaoKao provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu TakeGaoKao provincedum2-provincedum15  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), vce(robust)
eststo
sum voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu TakeGaoKao provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Voc, Higheredu Seperate, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_log_monthlyearning  male exp expsqr higheredu TakeGaoKao provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr higheredu TakeGaoKao provincedum2-provincedum15  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), vce(robust)
eststo
sum gen_log_monthlyearning male exp expsqr higheredu TakeGaoKao provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Gen, Higheredu Together, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_log_monthlyearning  male exp expsqr highvocedu highgenedu adultedu TakeGaoKao provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu TakeGaoKao provincedum2-provincedum15  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), vce(robust)
eststo
sum gen_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu TakeGaoKao provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Gen, Higheredu Seperate, Province Dum) pvalue
drop m1 m2 m3

*columns 5-8

selmlog voc_log_monthlyearning  male exp expsqr higheredu parent_secedu parent_highedu parent_partymember provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu parent_partymember provincedum2-provincedum15  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), vce(robust)
eststo
sum voc_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu parent_partymember provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Voc, Higheredu Together, Province Dum) pvalue
drop m1 m2 m3

selmlog voc_log_monthlyearning  male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative ) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember provincedum2-provincedum15  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), vce(robust)
eststo
sum voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Voc, Higheredu Seperate, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_log_monthlyearning  male exp expsqr higheredu parent_secedu parent_highedu parent_partymember provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative ) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu parent_partymember provincedum2-provincedum15  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), vce(robust)
eststo
sum gen_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu parent_partymember provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Gen, Higheredu Together, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_log_monthlyearning  male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative ) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember provincedum2-provincedum15  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), vce(robust)
eststo
sum gen_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Gen, Higheredu Seperate, Province Dum) pvalue


***Table 5 Generation

local variablenames m1 m2 m3
local variablelabels ""Upper secondary vocational track selection correction" "Upper secondary general track selection correction" "No upper secondary degree selection correction""

local count 0
foreach labels in `variablelabels' {
	local count = `count' + 1
	local varname : word `count' of `variablenames'
	label var `varname' "`labels'"
}

local estlist est1 est2 est3 est4 est5 est6 est7 est8

outreg2 [`estlist'] using "Table 5/Table5.xls", excel replace pvalue adjr2 drop(provincedum*) dec(3) sortvar(male exp expsqr higheredu) title("Table 5 (TakeGaokao 1-4, Parent indicators 5-8; Sec Voc 1-2, Sec Gen 3-4; Non-specified 1 3 Specified 2 4)") ctitle(" ") addnote("More notes") label








***Table 7 with sequence: Unemployment types (A20=5 or A20=5|9) > Two_tracks > Higher_edu Combined/Seperated, 2*2*2=8 columns in total.

*Prepare

drop m1 m2 m3
local folderpath "/Users/wyattwyatt/Documents/Study - Now/Summer Research/NEW/Rural Tables 3 5 7 9 11"
local filename "Rural tables"
local datapath "/Users/wyattwyatt/Documents/Study - Now/Summer Research/NEW/20240716 Rural Chip2018 and Instrumental Statistics and Inflation.dta"


local xlspath "`folderpath'/`filename'.xls"

eststo clear

*Columns

selmlog voc_unemp_A20_5 male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
regress voc_unemp_A20_5 male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992), vce(robust)
eststo
outreg2 using "`xlspath'", append ctitle(Sec Voc, Higheredu Together, Province Dum) pvalue
drop m1 m2 m3

selmlog voc_unemp_A20_5 male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
regress voc_unemp_A20_5 male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992), vce(robust)
eststo
outreg2 using "`xlspath'", append ctitle(Sec Voc, Higheredu Seperate, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_unemp_A20_5 male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
regress gen_unemp_A20_5 male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992), vce(robust)
eststo
outreg2 using "`xlspath'", append ctitle(Sec Gen, Higheredu Together, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_unemp_A20_5 male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
regress gen_unemp_A20_5 male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992), vce(robust)
eststo
outreg2 using "`xlspath'", append ctitle(Sec Gen, Higheredu Seperate, Province Dum) pvalue
drop m1 m2 m3

selmlog voc_unemp_A20_59 male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
regress voc_unemp_A20_59 male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992), vce(robust)
eststo
outreg2 using "`xlspath'", append ctitle(Sec Voc, Higheredu Together, Province Dum) pvalue
drop m1 m2 m3

selmlog voc_unemp_A20_59 male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
regress voc_unemp_A20_59 male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992), vce(robust)
eststo
outreg2 using "`xlspath'", append ctitle(Sec Voc, Higheredu Seperate, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_unemp_A20_59 male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
regress gen_unemp_A20_59 male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992), vce(robust)
eststo
outreg2 using "`xlspath'", append ctitle(Sec Gen, Higheredu Together, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_unemp_A20_59 male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
regress gen_unemp_A20_59 male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992), vce(robust)
eststo
outreg2 using "`xlspath'", append ctitle(Sec Gen, Higheredu Seperate, Province Dum) pvalue

***Table 7 Generation

local variablenames m1 m2 m3
local variablelabels ""Upper secondary vocational track selection correction" "Upper secondary general track selection correction" "No upper secondary degree selection correction""

local count 0
foreach labels in `variablelabels' {
	local count = `count' + 1
	local varname : word `count' of `variablenames'
	label var `varname' "`labels'"
}


local estlist est1 est2 est3 est4 est5 est6 est7 est8

outreg2 [`estlist'] using "Table 7/Table7.xls", excel replace pvalue adjr2 drop(provincedum*) dec(3) sortvar(male exp expsqr higheredu) title("Table 7 (Unemployment A20=5 1-4 A20=5|9 5-8; Sec Voc 1-2 5-6, Sec Gen 3-4 7-8; Non-specified 1 3 5 7 Specified 2 4 6 8)") ctitle(" ") addnote("More notes") label




***Table 9 with sequence: Occupytion or Contract > Two_tracks > Higher_edu Combined/Seperated, 2*2*2=8 columns in total.

*Prepare

drop m1 m2 m3
local folderpath "/Users/wyattwyatt/Documents/Study - Now/Summer Research/NEW/Rural Tables 3 5 7 9 11"
local filename "Rural tables"
local datapath "/Users/wyattwyatt/Documents/Study - Now/Summer Research/NEW/20240716 Rural Chip2018 and Instrumental Statistics and Inflation.dta"


local xlspath "`folderpath'/`filename'.xls"

eststo clear

*Columns

selmlog voc_highocc male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
regress voc_highocc male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992), vce(robust)
eststo
outreg2 using "`xlspath'", append ctitle(Sec Voc, Higheredu Together, Province Dum) pvalue
drop m1 m2 m3

selmlog voc_highocc male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
regress voc_highocc male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992), vce(robust)
eststo
outreg2 using "`xlspath'", append ctitle(Sec Voc, Higheredu Seperate, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_highocc male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
regress gen_highocc male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992), vce(robust)
eststo
outreg2 using "`xlspath'", append ctitle(Sec Gen, Higheredu Together, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_highocc male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
regress gen_highocc male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992), vce(robust)
eststo
outreg2 using "`xlspath'", append ctitle(Sec Gen, Higheredu Seperate, Province Dum) pvalue
drop m1 m2 m3

selmlog voc_longtermcontract male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
regress voc_longtermcontract male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992), vce(robust)
eststo
outreg2 using "`xlspath'", append ctitle(Sec Voc, Higheredu Together, Province Dum) pvalue
drop m1 m2 m3

selmlog voc_longtermcontract male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
regress voc_longtermcontract male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992), vce(robust)
eststo
outreg2 using "`xlspath'", append ctitle(Sec Voc, Higheredu Seperate, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_longtermcontract male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
regress gen_longtermcontract male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992), vce(robust)
eststo
outreg2 using "`xlspath'", append ctitle(Sec Gen, Higheredu Together, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_longtermcontract male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
regress gen_longtermcontract male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992), vce(robust)
eststo
outreg2 using "`xlspath'", append ctitle(Sec Gen, Higheredu Seperate, Province Dum) pvalue

***Table 9 Generation

local variablenames m1 m2 m3
local variablelabels ""Upper secondary vocational track selection correction" "Upper secondary general track selection correction" "No upper secondary degree selection correction""

local count 0
foreach labels in `variablelabels' {
	local count = `count' + 1
	local varname : word `count' of `variablenames'
	label var `varname' "`labels'"
}


local estlist est1 est2 est3 est4 est5 est6 est7 est8

outreg2 [`estlist'] using "Table 9/Table9.xls", excel replace pvalue adjr2 drop(provincedum*) dec(3) sortvar(male exp expsqr higheredu) title("Table 9 (Occupation 1-4 High contract 5-8; Sec Voc 1-2 5-6, Sec Gen 3-4 7-8; Non-specified 1 3 5 7 Specified 2 4 6 8)") ctitle(" ") addnote("More notes") label 


***Table 11 with sequence: Sec Voc or Sec Gen, 2 columns.

*Prepare

drop m1 m2 m3
local folderpath "/Users/wyattwyatt/Documents/Study - Now/Summer Research/NEW/Rural Tables 3 5 7 9 11"
local filename "Rural tables"
local datapath "/Users/wyattwyatt/Documents/Study - Now/Summer Research/NEW/20240716 Rural Chip2018 and Instrumental Statistics and Inflation.dta"


local xlspath "`folderpath'/`filename'.xls"

eststo clear

*Columns

selmlog voc_log_monthlyearning male exp expsqr higheredu highereduafter79 provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr higheredu highereduafter79 provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), vce(robust)
eststo
sum voc_log_monthlyearning male exp expsqr higheredu highereduafter79 m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Voc, All Gender, Non-specified Higheredu, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_log_monthlyearning male exp expsqr higheredu highereduafter79 provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr higheredu highereduafter79 provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), vce(robust)
eststo
sum gen_log_monthlyearning male exp expsqr higheredu highereduafter79 m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Gen, All Gender, Non-specified Higheredu, Province Dum) pvalue

***Table 11 Generation

local variablenames m1 m2 m3
local variablelabels ""Upper secondary vocational track selection correction" "Upper secondary general track selection correction" "No upper secondary degree selection correction""

local count 0
foreach labels in `variablelabels' {
	local count = `count' + 1
	local varname : word `count' of `variablenames'
	label var `varname' "`labels'"
}


local estlist est1 est2

outreg2 [`estlist'] using "Table 11/Table11.xls", excel replace pvalue adjr2 drop(provincedum*) dec(3) sortvar(male exp expsqr higheredu) title("Table 11") ctitle(" ") addnote("More notes") label

log close
