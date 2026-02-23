local xlsxfolderpath "/Users/wyattwyatt/Downloads/Revision Code/Aiden/Indicator & DIff-in-diff/1979"
local folderpath "/Users/wyattwyatt/Downloads/Revision Code/Aiden/Indicator & DIff-in-diff/1979/Rural"
local logname "Indicator DID Urban 1979"
local datapath "/Users/wyattwyatt/Downloads/Revision Code/20240716 Rural Chip2018 and Instrumental Statistics and Inflation.dta"

local xlsxpath "`xlsxfolderpath'/DID 1979.xlsx"
log using "`folderpath'/`logname'.log", replace
use "`datapath'", clear
****DIFF if DIFF has two procedures. First it creates a new dataset with parents info, then it merges the new dataset for further regressions.
****Urban and Rural codes are in two .do files, but they are stored in the same excel workbook (if we make the xlsxfolderpath the same).

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
tab province_code, gen(provincedum)

*8) Birth Month cohort

gen birthmonth = A04_2 if A04_2!=-88 & A04_2!=-99
gen t = birthmonth - 9 + 12 * (birthyear - 1979)
gen d = 1 if t >= 0 & t != .
replace d = 0 if t < 1
gen td = t * d

*9) Parent Indicators
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

*10) GaoKao Indicator
gen TakeGaoKao = 1 if A15_1 == 1
replace TakeGaoKao = 0 if A15_1 == 2
tab TakeGaoKao

*11) Key School Indicator

gen Keyschool = 0 if A14 != .
replace Keyschool = 1 if inrange(A14, 1, 3)

*12) Birth Year Dums
keep if inrange(birthyear, 1971, 1992)
tab birthyear, gen(birthyeardum)

*Step Two: Regressions

*Formulate excel sheet
putexcel set "`xlsxpath'"
putexcel C16:D16 E16:F16 G16:H16, merge hcenter
putexcel A17:B17 A19:A20 A21:A22 A23:A24 A25:A26 A27:A28, merge left
putexcel A17="Sum Statistics of" B18="Total Obs" A19="Keyschool" A21="parent_secedu" A23="parent_highedu" A25="parent_partymember" A27="TakeGaoKao"
putexcel B19="mean" B21="mean" B23="mean" B25="mean" B27="mean" B20="obs" B22="obs" B24="obs" B26="obs" B28="obs"
putexcel A16="Rural 1979" C16="SecVoc Track" E16="SecGen Track" G16="SecJun Track"
putexcel C17="t<0" D17="t>=0" E17="t<0" F17="t>=0" G17="t<0" H17="t>=0"


qui selmlog voc_log_monthlyearning male  highvocedu highgenedu adultedu birthyeardum2-birthyeardum22 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male  ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress voc_log_monthlyearning male  highvocedu highgenedu adultedu m1 m2 m3 birthyeardum2-birthyeardum22 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
drop m1 m2 m3

sum Keyschool parent_secedu parent_highedu parent_partymember TakeGaoKao if e(sample) & t < 0
sum Keyschool parent_secedu parent_highedu parent_partymember TakeGaoKao if e(sample) & t >= 0

qui sum monthlyearning if e(sample) & t < 0
putexcel C18=`r(N)'
qui sum monthlyearning if e(sample) & t >= 0
putexcel D18=`r(N)'
qui sum Keyschool if e(sample) & t < 0
putexcel C19=`r(mean)' C20=`r(N)'
qui sum Keyschool if e(sample) & t >= 0
putexcel D19=`r(mean)' D20=`r(N)'
qui sum parent_secedu if e(sample) & t < 0
putexcel C21=`r(mean)' C22=`r(N)'
qui sum parent_secedu if e(sample) & t >= 0
putexcel D21=`r(mean)' D22=`r(N)'
qui sum parent_highedu if e(sample) & t < 0
putexcel C23=`r(mean)' C24=`r(N)'
qui sum parent_highedu if e(sample) & t >= 0
putexcel D23=`r(mean)' D24=`r(N)'
qui sum parent_partymember if e(sample) & t < 0
putexcel C25=`r(mean)' C26=`r(N)'
qui sum parent_partymember if e(sample) & t >= 0
putexcel D25=`r(mean)' D26=`r(N)'
qui sum TakeGaoKao if e(sample) & t < 0
putexcel C27=`r(mean)' C28=`r(N)'
qui sum TakeGaoKao if e(sample) & t >= 0
putexcel D27=`r(mean)' D28=`r(N)'

