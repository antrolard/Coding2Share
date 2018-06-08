// ++++++++++++++++++++++++++++ PROLOG +++++++++++++++++++
/* 
    
   DATA: EDVISIT_CLEAN; EDVISIT_PATIENT
   AUTHOR: Anne Trolard
   NOTES: GC = gonorrhea, Ct = chlamydia
		   
   
 */

// +++++++++++++++++++++++++++ DATA MANAGEMENT ++++++++++++++


use EDVISIT_PATIENT, clear

//collpase infection variables, they capture duplicate testing
recode micro_gonorh (1/6 = 1), gen(micro_gonorh_YN)
recode micro_chlamydia (1/5 = 1), gen(micro_chlamydia_YN)

// clean up sex and pregnancy vars
encode sex, gen(sexnum)
	label define sexnum 1 "female" 2 "male", replace
	label values sexnum sexnum
	
	recode preg_YN (1/3=1) // # who were not pregnant stayed the same
	replace preg_YN = . if preg_YN==0 & sexnum==2 

// clean race, & create 5 and 3 category vars
encode race, gen(racenum)
	recode racenum (2/3=1) (8/10=2)(1=3)(5=4)(11=4)(4=5)(6/7=5), gen(race5cat)
	label define racenum 1 "Black/AA" 2 "Caucasian" 3 "Asian" 4 "Other" ///
						 5 "Declined/Missing", replace
	label values racenum racenum
	recode race5cat (3/5=3), gen(race3cat)
	label define race3cat 1 "Black/AA" 2 "Caucasian" 3 "Other"
	label values race3cat race3cat

//clean age & create 5 CDC category var
recode age (min/19.99999 = 1 "13-19") (20/24.99999 = 2 "20-24") ///
	(25/29.99999 = 3 "25-29")(30/39.99999 = 4 "30-39")(40/max =5 "40+"),gen(age5cat)
save EDVISIT_PATIENT_temp, replace
	
	
use EDVISIT_CLEAN, clear 
//create one infection var
gen infection_status = 1 if (micro_gonorh==1 & micro_chlam==0) //234
	replace infection_status = 2 if (micro_gonorh==0 & micro_chlamydia==1) //512
	replace infection_status = 3 if (micro_gonorh==1 & micro_chlamydia==1) //152
	replace infection_status = 4 if (micro_gonorh==0 & micro_chlamydia==0) //4295
	label define infection_status 1 "Pos GC" 2 "Pos Ct" 3 "Dual" 4 "Neg"
	label values infection_status infection_status

//label treatment var
label define treatment_3 1"Properly Treated" 2"Under Treated" ///
	  3"Over Treated", modify
	  label values treatment_3  treatment_3
	  
// clean up sex and pregnancy vars
encode sex, gen(sexnum)
	label define sexnum 1 "female" 2 "male", replace
	label values sexnum sexnum
	
	recode preg_YN (1/3=1) // # who were not pregnant stayed the same
	replace preg_YN = . if preg_YN==0 & sexnum==2 

save EDVISIT_CLEAN_temp, replace

// ######################## TABLE 1 - DEMOGRAPHICS ##########
use EDVISIT_PATIENT_temp, clear

//breakdown of patient sex by race
ta race3cat sex, chi2 m column

//breakdown of age by sex
ta age5cat sex, chi2 m col

// is there a sig difference between GC infections by sex?
ta micro_gonorh_YN sexnum, chi2 col

// is there a sig difference between GC infections by sex?
ta micro_chlamydia_YN sexnum, chi2 col

// are super users more likely to have GC?
ta micro_gonorh_YN superusers, chi2 col

// are super users more likely to have Ct?
ta micro_chlamydia_YN superusers, chi2 col

//switch to visit level file
use EDVISIT_CLEAN_temp, clear

// how many tests for GC broken out by sex?
ta micro_gonorh sexnum, chi2 col

// how many tests for Ct broken out by sex?
ta micro_chlamydia sexnum, chi2 col

// ####################### TABLE 2 - SPECIAL POPULATIONS #######

use EDVISIT_PATIENT_temp, clear
// for results section
ta micro_gonorh_YN sex, m chi2 col
ta micro_chlamydia_YN sex, m chi2 col

// for the table
//What is prevalence of GC, Ct, and dual infections
ta micro_gonorh_YN micro_chlamydia_YN, m

