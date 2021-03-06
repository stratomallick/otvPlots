% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/categorical.R
\name{PlotRatesOverTime}
\alias{PlotRatesOverTime}
\title{Creates trace plots of categories' proportions over time for a discrete (or
binary) variable}
\usage{
PlotRatesOverTime(dataFl, dateGp, myVar, normBy = "time", weightNm = NULL,
  newLevels = NULL, kCategories = 9)
}
\arguments{
\item{dataFl}{A \code{data.table} of data; must be the output of the
\code{\link{PrepData}} function.}

\item{dateGp}{Name of the variable that the time series plots should be 
grouped by. Options are \code{NULL}, \code{"weeks"}, \code{"months"}, 
\code{"quarters"}, \code{"years"}. See \code{\link[data.table]{IDate}} for
details. If \code{NULL}, then \code{dateNm} will be used as \code{dateGp}.}

\item{myVar}{The name of the variable to be plotted}

\item{normBy}{The normalization factor for rate plots, can be \code{"time"}
or \code{"var"}. If \code{"time"}, then for each time period of 
\code{dateGp}, counts are normalized by the total counts over all 
categories in that time period. This illustrates changes of categories' 
proportions over time. If \code{"var"}, then for each category, its counts 
are normalized by the total counts over time from only this category. This
illustrates changes of categories' volumes over time.}

\item{weightNm}{Name of the variable containing row weights, or \code{NULL} for 
no weights (all rows receiving weight 1).}

\item{newLevels}{categories of \code{myVar} in order of global frequency}

\item{kCategories}{If a categorical variable has more than \code{kCategories},
trace plots of only the \code{kCategories} most prevalent categories are
plotted.}
}
\value{
A list:
  \item{p}{\code{ggplot} object, trace plots of categories' proportions 
    \code{myVar} over time.}
  \item{catVarSummary}{A \code{data.table}, contains categories' proportions 
    globally, and over-time in each time period in \code{dateGp}. Each row is
    a category of the categorical (or binary) variable \code{myVar}. The row
    whose \code{category == 'NA'} corresponds to missing. Categories are 
    ordered by global prevalence in a descending order.}
}
\description{
Creates trace plots of categories' proportions over time for a discrete (or
binary) variable
}
\section{License}{

Copyright 2017 Capital One Services, LLC Licensed under the Apache License,
Version 2.0 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the  License at
http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law
or agreed to in writing, software distributed under the License is 
distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY 
KIND, either express or implied. See the License for the specific language 
governing permissions and limitations under the License.
}

\examples{
data(bankData)
bankData$weight = rpois(nrow(bankData), 5)
bankData <- PrepData(bankData, dateNm = "date", dateGp = "months", 
                     dateGpBp = "quarters", weightNm = "weight")
PlotRatesOverTime(dataFl = bankData, dateGp = "months", weightNm = "weight",
                  myVar = "job", newLevels = NULL, normBy = "time")

}
\seealso{
Functions depend on this function:
         \code{\link{PlotCatVar}}.

This function depends on:
         \code{\link{PrepData}}.
}
