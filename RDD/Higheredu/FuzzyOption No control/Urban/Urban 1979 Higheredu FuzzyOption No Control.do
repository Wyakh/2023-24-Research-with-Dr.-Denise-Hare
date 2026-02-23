local folderpath "/Users/wyattwyatt/Downloads/Revision Code/Wyatt/RDD/Higheredu/FuzzyOption No control/Urban"
local filename "Urban 1979 Higheredu FuzzyOption No Control"
local datapath "/Users/wyattwyatt/Downloads/Revision Code/20240716 Urban Chip2018 and Instrumental Statistics and Inflation.dta"

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

gen yearstart = C02 if C02!=-88 & C02!=-99
gen tenure = 2018 - yearstart
gen tenuresqr = tenure * tenure

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
gen jun_log_monthlyearning = log_monthlyearning if secjun==1

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

*Track based Higheredu
gen secvochighedu = secvocedu * higheredu
gen secgenhighedu = secgenedu * higheredu
gen secjunhighedu = secjun * higheredu

*6) Educational Instrucments; Omit here because we are using this RDD to estimate it locally!!!

*7) Province fixed effect (Method: By the first two digits of household code)

destring hhcode, generate(province_code) force float
replace province_code = floor(province_code/1000000000000) if province_code<100000000000000
replace province_code = floor(province_code/10000000000000) if province_code>=100000000000000 & province_code<1000000000000000
replace province_code = floor(province_code/1000000000000000) if province_code>=10000000000000000
tab province_code, gen(provincedum)

*8) Birth Month cohort & GaoKao_Treatment

gen birthmonth = A04_2 if A04_2!=-88 & A04_2!=-99
gen t = birthmonth - 9 + 12 * (birthyear - 1979)
gen d = 1 if t >= 1 & t != .
replace d = 0 if t < 1
gen td = t * d

gen GaoKao_Treatment = 0 if A15_2<=1998 & A15_2!=-99 & A15_2!=-88
replace GaoKao_Treatment = 1 if A15_2>=1999

*Step Two: Regressions

*2_1) RDD Earning t

*2_1_1) rdrobust on earning, sheet 1, no province no omitting local variables

**2_1_1_1 Pooled 
*One year each
rdrobust log_monthlyearning t if inrange(t, -12, 11) & inrange(monthlyearning, 250, 25000) & educat != ., covs() fuzzy(higheredu) kernel(uni) p(1) h(12) all
outreg2 using "`folderpath'/Earning Sheet 1 results.xls", replace ctitle(no province no local adjustment, pooled, uniform weight, 12-month bandwidth) pvalue

*Three year each
rdrobust log_monthlyearning t if inrange(t, -36, 35) & inrange(monthlyearning, 250, 25000) & educat != ., covs() fuzzy(higheredu) kernel(uni) p(1) h(36) all
outreg2 using "`folderpath'/Earning Sheet 1 results.xls", append ctitle(no province no local adjustment, pooled, uniform weight, 36-month bandwidth) pvalue

