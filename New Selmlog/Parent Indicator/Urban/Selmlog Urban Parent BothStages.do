local folderpath "/Users/wyattwyatt/Downloads/Revision Code/Aiden/New Selmlog/Parent Indicator/Urban"
local logname "Selmlog Urban Parent BothStages"
local datapath "/Users/wyattwyatt/Downloads/Revision Code/20240716 Urban Chip2018 and Instrumental Statistics and Inflation.dta"

local xlspath "`folderpath'/`logname'.xls"
log using "`folderpath'/`logname'.log", replace
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

save "`folderpath'/`logname'.dta", replace

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
*income for secjun
gen jun_log_monthlyearning = log_monthlyearning if secjun == 1

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

*8) Parent Indicators
merge m:1 hhcode using "`folderpath'/`logname'.dta"
*parent_secedu
gen parent_secedu = 0 if (A02==1 & (inrange(H03_R1, 1, 3) | inrange(H03_R2, 1, 3))) | (A02==2 & (inrange(H03_R3, 1, 3) | inrange(H03_R4, 1, 3)))
replace parent_secedu = 0 if A02 ==3 & (headsecedu == 0 | spousesecedu == 0)
replace parent_secedu = 0 if (A02 == 2 & spouseparentsecedu == 0) | (A02 == 1 & headparentsecedu == 0)
replace parent_secedu=1 if (A02==1 & (inrange(H03_R1, 4, 9) | inrange(H03_R2, 4, 9)))|(A02==2 & (inrange(H03_R3, 4, 9) | inrange(H03_R4, 4, 9)))
replace parent_secedu = 1 if A02 ==3 & (headsecedu == 1 | spousesecedu == 1)
replace parent_secedu = 1 if (A02 == 2 & spouseparentsecedu == 1) | (A02 == 1 & headparentsecedu == 1)
tab parent_secedu
 *parent_highedu
gen parent_highedu = 0 if (A02==1 & (inrange(H03_R1, 1, 6) | inrange(H03_R2, 1, 6))) | (A02==2 & (inrange(H03_R3, 1, 6) | inrange(H03_R4, 1, 6)))
replace parent_highedu = 0 if A02 == 3 & (headhighedu == 0 | spousehighedu == 0)
replace parent_highedu = 0 if (A02 == 2 & spouseparenthighedu == 0) | (A02 == 1 & headparenthighedu == 0)
replace parent_highedu=1 if (A02==1 & (inrange(H03_R1, 7, 9) | inrange(H03_R2, 7, 9)))|(A02==2 & (inrange(H03_R3, 7, 9) | inrange(H03_R4, 7, 9)))
replace parent_highedu = 1 if A02 == 3 & (headhighedu == 1 | spousehighedu == 1)
replace parent_highedu = 1 if (A02 == 2 & spouseparenthighedu == 1) | (A02 == 1 & headparenthighedu == 1)
tab parent_highedu
*parent_partymember
gen parent_partymember = 0 if ((A02==1 & (inrange(H07_R1, 2, 4) | inrange(H07_R2, 2, 4))) | (A02==2 & (inrange(H07_R3, 2, 4) | inrange(H07_R4, 2, 4))))
replace parent_partymember = 0 if A02 == 3 & (headparty == 0 | spouseparty == 0)
replace parent_partymember = 0 if (A02 == 2 & spouseparentparty == 0) | (A02 == 1 & headparentparty == 0)
replace parent_partymember=1 if (A02==1 & (H07_R1 == 1 | H07_R2 == 1)) | (A02==2 & (H07_R3 == 1 | H07_R4 == 1))
replace parent_partymember = 1 if A02 == 3 & (headparty == 1 | spouseparty == 1)
replace parent_partymember = 1 if (A02 == 2 & spouseparentparty == 1) | (A02 == 1 & headparentparty == 1)
tab parent_partymember

*9) Key School Indicator

gen Keyschool = 0 if A14 != .
replace Keyschool = 1 if inrange(A14, 1, 3)

*10) GaoKao Indicator
gen TakeGaoKao = 1 if A15_1 == 1
replace TakeGaoKao = 0 if A15_1 == 2
tab TakeGaoKao
tab TakeGaoKao educat
tab TakeGaoKao educat if male==1
tab TakeGaoKao educat if male==0

*Step Two: Regressions

*1) All parent indicators & Specified higher education, Sec Voc + inrange(birthyear, 1971, 1992)
selmlog voc_log_monthlyearning  male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_secedu parent_highedu parent_partymember ) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", replace ctitle(All Parent Indicators, Sec Voc, Specified Higheredu,) pvalue
drop m1 m2 m3

