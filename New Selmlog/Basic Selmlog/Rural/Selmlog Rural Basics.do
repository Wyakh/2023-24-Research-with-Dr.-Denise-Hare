local folderpath "/Users/wyattwyatt/Downloads/Revision Code/Aiden/New Selmlog/Basic Selmlog/Rural"
local filename "Selmlog Rural Basics"
local datapath "/Users/wyattwyatt/Downloads/Revision Code/20240716 Rural Chip2018 and Instrumental Statistics and Inflation.dta"


local xlspath "`folderpath'/`filename'.xls"
log using "`folderpath'/`filename'.log", replace
use "`datapath'", clear

*Step One: Variables and Data Processing

*1) Monthly earning & it's ln value

gen annualearning = C05_1 if C05_1!=-99 & C05_1!=-88
gen workmonths=C01_1 if C01_1!=-99
gen monthlyearning = annualearning/workmonths
gen log_monthlyearning = ln(monthlyearning)

*2) Sex (Male)

gen male=1 if A03==1
replace male=0 if A03==2

*3) Age & Exp

gen birthyear = A04_1 if A04_1!=-88 & A04_1!=-99
gen age = 2018-birthyear
gen agesqr = age*age

gen exp = age-A13_3-6 if A13_3>=0
replace exp=0 if exp<0
gen expsqr = exp*exp

*4) Secondary education (Sec Voc; Sec Gen; Sec Jun)

*Sec Voc
*filter by secondary school types.
gen secvocedu=1 if A14==5
replace secvocedu =0 if A14!=5
*include who reported vocational secondary degrees
replace secvocedu=1 if inrange(A13_1, 5, 6) & A13_2==1
*remove who had not finished secondary vocational education.
replace secvocedu=0 if (inrange(A13_1,4,6) & A13_2>1) | A13_1<4
tab secvocedu
*income for sec voc
gen voc_log_monthlyearning = log_monthlyearning if secvocedu==1

*Sec Gen
*filter by secondary school types.
gen secgenedu = 1 if A14!=-99 & A14!=-88 & A14!=5
replace secgenedu =0 if A14==-99 | A14==-88 | A14==5
*remove who had/have not finished secondary general schools.
replace secgenedu =0 if (A13_1==4 & A13_2>1) | inrange(A13_1, 5, 6) | A13_1<4
tab secgenedu
*income for sec gen
gen gen_log_monthlyearning = log_monthlyearning if secgenedu==1

*Only Sec Junior
*filter by A13_1
gen secjun = 1 if (A13_1 ==3 & A13_2 ==1) | (inrange(A13_1, 4, 6) & A13_2>1) 
replace secjun = 0 if secjun!=1
tab secjun

*Categotical variable of education
gen educat=1 if secvocedu==1
replace educat=2 if secgenedu==1
replace educat=3 if secjun==1
tab educat

*5) Higher education (High Voc; High Gen; Adult Edu; Higher Edu)

*Higher vocational education (full-time)
gen highvocedu =1 if A13_1==7 & A13_2==1
replace highvocedu=0 if highvocedu!=1
replace highvocedu=0 if A15_7==6

*Higher general education (full-time)
gen highgenedu =1 if (A13_1==8 & A13_2==1) | A13_1==9
replace highgenedu =0 if highgenedu!=1
replace highgenedu=0 if A15_7==6

*Adult continuing education
gen adultedu = 1 if A15_7 == 6
replace adultedu = 0 if A15_7!=6
replace adultedu = 0 if ((A13_1==7 | A13_1==8) & A13_2!=1) | A13_1<=6
tab adultedu

*higheredu (dummy variable of higher education)
gen higheredu=1 if highvocedu==1 | highgenedu==1 | adultedu==1
replace higheredu=0 if higheredu!=1

*6) Instrument

gen yearat15 = birthyear+15
local obsnum = _N

