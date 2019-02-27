libname card "D:\Gautam_Jig11226\LogGraded";

proc import datafile="Z:\Assignments\Graded Assignment\Topic 10 -  Regression Models\Credit.csv"
out=card.creditcard dbms=csv replace;
run;

proc contents data=card.creditcard;
run;

proc means data=card.creditcard;
run;

proc freq data=card.creditcard;
run;

/*DATA EXPLORATION AND DATA PREPARATION*/

/*Initial Missing value check for Dependent variable*/
data missingcheck;
set card.creditcard;
if npa_status=" ";
run;

/* Found two rows with missing value in Dependent variable which we will delete from our dataset*/
/* Dropping extra monthly variable from dataset */
data card.creditcard1(drop= monthlyincome1);
set card.creditcard;
if npa_status=" " then delete; 
run;

/*Coverting following to character to numeric variable :
 1)Monthly Income 
 2)Number of dependents*/
 
data card.creditcard2(rename = (monthlyincome_new = monthlyincome NumberOfDependents_new = NumberOfDependents));
set card.creditcard1;
monthlyincome_new = monthlyincome * 1;
drop monthlyincome;
NumberOfDependents_new = NumberOfDependents * 1;
drop NumberOfDependents;
run;

/*We will now check for outliers for each numeric variable and then look for missing values */

proc univariate data=card.creditcard2;
var RevolvingUtilizationOfUnsecuredL;
run;
proc gplot data=card.creditcard2;
plot RevolvingUtilizationOfUnsecuredL*monthlyincome=gender;
run;

proc univariate data=card.creditcard2;
var NumberOfTime30_59DaysPastDueNotW;
run;
proc gplot data=card.creditcard2;
plot NumberOfTime30_59DaysPastDueNotW*monthlyincome=gender;
run;

proc univariate data=card.creditcard2;
var  NumberOfOpenCreditLinesAndLoans;
run;
proc gplot data=card.creditcard2;
plot NumberOfOpenCreditLinesAndLoans*monthlyincome=gender;
run;

proc univariate data=card.creditcard2;
var NumberOfTimes90DaysLate;
run;
proc gplot data=card.creditcard2;
plot NumberOfTimes90DaysLate*monthlyincome=gender;
run;

proc univariate data=card.creditcard2;
var NumberRealEstateLoansOrLines;
run;
proc gplot data=card.creditcard2;
plot NumberRealEstateLoansOrLines*monthlyincome=gender;
run;

proc univariate data=card.creditcard2;
var NumberOfTime60_89DaysPastDueNotW;
run;
proc gplot data=card.creditcard2;
plot NumberOfTime60_89DaysPastDueNotW*monthlyincome=gender;
run;

proc univariate data=card.creditcard2;
var NumberOfDependents;
run;
proc gplot data=card.creditcard2;
plot NumberOfDependents*age=gender;
run;

/*Treating outliers*/
/*I have come with the following conclusion with respect to the outliers ,  

1) Delete whose age =0 
2) Delete NumberOfTime30_59DaysPastDueNotW > 90
3) Delete NumberOfOpenCreditLinesAndLoans whose monthly salary is greater than 1000000
4) Delete NumberOfTimes90DaysLate>90
5) Delete NumberRealEstateLoansOrLines>20
6) Delete NumberOfTime60_89DaysPastDueNotWorse>90
7) Delete NumberOfDependents>9
8) Delete monthly income =0 & grester than 1000000
*/

data card.creditcard3;
set card.creditcard2;
if age = 0 then delete;
if NumberOfTime30_59DaysPastDueNotW>90 then delete;
if monthlyincome= 0 then delete;
if monthlyincome >= 1000000 then delete;
if NumberOfTimes90DaysLate>90 then delete;
if NumberRealEstateLoansOrLines>20 then delete;
if NumberOfTime60_89DaysPastDueNotW>90 then delete;
if NumberOfDependents>9 then delete ;
run;

/*Check for Missing values*/


proc means n nmiss DATA = card.creditcard3;
var monthlyincome numberofdependents;
RUN;

/*Missing values in following variables
 1) Monthlyincome = 29609
 2) Number of dependents = 3893
*/

/*Similar Case Imputation - Identifying the similar observation with respect to gender and education for 
monthlyincome and impute the average   */

data gen_edu_avg;
set card.creditcard3(keep = gender education monthlyincome);
run;

proc sort data=gen_edu_avg;
by gender education;
run;

proc freq data=gen_edu_avg;
tables gender*education / nopercent norow nocol;
run;

proc gchart data= gen_edu_avg;
vbar education / subgroup = gender;
run;

proc means mean data=gen_edu_avg;
class gender education;
var monthlyincome;
*output out=card.m_inc_mean;
run;

