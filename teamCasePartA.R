#Load the data file
historical = read.csv('Dartboard_historical.csv')

#Create the necessary variables for the regression model
#dependent variable
historical$DP = log10(historical$Sales/historical$Population)
#independent variables
historical$Season = factor(historical$Season)
historical$LOGincome = log10(historical$Income)
historical$Week_Num_new = historical$Week + (historical$Year-2012)*52

#Split training/testing
histTrain = historical[historical$Year <= 2013,]
histTest = historical[historical$Year > 2013,]

#Create model
mod = lm(DP~LOGincome+Week_Num_new+Season,data=histTrain)

summary(mod)

#Performance metrics
pred = predict(mod,newdata=histTest)
SSE = sum((pred - histTest$DP)^2)
SSE
train.mean = mean(histTrain$DP)
SST = sum((train.mean - histTest$DP)^2)
SST
OSR2 = 1 - SSE/SST
OSR2

#Question: why is OSR2 so much larger than in-sample R2?



#Read data file
future = read.csv('Dartboard_future.csv')

#create independent variables
future$Season = factor(future$Season)
future$LOGincome = log10(future$Income)
future$Week_Num_new = future$Week + (future$Year-2012)*52

#Apply model
predFuture = predict(mod,newData=future)
#Convert dependent variable to actual sales
predFuture = 10^predFuture*future$Population

#Append predicted sales to 'future' dataframe
future$Sales = predFuture