*2) All parent indicators & Specified higher education, Sec Voc + inrange(birthyear, 1971, 1992) + Provincedums
selmlog voc_log_monthlyearning  male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_secedu parent_highedu parent_partymember ) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember provincedum2-provincedum15  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(All Parent Indicators, Sec Voc, Specified Higheredu, Province Dum) pvalue
drop m1 m2 m3

*3) All parent indicators & Combined higher education, Sec Voc + inrange(birthyear, 1971, 1992)
selmlog voc_log_monthlyearning  male exp expsqr higheredu parent_secedu parent_highedu parent_partymember if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_secedu parent_highedu parent_partymember ) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu parent_partymember  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum voc_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu parent_partymember m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(All Parent Indicators, Sec Voc, Non-specified Higheredu,) pvalue
drop m1 m2 m3

*4) All parent indicators & Combined higher education, Sec Voc + inrange(birthyear, 1971, 1992) + Provincedums
selmlog voc_log_monthlyearning  male exp expsqr higheredu parent_secedu parent_highedu parent_partymember provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_secedu parent_highedu parent_partymember ) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu parent_partymember provincedum2-provincedum15  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum voc_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu parent_partymember provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(All Parent Indicators, Sec Voc, Non-specified Higheredu, Province Dum) pvalue
drop m1 m2 m3

*5) All parent indicators & Specified higher education, Sec Gen + inrange(birthyear, 1971, 1992)
selmlog gen_log_monthlyearning  male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_secedu parent_highedu parent_partymember ) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(All Parent Indicators, Sec Gen, Specified Higheredu,) pvalue
drop m1 m2 m3

*6) All parent indicators & Specified higher education, Sec Gen + inrange(birthyear, 1971, 1992) + Provincedums
selmlog gen_log_monthlyearning  male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_secedu parent_highedu parent_partymember ) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember provincedum2-provincedum15  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum gen_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(All Parent Indicators, Sec Gen, Specified Higheredu, Province Dum) pvalue
drop m1 m2 m3

*7) All parent indicators & Combined higher education, Sec Gen + inrange(birthyear, 1971, 1992)
selmlog gen_log_monthlyearning  male exp expsqr higheredu parent_secedu parent_highedu parent_partymember if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_secedu parent_highedu parent_partymember ) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu parent_partymember  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum gen_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu parent_partymember m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(All Parent Indicators, Sec Gen, Non-specified Higheredu,) pvalue
drop m1 m2 m3

*8) All parent indicators & Combined higher education, Sec Gen + inrange(birthyear, 1971, 1992) + Provincedums
selmlog gen_log_monthlyearning  male exp expsqr higheredu parent_secedu parent_highedu parent_partymember provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_secedu parent_highedu parent_partymember ) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu parent_partymember provincedum2-provincedum15  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum gen_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu parent_partymember provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(All Parent Indicators, Sec Gen, Non-specified Higheredu, Province Dum) pvalue
drop m1 m2 m3












*1) Parent Edu & Specified higher education, Sec Voc + inrange(birthyear, 1971, 1992)
selmlog voc_log_monthlyearning  male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_secedu parent_highedu ) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Parent Edu, Sec Voc, Specified Higheredu,) pvalue
drop m1 m2 m3

*2) Parent Edu & Specified higher education, Sec Voc + inrange(birthyear, 1971, 1992) + Provincedums
selmlog voc_log_monthlyearning  male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_secedu parent_highedu ) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu provincedum2-provincedum15  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Parent Edu, Sec Voc, Specified Higheredu, Province Dum) pvalue
drop m1 m2 m3

*3) Parent Edu & Combined higher education, Sec Voc + inrange(birthyear, 1971, 1992)
selmlog voc_log_monthlyearning  male exp expsqr higheredu parent_secedu parent_highedu if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_secedu parent_highedu ) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum voc_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Parent Edu, Sec Voc, Non-specified Higheredu,) pvalue
drop m1 m2 m3

*4) Parent Edu & Combined higher education, Sec Voc + inrange(birthyear, 1971, 1992) + Provincedums
selmlog voc_log_monthlyearning  male exp expsqr higheredu parent_secedu parent_highedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_secedu parent_highedu ) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu provincedum2-provincedum15  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum voc_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Parent Edu, Sec Voc, Non-specified Higheredu, Province Dum) pvalue
drop m1 m2 m3

*5) Parent Edu & Specified higher education, Sec Gen + inrange(birthyear, 1971, 1992)
selmlog gen_log_monthlyearning  male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_secedu parent_highedu ) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Parent Edu, Sec Gen, Specified Higheredu,) pvalue
drop m1 m2 m3