*Automatic
rdrobust log_monthlyearning t if inrange(monthlyearning, 250, 25000) & educat != ., covs() fuzzy(higheredu) kernel(epa) p(1) bwselect(mserd) all
local bandwidth = e(h_l)
mata : st_numscalar("e(N)", `e(N_h_l)'+`e(N_h_r)')
outreg2 using "`folderpath'/Earning Sheet 1 results.xls", append ctitle(no province no local adjustment, pooled, epa weight, automatic bandwidth) pvalue

**2_1_1_2 Pooled without SecJun
*One year each
rdrobust log_monthlyearning t if inrange(t, -12, 11) & inrange(monthlyearning, 250, 25000) & (educat==1 | educat==2), covs() fuzzy(higheredu) kernel(uni) p(1) h(12) all
outreg2 using "`folderpath'/Earning Sheet 1 results.xls", append ctitle(no province no local adjustment, pooled without secjun, uniform weight, 12-month bandwidth) pvalue

*Three year each
rdrobust log_monthlyearning t if inrange(t, -36, 35) & inrange(monthlyearning, 250, 25000) & (educat==1 | educat==2), covs() fuzzy(higheredu) kernel(uni) p(1) h(36) all
outreg2 using "`folderpath'/Earning Sheet 1 results.xls", append ctitle(no province no local adjustment, pooled without secjun, uniform weight, 36-month bandwidth) pvalue

*Automatic
rdrobust log_monthlyearning t if inrange(monthlyearning, 250, 25000) & (educat==1 | educat==2), covs() fuzzy(higheredu) kernel(epa) p(1) bwselect(mserd) all
local bandwidth = e(h_l)
mata : st_numscalar("e(N)", `e(N_h_l)'+`e(N_h_r)')
outreg2 using "`folderpath'/Earning Sheet 1 results.xls", append ctitle(no province no local adjustment, pooled without secjun, epa weight, automatic bandwidth) pvalue

**2_1_1_3 SecVoc
*One year each
rdrobust log_monthlyearning t if inrange(t, -12, 11) & inrange(monthlyearning, 250, 25000) & educat ==1, covs() fuzzy(higheredu) kernel(uni) p(1) h(12) all
outreg2 using "`folderpath'/Earning Sheet 1 results.xls", append ctitle(no province no local adjustment, secvoc, uniform weight, 12-month bandwidth) pvalue

*Three year each
rdrobust log_monthlyearning t if inrange(t, -36, 35) & inrange(monthlyearning, 250, 25000) & educat ==1, covs() fuzzy(higheredu) kernel(uni) p(1) h(36) all
outreg2 using "`folderpath'/Earning Sheet 1 results.xls", append ctitle(no province no local adjustment, secvoc, uniform weight, 36-month bandwidth) pvalue

*Automatic
rdrobust log_monthlyearning t if inrange(monthlyearning, 250, 25000) & educat ==1, covs() fuzzy(higheredu) kernel(epa) p(1) bwselect(mserd) all
local bandwidth = e(h_l)
mata : st_numscalar("e(N)", `e(N_h_l)'+`e(N_h_r)')
outreg2 using "`folderpath'/Earning Sheet 1 results.xls", append ctitle(no province no local adjustment, secvoc, epa weight, automatic bandwidth) pvalue

**2_1_1_4 SecGen
*One year each
rdrobust log_monthlyearning t if inrange(t, -12, 11) & inrange(monthlyearning, 250, 25000) & educat ==2, covs() fuzzy(higheredu) kernel(uni) p(1) h(12) all
outreg2 using "`folderpath'/Earning Sheet 1 results.xls", append ctitle(no province no local adjustment, secgen, uniform weight, 12-month bandwidth) pvalue

*Three year each
rdrobust log_monthlyearning t if inrange(t, -36, 35) & inrange(monthlyearning, 250, 25000) & educat ==2, covs() fuzzy(higheredu) kernel(uni) p(1) h(36) all
outreg2 using "`folderpath'/Earning Sheet 1 results.xls", append ctitle(no province no local adjustment, secgen, uniform weight, 36-month bandwidth) pvalue

*Automatic
rdrobust log_monthlyearning t if inrange(monthlyearning, 250, 25000) & educat ==2, covs() fuzzy(higheredu) kernel(epa) p(1) bwselect(mserd) all
local bandwidth = e(h_l)
mata : st_numscalar("e(N)", `e(N_h_l)'+`e(N_h_r)')
outreg2 using "`folderpath'/Earning Sheet 1 results.xls", append ctitle(no province no local adjustment, secgen, epa weight, automatic bandwidth) pvalue

*2_1_2) rdrobust on earning, sheet 2, province-clustered no omitting local variables

**2_1_2_1 Pooled 
*One year each
rdrobust log_monthlyearning t if inrange(t, -12, 11) & inrange(monthlyearning, 250, 25000) & educat != ., covs() fuzzy(higheredu) kernel(uni) p(1) h(12) all vce(nncluster province_code)
outreg2 using "`folderpath'/Earning Sheet 2 results.xls", replace ctitle(province-clustered no local adjustment, pooled, uniform weight, 12-month bandwidth) pvalue

*Three year each
rdrobust log_monthlyearning t if inrange(t, -36, 35) & inrange(monthlyearning, 250, 25000) & educat != ., covs() fuzzy(higheredu) kernel(uni) p(1) h(36) all vce(nncluster province_code)
outreg2 using "`folderpath'/Earning Sheet 2 results.xls", append ctitle(province-clustered no local adjustment, pooled, uniform weight, 36-month bandwidth) pvalue

*Automatic
rdrobust log_monthlyearning t if inrange(monthlyearning, 250, 25000) & educat != ., covs() fuzzy(higheredu) kernel(epa) p(1) bwselect(mserd) all vce(nncluster province_code)
local bandwidth = e(h_l)
mata : st_numscalar("e(N)", `e(N_h_l)'+`e(N_h_r)')
outreg2 using "`folderpath'/Earning Sheet 2 results.xls", append ctitle(province-clustered no local adjustment, pooled, epa weight, automatic bandwidth) pvalue

**2_1_2_2 Pooled without SecJun
*One year each
rdrobust log_monthlyearning t if inrange(t, -12, 11) & inrange(monthlyearning, 250, 25000) & (educat==1 | educat==2), covs() fuzzy(higheredu) kernel(uni) p(1) h(12) all vce(nncluster province_code)
outreg2 using "`folderpath'/Earning Sheet 2 results.xls", append ctitle(province-clustered no local adjustment, pooled without secjun, uniform weight, 12-month bandwidth) pvalue

*Three year each
rdrobust log_monthlyearning t if inrange(t, -36, 35) & inrange(monthlyearning, 250, 25000) & (educat==1 | educat==2), covs() fuzzy(higheredu) kernel(uni) p(1) h(36) all vce(nncluster province_code)
outreg2 using "`folderpath'/Earning Sheet 2 results.xls", append ctitle(province-clustered no local adjustment, pooled without secjun, uniform weight, 36-month bandwidth) pvalue

*Automatic
rdrobust log_monthlyearning t if inrange(monthlyearning, 250, 25000) & (educat==1 | educat==2), covs() fuzzy(higheredu) kernel(epa) p(1) bwselect(mserd) all vce(nncluster province_code)
local bandwidth = e(h_l)
mata : st_numscalar("e(N)", `e(N_h_l)'+`e(N_h_r)')
outreg2 using "`folderpath'/Earning Sheet 2 results.xls", append ctitle(province-clustered no local adjustment, pooled without secjun, epa weight, automatic bandwidth) pvalue

**2_1_2_3 SecVoc
*One year each
rdrobust log_monthlyearning t if inrange(t, -12, 11) & inrange(monthlyearning, 250, 25000) & educat ==1, covs() fuzzy(higheredu) kernel(uni) p(1) h(12) all vce(nncluster province_code)
outreg2 using "`folderpath'/Earning Sheet 2 results.xls", append ctitle(province-clustered no local adjustment, secvoc, uniform weight, 12-month bandwidth) pvalue

*Three year each
rdrobust log_monthlyearning t if inrange(t, -36, 35) & inrange(monthlyearning, 250, 25000) & educat ==1, covs() fuzzy(higheredu) kernel(uni) p(1) h(36) all vce(nncluster province_code)
outreg2 using "`folderpath'/Earning Sheet 2 results.xls", append ctitle(province-clustered no local adjustment, secvoc, uniform weight, 36-month bandwidth) pvalue

*Automatic
rdrobust log_monthlyearning t if inrange(monthlyearning, 250, 25000) & educat ==1, covs() fuzzy(higheredu) kernel(epa) p(1) bwselect(mserd) all vce(nncluster province_code)
local bandwidth = e(h_l)
mata : st_numscalar("e(N)", `e(N_h_l)'+`e(N_h_r)')
outreg2 using "`folderpath'/Earning Sheet 2 results.xls", append ctitle(province-clustered no local adjustment, secvoc, epa weight, automatic bandwidth) pvalue

**2_1_2_4 SecGen
*One year each
rdrobust log_monthlyearning t if inrange(t, -12, 11) & inrange(monthlyearning, 250, 25000) & educat ==2, covs() fuzzy(higheredu) kernel(uni) p(1) h(12) all vce(nncluster province_code)
outreg2 using "`folderpath'/Earning Sheet 2 results.xls", append ctitle(province-clustered no local adjustment, secgen, uniform weight, 12-month bandwidth) pvalue

*Three year each
rdrobust log_monthlyearning t if inrange(t, -36, 35) & inrange(monthlyearning, 250, 25000) & educat ==2, covs() fuzzy(higheredu) kernel(uni) p(1) h(36) all vce(nncluster province_code)
outreg2 using "`folderpath'/Earning Sheet 2 results.xls", append ctitle(province-clustered no local adjustment, secgen, uniform weight, 36-month bandwidth) pvalue

*Automatic
rdrobust log_monthlyearning t if inrange(monthlyearning, 250, 25000) & educat ==2, covs() fuzzy(higheredu) kernel(epa) p(1) bwselect(mserd) all vce(nncluster province_code)
local bandwidth = e(h_l)
mata : st_numscalar("e(N)", `e(N_h_l)'+`e(N_h_r)')
outreg2 using "`folderpath'/Earning Sheet 2 results.xls", append ctitle(province-clustered no local adjustment, secgen, epa weight, automatic bandwidth) pvalue

*2_1_3) rdrobust on earning, sheet 3, no province no Aug-Sep

**2_1_3_1 Pooled 
*One year each
rdrobust log_monthlyearning t if (t<=-2 | t>=1) & inrange(t, -12, 11) & inrange(monthlyearning, 250, 25000) & educat != ., covs() fuzzy(higheredu) kernel(uni) p(1) h(12) all
outreg2 using "`folderpath'/Earning Sheet 3 results.xls", replace ctitle(no province no Aug-Sep, pooled, uniform weight, 12-month bandwidth) pvalue

*Three year each
rdrobust log_monthlyearning t if (t<=-2 | t>=1) & inrange(t, -36, 35) & inrange(monthlyearning, 250, 25000) & educat != ., covs() fuzzy(higheredu) kernel(uni) p(1) h(36) all
outreg2 using "`folderpath'/Earning Sheet 3 results.xls", append ctitle(no province no Aug-Sep, pooled, uniform weight, 36-month bandwidth) pvalue

*Automatic
rdrobust log_monthlyearning t if (t<=-2 | t>=1) & inrange(monthlyearning, 250, 25000) & educat != ., covs() fuzzy(higheredu) kernel(epa) p(1) bwselect(mserd) all
local bandwidth = e(h_l)
mata : st_numscalar("e(N)", `e(N_h_l)'+`e(N_h_r)')
outreg2 using "`folderpath'/Earning Sheet 3 results.xls", append ctitle(no province no Aug-Sep, pooled, epa weight, automatic bandwidth) pvalue

**2_1_3_2 Pooled without SecJun
*One year each
rdrobust log_monthlyearning t if (t<=-2 | t>=1) & inrange(t, -12, 11) & inrange(monthlyearning, 250, 25000) & (educat==1 | educat==2), covs() fuzzy(higheredu) kernel(uni) p(1) h(12) all
outreg2 using "`folderpath'/Earning Sheet 3 results.xls", append ctitle(no province no Aug-Sep, pooled without secjun, uniform weight, 12-month bandwidth) pvalue

*Three year each
rdrobust log_monthlyearning t if (t<=-2 | t>=1) & inrange(t, -36, 35) & inrange(monthlyearning, 250, 25000) & (educat==1 | educat==2), covs() fuzzy(higheredu) kernel(uni) p(1) h(36) all
outreg2 using "`folderpath'/Earning Sheet 3 results.xls", append ctitle(no province no Aug-Sep, pooled without secjun, uniform weight, 36-month bandwidth) pvalue

*Automatic
rdrobust log_monthlyearning t if (t<=-2 | t>=1) & inrange(monthlyearning, 250, 25000) & (educat==1 | educat==2), covs() fuzzy(higheredu) kernel(epa) p(1) bwselect(mserd) all
local bandwidth = e(h_l)
mata : st_numscalar("e(N)", `e(N_h_l)'+`e(N_h_r)')
outreg2 using "`folderpath'/Earning Sheet 3 results.xls", append ctitle(no province no Aug-Sep, pooled without secjun, epa weight, automatic bandwidth) pvalue

**2_1_3_3 SecVoc
*One year each
rdrobust log_monthlyearning t if (t<=-2 | t>=1) & inrange(t, -12, 11) & inrange(monthlyearning, 250, 25000) & educat ==1, covs() fuzzy(higheredu) kernel(uni) p(1) h(12) all
outreg2 using "`folderpath'/Earning Sheet 3 results.xls", append ctitle(no province no Aug-Sep, secvoc, uniform weight, 12-month bandwidth) pvalue

*Three year each
rdrobust log_monthlyearning t if (t<=-2 | t>=1) & inrange(t, -36, 35) & inrange(monthlyearning, 250, 25000) & educat ==1, covs() fuzzy(higheredu) kernel(uni) p(1) h(36) all
outreg2 using "`folderpath'/Earning Sheet 3 results.xls", append ctitle(no province no Aug-Sep, secvoc, uniform weight, 36-month bandwidth) pvalue

*Automatic
rdrobust log_monthlyearning t if (t<=-2 | t>=1) & inrange(monthlyearning, 250, 25000) & educat ==1, covs() fuzzy(higheredu) kernel(epa) p(1) bwselect(mserd) all
local bandwidth = e(h_l)
mata : st_numscalar("e(N)", `e(N_h_l)'+`e(N_h_r)')
outreg2 using "`folderpath'/Earning Sheet 3 results.xls", append ctitle(no province no Aug-Sep, secvoc, epa weight, automatic bandwidth) pvalue

**2_1_3_4 SecGen
*One year each
rdrobust log_monthlyearning t if (t<=-2 | t>=1) & inrange(t, -12, 11) & inrange(monthlyearning, 250, 25000) & educat ==2, covs() fuzzy(higheredu) kernel(uni) p(1) h(12) all
outreg2 using "`folderpath'/Earning Sheet 3 results.xls", append ctitle(no province no Aug-Sep, secgen, uniform weight, 12-month bandwidth) pvalue

*Three year each
rdrobust log_monthlyearning t if (t<=-2 | t>=1) & inrange(t, -36, 35) & inrange(monthlyearning, 250, 25000) & educat ==2, covs() fuzzy(higheredu) kernel(uni) p(1) h(36) all
outreg2 using "`folderpath'/Earning Sheet 3 results.xls", append ctitle(no province no Aug-Sep, secgen, uniform weight, 36-month bandwidth) pvalue

*Automatic
rdrobust log_monthlyearning t if (t<=-2 | t>=1) & inrange(monthlyearning, 250, 25000) & educat ==2, covs() fuzzy(higheredu) kernel(epa) p(1) bwselect(mserd) all
local bandwidth = e(h_l)
mata : st_numscalar("e(N)", `e(N_h_l)'+`e(N_h_r)')
outreg2 using "`folderpath'/Earning Sheet 3 results.xls", append ctitle(no province no Aug-Sep, secgen, epa weight, automatic bandwidth) pvalue


*2_1_4) rdrobust on earning, sheet 4, province-clustered no Aug-Sep

**2_1_4_1 Pooled 
*One year each
rdrobust log_monthlyearning t if (t<=-2 | t>=1) & inrange(t, -12, 11) & inrange(monthlyearning, 250, 25000) & educat != ., covs() fuzzy(higheredu) kernel(uni) p(1) h(12) all vce(nncluster province_code)
outreg2 using "`folderpath'/Earning Sheet 4 results.xls", replace ctitle(province-clustered no Aug-Sep, pooled, uniform weight, 12-month bandwidth) pvalue

*Three year each
rdrobust log_monthlyearning t if (t<=-2 | t>=1) & inrange(t, -36, 35) & inrange(monthlyearning, 250, 25000) & educat != ., covs() fuzzy(higheredu) kernel(uni) p(1) h(36) all vce(nncluster province_code)
outreg2 using "`folderpath'/Earning Sheet 4 results.xls", append ctitle(province-clustered no Aug-Sep, pooled, uniform weight, 36-month bandwidth) pvalue

*Automatic
rdrobust log_monthlyearning t if (t<=-2 | t>=1) & inrange(monthlyearning, 250, 25000) & educat != ., covs() fuzzy(higheredu) kernel(epa) p(1) bwselect(mserd) all vce(nncluster province_code)
local bandwidth = e(h_l)
mata : st_numscalar("e(N)", `e(N_h_l)'+`e(N_h_r)')
outreg2 using "`folderpath'/Earning Sheet 4 results.xls", append ctitle(province-clustered no Aug-Sep, pooled, epa weight, automatic bandwidth) pvalue

**2_1_4_2 Pooled without SecJun
*One year each
rdrobust log_monthlyearning t if (t<=-2 | t>=1) & inrange(t, -12, 11) & inrange(monthlyearning, 250, 25000) & (educat==1 | educat==2), covs() fuzzy(higheredu) kernel(uni) p(1) h(12) all vce(nncluster province_code)
outreg2 using "`folderpath'/Earning Sheet 4 results.xls", append ctitle(province-clustered no Aug-Sep, pooled without secjun, uniform weight, 12-month bandwidth) pvalue

*Three year each
rdrobust log_monthlyearning t if (t<=-2 | t>=1) & inrange(t, -36, 35) & inrange(monthlyearning, 250, 25000) & (educat==1 | educat==2), covs() fuzzy(higheredu) kernel(uni) p(1) h(36) all vce(nncluster province_code)
outreg2 using "`folderpath'/Earning Sheet 4 results.xls", append ctitle(province-clustered no Aug-Sep, pooled without secjun, uniform weight, 36-month bandwidth) pvalue

*Automatic
rdrobust log_monthlyearning t if (t<=-2 | t>=1) & inrange(monthlyearning, 250, 25000) & (educat==1 | educat==2), covs() fuzzy(higheredu) kernel(epa) p(1) bwselect(mserd) all vce(nncluster province_code)
local bandwidth = e(h_l)
mata : st_numscalar("e(N)", `e(N_h_l)'+`e(N_h_r)')
outreg2 using "`folderpath'/Earning Sheet 4 results.xls", append ctitle(province-clustered no Aug-Sep, pooled without secjun, epa weight, automatic bandwidth) pvalue

**2_1_4_3 SecVoc
*One year each
rdrobust log_monthlyearning t if (t<=-2 | t>=1) & inrange(t, -12, 11) & inrange(monthlyearning, 250, 25000) & educat ==1, covs() fuzzy(higheredu) kernel(uni) p(1) h(12) all vce(nncluster province_code)
outreg2 using "`folderpath'/Earning Sheet 4 results.xls", append ctitle(province-clustered no Aug-Sep, secvoc, uniform weight, 12-month bandwidth) pvalue

*Three year each
rdrobust log_monthlyearning t if (t<=-2 | t>=1) & inrange(t, -36, 35) & inrange(monthlyearning, 250, 25000) & educat ==1, covs() fuzzy(higheredu) kernel(uni) p(1) h(36) all vce(nncluster province_code)
outreg2 using "`folderpath'/Earning Sheet 4 results.xls", append ctitle(province-clustered no Aug-Sep, secvoc, uniform weight, 36-month bandwidth) pvalue

*Automatic
rdrobust log_monthlyearning t if (t<=-2 | t>=1) & inrange(monthlyearning, 250, 25000) & educat ==1, covs() fuzzy(higheredu) kernel(epa) p(1) bwselect(mserd) all vce(nncluster province_code)
local bandwidth = e(h_l)
mata : st_numscalar("e(N)", `e(N_h_l)'+`e(N_h_r)')
outreg2 using "`folderpath'/Earning Sheet 4 results.xls", append ctitle(province-clustered no Aug-Sep, secvoc, epa weight, automatic bandwidth) pvalue

**2_1_4_4 SecGen
*One year each
rdrobust log_monthlyearning t if (t<=-2 | t>=1) & inrange(t, -12, 11) & inrange(monthlyearning, 250, 25000) & educat ==2, covs() fuzzy(higheredu) kernel(uni) p(1) h(12) all vce(nncluster province_code)
outreg2 using "`folderpath'/Earning Sheet 4 results.xls", append ctitle(province-clustered no Aug-Sep, secgen, uniform weight, 12-month bandwidth) pvalue

*Three year each
rdrobust log_monthlyearning t if (t<=-2 | t>=1) & inrange(t, -36, 35) & inrange(monthlyearning, 250, 25000) & educat ==2, covs() fuzzy(higheredu) kernel(uni) p(1) h(36) all vce(nncluster province_code)
outreg2 using "`folderpath'/Earning Sheet 4 results.xls", append ctitle(province-clustered no Aug-Sep, secgen, uniform weight, 36-month bandwidth) pvalue

*Automatic
rdrobust log_monthlyearning t if (t<=-2 | t>=1) & inrange(monthlyearning, 250, 25000) & educat ==2, covs() fuzzy(higheredu) kernel(epa) p(1) bwselect(mserd) all vce(nncluster province_code)
local bandwidth = e(h_l)
mata : st_numscalar("e(N)", `e(N_h_l)'+`e(N_h_r)')
outreg2 using "`folderpath'/Earning Sheet 4 results.xls", append ctitle(province-clustered no Aug-Sep, secgen, epa weight, automatic bandwidth) pvalue

*2_1_5) rdrobust on earning, sheet 5, no province no July-Oct

**2_1_5_1 Pooled 
*One year each
rdrobust log_monthlyearning t if (t<=-3 | t>=2) & inrange(t, -12, 11) & inrange(monthlyearning, 250, 25000) & educat != ., covs() fuzzy(higheredu) kernel(uni) p(1) h(12) all
outreg2 using "`folderpath'/Earning Sheet 5 results.xls", replace ctitle(no province no July-Oct, pooled, uniform weight, 12-month bandwidth) pvalue

*Three year each
rdrobust log_monthlyearning t if (t<=-3 | t>=2) & inrange(t, -36, 35) & inrange(monthlyearning, 250, 25000) & educat != ., covs() fuzzy(higheredu) kernel(uni) p(1) h(36) all
outreg2 using "`folderpath'/Earning Sheet 5 results.xls", append ctitle(no province no July-Oct, pooled, uniform weight, 36-month bandwidth) pvalue

*Automatic
rdrobust log_monthlyearning t if (t<=-3 | t>=2) & inrange(monthlyearning, 250, 25000) & educat != ., covs() fuzzy(higheredu) kernel(epa) p(1) bwselect(mserd) all
local bandwidth = e(h_l)
mata : st_numscalar("e(N)", `e(N_h_l)'+`e(N_h_r)')
outreg2 using "`folderpath'/Earning Sheet 5 results.xls", append ctitle(no province no July-Oct, pooled, epa weight, automatic bandwidth) pvalue

**2_1_5_2 Pooled without SecJun
*One year each
rdrobust log_monthlyearning t if (t<=-3 | t>=2) & inrange(t, -12, 11) & inrange(monthlyearning, 250, 25000) & (educat==1 | educat==2), covs() fuzzy(higheredu) kernel(uni) p(1) h(12) all
outreg2 using "`folderpath'/Earning Sheet 5 results.xls", append ctitle(no province no July-Oct, pooled without secjun, uniform weight, 12-month bandwidth) pvalue

*Three year each
rdrobust log_monthlyearning t if (t<=-3 | t>=2) & inrange(t, -36, 35) & inrange(monthlyearning, 250, 25000) & (educat==1 | educat==2), covs() fuzzy(higheredu) kernel(uni) p(1) h(36) all
outreg2 using "`folderpath'/Earning Sheet 5 results.xls", append ctitle(no province no July-Oct, pooled without secjun, uniform weight, 36-month bandwidth) pvalue

*Automatic
rdrobust log_monthlyearning t if (t<=-3 | t>=2) & inrange(monthlyearning, 250, 25000) & (educat==1 | educat==2), covs() fuzzy(higheredu) kernel(epa) p(1) bwselect(mserd) all
local bandwidth = e(h_l)
mata : st_numscalar("e(N)", `e(N_h_l)'+`e(N_h_r)')
outreg2 using "`folderpath'/Earning Sheet 5 results.xls", append ctitle(no province no July-Oct, pooled without secjun, epa weight, automatic bandwidth) pvalue

**2_1_5_3 SecVoc
*One year each
rdrobust log_monthlyearning t if (t<=-3 | t>=2) & inrange(t, -12, 11) & inrange(monthlyearning, 250, 25000) & educat ==1, covs() fuzzy(higheredu) kernel(uni) p(1) h(12) all
outreg2 using "`folderpath'/Earning Sheet 5 results.xls", append ctitle(no province no July-Oct, secvoc, uniform weight, 12-month bandwidth) pvalue

*Three year each
rdrobust log_monthlyearning t if (t<=-3 | t>=2) & inrange(t, -36, 35) & inrange(monthlyearning, 250, 25000) & educat ==1, covs() fuzzy(higheredu) kernel(uni) p(1) h(36) all
outreg2 using "`folderpath'/Earning Sheet 5 results.xls", append ctitle(no province no July-Oct, secvoc, uniform weight, 36-month bandwidth) pvalue

*Automatic
rdrobust log_monthlyearning t if (t<=-3 | t>=2) & inrange(monthlyearning, 250, 25000) & educat ==1, covs() fuzzy(higheredu) kernel(epa) p(1) bwselect(mserd) all
local bandwidth = e(h_l)
mata : st_numscalar("e(N)", `e(N_h_l)'+`e(N_h_r)')
outreg2 using "`folderpath'/Earning Sheet 5 results.xls", append ctitle(no province no July-Oct, secvoc, epa weight, automatic bandwidth) pvalue

**2_1_5_4 SecGen
*One year each
rdrobust log_monthlyearning t if (t<=-3 | t>=2) & inrange(t, -12, 11) & inrange(monthlyearning, 250, 25000) & educat ==2, covs() fuzzy(higheredu) kernel(uni) p(1) h(12) all
outreg2 using "`folderpath'/Earning Sheet 5 results.xls", append ctitle(no province no July-Oct, secgen, uniform weight, 12-month bandwidth) pvalue

*Three year each
rdrobust log_monthlyearning t if (t<=-3 | t>=2) & inrange(t, -36, 35) & inrange(monthlyearning, 250, 25000) & educat ==2, covs() fuzzy(higheredu) kernel(uni) p(1) h(36) all
outreg2 using "`folderpath'/Earning Sheet 5 results.xls", append ctitle(no province no July-Oct, secgen, uniform weight, 36-month bandwidth) pvalue

*Automatic
rdrobust log_monthlyearning t if (t<=-3 | t>=2) & inrange(monthlyearning, 250, 25000) & educat ==2, covs() fuzzy(higheredu) kernel(epa) p(1) bwselect(mserd) all
local bandwidth = e(h_l)
mata : st_numscalar("e(N)", `e(N_h_l)'+`e(N_h_r)')
outreg2 using "`folderpath'/Earning Sheet 5 results.xls", append ctitle(no province no July-Oct, secgen, epa weight, automatic bandwidth) pvalue


*2_1_6) rdrobust on earning, sheet 6, province-clustered no July-Oct

**2_1_6_1 Pooled 
*One year each
rdrobust log_monthlyearning t if (t<=-3 | t>=2) & inrange(t, -12, 11) & inrange(monthlyearning, 250, 25000) & educat != ., covs() fuzzy(higheredu) kernel(uni) p(1) h(12) all vce(nncluster province_code)
outreg2 using "`folderpath'/Earning Sheet 6 results.xls", replace ctitle(province-clustered no July-Oct, pooled, uniform weight, 12-month bandwidth) pvalue

*Three year each
rdrobust log_monthlyearning t if (t<=-3 | t>=2) & inrange(t, -36, 35) & inrange(monthlyearning, 250, 25000) & educat != ., covs() fuzzy(higheredu) kernel(uni) p(1) h(36) all vce(nncluster province_code)
outreg2 using "`folderpath'/Earning Sheet 6 results.xls", append ctitle(province-clustered no July-Oct, pooled, uniform weight, 36-month bandwidth) pvalue

*Automatic
rdrobust log_monthlyearning t if (t<=-3 | t>=2) & inrange(monthlyearning, 250, 25000) & educat != ., covs() fuzzy(higheredu) kernel(epa) p(1) bwselect(mserd) all vce(nncluster province_code)
local bandwidth = e(h_l)
mata : st_numscalar("e(N)", `e(N_h_l)'+`e(N_h_r)')
outreg2 using "`folderpath'/Earning Sheet 6 results.xls", append ctitle(province-clustered no July-Oct, pooled, epa weight, automatic bandwidth) pvalue

**2_1_6_2 Pooled without SecJun
*One year each
rdrobust log_monthlyearning t if (t<=-3 | t>=2) & inrange(t, -12, 11) & inrange(monthlyearning, 250, 25000) & (educat==1 | educat==2), covs() fuzzy(higheredu) kernel(uni) p(1) h(12) all vce(nncluster province_code)
outreg2 using "`folderpath'/Earning Sheet 6 results.xls", append ctitle(province-clustered no July-Oct, pooled without secjun, uniform weight, 12-month bandwidth) pvalue

*Three year each
rdrobust log_monthlyearning t if (t<=-3 | t>=2) & inrange(t, -36, 35) & inrange(monthlyearning, 250, 25000) & (educat==1 | educat==2), covs() fuzzy(higheredu) kernel(uni) p(1) h(36) all vce(nncluster province_code)
outreg2 using "`folderpath'/Earning Sheet 6 results.xls", append ctitle(province-clustered no July-Oct, pooled without secjun, uniform weight, 36-month bandwidth) pvalue

*Automatic
rdrobust log_monthlyearning t if (t<=-3 | t>=2) & inrange(monthlyearning, 250, 25000) & (educat==1 | educat==2), covs() fuzzy(higheredu) kernel(epa) p(1) bwselect(mserd) all vce(nncluster province_code)
local bandwidth = e(h_l)
mata : st_numscalar("e(N)", `e(N_h_l)'+`e(N_h_r)')
outreg2 using "`folderpath'/Earning Sheet 6 results.xls", append ctitle(province-clustered no July-Oct, pooled without secjun, epa weight, automatic bandwidth) pvalue

**2_1_6_3 SecVoc
*One year each
rdrobust log_monthlyearning t if (t<=-3 | t>=2) & inrange(t, -12, 11) & inrange(monthlyearning, 250, 25000) & educat ==1, covs() fuzzy(higheredu) kernel(uni) p(1) h(12) all vce(nncluster province_code)
outreg2 using "`folderpath'/Earning Sheet 6 results.xls", append ctitle(province-clustered no July-Oct, secvoc, uniform weight, 12-month bandwidth) pvalue

*Three year each
rdrobust log_monthlyearning t if (t<=-3 | t>=2) & inrange(t, -36, 35) & inrange(monthlyearning, 250, 25000) & educat ==1, covs() fuzzy(higheredu) kernel(uni) p(1) h(36) all vce(nncluster province_code)
outreg2 using "`folderpath'/Earning Sheet 6 results.xls", append ctitle(province-clustered no July-Oct, secvoc, uniform weight, 36-month bandwidth) pvalue

*Automatic
rdrobust log_monthlyearning t if (t<=-3 | t>=2) & inrange(monthlyearning, 250, 25000) & educat ==1, covs() fuzzy(higheredu) kernel(epa) p(1) bwselect(mserd) all vce(nncluster province_code)
local bandwidth = e(h_l)
mata : st_numscalar("e(N)", `e(N_h_l)'+`e(N_h_r)')
outreg2 using "`folderpath'/Earning Sheet 6 results.xls", append ctitle(province-clustered no July-Oct, secvoc, epa weight, automatic bandwidth) pvalue

**2_1_6_4 SecGen
*One year each
rdrobust log_monthlyearning t if (t<=-3 | t>=2) & inrange(t, -12, 11) & inrange(monthlyearning, 250, 25000) & educat ==2, covs() fuzzy(higheredu) kernel(uni) p(1) h(12) all vce(nncluster province_code)
outreg2 using "`folderpath'/Earning Sheet 6 results.xls", append ctitle(province-clustered no July-Oct, secgen, uniform weight, 12-month bandwidth) pvalue

*Three year each
rdrobust log_monthlyearning t if (t<=-3 | t>=2) & inrange(t, -36, 35) & inrange(monthlyearning, 250, 25000) & educat ==2, covs() fuzzy(higheredu) kernel(uni) p(1) h(36) all vce(nncluster province_code)
outreg2 using "`folderpath'/Earning Sheet 6 results.xls", append ctitle(province-clustered no July-Oct, secgen, uniform weight, 36-month bandwidth) pvalue

*Automatic
rdrobust log_monthlyearning t if (t<=-3 | t>=2) & inrange(monthlyearning, 250, 25000) & educat ==2, covs() fuzzy(higheredu) kernel(epa) p(1) bwselect(mserd) all vce(nncluster province_code)
local bandwidth = e(h_l)
mata : st_numscalar("e(N)", `e(N_h_l)'+`e(N_h_r)')
outreg2 using "`folderpath'/Earning Sheet 6 results.xls", append ctitle(province-clustered no July-Oct, secgen, epa weight, automatic bandwidth) pvalue


log close
clear all