/*Merge the means into the main dataset*/

data card.m_inc_mean(drop= _type_ _freq_ _stat_ rename=(monthlyincome=monthlyincome_mean));
set card.m_inc_mean;
run;


proc sort data=card.creditcard3;
by gender education;
run;

data card.creditcard4;
merge card.creditcard3 card.m_inc_mean;
by gender education;
run;

/*imputing missing value and fixing debtratio */
data card.creditcard5 (drop = monthlyincome_mean);
set card.creditcard4;
if monthlyincome="." 
   then debtratio= (debtratio/monthlyincome_mean);
if monthlyincome="." 
   then monthlyincome= monthlyincome_mean; 
run;

/*Calculating mean for Numberofdependents*/

proc means mean data=card.creditcard5;
var numberofdependents;
output out=dep_mean mean(numberofdependents)= dependent_mean;
run;

data card.dep_mean(drop = _type_ _freq_);
set dep_mean;
column=1;
run;

data card.creditcard5;
set card.creditcard5;
column=1;
run;

data card.creditcard5;
merge card.creditcard5 card.dep_mean;
by column;
drop column;
run;

/* imputing missing value - number of dependents*/
data card.creditcard6;
set card.creditcard5;
if 0 < dependent_mean < 1 then dependent_mean= 1;
if numberofdependents = . then numberofdependents= dependent_mean;
drop dependent_mean;
run;

/*check for missing value*/

Proc means n nmiss data=card.creditcard6;
run;

 /* NO MORE MISSING VALUE */

/* Outlier Treatment for RevolvingUtilisation*/
/* Some values are in percent and some values are in whole number as we don't have credit limit in the 
   data to calculate all values in percent, hence , we will delete some observationa with 
   the whole numbers */
   
/* Delete RevolvingUtilizationOfUnsecuredL > 20 */   

data card.creditcard6;
set card.creditcard6;
if RevolvingUtilizationOfUnsecuredL > 20 then delete;
run;

 
 /*Convert Qualitative to Quantitative*/
 
 /*dummy variable for Region*/
 
DATA card.creditcard7;
set card.creditcard6;
IF Region = 'South' then south =1 ;
else south = 0;
IF Region = 'North' then north =1 ;
else north = 0;
IF Region = 'East' then east =1 ;
else east = 0;
IF Region = 'West' then west =1 ;
else west = 0;
IF Region = 'Centr' then central =1 ;
else central = 0;
RUN;
 
/*dummy variable for occupation*/

data card.creditcard7;
set card.creditcard7;
IF Occupation = 'Self_Emp' then self_emp =1 ;
else self_emp = 0;
IF Occupation = 'Officer1' then officer_1 =1 ;
else officer_1 = 0;
IF Occupation = 'Officer2' then officer_2 =1 ;
else officer_2 = 0;
IF Occupation = 'Officer3' then officer_3 =1 ;
else officer_3 = 0;
IF Occupation = 'Non-offi' then not_officer =1 ;
else not_officer = 0;
RUN;

/*dummy variable for education*/

data card.creditcard7;
set card.creditcard7;
IF Education = 'Professional' then edu_prof =1 ;
else edu_prof = 0;
IF Education = 'Graduate' then edu_grad =1 ;
else edu_grad = 0;
IF Education = 'Post-Grad' then edu_postgrd =1 ;
else edu_postgrd = 0;
IF Education = 'Matric' then edu_matric =1 ;
else edu_matric = 0;
IF Education = 'PhD' then edu_phd =1 ;
else edu_phd = 0;
RUN;

/*dummy variable for gender*/
/*Male and Female - since the variable are liear combination */
/*
data card.creditcard_final;
set card.creditcard7;
if gender = 'Male' then gen_male = 1;
else gen_male = 0;
if gender = 'Female' then gen_female = 1;
else gen_female = 0;
run;*/

data card.creditcard8;
set card.creditcard7;
if gender = 'Male' then gen_new = 1;
else gen_new = 0;
run;

/*dummy variable for age*/

data card.creditcard9(drop = house_own house_rent);
set card.creditcard8;
if 20 le age le 29 then age20= 1;
else age20=0;
if 30 le age le 39 then age30= 1;
else age30=0;
if 40 le age le 49 then age40= 1;
else age40=0;
if 50 le age le 59 then age50= 1;
else age50=0;
if 60 le age le 69 then age60= 1;
else age60=0;
if 70 le age le 79 then age70= 1;
else age70=0;
if 80 le age le 89 then age80= 1;
else age80=0;
if age ge 90 then age90= 1;
else age90=0;
run;

 /*dummy variable for rent_ownhouse
 ownhouse = 1
 rent = 0
 */
