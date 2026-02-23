local folderpath "/Users/wyattwyatt/Downloads/Revision Code/Aiden/Alternative Dependent Variables/Selmlog #Job & Wages/Urban"
local logname "Selmlog Urban (1) #Jobs (2) Start Wage (3) Wage Growth"
local datapath "/Users/wyattwyatt/Downloads/Revision Code/20240716 Urban Chip2018 and Instrumental Statistics and Inflation"
local filename1 "Selmlog Urban #Jobs"
local filename2 "Selmlog Urban Start Wage"
local filename3 "Selmlog Urban Wage Growth"

local xlspath1_1 "`folderpath'/`filename1'.xls"
local xlspath1_2 "`folderpath'/`filename1' NoOutliers.xls"
local xlspath2_1 "`folderpath'/`filename2'.xls"
local xlspath2_2 "`folderpath'/`filename2' NoOutliers.xls"
local xlspath3_1 "`folderpath'/`filename3'.xls"
local xlspath3_2 "`folderpath'/`filename3' NoOutliers.xls"
log using "`folderpath'/`logname'.log", replace
use "`datapath'", clear
****Because the instrumental variables take too much time to run, I combine the #Jobs, Current Job Start Wage, and Wage Growth regressions all into this .do file. If you wish to run one seperately, simply delete or nullify the other two parts of regressions. Search *1) #Jobs, *2) Start Wage, or *3) Wage Growth in this file to jump to the regressions!

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
*The specific two; Do that for rural after special care.
replace province_code = 51 if province_code==.
tab province_code, gen(provincedum)

*8) Birth Month cohort

gen birthmonth = A04_2 if A04_2!=-88 & A04_2!=-99
gen t = birthmonth - 9 + 12 * (birthyear - 1979)
gen d = 1 if t >= 0 & t != .
replace d = 0 if t < 1
gen td = t * d

*9) Tenure

gen yearstart = C02 if C02!=-88 & C02!=-99
gen tenure = 2018 - yearstart
replace tenure = 0 if tenure == -1
gen tenuresqr = tenure * tenure

*10) Dependent variables: Current Job Condition

*number of jobs
gen jobs = C05_3 if C05_3 >= 1
gen voc_jobs = jobs if secvocedu == 1
gen gen_jobs = jobs if secgenedu == 1

sum jobs, d

*start exp
gen startexp = exp - tenure
replace startexp = 0 if startexp<0
gen startexpsqr = startexp * startexp
**********PROBLEM HERE: NEGATIVE & EXTREME VALUES


*start wage & wage growth
gen age_yearstart = yearstart - birthyear
	*the outlier of age_yearstart will be corrected in the following calculation.
gen startwage = C05_2 if C05_2 != -88 & C05_2 != -99
gen startwage2018 = .
foreach i of num 1987/2018 {
	replace startwage2018 = startwage / inflation`i' * 100 if yearstart == `i' & startwage > 0 & monthlyearning > 0 & age_yearstart >= 16
}
gen logstartwage2018 = ln(startwage2018)
gen voc_logstartwage2018 = logstartwage2018 if secvocedu == 1
gen gen_logstartwage2018 = logstartwage2018 if secgenedu == 1

gen wagegrowth = (monthlyearning / startwage2018)^(1 / tenure) - 1
gen voc_wagegrowth = wagegrowth if secvocedu == 1
gen gen_wagegrowth = wagegrowth if secgenedu == 1

sum startwage, d
sum startwage2018, d
sum logstartwage2018, d
sum wagegrowth, d

*Step Two: Regressions

*1) #Jobs

*With Outliners
selmlog voc_jobs male exp expsqr highvocedu highgenedu adultedu if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress voc_jobs male exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if inrange(birthyear, 1971, 1992)
sum voc_jobs male exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath1_1'", replace ctitle(Sec Voc, Higheredu Seperate,) pvalue
drop m1 m2 m3

selmlog voc_jobs male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress voc_jobs male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992)
sum voc_jobs male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath1_1'", append ctitle(Sec Voc, Higheredu Seperate, Province Dum) pvalue
drop m1 m2 m3