qui selmlog gen_log_monthlyearning male  highvocedu highgenedu adultedu birthyeardum2-birthyeardum22 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male  ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress gen_log_monthlyearning male  highvocedu highgenedu adultedu m1 m2 m3 birthyeardum2-birthyeardum22 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
drop m1 m2 m3

sum Keyschool parent_secedu parent_highedu parent_partymember TakeGaoKao if e(sample) & t < 0
sum Keyschool parent_secedu parent_highedu parent_partymember TakeGaoKao if e(sample) & t >= 0

qui sum monthlyearning if e(sample) & t < 0
putexcel E18=`r(N)'
qui sum monthlyearning if e(sample) & t >= 0
putexcel F18=`r(N)'
qui sum Keyschool if e(sample) & t < 0
putexcel E19=`r(mean)' E20=`r(N)'
qui sum Keyschool if e(sample) & t >= 0
putexcel F19=`r(mean)' F20=`r(N)'
qui sum parent_secedu if e(sample) & t < 0
putexcel E21=`r(mean)' E22=`r(N)'
qui sum parent_secedu if e(sample) & t >= 0
putexcel F21=`r(mean)' F22=`r(N)'
qui sum parent_highedu if e(sample) & t < 0
putexcel E23=`r(mean)' E24=`r(N)'
qui sum parent_highedu if e(sample) & t >= 0
putexcel F23=`r(mean)' F24=`r(N)'
qui sum parent_partymember if e(sample) & t < 0
putexcel E25=`r(mean)' E26=`r(N)'
qui sum parent_partymember if e(sample) & t >= 0
putexcel F25=`r(mean)' F26=`r(N)'
qui sum TakeGaoKao if e(sample) & t < 0
putexcel E27=`r(mean)' E28=`r(N)'
qui sum TakeGaoKao if e(sample) & t >= 0
putexcel F27=`r(mean)' F28=`r(N)'

qui selmlog jun_log_monthlyearning male  highvocedu highgenedu adultedu birthyeardum1-birthyeardum22 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667), sel(educat=male  ins1_secgen_entrant_relative ins2_highedu_entrant_relative ins3_vs_entrant_relative) dmf(2) showmlogit gen(m)
qui regress jun_log_monthlyearning male  highvocedu highgenedu adultedu m1 m2 m3 birthyeardum1-birthyeardum22 if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 200, 16667)
drop m1 m2 m3

sum Keyschool parent_secedu parent_highedu parent_partymember TakeGaoKao if e(sample) & t < 0
sum Keyschool parent_secedu parent_highedu parent_partymember TakeGaoKao if e(sample) & t >= 1

qui sum monthlyearning if e(sample) & t < 0
putexcel G18=`r(N)'
qui sum monthlyearning if e(sample) & t >= 0
putexcel H18=`r(N)'
qui sum Keyschool if e(sample) & t < 0
putexcel G19=`r(mean)' G20=`r(N)'
qui sum Keyschool if e(sample) & t >= 0
putexcel H19=`r(mean)' H20=`r(N)'
qui sum parent_secedu if e(sample) & t < 0
putexcel G21=`r(mean)' G22=`r(N)'
qui sum parent_secedu if e(sample) & t >= 0
putexcel H21=`r(mean)' H22=`r(N)'
qui sum parent_highedu if e(sample) & t < 0
putexcel G23=`r(mean)' G24=`r(N)'
qui sum parent_highedu if e(sample) & t >= 0
putexcel H23=`r(mean)' H24=`r(N)'
qui sum parent_partymember if e(sample) & t < 0
putexcel G25=`r(mean)' G26=`r(N)'
qui sum parent_partymember if e(sample) & t >= 0
putexcel H25=`r(mean)' H26=`r(N)'
qui sum TakeGaoKao if e(sample) & t < 0
putexcel G27=`r(mean)' G28=`r(N)'
qui sum TakeGaoKao if e(sample) & t >= 0
putexcel H27=`r(mean)' H28=`r(N)'

putexcel save

log close
clear all
