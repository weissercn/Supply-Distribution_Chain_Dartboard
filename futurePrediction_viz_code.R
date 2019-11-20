library(dplyr)
library(tidyverse)
library(readxl)

#setwd("~/Documents/School/Fall 2019/Analytics Edge/Case/Supply-Distribution_Chain_Dartboard")

futurePrediction_viz <- read.csv("futurePrediction.csv")

future = futurePrediction_viz

# Filtering data
future_2017_8wk <- future %>%
  filter(Week_Num >= "305" & Year == "2017")

# Total $Sales by year
Year = future %>% group_by(Year)
YearSales = Year %>% summarise(sum(Sales))
YearSales

# Total $Sales by week and year
# 2015
Sales15 = future %>% filter(Year == "2015") %>% group_by(Week)
Sales15_wk = Sales15 %>% summarise(sum(Sales))
Sales15_wk

# 2016
Sales16 = future %>% filter(Year == "2016") %>% group_by(Week)
Sales16_wk = Sales16 %>% summarise(sum(Sales))
Sales16_wk

# 2017
Sales17 = future %>% filter(Year == "2017") %>% group_by(Week)
Sales17_wk = Sales17 %>% summarise(sum(Sales))
Sales17_wk

# Income vs. Sales 
ggplot() + 
  geom_point(data = future, aes(x = Income, y = Sales, color = Population)) +
  ggtitle("Dartboard Northeast Income vs. Sales by Population Size") +
  xlab("Income") +
  ylab("Total Sales") + scale_y_continuous(breaks = scales::pretty_breaks(n = 9)) +
  theme(legend.position = "right", legend.key = element_rect(fill = NA))

# Sales by Year  
ggplot() + 
  geom_line(data = future, aes(x = Week_Num, y = Sales, color = "blue")) +
  ggtitle("Dartboard Northeast Demand Sales") +
  xlab("Week") +
  ylab("Total Sales") + scale_y_continuous(breaks = scales::pretty_breaks(n = 10))