*6) Parent Edu & Specified higher education, Sec Gen + inrange(birthyear, 1971, 1992) + Provincedums
selmlog gen_log_monthlyearning  male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_secedu parent_highedu ) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu provincedum2-provincedum15  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum gen_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Parent Edu, Sec Gen, Specified Higheredu, Province Dum) pvalue
drop m1 m2 m3

*7) Parent Edu & Combined higher education, Sec Gen + inrange(birthyear, 1971, 1992)
selmlog gen_log_monthlyearning  male exp expsqr higheredu parent_secedu parent_highedu if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_secedu parent_highedu ) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum gen_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Parent Edu, Sec Gen, Non-specified Higheredu,) pvalue
drop m1 m2 m3

*8) Parent Edu & Combined higher education, Sec Gen + inrange(birthyear, 1971, 1992) + Provincedums
selmlog gen_log_monthlyearning  male exp expsqr higheredu parent_secedu parent_highedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_secedu parent_highedu ) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu provincedum2-provincedum15  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum gen_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Parent Edu, Sec Gen, Non-specified Higheredu, Province Dum) pvalue
drop m1 m2 m3










*1) Parent Party Membership & Specified higher education, Sec Voc + inrange(birthyear, 1971, 1992)
selmlog voc_log_monthlyearning  male exp expsqr highvocedu highgenedu adultedu parent_partymember if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_partymember ) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_partymember  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_partymember m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Parent Party Membership, Sec Voc, Specified Higheredu,) pvalue
drop m1 m2 m3

*2) Parent Party Membership & Specified higher education, Sec Voc + inrange(birthyear, 1971, 1992) + Provincedums
selmlog voc_log_monthlyearning  male exp expsqr highvocedu highgenedu adultedu parent_partymember provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_partymember ) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_partymember provincedum2-provincedum15  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_partymember provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Parent Party Membership, Sec Voc, Specified Higheredu, Province Dum) pvalue
drop m1 m2 m3

*3) Parent Party Membership & Combined higher education, Sec Voc + inrange(birthyear, 1971, 1992)
selmlog voc_log_monthlyearning  male exp expsqr higheredu parent_partymember if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_partymember ) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr higheredu parent_partymember  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum voc_log_monthlyearning male exp expsqr higheredu parent_partymember m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Parent Party Membership, Sec Voc, Non-specified Higheredu,) pvalue
drop m1 m2 m3

*4) Parent Party Membership & Combined higher education, Sec Voc + inrange(birthyear, 1971, 1992) + Provincedums
selmlog voc_log_monthlyearning  male exp expsqr higheredu parent_partymember provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_partymember ) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr higheredu parent_partymember provincedum2-provincedum15  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum voc_log_monthlyearning male exp expsqr higheredu parent_partymember provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Parent Party Membership, Sec Voc, Non-specified Higheredu, Province Dum) pvalue
drop m1 m2 m3

*5) Parent Party Membership & Specified higher education, Sec Gen + inrange(birthyear, 1971, 1992)
selmlog gen_log_monthlyearning  male exp expsqr highvocedu highgenedu adultedu parent_partymember if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_partymember ) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_partymember  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_partymember m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Parent Party Membership, Sec Gen, Specified Higheredu,) pvalue
drop m1 m2 m3

*6) Parent Party Membership & Specified higher education, Sec Gen + inrange(birthyear, 1971, 1992) + Provincedums
selmlog gen_log_monthlyearning  male exp expsqr highvocedu highgenedu adultedu parent_partymember provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_partymember ) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_partymember provincedum2-provincedum15  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum gen_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_partymember provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Parent Party Membership, Sec Gen, Specified Higheredu, Province Dum) pvalue
drop m1 m2 m3

*7) Parent Party Membership & Combined higher education, Sec Gen + inrange(birthyear, 1971, 1992)
selmlog gen_log_monthlyearning  male exp expsqr higheredu parent_partymember if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_partymember ) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr higheredu parent_partymember  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum gen_log_monthlyearning male exp expsqr higheredu parent_partymember m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Parent Party Membership, Sec Gen, Non-specified Higheredu,) pvalue
drop m1 m2 m3

*8) Parent Party Membership & Combined higher education, Sec Gen + inrange(birthyear, 1971, 1992) + Provincedums
selmlog gen_log_monthlyearning  male exp expsqr higheredu parent_partymember provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_partymember ) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr higheredu parent_partymember provincedum2-provincedum15  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum gen_log_monthlyearning male exp expsqr higheredu parent_partymember provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(Parent Party Membership, Sec Gen, Non-specified Higheredu, Province Dum) pvalue
drop m1 m2 m3












