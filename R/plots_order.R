# SPDX-Copyright: Copyright (c) Capital One Services, LLC 
# SPDX-License-Identifier: Apache-2.0 
# Copyright 2017 Capital One Services, LLC 
#
# Licensed under the Apache License, Version 2.0 (the "License"); 
# you may not use this file except in compliance with the License. 
#
# You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0 
#
# Unless required by applicable law or agreed to in writing, software distributed 
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS
# OF ANY KIND, either express or implied. 
# 
# See the License for the specific language governing permissions and limitations under the License. 


###########################################
#          Order By R2                    #
###########################################

#' Create numerical variable ranking using R2 between date to and variable
#' 
#' Calculates R2 of a linear model of the formula \code{var} ~ \code{dateNm} for
#' each \code{var} of class \code{nmrcl} and returns a vector of
#' variable names ordered by highest R2. The linear model can be calculated over
#' a subset of dates, see details of parameter \code{buildTm}. Non-numerical
#' variables are returned in alphabetical order after the sorted numerical
#' variables.
#'
#' @inheritParams PrepData
#' @inheritParams PlotNumVar
#' @param dataFl A \code{data.table} of data; must be the output of the
#'   \code{\link{PrepData}} function. 
#' @param buildTm Vector identify time period for ranking/anomaly detection
#' (most likely model build period). Allows for a subset of plotting time
#' period to be used for anomaly detection.
#' \itemize{
#'      \item Must be a vector of dates and must be inclusive i.e. buildTm[1]
#'        <= date <= buildTm[2] will define the time period.
#'      \item Must be either \code{NULL}, a vector of length 2, or a vector of 
#'        length 3. 
#'      \item If \code{NULL}, the entire dataset will be used for 
#'        ranking/anomaly detection. 
#'      \item If a vector of length 2, the format of the dates must be
#'        a character vector in default R date format (e.g. "2017-01-30"). 
#'      \item If a vector of length 3, the first two columns must contain dates 
#'        in any strptime format, while the 3rd column contains the strptime 
#'        format (see \code{\link{strptime}}). 
#'      \item The following are equivalent ways of selecting
#'        all of 2014:
#'      \itemize{
#'        \item \code{c("2014-01-01","2014-12-31")}
#'        \item \code{c("01JAN2014","31DEC2014", "\%d\%h\%Y")}
#'      }
#' }
#' @export
#' 
#' @seealso Functions depend on this function:
#'          \code{\link{vlm}}.
#' @seealso This function depends on:
#'          \code{\link{CalcR2}},
#'          \code{\link{PrepData}}.
#'          
#' @return A vector of variable names sorted by R2 of \code{lm} of the formula
#'   \code{var} ~ \code{dateNm} (highest R2 to lowest)
#' @section License: 
#' Copyright 2017 Capital One Services, LLC Licensed under the
#' Apache License, Version 2.0 (the "License"); you may not use this file
#' except in compliance with the License. You may obtain a copy of the 
#' License at http://www.apache.org/licenses/LICENSE-2.0 Unless required by
#' applicable law or agreed to in writing, software distributed under the
#' License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#' CONDITIONS OF ANY KIND, either express or implied. See the License for the
#' specific language governing permissions and limitations under the License.
#' @examples
#' data(bankData)
#' bankData <- PrepData(bankData, dateNm = "date", dateGp = "months", 
#'                      dateGpBp = "quarters")
#' OrderByR2(bankData, dateNm = "date")

OrderByR2 <- function(dataFl, dateNm, buildTm = NULL, weightNm = NULL,
                      kSample = 50000) {
  
  ## Make sure no NAs in weights and dates
  if (!is.null(weightNm)) {
    if (any(is.na(dataFl[[weightNm]]))) {
      warning("Weights column contains NAs--will be deleted casewise")
    }
  }
  if (any(is.na(dataFl[[dateNm]]))) {
    warning("Date column contains NAs--will be deleted casewise")
  }
  
  ## Convert buildTm to IDate format
  ## If the length of input buildTm is not 2 or 3, then use start and end time in dateNm
  buildTm <- switch(as.character(length(buildTm)), "2" = as.IDate(buildTm),
                    "3" = as.IDate(buildTm[1:2], buildTm[3]),
                    # avoid inheritence as list using [[]]
                    dataFl[c(1, .N), dateNm, with = FALSE][[1]])
  
  num_vars <- names(Filter(is.nmrcl, dataFl))
  cat_vars <- names(Filter(is.ctgrl, dataFl))
  
  ## Sorting by R2 only works for numeric variables.
  if (length(num_vars > 0)) {
    
    # Using sample directly in dataFl parameter for brevity,
    # which reorders the input to CalcR2 but does not change output
    r2 <- vapply(num_vars, CalcR2,
                 dataFl = dataFl[buildTm[1] <= get(dateNm) &
                                   get(dateNm) <= buildTm[2], ][
                                     sample(.N, min(.N, kSample))],
                 dateNm = dateNm, weightNm = weightNm, imputeValue = NULL,
                 numeric(1))
    sortVars <- c(num_vars[order(r2, decreasing = TRUE)], cat_vars)
  } else {
    sortVars <- cat_vars
  }
  
  return(sortVars)
}