selmlog voc_jobs male exp expsqr higheredu if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress voc_jobs male exp expsqr higheredu m1 m2 m3 if inrange(birthyear, 1971, 1992)
sum voc_jobs male exp expsqr higheredu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath1_1'", append ctitle(Sec Voc, Higheredu Together,) pvalue
drop m1 m2 m3

selmlog voc_jobs male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress voc_jobs male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992)
sum voc_jobs male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath1_1'", append ctitle(Sec Voc, Higheredu Together, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_jobs male exp expsqr highvocedu highgenedu adultedu if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress gen_jobs male exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if inrange(birthyear, 1971, 1992)
sum gen_jobs male exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath1_1'", append ctitle(Sec Gen, Higheredu Seperate,) pvalue
drop m1 m2 m3

selmlog gen_jobs male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress gen_jobs male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992)
sum gen_jobs male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath1_1'", append ctitle(Sec Gen, Higheredu Seperate, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_jobs male exp expsqr higheredu if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress gen_jobs male exp expsqr higheredu m1 m2 m3 if inrange(birthyear, 1971, 1992)
sum gen_jobs male exp expsqr higheredu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath1_1'", append ctitle(Sec Gen, Higheredu Together,) pvalue
drop m1 m2 m3

selmlog gen_jobs male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress gen_jobs male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992)
sum gen_jobs male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath1_1'", append ctitle(Sec Gen, Higheredu Together, Province Dum) pvalue
drop m1 m2 m3

*Without Outliers (99%)
selmlog voc_jobs male exp expsqr highvocedu highgenedu adultedu if inrange(birthyear, 1971, 1992) & inrange(jobs, 1, 8), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress voc_jobs male exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(jobs, 1, 8)
sum voc_jobs male exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath1_2'", replace ctitle(Sec Voc, Higheredu Seperate,) pvalue
drop m1 m2 m3

selmlog voc_jobs male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(jobs, 1, 8), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress voc_jobs male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(jobs, 1, 8)
sum voc_jobs male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath1_2'", append ctitle(Sec Voc, Higheredu Seperate, Province Dum) pvalue
drop m1 m2 m3

selmlog voc_jobs male exp expsqr higheredu if inrange(birthyear, 1971, 1992) & inrange(jobs, 1, 8), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress voc_jobs male exp expsqr higheredu m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(jobs, 1, 8)
sum voc_jobs male exp expsqr higheredu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath1_2'", append ctitle(Sec Voc, Higheredu Together,) pvalue
drop m1 m2 m3

selmlog voc_jobs male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(jobs, 1, 8), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress voc_jobs male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(jobs, 1, 8)
sum voc_jobs male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath1_2'", append ctitle(Sec Voc, Higheredu Together, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_jobs male exp expsqr highvocedu highgenedu adultedu if inrange(birthyear, 1971, 1992) & inrange(jobs, 1, 8), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress gen_jobs male exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(jobs, 1, 8)
sum gen_jobs male exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath1_2'", append ctitle(Sec Gen, Higheredu Seperate,) pvalue
drop m1 m2 m3

selmlog gen_jobs male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(jobs, 1, 8), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress gen_jobs male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(jobs, 1, 8)
sum gen_jobs male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath1_2'", append ctitle(Sec Gen, Higheredu Seperate, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_jobs male exp expsqr higheredu if inrange(birthyear, 1971, 1992) & inrange(jobs, 1, 8), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress gen_jobs male exp expsqr higheredu m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(jobs, 1, 8)
sum gen_jobs male exp expsqr higheredu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath1_2'", append ctitle(Sec Gen, Higheredu Together,) pvalue
drop m1 m2 m3

selmlog gen_jobs male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(jobs, 1, 8), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress gen_jobs male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(jobs, 1, 8)
sum gen_jobs male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath1_2'", append ctitle(Sec Gen, Higheredu Together, Province Dum) pvalue
drop m1 m2 m3

*2) Start Wage

