setwd("C:/Users/tanya/OneDrive/Desktop")

library(tidyverse)
library(lubridate)
library(caret)

### Loading and Preparing the Data

data_calls <- read_delim("case_data_calls.csv",delim=";") %>%
  mutate_at(vars(date),~as.Date(., format = "%d-%m-%Y"))

data_resv <- read_delim("case_data_reservations.csv",delim = ";") %>%
  mutate_at(vars(date),~as.Date(., format = "%d-%m-%Y"))

combined_data <- data_calls %>%
  inner_join(data_resv,by=c("date"))

### Plot of Calls against Date

data_calls %>%
  ggplot(aes(x=date,y=calls)) +
  geom_line() +
  scale_x_date(date_breaks = "1 month") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90),
        panel.grid.minor.x = element_blank()) +
  scale_y_continuous(labels = scales::number) +
  labs(
    x = "Date",
    y= "Calls",
    title = "Chart of Calls against Date",
    subtitle = "Yearly Cycles of Peak in Aug, Trough in Feb"
  )


### Plot of Reservations against Date

data_resv %>%
  ggplot(aes(x=date,y=total_reservations)) +
  geom_line() +
  scale_x_date(date_breaks = "6 month") +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 90)) +
  scale_y_continuous(labels = scales::number) +
  labs(
    x = "Date",
    y= "Total Reservations",
    title = "Chart of Total Reservations against Date",
    subtitle = "Seasonal Effect coupled with cyclical effect"
  )


### Merging 2 Plots

combined_data %>%
  mutate_at(vars(total_reservations),~./2.5) %>%
  ggplot() +
  geom_line(aes(x=date,y=calls), colour = "tomato3") +
  geom_line(aes(x=date,y=total_reservations), colour = "deepskyblue4") +
  scale_y_continuous(
    name = "Calls",
    sec.axis = sec_axis(trans=~./2.5, name = "Total Reservations",
                        labels = scales::number),
    labels = scales::number
  ) +
  theme_classic() +
  labs(
    x = "Date",
    title = "Plotting both Calls and Reservations against Date"
  ) +
  scale_x_date(date_breaks = "6 month")

### correlation between both

combined_corr <- combined_data %>%
  mutate(PreviousCalls = lag(calls,n=1,order_by = date),
         PreviousTotalReservations = lag(total_reservations,n=1,order_by = date)) 

cor.test(combined_corr$PreviousCalls,combined_corr$PreviousTotalReservations)

ggplot(data=NULL,aes(x=combined_corr$PreviousCalls,y=combined_corr$PreviousTotalReservations)) +
  geom_point() +
  theme_classic() +
  geom_smooth(formula = y~x, method="lm", linetype = 2, colour = "tomato3") +
  labs(
    x = expression(Delta*" Calls (First Order Difference)"),
    y = expression(Delta*" Total Reservations (First Order Difference)"),
    title = "Correlation between First Order Difference of Calls against Total Reservations",
    subtitle = "Close Correlation Observed"
  ) +
  scale_x_continuous(labels=scales::number) +
  scale_y_continuous(labels=scales::number) +
  ggpmisc::stat_poly_eq(formula = y~x,
                        aes(label = ..rr.label..),
                        parse = TRUE) 

# Poisson Regression (Exploratory)

combined_data_model <- combined_data %>%
  mutate_at(vars(weekday),~factor(.,
                                  levels = c(1,2,3,4,5,6,7),
                                  labels = c("Mon","Tues","Wed",
                                             "Thurs","Fri","Sat",
                                             "Sun"))) %>%
  select(-date)

model_poisson <- glm(calls~., data = combined_data_model,
                     family = "poisson")

summary(model_poisson)

### Test for Total Regressopm

qchisq(0.95,11)

model_poisson$null.deviance - model_poisson$deviance

### Overll significant

### GOF Test

qchisq(0.95,nrow(combined_data_model) - length(coef(model_poisson)))

model_poisson$deviance

## Not a good fit

tibble(cooks_distance = cooks.distance(model_poisson)) %>%
  rownames_to_column(var="rowIndex") %>%
  ggplot(aes(x=factor(rowIndex),y=cooks_distance)) +
  geom_col() +
  scale_x_discrete(breaks = seq(0,nrow(combined_data_model),100)) +
  labs(
    x = "Index",
    y = "Cook's Distance",
    title = "Outlier Detection Plot for Poisson Regression",
    subtitle = "Leverage Points Spotted Around Aug 2015"
  ) +
  geom_hline(aes(yintercept = 1), linetype = 2, colour = "tomato3") +
  theme_minimal()

tibble(cooks_distance = cooks.distance(model_poisson)) %>%
  bind_cols(combined_data) %>%
  rownames_to_column(var="rowIndex") %>%
  mutate_at(vars(rowIndex),~as.integer(.)) %>%
  filter(rowIndex>=580 & rowIndex<=595)

combined_data %>%
  mutate(month = month(date),
         day = day(date),
         year = year(date)) %>%
  filter(month ==8 & day %in% seq(3,18,1)) %>%
  mutate_at(vars(year),~as.factor(.)) %>%
  ggplot(aes(x=year,y=calls,fill=year)) +
  geom_col() +
  facet_wrap(~day) +
  theme_minimal() +
  geom_text(aes(label = scales::number(calls,accuracy = 1)), vjust = -0.25) +
  ggsci::scale_fill_d3() +
  scale_y_continuous(expand = expansion(0,3000)) +
  labs(
    fill = "Year",
    y = "Calls",
    x = "Year"
  )