//Are pregnant women more likely to have GC or Ct compared with non-pregnant women?
ta micro_gonorh_YN preg_YN, chi2 row col // p = .37, they are as likely to have GC
ta micro_chlamydia_YN preg_YN, chi2 row col // p = .50, as likely to have Ct
ta micro_gonorh_YN micro_chlamydia_YN if preg_YN==1, m
ta micro_gonorh_YN micro_chlamydia_YN if preg_YN==0, m

//Are super users more likely to have GC or Ct compared with single users
ta micro_gonorh_YN superusers, chi2 row col
ta micro_chlamydia_YN superusers, chi2 row col
ta micro_gonorh_YN micro_chlamydia_YN if superusers==1, m
ta micro_gonorh_YN micro_chlamydia_YN if superusers==0, m

// ############################# TABLE 3 ICD 9 CODES ########################

use EDVISIT_CLEAN_temp
// get top 5 (and 20 for reference)  dx codes in each dx code var
bysort sexnum: fre cat_icd9_1, de row(20) // 789,616,599,614,099
fre cat_icd9_2 if NAAT_Valid==1, de row(20) // 789,599,616,623,112         
fre cat_icd9_3 if NAAT_Valid==1, de row(20) // 789,599,616,787,623          
fre cat_icd9_4 if NAAT_Valid==1, de row(20) // 616,599,789,623,787  

// for females 
foreach x of varlist cat_icd9* {
	count if `x' == "789" & sexnum==1
	}
    
foreach var of varlist cat_icd9* {
	count if `var' == "616" & sexnum==1
	}

	
foreach var of varlist cat_icd9* {
	count if `var' == "599" & sexnum==1
	}
	
foreach var of varlist cat_icd9* {
	count if `var' == "614" & sexnum==1
	}
	
foreach var of varlist cat_icd9* {
	count if `var' == "V22" & sexnum==1
	}

foreach var of varlist cat_icd9* {
	count if `var' == "623" & sexnum==1
	}

	foreach var of varlist cat_icd9* {
	count if `var' == "625" & sexnum==1
	}

  // males
  
foreach var of varlist cat_icd9* {
	count if `var' == "597" & sexnum==2
	}

foreach var of varlist cat_icd9* {
	count if `var' == "099" & sexnum==2
	}
	
foreach var of varlist cat_icd9* {
	count if `var' == "788" & sexnum==2
	}
	
foreach var of varlist cat_icd9* {
	count if `var' == "604" & sexnum==2
	}

foreach var of varlist cat_icd9* {
	count if `var' == "599" & sexnum==2
	}

foreach var of varlist cat_icd9* {
	count if `var' == "789" & sexnum==2
	}

foreach var of varlist cat_icd9* {
	count if `var' == "607" & sexnum==2
	}

// ############################# TABLE 4 TREATMENT ###########################
use EDVISIT_CLEAN_temp, clear

/*Of the 979 visits positive for any infection, 60% were appropriately treated, 
while 40% were undertreated. */
ta treatment_3 if infection_status != 4

/*Among visits positive for GC, Ct, or a dual infection, men were significantly 
more likely to be properly treated compared to women 
(χ 2 = 315.36, χ 2=53.89, χ 2 = 49.33, all p < .001); */
	// treatment status for all visits positive for an infection by sex
ta treatment_3 sex if infection_status != 4, chi2 col
	ta treatment_3 sex if infection_status==1, chi2 col exact
	ta treatment_3 sex if infection_status==2, chi2 col
	ta treatment_3 sex if infection_status==3, chi2 col
	ta treatment_3 sex if infection_status==4, chi2 col
/*Among all visits negative for an infection, women were less likely to be over-treated 
than men (χ 2 = 393.58, p < .001). */ 
ta treatment_3 sex if infection_status==4, chi2 col

/*Across all three categories of infection (GC, Ct, and dual infection), pregnant women had the lowest rates 
of proper treatment by visit, followed by non-pregnant women, and then men. */
ta preg_YN infection_status, m col
	ta infection_status treatment_3 if preg_YN==1, nofreq row
	ta infection_status treatment_3 if preg_YN==0, nofreq row
	ta infection_status treatment_3 if preg_YN==., nofreq row
	bysort preg_YN: ta infection_status treatment_3, m














