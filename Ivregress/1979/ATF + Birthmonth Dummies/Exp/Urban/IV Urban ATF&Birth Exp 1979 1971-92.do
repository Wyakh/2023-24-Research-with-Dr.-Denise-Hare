local folderpath "/Users/wyattwyatt/Downloads/Revision Code/Wyatt/Ivregress/1979/ATF + Birthmonth Dummies/Exp"
local filename "IV Urban ATF&Birth Exp 1979 1971-1992"
local datapath "/Users/wyattwyatt/Downloads/Revision Code/20240716 Urban Chip2018 and Instrumental Statistics and Inflation.dta"

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

**
tab birthmonth, gen(birthmonthdum)

*9) Tenure
gen yearstart = C02 if C02!=-88 & C02!=-99
gen tenure = 2018 - yearstart
gen tenuresqr = tenure * tenure


*Step Two: Regressions

gen secvochighedu = secvocedu * higheredu
gen secgenhighedu = secgenedu * higheredu

*1)
ivregress 2sls log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 male (higheredu secgenhighedu secgenedu = t d td) if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000) & educat != ., first
estat endog
local durbin_p = r(p_durbin)
local wu_p = r(p_wu)
local endog_df = r(df)
ivhettest
local pagan_hall_p = r(php)
local hetero_df = r(df)
sum log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 male if e(sample)
outreg2 using "`xlspath'", replace ctitle(IV: higheredu secgenedu & their product, Pooled) pvalue addstat("Engod: Durbin p-value", `durbin_p', "Engod: Wu-Hausman p-value", `wu_p', "Endogeneity df", `endog_df', "Heterosk: Pagan-Hall p-value", `pagan_hall_p', "Heteroskedasticity df", `hetero_df')

ivregress 2sls log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 male provincedum2-provincedum15 (higheredu secgenhighedu secgenedu = t d td ) if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000) & educat != ., first
estat endog
local durbin_p = r(p_durbin)
local wu_p = r(p_wu)
local endog_df = r(df)
ivhettest
local pagan_hall_p = r(php)
local hetero_df = r(df)
sum log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 male if e(sample)
outreg2 using "`xlspath'", append ctitle(IV: higheredu secgenedu & their product, Pooled Province) pvalue addstat("Engod: Durbin p-value", `durbin_p', "Engod: Wu-Hausman p-value", `wu_p', "Endogeneity df", `endog_df', "Heterosk: Pagan-Hall p-value", `pagan_hall_p', "Heteroskedasticity df", `hetero_df')

ivregress 2sls log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 (higheredu secgenhighedu secgenedu = t d td ) if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000) & male == 1 & educat != ., first
estat endog
local durbin_p = r(p_durbin)
local wu_p = r(p_wu)
local endog_df = r(df)
ivhettest
local pagan_hall_p = r(php)
local hetero_df = r(df)
sum log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 male if e(sample)
outreg2 using "`xlspath'", append ctitle(IV: higheredu secgenedu & their product, Male) pvalue addstat("Engod: Durbin p-value", `durbin_p', "Engod: Wu-Hausman p-value", `wu_p', "Endogeneity df", `endog_df', "Heterosk: Pagan-Hall p-value", `pagan_hall_p', "Heteroskedasticity df", `hetero_df')

ivregress 2sls log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 provincedum2-provincedum15 (higheredu secgenhighedu secgenedu = t d td ) if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000) & male == 1 & educat != ., first
estat endog
local durbin_p = r(p_durbin)
local wu_p = r(p_wu)
local endog_df = r(df)
ivhettest
local pagan_hall_p = r(php)
local hetero_df = r(df)
sum log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 male if e(sample)
outreg2 using "`xlspath'", append ctitle(IV: higheredu secgenedu & their product, Male Province) pvalue addstat("Engod: Durbin p-value", `durbin_p', "Engod: Wu-Hausman p-value", `wu_p', "Endogeneity df", `endog_df', "Heterosk: Pagan-Hall p-value", `pagan_hall_p', "Heteroskedasticity df", `hetero_df')

ivregress 2sls log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 (higheredu secgenhighedu secgenedu = t d td ) if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000) & male == 0 & educat != ., first
estat endog
local durbin_p = r(p_durbin)
local wu_p = r(p_wu)
local endog_df = r(df)
ivhettest
local pagan_hall_p = r(php)
local hetero_df = r(df)
sum log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 male if e(sample)
outreg2 using "`xlspath'", append ctitle(IV: higheredu secgenedu & their product, Female) pvalue addstat("Engod: Durbin p-value", `durbin_p', "Engod: Wu-Hausman p-value", `wu_p', "Endogeneity df", `endog_df', "Heterosk: Pagan-Hall p-value", `pagan_hall_p', "Heteroskedasticity df", `hetero_df')

ivregress 2sls log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 provincedum2-provincedum15 (higheredu secgenhighedu secgenedu = t d td ) if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000) & male == 0 & educat != ., first
estat endog
local durbin_p = r(p_durbin)
local wu_p = r(p_wu)
local endog_df = r(df)
ivhettest
local pagan_hall_p = r(php)
local hetero_df = r(df)
sum log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 male if e(sample)
outreg2 using "`xlspath'", append ctitle(IV: higheredu secgenedu & their product, Female Province) pvalue addstat("Engod: Durbin p-value", `durbin_p', "Engod: Wu-Hausman p-value", `wu_p', "Endogeneity df", `endog_df', "Heterosk: Pagan-Hall p-value", `pagan_hall_p', "Heteroskedasticity df", `hetero_df')

*2)
ivregress 2sls log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 male (higheredu secgenhighedu = t d td ) if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000) & educat != ., first
estat endog
local durbin_p = r(p_durbin)
local wu_p = r(p_wu)
local endog_df = r(df)
estat overid
local sargan_p = r(p_sargan) 
local basman_p = r(p_basmann) 
local overid_df = r(df)
ivhettest
local pagan_hall_p = r(php)
local hetero_df = r(df)
sum log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 male if e(sample)
outreg2 using "`xlspath'", append ctitle(IV: higheredu & the product, Pooled) pvalue addstat("Engod: Durbin p-value", `durbin_p', "Engod: Wu-Hausman p-value", `wu_p', "Endogeneity df", `endog_df', "Overid: Sargan p-value", `sargan_p', "Overid: Basmann p-value", `basman_p', "Overidentification df", `overid_df', "Heterosk: Pagan-Hall p-value", `pagan_hall_p', "Heteroskedasticity df", `hetero_df')

ivregress 2sls log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 male provincedum2-provincedum15 (higheredu secgenhighedu = t d td ) if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000) & educat != ., first
estat endog
local durbin_p = r(p_durbin)
local wu_p = r(p_wu)
local endog_df = r(df)
estat overid
local sargan_p = r(p_sargan) 
local basman_p = r(p_basmann) 
local overid_df = r(df)
ivhettest
local pagan_hall_p = r(php)
local hetero_df = r(df)
sum log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 male if e(sample)
outreg2 using "`xlspath'", append ctitle(IV: higheredu & the product, Pooled Province) pvalue addstat("Engod: Durbin p-value", `durbin_p', "Engod: Wu-Hausman p-value", `wu_p', "Endogeneity df", `endog_df', "Overid: Sargan p-value", `sargan_p', "Overid: Basmann p-value", `basman_p', "Overidentification df", `overid_df', "Heterosk: Pagan-Hall p-value", `pagan_hall_p', "Heteroskedasticity df", `hetero_df')

ivregress 2sls log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 (higheredu secgenhighedu = t d td ) if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000) & male == 1 & educat != ., first
estat endog
local durbin_p = r(p_durbin)
local wu_p = r(p_wu)
local endog_df = r(df)
estat overid
local sargan_p = r(p_sargan) 
local basman_p = r(p_basmann) 
local overid_df = r(df)
ivhettest
local pagan_hall_p = r(php)
local hetero_df = r(df)
sum log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 male if e(sample)
outreg2 using "`xlspath'", append ctitle(IV: higheredu & the product, Male) pvalue addstat("Engod: Durbin p-value", `durbin_p', "Engod: Wu-Hausman p-value", `wu_p', "Endogeneity df", `endog_df', "Overid: Sargan p-value", `sargan_p', "Overid: Basmann p-value", `basman_p', "Overidentification df", `overid_df', "Heterosk: Pagan-Hall p-value", `pagan_hall_p', "Heteroskedasticity df", `hetero_df')

ivregress 2sls log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 provincedum2-provincedum15 (higheredu secgenhighedu = t d td ) if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000) & male == 1 & educat != ., first
estat endog
local durbin_p = r(p_durbin)
local wu_p = r(p_wu)
local endog_df = r(df)
estat overid
local sargan_p = r(p_sargan) 
local basman_p = r(p_basmann) 
local overid_df = r(df)
ivhettest
local pagan_hall_p = r(php)
local hetero_df = r(df)
sum log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 male if e(sample)
outreg2 using "`xlspath'", append ctitle(IV: higheredu & the product, Male Province) pvalue addstat("Engod: Durbin p-value", `durbin_p', "Engod: Wu-Hausman p-value", `wu_p', "Endogeneity df", `endog_df', "Overid: Sargan p-value", `sargan_p', "Overid: Basmann p-value", `basman_p', "Overidentification df", `overid_df', "Heterosk: Pagan-Hall p-value", `pagan_hall_p', "Heteroskedasticity df", `hetero_df')

ivregress 2sls log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 (higheredu secgenhighedu = t d td ) if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000) & male == 0 & educat != ., first
estat endog
local durbin_p = r(p_durbin)
local wu_p = r(p_wu)
local endog_df = r(df)
estat overid
local sargan_p = r(p_sargan) 
local basman_p = r(p_basmann) 
local overid_df = r(df)
ivhettest
local pagan_hall_p = r(php)
local hetero_df = r(df)
sum log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 male if e(sample)
outreg2 using "`xlspath'", append ctitle(IV: higheredu & the product, Female) pvalue addstat("Engod: Durbin p-value", `durbin_p', "Engod: Wu-Hausman p-value", `wu_p', "Endogeneity df", `endog_df', "Overid: Sargan p-value", `sargan_p', "Overid: Basmann p-value", `basman_p', "Overidentification df", `overid_df', "Heterosk: Pagan-Hall p-value", `pagan_hall_p', "Heteroskedasticity df", `hetero_df')

ivregress 2sls log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 provincedum2-provincedum15 (higheredu secgenhighedu = t d td ) if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000) & male == 0 & educat != ., first
estat endog
local durbin_p = r(p_durbin)
local wu_p = r(p_wu)
local endog_df = r(df)
estat overid
local sargan_p = r(p_sargan) 
local basman_p = r(p_basmann) 
local overid_df = r(df)
ivhettest
local pagan_hall_p = r(php)
local hetero_df = r(df)
sum log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 male if e(sample)
outreg2 using "`xlspath'", append ctitle(IV: higheredu & the product, Female Province) pvalue addstat("Engod: Durbin p-value", `durbin_p', "Engod: Wu-Hausman p-value", `wu_p', "Endogeneity df", `endog_df', "Overid: Sargan p-value", `sargan_p', "Overid: Basmann p-value", `basman_p', "Overidentification df", `overid_df', "Heterosk: Pagan-Hall p-value", `pagan_hall_p', "Heteroskedasticity df", `hetero_df')

*3)
ivregress 2sls log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 male (higheredu = t d td ) if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000) & educat != ., first
estat endog
local durbin_p = r(p_durbin)
local wu_p = r(p_wu)
local endog_df = r(df)
estat overid
local sargan_p = r(p_sargan) 
local basman_p = r(p_basmann) 
local overid_df = r(df)
ivhettest
local pagan_hall_p = r(php)
local hetero_df = r(df)
sum log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 male if e(sample)
outreg2 using "`xlspath'", append ctitle(IV: higheredu, Pooled) pvalue addstat("Engod: Durbin p-value", `durbin_p', "Engod: Wu-Hausman p-value", `wu_p', "Endogeneity df", `endog_df', "Overid: Sargan p-value", `sargan_p', "Overid: Basmann p-value", `basman_p', "Overidentification df", `overid_df', "Heterosk: Pagan-Hall p-value", `pagan_hall_p', "Heteroskedasticity df", `hetero_df')

ivregress 2sls log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 male provincedum2-provincedum15 (higheredu  = t d td ) if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000) & educat != ., first
estat endog
local durbin_p = r(p_durbin)
local wu_p = r(p_wu)
local endog_df = r(df)
estat overid
local sargan_p = r(p_sargan) 
local basman_p = r(p_basmann) 
local overid_df = r(df)
ivhettest
local pagan_hall_p = r(php)
local hetero_df = r(df)
sum log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 male if e(sample)
outreg2 using "`xlspath'", append ctitle(IV: higheredu, Pooled Province) pvalue addstat("Engod: Durbin p-value", `durbin_p', "Engod: Wu-Hausman p-value", `wu_p', "Endogeneity df", `endog_df', "Overid: Sargan p-value", `sargan_p', "Overid: Basmann p-value", `basman_p', "Overidentification df", `overid_df', "Heterosk: Pagan-Hall p-value", `pagan_hall_p', "Heteroskedasticity df", `hetero_df')

ivregress 2sls log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 (higheredu  = t d td ) if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000) & male == 1 & educat != ., first
estat endog
local durbin_p = r(p_durbin)
local wu_p = r(p_wu)
local endog_df = r(df)
estat overid
local sargan_p = r(p_sargan) 
local basman_p = r(p_basmann) 
local overid_df = r(df)
ivhettest
local pagan_hall_p = r(php)
local hetero_df = r(df)
sum log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 male if e(sample)
outreg2 using "`xlspath'", append ctitle(IV: higheredu, Male) pvalue addstat("Engod: Durbin p-value", `durbin_p', "Engod: Wu-Hausman p-value", `wu_p', "Endogeneity df", `endog_df', "Overid: Sargan p-value", `sargan_p', "Overid: Basmann p-value", `basman_p', "Overidentification df", `overid_df', "Heterosk: Pagan-Hall p-value", `pagan_hall_p', "Heteroskedasticity df", `hetero_df')
ivregress 2sls log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 provincedum2-provincedum15 (higheredu  = t d td ) if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000) & male == 1 & educat != ., first
estat endog
local durbin_p = r(p_durbin)
local wu_p = r(p_wu)
local endog_df = r(df)
estat overid
local sargan_p = r(p_sargan) 
local basman_p = r(p_basmann) 
local overid_df = r(df)
ivhettest
local pagan_hall_p = r(php)
local hetero_df = r(df)
sum log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 male if e(sample)
outreg2 using "`xlspath'", append ctitle(IV: higheredu, Male Province) pvalue addstat("Engod: Durbin p-value", `durbin_p', "Engod: Wu-Hausman p-value", `wu_p', "Endogeneity df", `endog_df', "Overid: Sargan p-value", `sargan_p', "Overid: Basmann p-value", `basman_p', "Overidentification df", `overid_df', "Heterosk: Pagan-Hall p-value", `pagan_hall_p', "Heteroskedasticity df", `hetero_df')

ivregress 2sls log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 (higheredu  = t d td ) if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000) & male == 0 & educat != ., first
estat endog
local durbin_p = r(p_durbin)
local wu_p = r(p_wu)
local endog_df = r(df)
estat overid
local sargan_p = r(p_sargan) 
local basman_p = r(p_basmann) 
local overid_df = r(df)
ivhettest
local pagan_hall_p = r(php)
local hetero_df = r(df)
sum log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 male if e(sample)
outreg2 using "`xlspath'", append ctitle(IV: higheredu, Female) pvalue addstat("Engod: Durbin p-value", `durbin_p', "Engod: Wu-Hausman p-value", `wu_p', "Endogeneity df", `endog_df', "Overid: Sargan p-value", `sargan_p', "Overid: Basmann p-value", `basman_p', "Overidentification df", `overid_df', "Heterosk: Pagan-Hall p-value", `pagan_hall_p', "Heteroskedasticity df", `hetero_df')

ivregress 2sls log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 provincedum2-provincedum15 (higheredu = t d td ) if inrange(birthyear, 1971, 1992) & inrange(monthlyearning, 250, 25000) & male == 0 & educat != ., first
estat endog
local durbin_p = r(p_durbin)
local wu_p = r(p_wu)
local endog_df = r(df)
estat overid
local sargan_p = r(p_sargan) 
local basman_p = r(p_basmann) 
local overid_df = r(df)
ivhettest
local pagan_hall_p = r(php)
local hetero_df = r(df)
sum log_monthlyearning exp expsqr birthmonthdum2-birthmonthdum12 male if e(sample)
outreg2 using "`xlspath'", append ctitle(IV: higheredu, Female Province) pvalue addstat("Engod: Durbin p-value", `durbin_p', "Engod: Wu-Hausman p-value", `wu_p', "Endogeneity df", `endog_df', "Overid: Sargan p-value", `sargan_p', "Overid: Basmann p-value", `basman_p', "Overidentification df", `overid_df', "Heterosk: Pagan-Hall p-value", `pagan_hall_p', "Heteroskedasticity df", `hetero_df')

log close
clear all