************PROBLRM HERE: SEL(EDUCAT: EXP)

*With Outliners
selmlog voc_logstartwage2018 male startexp startexpsqr highvocedu highgenedu adultedu if inrange(birthyear, 1971, 1992), sel(educat=male startexp startexpsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress voc_logstartwage2018 male startexp startexpsqr highvocedu highgenedu adultedu m1 m2 m3 if inrange(birthyear, 1971, 1992)
sum voc_logstartwage2018 male startexp startexpsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath2_1'", replace ctitle(Sec Voc, Higheredu Seperate,) pvalue
drop m1 m2 m3

selmlog voc_logstartwage2018 male startexp startexpsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male startexp startexpsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress voc_logstartwage2018 male startexp startexpsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992)
sum voc_logstartwage2018 male startexp startexpsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath2_1'", append ctitle(Sec Voc, Higheredu Seperate, Province Dum) pvalue
drop m1 m2 m3

selmlog voc_logstartwage2018 male startexp startexpsqr higheredu if inrange(birthyear, 1971, 1992), sel(educat=male startexp startexpsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress voc_logstartwage2018 male startexp startexpsqr higheredu m1 m2 m3 if inrange(birthyear, 1971, 1992)
sum voc_logstartwage2018 male startexp startexpsqr higheredu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath2_1'", append ctitle(Sec Voc, Higheredu Together,) pvalue
drop m1 m2 m3

selmlog voc_logstartwage2018 male startexp startexpsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male startexp startexpsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress voc_logstartwage2018 male startexp startexpsqr higheredu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992)
sum voc_logstartwage2018 male startexp startexpsqr higheredu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath2_1'", append ctitle(Sec Voc, Higheredu Together, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_logstartwage2018 male startexp startexpsqr highvocedu highgenedu adultedu if inrange(birthyear, 1971, 1992), sel(educat=male startexp startexpsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress gen_logstartwage2018 male startexp startexpsqr highvocedu highgenedu adultedu m1 m2 m3 if inrange(birthyear, 1971, 1992)
sum gen_logstartwage2018 male startexp startexpsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath2_1'", append ctitle(Sec Gen, Higheredu Seperate,) pvalue
drop m1 m2 m3

selmlog gen_logstartwage2018 male startexp startexpsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male startexp startexpsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress gen_logstartwage2018 male startexp startexpsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992)
sum gen_logstartwage2018 male startexp startexpsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath2_1'", append ctitle(Sec Gen, Higheredu Seperate, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_logstartwage2018 male startexp startexpsqr higheredu if inrange(birthyear, 1971, 1992), sel(educat=male startexp startexpsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress gen_logstartwage2018 male startexp startexpsqr higheredu m1 m2 m3 if inrange(birthyear, 1971, 1992)
sum gen_logstartwage2018 male startexp startexpsqr higheredu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath2_1'", append ctitle(Sec Gen, Higheredu Together,) pvalue
drop m1 m2 m3

selmlog gen_logstartwage2018 male startexp startexpsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male startexp startexpsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress gen_logstartwage2018 male startexp startexpsqr higheredu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992)
sum gen_logstartwage2018 male startexp startexpsqr higheredu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath2_1'", append ctitle(Sec Gen, Higheredu Together, Province Dum) pvalue
drop m1 m2 m3

