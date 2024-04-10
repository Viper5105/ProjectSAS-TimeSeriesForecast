/* STSM03d05.sas */
/* Forecasting out-of-sample and validating */
/* This option causes the macro-generated SAS code to be printed in the log. */
options mprint;

/* Specify the number of timepoints for holdback across the program with &nhold. */


%let nhold=12;

/* This reads in the external file containing the actual macros and submits it when */
/* this statement is submitted. */

%include "C:/Users/cheta/Desktop/SAS/macros2_with_AIC_SBC.sas" / source2;

/* The %accuracy_prep macro prepares the series by assuring that the holdout */
/* measurements are not included in the estimation of the time series model, */
/* but rather saved for a later time, when the %accuracy macro is submitted. */
/* The macro creates a temporary data set called WORK._TEMP, containing two  */
/* variables: Y_FIT for the in-sample observations; and */
/*            Y_HOLDOUT for the out-of-sample observations. */
/* The syntax for the %accuracy_prep macro is: */
/* %ACCURACY_PREP (INDSN=              series data set name, */
/*                 SERIES=             name of the target series, */
/*                 TIMEID=             time ID variable, */
/*                 NUMHOLDBACK=        number of time points to hold out); */

     
%accuracy_prep(indsn= PROJECT1.AIRTRAFFIC1, series=RPM, timeid=Date, 
    numholdback=&nhold);

/* ODS SELECT NONE is used to suppress printing of the PROC ARIMA output. */
/* PROC ARIMA is run to estimate the model based on the non-holdout sample  */
/* and a forecast is requested for the entire sample.  Here, this is done
/* for two different models - the AR(1) model and the ARX(1) model. */
ods select none;

proc arima data=work._temp;
    identify var=_y_fit(1 12) crosscorr=(Ramp Flt);
    estimate p=(1) q=(12) method=ML outstat=AR1_forecast_STAT;
	forecast lead=12 back=0 alpha=0.05 id=Date interval=month out=AR1_forecast nooutall;
    estimate p=(1 2) q=(12) input=(Ramp) method=ML outstat=AR2_ramp_forecast_STAT; 
    forecast lead=12 back=0 alpha=0.05 id=Date interval=month out=AR2_ramp_forecast nooutall;
    estimate p=(1 2) q=(12) input=(1 $ Flt) method=ML outstat=AR2_flt_forecast_STAT;
    forecast lead=12 back=0 alpha=0.05 id=Date interval=month out=AR2_Flt_forecast nooutall;
    estimate p=(1 2) q=(12) input=(Ramp 1 $ Flt) method=ML outstat=AR2_rampflt_forecast_STAT;
    forecast lead=12 back=0 alpha=0.05 id=Date interval=month out=AR2_rampflt_forecast nooutall;
quit;

ods select all;

/* Using the %ACCURACY macro */
/* The syntax for the %accuracy macro is: */
/* %ACCURACY (INDSN=              series data set name, */
/*            SERIES=             name of the target series, */
/*            TIMEID=             time ID variable, */
/*            NUMHOLDBACK=        number of time points to hold out, */
/*            FORECAST=           name of the variable containing forecasts); */


%accuracy(indsn=work.AR1_forecast, instat=work.AR1_forecast_STAT, timeid=Date, series=RPM, 
    numholdback=&nhold);
%accuracy(indsn=work.AR2_ramp_forecast, instat=work.AR2_ramp_forecast_STAT, timeid=Date, series=RPM, 
    numholdback=&nhold);
%accuracy(indsn=work.AR2_flt_forecast, instat=work.AR2_flt_forecast_STAT, timeid=Date, series=RPM, 
    numholdback=&nhold);
%accuracy(indsn=work.AR2_rampflt_forecast, instat=work.AR2_rampflt_forecast_STAT, timeid=Date, series=RPM, 
    numholdback=&nhold);
   

data work.allmodels;
    set work.AR1_forecast_ACC work.AR2_ramp_forecast_ACC 
        work.AR2_flt_forecast_ACC work.AR2_rampflt_forecast_ACC;
run;

data work.trainaicsbc;
	set work.AR1_forecast_STAT work.AR2_ramp_forecast_STAT 
        work.AR2_flt_forecast_STAT work.AR2_rampflt_forecast_STAT;
run;

proc print data=work.allmodels label;
    id series model;
run;

proc print data=work.trainaicsbc label;
    id series model;
run;