*1) All Parent Indicators & Keyschool & Specified higher education, Sec Voc + inrange(birthyear, 1971, 1992)
selmlog voc_log_monthlyearning  male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember Keyschool if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_secedu parent_highedu parent_partymember Keyschool) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember Keyschool m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember Keyschool m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(All Parent Indicators & Keyschool, Sec Voc, Specified Higheredu,) pvalue
drop m1 m2 m3

*2) All Parent Indicators & Keyschool & Specified higher education, Sec Voc + inrange(birthyear, 1971, 1992) + Provincedums
selmlog voc_log_monthlyearning  male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember Keyschool provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_secedu parent_highedu parent_partymember Keyschool) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember Keyschool provincedum2-provincedum15  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember Keyschool provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(All Parent Indicators & Keyschool, Sec Voc, Specified Higheredu, Province Dum) pvalue
drop m1 m2 m3

*3) All Parent Indicators & Keyschool & Combined higher education, Sec Voc + inrange(birthyear, 1971, 1992)
selmlog voc_log_monthlyearning  male exp expsqr higheredu parent_secedu parent_highedu parent_partymember Keyschool if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_secedu parent_highedu parent_partymember Keyschool) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu parent_partymember Keyschool m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum voc_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu parent_partymember Keyschool m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(All Parent Indicators & Keyschool, Sec Voc, Non-specified Higheredu,) pvalue
drop m1 m2 m3

*4) All Parent Indicators & Keyschool & Combined higher education, Sec Voc + inrange(birthyear, 1971, 1992) + Provincedums
selmlog voc_log_monthlyearning  male exp expsqr higheredu parent_secedu parent_highedu parent_partymember Keyschool provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_secedu parent_highedu parent_partymember Keyschool) dmf(2) showmlogit gen(m)

qui regress voc_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu parent_partymember Keyschool provincedum2-provincedum15  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum voc_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu parent_partymember Keyschool provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(All Parent Indicators & Keyschool, Sec Voc, Non-specified Higheredu, Province Dum) pvalue
drop m1 m2 m3

*5) All Parent Indicators & Keyschool & Specified higher education, Sec Gen + inrange(birthyear, 1971, 1992)
selmlog gen_log_monthlyearning  male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember Keyschool if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_secedu parent_highedu parent_partymember Keyschool) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember Keyschool m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum voc_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember Keyschool m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(All Parent Indicators & Keyschool, Sec Gen, Specified Higheredu,) pvalue
drop m1 m2 m3

*6) All Parent Indicators & Keyschool & Specified higher education, Sec Gen + inrange(birthyear, 1971, 1992) + Provincedums
selmlog gen_log_monthlyearning  male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember Keyschool provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_secedu parent_highedu parent_partymember Keyschool) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember Keyschool provincedum2-provincedum15  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum gen_log_monthlyearning male exp expsqr highvocedu highgenedu adultedu parent_secedu parent_highedu parent_partymember Keyschool provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(All Parent Indicators & Keyschool, Sec Gen, Specified Higheredu, Province Dum) pvalue
drop m1 m2 m3

*7) All Parent Indicators & Keyschool & Combined higher education, Sec Gen + inrange(birthyear, 1971, 1992)
selmlog gen_log_monthlyearning  male exp expsqr higheredu parent_secedu parent_highedu parent_partymember Keyschool if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_secedu parent_highedu parent_partymember Keyschool) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu parent_partymember Keyschool m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum gen_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu parent_partymember Keyschool m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(All Parent Indicators & Keyschool, Sec Gen, Non-specified Higheredu,) pvalue
drop m1 m2 m3

*8) All Parent Indicators & Keyschool & Combined higher education, Sec Gen + inrange(birthyear, 1971, 1992) + Provincedums
selmlog gen_log_monthlyearning  male exp expsqr higheredu parent_secedu parent_highedu parent_partymember Keyschool provincedum2-provincedum15 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000), sel(educat=male exp expsqr ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative  parent_secedu parent_highedu parent_partymember Keyschool) dmf(2) showmlogit gen(m)

qui regress gen_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu parent_partymember Keyschool provincedum2-provincedum15  m1 m2 m3 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000)
sum gen_log_monthlyearning male exp expsqr higheredu parent_secedu parent_highedu parent_partymember Keyschool provincedum2-provincedum15 m1 m2 m3 if e(sample)
outreg2 using "`xlspath'", append ctitle(All Parent Indicators & Keyschool, Sec Gen, Non-specified Higheredu, Province Dum) pvalue
drop m1 m2 m3



log close
clear all