forval i =  1/`obsnum' {
	
	*extract the observation's year at age 15
	qui sum yearat15  in `i'
	local yearvalue = round(mod(r(mean),100))
	
	*get the variables' names for this observation
	*graduates of mid and sec schools
	if inrange(`yearvalue', 0, 9) {
		local czgrad_year = "czgrad0`yearvalue'"
		local gzgrad_year = "gzgrad0`yearvalue'"
	}
	else {
		local czgrad_year = "czgrad`yearvalue'"
		local gzgrad_year = "gzgrad`yearvalue'"
	}
	*entrants of sec and universities
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
	
	
	*For Ins 1 & 2: check whether the variable names exist (whether we have those years' or not)
	capture ds `czgrad_year' `gzgrad_year' `gzentrant_year' `gxentrant_year'
	if _rc == 0 {
		*generate/replace the instrument
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
	
	*For Ins 3
	capture ds `czgrad_year' `vsentrant_year'
	if _rc == 0 {
		*generate/replace the instrument
		capture ds ins3_vs_entrant_relative
		if _rc!=0 {
			qui gen ins3_vs_entrant_relative = `vsentrant_year'/`czgrad_year' if _n == `i'
		}
		else {
			qui replace ins3_vs_entrant_relative = `vsentrant_year'/`czgrad_year' if _n == `i'
		}
	}
}


sum ins1_secgen_entrant_relative, d
sum ins2_highedu_entrant_relative, d
sum ins3_vs_entrant_relative, d

*7) Province fixed effect (Method: By the first two digits of household code)

destring hhcode, generate(province_code) force float
replace province_code = floor(province_code/1000000000000) if province_code<100000000000000
replace province_code = floor(province_code/10000000000000) if province_code>=100000000000000 & province_code<1000000000000000
replace province_code = floor(province_code/1000000000000000) if province_code>=10000000000000000
tab province_code, gen(provincedum)

*Step Two: Regressions

*1) Exp & Specified higher education, Sec Voc + inrange(birthyear, 1971, 1992) + no outliers
selmlog voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
estat hettest
local het_p = r(p)
local het_df = r(df)
sum voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", replace ctitle(Sec Voc, All Gender, Specified Higheredu,) pvalue addstat("Hettest: p-value", `het_p', "Hettest: df", `het_df')
drop m1 m2 m3

*2) Exp & Specified higher education & province fixed, Sec Voc + inrange(birthyear, 1971, 1992) + no outliers