plot(model_poisson)

ggplot(data=NULL, aes(sample = residuals(model_poisson,type = "deviance"))) +
  stat_qq() +
  stat_qq_line() +
  theme_classic() +
  labs(
    title = "Quantile-Quantile Plot of Deviance Residuals of Poisson Regression",
    subtitle = "Normal Distribution Not Achived Based on Deviances"
  )

ggplot(data=NULL, aes(x = residuals(model_poisson,type = "deviance"))) +
  geom_histogram() +
  theme_classic() +
  labs(
    x = "Residuals",
    y = "Occurences",
    title = "Histogram of Deviances",
    subtitle = "Normality not observed"
  )

# Variance Inflation Factor

car::vif(model_poisson)

# Box Plot between weekdays

param <- combined_data_model %>%
  ggplot(aes(x=weekday,y=calls,fill=weekday)) +
  geom_boxplot(notch = TRUE) +
  ggsci::scale_fill_d3() +
  theme_classic() +
  xlab ("Day") +
  ylab("Calls") +
  scale_y_continuous(labels = scales::number) +
  labs(
    fill = "Day"
  ) +
  labs(
    title = "Non-Parametric Method of Estimating Median of Calls",
    subtitle = "Number of Calls Lower on Sat and Sun"
  )

non_param <- combined_data_model %>%
  ggplot(aes(x=weekday,y=calls,colour=weekday)) +
  stat_summary(fun.data = "mean_cl_boot",
               fun.args = list(
                 conf.int = 0.95
               )) +
  theme_classic() +
  xlab ("Day") +
  ylab("Calls") +
  labs(
    caption = "Range based on 95% Confidence Interval",
    colour = "Day",
    title = "Parametric Method of Estimating Mean of Number of Calls",
    subtitle = "Number of Calls Lower on Sat and Sun"
  ) +
  ggsci::scale_color_d3() +
  scale_y_continuous(breaks = seq(2000,8000,by=1000),labels = scales::number) 

ggpubr::ggarrange(param,non_param, nrow = 2)

### Machine Learning Predictive Model

# 10 k-folds, 90% Training + Validation, 10% Test Set

set.seed(13112020)

test_set <- combined_data_model %>%
  sample_frac(0.1)

train_set <- combined_data_model %>%
  anti_join(test_set)

# Poisson Regression

tc <- trainControl("repeatedcv",
                   number = 10,
                   repeats = 3,
                   savePredictions = TRUE)

poisson_model_pred <- train(
  calls ~.,
  data = train_set,
  method = "glm",
  trControl = tc,
  family = poisson
)

poisson_model_pred$results["RMSE"]

# Linear Regression

linear_regression_model_pred <- train(
  calls ~.,
  data = train_set,
  method = "lm",
  trControl = tc
)

linear_regression_model_pred$results["RMSE"]

### random Forest

control_rf <- trainControl(method = "repeatedcv",
                        number = 10,
                        repeats = 3,
                        search = "random",
                        savePredictions = TRUE)

random_forest <- train(
  calls ~.,
  data = train_set,
  method = "rf",
  trControl = control_rf
)

rf_results <- random_forest$results
rf_results[which.min(rf_results$RMSE),"RMSE"]

### Support Vector Regression

train_set_dummies_scale <- fastDummies::dummy_cols(train_set,select_columns = c("weekday"),
                                                   remove_first_dummy = TRUE) %>%
  select(-weekday) %>%
  scale(.)

svr <- train(
  calls ~.,
  data = train_set_dummies_scale,
  method = "svmLinear",
  trControl = control_rf
)

svr_results <- svr$results
svr_results[which.min(svr_results$RMSE),"RMSE"] * sd(train_set$calls) 

### kNN Regression

knn <- train(
  calls ~.,
  data = train_set,
  method = "knn",
  trControl = control_rf
)

## Linear Regression is the best fit

model_pred <- test_set %>%
  mutate(predicted_values = predict(linear_regression_model_pred, newdata = test_set)) %>%
  mutate(sqerror = (calls-predicted_values)^2) %>%
  summarise(RMSE = sqrt(sum(sqerror)/n()))

## Fit to Whole Model

combined_data_model_scaled <- combined_data_model %>%
  fastDummies::dummy_cols(select_columns = "weekday", remove_first_dummy = TRUE) %>%
  select(-weekday) %>%
  scale(.) %>%
  as.data.frame(.)

chosen_model <- lm(calls~., data = combined_data_model_scaled )

enframe(coef(chosen_model)) %>%
  arrange(desc(value)) %>%
  filter(name != "(Intercept)") %>%
  ggplot(aes(x=reorder(name,value),y=value)) +
  geom_col() +
  scale_x_discrete(labels = function(x) str_wrap(x, width = 5)) +
  theme_minimal() +
  coord_flip() +
  labs(
    y = "Scaled Coefficient",
    x = "Coefficient",
    title = "Scaled Coefficients of Linear Regression"
  )

combined_data_model_with_pred <- combined_data_model %>%
  bind_cols(prediction = predict(chosen_model))

ggplot(data=NULL,aes(sample = MASS::stdres(chosen_model))) +
  stat_qq() +
  stat_qq_line()