data card.creditcard_final;
set card.creditcard9;
IF Rented_OwnHouse = 'Ownhouse' then house_own =1 ;
else house_own = 0;
Run;

/*Model Building - Spliting the data*/
proc surveyselect data=card.creditcard_final
method = SRS out=samp1 samprate=0.70 outall;
run;

/*
data devsamp valsamp;
set card.creditcard_final;
if ranuni(100) < 0.7 then output devsamp;
else output valsamp;
run;
*/



/*Training and validate datasets*/

data card.creditcard_train card.creditcard_validate;
set samp1;
if selected = 0 then output card.creditcard_train;
else if selected = 1 then output card.creditcard_validate;
run;

/*Logistic regression*/

proc logistic data= card.creditcard_train descending;
model NPA_Status = RevolvingUtilizationOfUnsecuredL age gen_new north south east west /*central*/ 
                   house_own self_emp officer_1 officer_2 officer_3 /*not_officer*/
                   edu_prof edu_grad edu_postgrd edu_matric /*edu_phd*/ debtratio NumberOfTime30_59DaysPastDueNotW
                   NumberOfOpenCreditLinesAndLoans NumberOfTimes90DaysLate NumberRealEstateLoansOrLines
                   NumberOfTime60_89DaysPastDueNotW monthlyincome NumberOfDependents / ctable lackfit; 
run;

/*model 2 - adding age variables*/

proc logistic data= card.creditcard_train descending ;
model NPA_Status = RevolvingUtilizationOfUnsecuredL 
                   age /*age20 age30 age40 age50 age60 age70 age80 age90*/
                   gen_new north south east west /*central*/ 
                   house_own
                   self_emp officer_1 officer_2 officer_3 /*not_officer*/
                   edu_prof edu_grad edu_postgrd /*edu_matric*/ /*edu_phd*/ 
                   debtratio 
                   /*NumberOfTime30_59DaysPastDueNotW*/
                   NumberOfOpenCreditLinesAndLoans
                   /*NumberOfTimes90DaysLate */
                   NumberRealEstateLoansOrLines
                   NumberOfTime60_89DaysPastDueNotW
                   monthlyincome 
                   /*NumberOfDependents*/ / ctable lackfit; 
run;

proc logistic data= card.creditcard_train descending ;
model NPA_Status = RevolvingUtilizationOfUnsecuredL age /*age20 age30 age40 age50 age60 age70 age80 age90*/
                   gen_new north south east west /*central*/ 
                   /*house_rent*/ /*house_own*/ self_emp officer_1 officer_2 officer_3 /*not_officer*/
                   edu_prof edu_grad edu_postgrd /*edu_matric*/ /*edu_phd*/ /*debtratio*/ NumberOfTime30_59DaysPastDueNotW
                   /*NumberOfOpenCreditLinesAndLoans*/ NumberOfTimes90DaysLate /*NumberRealEstateLoansOrLines*/
                   NumberOfTime60_89DaysPastDueNotW monthlyincome /*NumberOfDependents*/ / ctable lackfit;
run;

/*Final Model */

proc logistic data= card.creditcard_train descending outmodel=dmm;
model NPA_Status = RevolvingUtilizationOfUnsecuredL 
                   age 
                   gen_new north east west  
                   house_own
                   self_emp officer_1 officer_2 officer_3 
                   edu_prof edu_grad edu_postgrd 
                   /*debtratio */
                   NumberOfOpenCreditLinesAndLoans
                   NumberRealEstateLoansOrLines
                   NumberOfTime60_89DaysPastDueNotW
                   monthlyincome 
                   NumberOfDependents / ctable lackfit; 
score out=dmp;
run;

/*Validation data */
proc logistic data= card.creditcard_validate descending outmodel=dmm;
model NPA_Status = RevolvingUtilizationOfUnsecuredL 
                   age 
                   gen_new north east west  
                   house_own
                   self_emp officer_1 officer_2 officer_3 
                   edu_prof edu_grad edu_postgrd 
                   /*debtratio */
                   NumberOfOpenCreditLinesAndLoans
                   NumberRealEstateLoansOrLines
                   NumberOfTime60_89DaysPastDueNotW
                   monthlyincome 
                   NumberOfDependents / ctable lackfit; 
                   score out=dmp;
run;

proc rank data= dmp out=decile groups=10 ties=mean;
var p_1;
ranks decile;
run; 

proc sort data= decile;
by descending decile;
run;

proc freq data=decile ;
tables decile*npa_status/ norow nocol nopercent;
run;


ods csv file='D:\Gautam_Jig11226\LogGraded\rankcurve1.csv';
proc print data= decile;
var npa_status p_1 decile;
run;
ods csv close;