selmlog voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
estat hettest
local het_p = r(p)
local het_df = r(df)
sum voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Voc, All Gender, Specified Higheredu, Province Dum) pvalue addstat("Hettest: p-value", `het_p', "Hettest: df", `het_df')
drop m1 m2 m3

*3) Exp & Non-specified higher education, Sec Voc + inrange(birthyear, 1971, 1992) + no outliers
selmlog voc_log_monthlyearning male exp expsqr higheredu if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr higheredu m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
estat hettest
local het_p = r(p)
local het_df = r(df)
sum voc_log_monthlyearning male exp expsqr higheredu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Voc, All Gender, Non-specified Higheredu,) pvalue addstat("Hettest: p-value", `het_p', "Hettest: df", `het_df')
drop m1 m2 m3

*4) Exp & Non-specified higher education & province fixed, Sec Voc + inrange(birthyear, 1971, 1992) + no outliers
selmlog voc_log_monthlyearning male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
estat hettest
local het_p = r(p)
local het_df = r(df)
sum voc_log_monthlyearning male exp expsqr higheredu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Voc, All Gender, Non-specified Higheredu, Province Dum) pvalue addstat("Hettest: p-value", `het_p', "Hettest: df", `het_df')
drop m1 m2 m3


*5) Exp & Specified higher education, Sec Gen + inrange(birthyear, 1971, 1992) + no outliers
selmlog gen_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
estat hettest
local het_p = r(p)
local het_df = r(df)
sum gen_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Gen, All Gender, Specified Higheredu,) pvalue addstat("Hettest: p-value", `het_p', "Hettest: df", `het_df')
drop m1 m2 m3

*6) Exp & Specified higher education & province fixed, Sec Gen + inrange(birthyear, 1971, 1992) + no outliers
selmlog gen_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
estat hettest
local het_p = r(p)
local het_df = r(df)
sum gen_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Gen, All Gender, Specified Higheredu, Province Dum) pvalue addstat("Hettest: p-value", `het_p', "Hettest: df", `het_df')
drop m1 m2 m3

*7) Exp & Non-specified higher education, Sec Gen + inrange(birthyear, 1971, 1992) + no outliers
selmlog gen_log_monthlyearning male exp expsqr higheredu if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr higheredu m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
estat hettest
local het_p = r(p)
local het_df = r(df)
sum gen_log_monthlyearning male exp expsqr higheredu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Gen, All Gender, Non-specified Higheredu,) pvalue addstat("Hettest: p-value", `het_p', "Hettest: df", `het_df')
drop m1 m2 m3

*8) Exp & Non-specified higher education & province fixed, Sec Gen + inrange(birthyear, 1971, 1992) + no outliers
selmlog gen_log_monthlyearning male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
estat hettest
local het_p = r(p)
local het_df = r(df)
sum gen_log_monthlyearning male exp expsqr higheredu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Gen, All Gender, Non-specified Higheredu, Province Dum) pvalue addstat("Hettest: p-value", `het_p', "Hettest: df", `het_df')
drop m1 m2 m3

*9) Exp & Specified higher education, Sec Voc + Male + inrange(birthyear, 1971, 1992) + no outliers
selmlog voc_log_monthlyearning exp expsqr highvocedu highgenedu adultedu if male==1 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if male==1 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
estat hettest
local het_p = r(p)
local het_df = r(df)
sum voc_log_monthlyearning exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Voc, Male, Specified Higheredu,) pvalue addstat("Hettest: p-value", `het_p', "Hettest: df", `het_df')
drop m1 m2 m3

*10) Exp & Specified higher education & province fixed, Sec Voc + Male + inrange(birthyear, 1971, 1992) + no outliers
selmlog voc_log_monthlyearning exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if male==1 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if male==1 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
estat hettest
local het_p = r(p)
local het_df = r(df)
sum voc_log_monthlyearning exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Voc, Male, Specified Higheredu, Province Dum) pvalue addstat("Hettest: p-value", `het_p', "Hettest: df", `het_df')
drop m1 m2 m3

*11) Exp & Non-specified higher education, Sec Voc + Male + inrange(birthyear, 1971, 1992) + no outliers
selmlog voc_log_monthlyearning exp expsqr higheredu if male==1 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning exp expsqr higheredu m1 m2 m3 if male==1 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
estat hettest
local het_p = r(p)
local het_df = r(df)
sum voc_log_monthlyearning exp expsqr higheredu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Voc, Male, Non-specified Higheredu,) pvalue addstat("Hettest: p-value", `het_p', "Hettest: df", `het_df')
drop m1 m2 m3

*12) Exp & Non-specified higher education & province fixed, Sec Voc + Male + inrange(birthyear, 1971, 1992) + no outliers
selmlog voc_log_monthlyearning exp expsqr higheredu provincedum2-provincedum15 if male==1 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if male==1 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
estat hettest
local het_p = r(p)
local het_df = r(df)
sum voc_log_monthlyearning exp expsqr higheredu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Voc, Male, Non-specified Higheredu, Province Dum) pvalue addstat("Hettest: p-value", `het_p', "Hettest: df", `het_df')
drop m1 m2 m3

*13) Exp & Specified higher education, Sec Voc + Female + inrange(birthyear, 1971, 1992) + no outliers
selmlog voc_log_monthlyearning exp expsqr highvocedu highgenedu adultedu if male==0 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if male==0 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
estat hettest
local het_p = r(p)
local het_df = r(df)
sum voc_log_monthlyearning exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Voc, Female, Specified Higheredu,) pvalue addstat("Hettest: p-value", `het_p', "Hettest: df", `het_df')
drop m1 m2 m3

*14) Exp & Specified higher education & province fixed, Sec Voc + Female + inrange(birthyear, 1971, 1992) + no outliers
selmlog voc_log_monthlyearning exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if male==0 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if male==0 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
estat hettest
local het_p = r(p)
local het_df = r(df)
sum voc_log_monthlyearning exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Voc, Female, Specified Higheredu, Province Dum) pvalue addstat("Hettest: p-value", `het_p', "Hettest: df", `het_df')
drop m1 m2 m3

*15) Exp & Non-specified higher education, Sec Voc + Female + inrange(birthyear, 1971, 1992) + no outliers
selmlog voc_log_monthlyearning exp expsqr higheredu if male==0 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning exp expsqr higheredu m1 m2 m3 if male==0 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
estat hettest
local het_p = r(p)
local het_df = r(df)
sum voc_log_monthlyearning male exp expsqr higheredu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Voc, Female, Non-specified Higheredu,) pvalue addstat("Hettest: p-value", `het_p', "Hettest: df", `het_df')
drop m1 m2 m3

*16) Exp & Non-specified higher education & province fixed, Sec Voc + Female + inrange(birthyear, 1971, 1992) + no outliers
selmlog voc_log_monthlyearning exp expsqr higheredu provincedum2-provincedum15 if male==0 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if male==0 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
estat hettest
local het_p = r(p)
local het_df = r(df)
sum voc_log_monthlyearning male exp expsqr higheredu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Voc, Female, Non-specified Higheredu, Province Dum) pvalue addstat("Hettest: p-value", `het_p', "Hettest: df", `het_df')
drop m1 m2 m3

*17) Exp & Specified higher education, Sec Gen + Male + inrange(birthyear, 1971, 1992) + no outliers
selmlog gen_log_monthlyearning exp expsqr highvocedu highgenedu adultedu if male==1 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if male==1 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
estat hettest
local het_p = r(p)
local het_df = r(df)
sum gen_log_monthlyearning exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Gen, Male, Specified Higheredu,) pvalue addstat("Hettest: p-value", `het_p', "Hettest: df", `het_df')
drop m1 m2 m3

*18) Exp & Specified higher education & province fixed, Sec Gen + Male + inrange(birthyear, 1971, 1992) + no outliers
selmlog gen_log_monthlyearning exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if male==1 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if male==1 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
estat hettest
local het_p = r(p)
local het_df = r(df)
sum gen_log_monthlyearning exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Gen, Male, Specified Higheredu, Province Dum) pvalue addstat("Hettest: p-value", `het_p', "Hettest: df", `het_df')
drop m1 m2 m3

*19) Exp & Non-specified higher education, Sec Gen + Male + inrange(birthyear, 1971, 1992) + no outliers
selmlog gen_log_monthlyearning exp expsqr higheredu if male==1 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning exp expsqr higheredu m1 m2 m3 if male==1 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
estat hettest
local het_p = r(p)
local het_df = r(df)
sum gen_log_monthlyearning male exp expsqr higheredu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Gen, Male, Non-specified Higheredu,) pvalue addstat("Hettest: p-value", `het_p', "Hettest: df", `het_df')
drop m1 m2 m3

*20) Exp & Non-specified higher education & province fixed, Sec Gen + Male + inrange(birthyear, 1971, 1992) + no outliers
selmlog gen_log_monthlyearning exp expsqr higheredu provincedum2-provincedum15 if male==1 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if male==1 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
estat hettest
local het_p = r(p)
local het_df = r(df)
sum gen_log_monthlyearning male exp expsqr higheredu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Gen, Male, Non-specified Higheredu, Province Dum) pvalue addstat("Hettest: p-value", `het_p', "Hettest: df", `het_df')
drop m1 m2 m3

*21) Exp & Specified higher education, Sec Gen + Female + inrange(birthyear, 1971, 1992) + no outliers
selmlog gen_log_monthlyearning exp expsqr highvocedu highgenedu adultedu if male==0 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if male==0 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
estat hettest
local het_p = r(p)
local het_df = r(df)
sum gen_log_monthlyearning exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Gen, Female, Specified Higheredu,) pvalue addstat("Hettest: p-value", `het_p', "Hettest: df", `het_df')
drop m1 m2 m3

*22) Exp & Specified higher education & province fixed, Sec Gen + Female + inrange(birthyear, 1971, 1992) + no outliers
selmlog gen_log_monthlyearning exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if male==0 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if male==0 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
estat hettest
local het_p = r(p)
local het_df = r(df)
sum gen_log_monthlyearning exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Gen, Female, Specified Higheredu, Province Dum) pvalue addstat("Hettest: p-value", `het_p', "Hettest: df", `het_df')
drop m1 m2 m3

*23) Exp & Non-specified higher education, Sec Gen + Female + inrange(birthyear, 1971, 1992) + no outliers
selmlog gen_log_monthlyearning exp expsqr higheredu if male==0 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning exp expsqr higheredu m1 m2 m3 if male==0 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
estat hettest
local het_p = r(p)
local het_df = r(df)
sum gen_log_monthlyearning exp expsqr higheredu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Gen, Female, Non-specified Higheredu,) pvalue addstat("Hettest: p-value", `het_p', "Hettest: df", `het_df')
drop m1 m2 m3

*24) Exp & Non-specified higher education & province fixed, Sec Gen + Female + inrange(birthyear, 1971, 1992) + no outliers
selmlog gen_log_monthlyearning exp expsqr higheredu provincedum2-provincedum15 if male==0 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if male==0 & inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
estat hettest
local het_p = r(p)
local het_df = r(df)
sum gen_log_monthlyearning exp expsqr higheredu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Sec Gen, Female, Non-specified Higheredu, Province Dum) pvalue addstat("Hettest: p-value", `het_p', "Hettest: df", `het_df')
drop m1 m2 m3

log close
clear all