###########################################
#           CalcR2 Function               #
###########################################

#' Calculates R2 of a numerical variable using date as the predictor
#'
#' Calculates weighted R2 of a univariate weighted linear model with
#' \code{dateNm} as x and \code{myVar} as y using the workhorse \code{lm.fit}
#' and \code{lm.wfit} functions.
#'
#' @param myVar Name of variable to model. 
#' @param dataFl A \code{data.table}, containing \code{myVar}, \code{dateNm}, 
#'   and \code{weightNm}.
#' @param dateNm Name of column containing the date variable (to be modeled as
#'   numeric); this date column must not have NA's. 
#' @param weightNm Name of column containing row weights. If weights equal one, 
#'   then the \code{\link{lm.fit}} function will be called, otherwise the 
#'   \code{\link{lm.wfit}} will be called. The weights column must not have NA's.
#' @param imputeValue Either \code{NULL} or numeric. If \code{NULL}, model will
#'   be fit on only non-NA components of \code{myVar}. If numeric, missing cases
#'   of \code{myVar} will be imputed to \code{imputeValue}.
#' @return A numeric value of R2.
#' @export
#'   
#' @seealso Functions depend on this function:
#'          \code{\link{OrderByR2}}.
#' @seealso This function depends on:
#'          \code{\link{PrepData}}.
#'   
#' @section License:
#' Copyright 2017 Capital One Services, LLC Licensed under the Apache License,
#' Version 2.0 (the "License"); you may not use this file except in compliance
#' with the License. You may obtain a copy of the  License at
#' http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law
#' or agreed to in writing, software distributed under the License is 
#' distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY 
#' KIND, either express or implied. See the License for the specific language 
#' governing permissions and limitations under the License.

CalcR2 <- function(myVar, dataFl, dateNm, weightNm = NULL, imputeValue = NULL) {

  message("Calculating R2 of ", myVar)
  
  if (sum(!is.na(dataFl[[myVar]])) < 2) {
    ## If kSample is not null, then we need to recheck that the subsample is not
    ## all missing. If there are less than 2 numeric values left after sampling
    ## we can't calculate R2
    return(Inf)
  } else {
    y <- dataFl[[myVar]]
    
    ## If imputeValue is available, we impute everywhere Y is missing
    if (!is.null(imputeValue)) {
      y[is.na(y)] <- imputeValue
    }
    
    ## Index of missing values in y (after imputation if applicable)
    yIdx <- which(is.na(y))
    
    ## We perform casewise deletion anywhere X, Y or W (if not null) is missing
    if (!is.null(weightNm)) {
      w <- dataFl[[weightNm]]
      wIdx <- which(is.na(w))
      yIdx <- unique(c(yIdx, wIdx))
    }
    
    ## Convert x from date to numeric, plus a column of ones as the intercept
    x <- cbind(1, as.matrix(as.numeric(dataFl[[dateNm]]), ncol = 1))
    xIdx <- which(is.na(x[, 2]))
    yIdx <- unique(c(xIdx, yIdx))
    
    ## Remove all entries as in yIdx
    if (length(yIdx) > 0) {
      if (!is.null(weightNm)) {
        w <- w[-c(yIdx)]
      }
      y <- y[-c(yIdx)]
      x <- x[-c(yIdx), ]
    }
    
    ## Compute R2 or weighted R2
    if (is.null(weightNm)) {
      mod <- lm.fit(x = x, y = y)
      r2  <- 1 - sum(mod$resid ^ 2) / sum( (y - mean(y)) ^ 2)
    } else {
      mod <- lm.wfit(x = x, y = y, w = w)
      r2  <- 1 - sum(w * mod$resid ^ 2) / sum(w * (y - Hmisc::wtd.mean(y, w, normwt = TRUE)) ^ 2)
    }
    return(r2)
  }
}
