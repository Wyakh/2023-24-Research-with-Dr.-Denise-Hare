local folderpath "/Users/wyattwyatt/Downloads/Revision Code/Aiden/Alternative Dependent Variables/OLS Job-types & Unemployment/Urban"
local logname "OLS Urban (1) Unemployment A20=5 (2) Unemployment A20=5|9 (3) High occupation (4) Long-term contract"
local datapath "/Users/wyattwyatt/Downloads/Revision Code/20240716 Urban Chip2018 and Instrumental Statistics and Inflation"
local filename1 "OLS Urban Unemployment A20=5"
local filename2 "OLS Urban Unemployment A20=5|9"
local filename3 "OLS Urban High occupation"
local filename4 "OLS Urban Long-term contract"

local xlspath1 "`folderpath'/`filename1'.xls"
local xlspath2 "`folderpath'/`filename2'.xls"
local xlspath3 "`folderpath'/`filename3'.xls"
local xlspath4 "`folderpath'/`filename4'.xls"
log using "`folderpath'/`logname'.log", replace
use "`datapath'", clear
****By convention in other folders, I combine the unemployment, high occupation, and long-term contract dependent variables into this one .do file. If you wish to run one seperately, simply delete or nullify the other two parts of regressions. Search *1) Unemployment A20=5, *2) Unemployment A20=5|9, *3) High occupation, or *4) Long-term contract in this file to jump to the regressions!


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

*6) Instrument (NOT USING HERE)


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

*10) Dependent variables: job-types specifications

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


*Step Two: Regressions

*1) Unemployment A20=5

regress voc_unemp_A20_5 male exp expsqr highvocedu highgenedu adultedu if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath1'", replace ctitle(Sec Voc, Higheredu Seperate,) pvalue

regress voc_unemp_A20_5 male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath1'", append ctitle(Sec Voc, Higheredu Seperate, Province Dum) pvalue

regress voc_unemp_A20_5 male exp expsqr higheredu if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath1'", append ctitle(Sec Voc, Higheredu Together,) pvalue

regress voc_unemp_A20_5 male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath1'", append ctitle(Sec Voc, Higheredu Together, Province Dum) pvalue

regress gen_unemp_A20_5 male exp expsqr highvocedu highgenedu adultedu if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath1'", append ctitle(Sec Gen, Higheredu Seperate,) pvalue

regress gen_unemp_A20_5 male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath1'", append ctitle(Sec Gen, Higheredu Seperate, Province Dum) pvalue

regress gen_unemp_A20_5 male exp expsqr higheredu if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath1'", append ctitle(Sec Gen, Higheredu Together,) pvalue

regress gen_unemp_A20_5 male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath1'", append ctitle(Sec Gen, Higheredu Together, Province Dum) pvalue

*2) Unemployment A20=5|9

regress voc_unemp_A20_59 male exp expsqr highvocedu highgenedu adultedu if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath2'", replace ctitle(Sec Voc, Higheredu Seperate,) pvalue

regress voc_unemp_A20_59 male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath2'", append ctitle(Sec Voc, Higheredu Seperate, Province Dum) pvalue

regress voc_unemp_A20_59 male exp expsqr higheredu if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath2'", append ctitle(Sec Voc, Higheredu Together,) pvalue

regress voc_unemp_A20_59 male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath2'", append ctitle(Sec Voc, Higheredu Together, Province Dum) pvalue

regress gen_unemp_A20_59 male exp expsqr highvocedu highgenedu adultedu if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath2'", append ctitle(Sec Gen, Higheredu Seperate,) pvalue

regress gen_unemp_A20_59 male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath2'", append ctitle(Sec Gen, Higheredu Seperate, Province Dum) pvalue

regress gen_unemp_A20_59 male exp expsqr higheredu if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath2'", append ctitle(Sec Gen, Higheredu Together,) pvalue

regress gen_unemp_A20_59 male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath2'", append ctitle(Sec Gen, Higheredu Together, Province Dum) pvalue

*3) High occupation

regress voc_highocc male exp expsqr highvocedu highgenedu adultedu if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath3'", replace ctitle(Sec Voc, Higheredu Seperate,) pvalue

regress voc_highocc male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath3'", append ctitle(Sec Voc, Higheredu Seperate, Province Dum) pvalue

regress voc_highocc male exp expsqr higheredu if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath3'", append ctitle(Sec Voc, Higheredu Together,) pvalue

regress voc_highocc male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath3'", append ctitle(Sec Voc, Higheredu Together, Province Dum) pvalue

regress gen_highocc male exp expsqr highvocedu highgenedu adultedu if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath3'", append ctitle(Sec Gen, Higheredu Seperate,) pvalue

regress gen_highocc male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath3'", append ctitle(Sec Gen, Higheredu Seperate, Province Dum) pvalue

regress gen_highocc male exp expsqr higheredu if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath3'", append ctitle(Sec Gen, Higheredu Together,) pvalue

regress gen_highocc male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath3'", append ctitle(Sec Gen, Higheredu Together, Province Dum) pvalue

*4) Long-term contract

regress voc_longtermcontract male exp expsqr highvocedu highgenedu adultedu if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath4'", replace ctitle(Sec Voc, Higheredu Seperate,) pvalue

regress voc_longtermcontract male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath4'", append ctitle(Sec Voc, Higheredu Seperate, Province Dum) pvalue

regress voc_longtermcontract male exp expsqr higheredu if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath4'", append ctitle(Sec Voc, Higheredu Together,) pvalue

regress voc_longtermcontract male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath4'", append ctitle(Sec Voc, Higheredu Together, Province Dum) pvalue

regress gen_longtermcontract male exp expsqr highvocedu highgenedu adultedu if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath4'", append ctitle(Sec Gen, Higheredu Seperate,) pvalue

regress gen_longtermcontract male exp expsqr highvocedu highgenedu adultedu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath4'", append ctitle(Sec Gen, Higheredu Seperate, Province Dum) pvalue

regress gen_longtermcontract male exp expsqr higheredu if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath4'", append ctitle(Sec Gen, Higheredu Together,) pvalue

regress gen_longtermcontract male exp expsqr higheredu provincedum2-provincedum15 if inrange(birthyear, 1971, 1992)
outreg2 using "`xlspath4'", append ctitle(Sec Gen, Higheredu Together, Province Dum) pvalue

log close
clear all