*Without Outliers (99%)
selmlog voc_logstartwage2018 male startexp startexpsqr highvocedu highgenedu adultedu if inrange(birthyear, 1971, 1992) & inrange(startwage2018, 172, 21651), sel(educat=male startexp startexpsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress voc_logstartwage2018 male startexp startexpsqr highvocedu highgenedu adultedu m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(startwage2018, 172, 21651)
sum voc_logstartwage2018 male startexp startexpsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath2_2'", replace ctitle(Sec Voc, Higheredu Seperate,) pvalue
drop m1 m2 m3

selmlog voc_logstartwage2018 male startexp startexpsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(startwage2018, 172, 21651), sel(educat=male startexp startexpsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress voc_logstartwage2018 male startexp startexpsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(startwage2018, 172, 21651)
sum voc_logstartwage2018 male startexp startexpsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath2_2'", append ctitle(Sec Voc, Higheredu Seperate, Province Dum) pvalue
drop m1 m2 m3

selmlog voc_logstartwage2018 male startexp startexpsqr higheredu if inrange(birthyear, 1971, 1992) & inrange(startwage2018, 172, 21651), sel(educat=male startexp startexpsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress voc_logstartwage2018 male startexp startexpsqr higheredu m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(startwage2018, 172, 21651)
sum voc_logstartwage2018 male startexp startexpsqr higheredu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath2_2'", append ctitle(Sec Voc, Higheredu Together,) pvalue
drop m1 m2 m3

selmlog voc_logstartwage2018 male startexp startexpsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(startwage2018, 172, 21651), sel(educat=male startexp startexpsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress voc_logstartwage2018 male startexp startexpsqr higheredu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(startwage2018, 172, 21651)
sum voc_logstartwage2018 male startexp startexpsqr higheredu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath2_2'", append ctitle(Sec Voc, Higheredu Together, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_logstartwage2018 male startexp startexpsqr highvocedu highgenedu adultedu if inrange(birthyear, 1971, 1992) & inrange(startwage2018, 172, 21651), sel(educat=male startexp startexpsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress gen_logstartwage2018 male startexp startexpsqr highvocedu highgenedu adultedu m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(startwage2018, 172, 21651)
sum gen_logstartwage2018 male startexp startexpsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath2_2'", append ctitle(Sec Gen, Higheredu Seperate,) pvalue
drop m1 m2 m3

selmlog gen_logstartwage2018 male startexp startexpsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(startwage2018, 172, 21651), sel(educat=male startexp startexpsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress gen_logstartwage2018 male startexp startexpsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(startwage2018, 172, 21651)
sum gen_logstartwage2018 male startexp startexpsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath2_2'", append ctitle(Sec Gen, Higheredu Seperate, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_logstartwage2018 male startexp startexpsqr higheredu if inrange(birthyear, 1971, 1992) & inrange(startwage2018, 172, 21651), sel(educat=male startexp startexpsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress gen_logstartwage2018 male startexp startexpsqr higheredu m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(startwage2018, 172, 21651)
sum gen_logstartwage2018 male startexp startexpsqr higheredu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath2_2'", append ctitle(Sec Gen, Higheredu Together,) pvalue
drop m1 m2 m3

selmlog gen_logstartwage2018 male startexp startexpsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(startwage2018, 172, 21651), sel(educat=male startexp startexpsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress gen_logstartwage2018 male startexp startexpsqr higheredu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(startwage2018, 172, 21651)
sum gen_logstartwage2018 male startexp startexpsqr higheredu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath2_2'", append ctitle(Sec Gen, Higheredu Together, Province Dum) pvalue
drop m1 m2 m3




*3) Wage Growth

*With Outliners
selmlog voc_wagegrowth male exp expsqr highvocedu highgenedu adultedu if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress voc_wagegrowth male exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if inrange(birthyear, 1971, 1992)
sum voc_wagegrowth male exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath3_1'", replace ctitle(Sec Voc, Higheredu Seperate,) pvalue
drop m1 m2 m3

selmlog voc_wagegrowth male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress voc_wagegrowth male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992)
sum voc_wagegrowth male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath3_1'", append ctitle(Sec Voc, Higheredu Seperate, Province Dum) pvalue
drop m1 m2 m3

selmlog voc_wagegrowth male exp expsqr higheredu if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress voc_wagegrowth male exp expsqr higheredu m1 m2 m3 if inrange(birthyear, 1971, 1992)
sum voc_wagegrowth male exp expsqr higheredu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath3_1'", append ctitle(Sec Voc, Higheredu Together,) pvalue
drop m1 m2 m3

selmlog voc_wagegrowth male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress voc_wagegrowth male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992)
sum voc_wagegrowth male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath3_1'", append ctitle(Sec Voc, Higheredu Together, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_wagegrowth male exp expsqr highvocedu highgenedu adultedu if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress gen_wagegrowth male exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if inrange(birthyear, 1971, 1992)
sum gen_wagegrowth male exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath3_1'", append ctitle(Sec Gen, Higheredu Seperate,) pvalue
drop m1 m2 m3

selmlog gen_wagegrowth male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress gen_wagegrowth male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992)
sum gen_wagegrowth male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath3_1'", append ctitle(Sec Gen, Higheredu Seperate, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_wagegrowth male exp expsqr higheredu if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress gen_wagegrowth male exp expsqr higheredu m1 m2 m3 if inrange(birthyear, 1971, 1992)
sum gen_wagegrowth male exp expsqr higheredu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath3_1'", append ctitle(Sec Gen, Higheredu Together,) pvalue
drop m1 m2 m3

selmlog gen_wagegrowth male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress gen_wagegrowth male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992)
sum gen_wagegrowth male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath3_1'", append ctitle(Sec Gen, Higheredu Together, Province Dum) pvalue
drop m1 m2 m3

*Without Outliers (99%)
selmlog voc_wagegrowth male exp expsqr highvocedu highgenedu adultedu if inrange(birthyear, 1971, 1992) & inrange(wagegrowth, -.50, 1.66), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress voc_wagegrowth male exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(wagegrowth, -.50, 1.66)
sum voc_wagegrowth male exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath3_2'", replace ctitle(Sec Voc, Higheredu Seperate,) pvalue
drop m1 m2 m3

selmlog voc_wagegrowth male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(wagegrowth, -.50, 1.66), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress voc_wagegrowth male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(wagegrowth, -.50, 1.66)
sum voc_wagegrowth male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath3_2'", append ctitle(Sec Voc, Higheredu Seperate, Province Dum) pvalue
drop m1 m2 m3

selmlog voc_wagegrowth male exp expsqr higheredu if inrange(birthyear, 1971, 1992) & inrange(wagegrowth, -.50, 1.66), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress voc_wagegrowth male exp expsqr higheredu m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(wagegrowth, -.50, 1.66)
sum voc_wagegrowth male exp expsqr higheredu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath3_2'", append ctitle(Sec Voc, Higheredu Together,) pvalue
drop m1 m2 m3

selmlog voc_wagegrowth male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(wagegrowth, -.50, 1.66), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress voc_wagegrowth male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(wagegrowth, -.50, 1.66)
sum voc_wagegrowth male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath3_2'", append ctitle(Sec Voc, Higheredu Together, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_wagegrowth male exp expsqr highvocedu highgenedu adultedu if inrange(birthyear, 1971, 1992) & inrange(wagegrowth, -.50, 1.66), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress gen_wagegrowth male exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(wagegrowth, -.50, 1.66)
sum gen_wagegrowth male exp expsqr highvocedu highgenedu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath3_2'", append ctitle(Sec Gen, Higheredu Seperate,) pvalue
drop m1 m2 m3

selmlog gen_wagegrowth male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(wagegrowth, -.50, 1.66), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress gen_wagegrowth male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(wagegrowth, -.50, 1.66)
sum gen_wagegrowth male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath3_2'", append ctitle(Sec Gen, Higheredu Seperate, Province Dum) pvalue
drop m1 m2 m3

selmlog gen_wagegrowth male exp expsqr higheredu if inrange(birthyear, 1971, 1992) & inrange(wagegrowth, -.50, 1.66), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress gen_wagegrowth male exp expsqr higheredu m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(wagegrowth, -.50, 1.66)
sum gen_wagegrowth male exp expsqr higheredu adultedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath3_2'", append ctitle(Sec Gen, Higheredu Together,) pvalue
drop m1 m2 m3

selmlog gen_wagegrowth male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(wagegrowth, -.50, 1.66), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress gen_wagegrowth male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(wagegrowth, -.50, 1.66)
sum gen_wagegrowth male exp expsqr higheredu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath3_2'", append ctitle(Sec Gen, Higheredu Together, Province Dum) pvalue
drop m1 m2 m3

log close
clear all
