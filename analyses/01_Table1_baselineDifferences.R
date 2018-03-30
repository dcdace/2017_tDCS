library(gmodels) # for Cross Table

# import the data
tDCSdata = read.csv(file = "tDCSraw.csv", header = T)

# make stimulation, gender and belief factors
tDCSdata$stimulation = factor(tDCSdata$stimulation,
                              levels = c(0, 1),
                              labels = c("sham", "active"))

# ==================================================================
# CALCULATE NECCESSARY VARIABLES
# ==================================================================
# Mean sensations
tDCSdata$maxMean      = rowMeans(subset(tDCSdata, select 
                                        = c(max1, max2, max3, max4)))
tDCSdata$affectedMean = rowMeans(subset(tDCSdata, select 
                                        = c(affected1, affected2, affected3, affected4)))
tDCSdata$stoppedMean = rowMeans(subset(tDCSdata, select 
                                       = c(stop1, stop2, stop3, stop4)))
# Baseline performance
tDCSdata$ITPre  = (tDCSdata$ITPreTR + tDCSdata$ITPreUN) / 2
tDCSdata$ETPre  = (tDCSdata$ETPreTR + tDCSdata$ETPreUN) / 2
tDCSdata$ErrPre = (tDCSdata$ErrPreTR + tDCSdata$ErrPreUN) / 2

shamN       = table(tDCSdata$stimulation)["sham"]
activeN     = table(tDCSdata$stimulation)["active"]
# ==================================================================
# SCORES FPR NON-PARAMETRIC AND PARAMETRIC TESTS
# ==================================================================
scoresNonp  = c("age", "maxMean", "affectedMean", "stoppedMean")
scoresPar   = c("ITPre", "ETPre", "ErrPre")
scores      = c(scoresNonp, scoresPar)
# ==================================================================
# GENDER PROPORTION
# ==================================================================
genderCount = table(tDCSdata$stimulation, tDCSdata$gender)

genderDiffpval = chisq.test(tDCSdata$stimulation, tDCSdata$gender)$p.value

resultsGender = matrix(
  c(
    paste(genderCount["sham", "male"], ":", genderCount["sham", "female"], sep = ""),
    paste(genderCount["active", "male"], ":", genderCount["active", "female"], sep = ""),
    round(genderDiffpval, 3)
    ),
  nrow = 1,
  ncol = 3,
  dimnames = list("gender male:female", c(
    paste("Sham (N =", shamN, ")"),
    paste("Active (N =", activeN, ")"),
    "Difference p-val"
  ))
)
# ==================================================================
# AGE AND SENSATION DIFFERENCES
# ==================================================================
# means
meansSham = lapply(scoresNonp, function(x)
  mean(subset(tDCSdata[, x], tDCSdata$stimulation == "sham")))
meansActive = lapply(scoresNonp, function(x)
  mean(subset(tDCSdata[, x], tDCSdata$stimulation == "active")))
sdSham = lapply(scoresNonp, function(x)
  sd(subset(tDCSdata[, x], tDCSdata$stimulation == "sham")))
sdActive = lapply(scoresNonp, function(x)
  sd(subset(tDCSdata[, x], tDCSdata$stimulation == "active")))

baselineDiffpval = lapply(scoresNonp, function(x)
  wilcox.test(
    tDCSdata[, x] ~ stimulation,
    data = tDCSdata,
    alternative = "two.sided"
  )$p.value)

baselineDiffpvalTxt = lapply(baselineDiffpval, function(x)
  ifelse(x < 0.001, "< 0.001", round(x, 3)))

resultsNonp = matrix(
  c(
    paste(
      lapply(meansSham, function(x)
        round(x, 2)),
      "+-",
      lapply(sdSham, function(x)
        round(x, 2))
    ),
    paste(
      lapply(meansActive, function(x)
        round(x, 2)),
      "+-",
      lapply(sdActive, function(x)
        round(x, 2))
    ),
    baselineDiffpvalTxt
  ),
  nrow = length(scoresNonp),
  ncol = 3,
  dimnames = list(scoresNonp, c(
    paste("Sham (N =", shamN, ")"),
    paste("Active (N =", activeN, ")"),
    "Difference p-val"
  ))
)
# ==================================================================
# BAELINE PERFORMANCE DIFFERENCES
# ==================================================================
# means
meansSham = lapply(scoresPar, function(x)
  mean(subset(tDCSdata[, x], tDCSdata$stimulation == "sham")))
meansActive = lapply(scoresPar, function(x)
  mean(subset(tDCSdata[, x], tDCSdata$stimulation == "active")))
sdSham = lapply(scoresPar, function(x)
  sd(subset(tDCSdata[, x], tDCSdata$stimulation == "sham")))
sdActive = lapply(scoresPar, function(x)
  sd(subset(tDCSdata[, x], tDCSdata$stimulation == "active")))

baselineDiffpval = lapply(scoresPar, function(x)
  t.test(
    tDCSdata[, x] ~ stimulation,
    data = tDCSdata,
    alternative = "two.sided"
  )$p.value)

baselineDiffpvalTxt = lapply(baselineDiffpval, function(x)
  ifelse(x < 0.001, "< 0.001", round(x, 3)))

resultsPar = matrix(
  c(
    paste(
      lapply(meansSham, function(x)
        round(x, 2)),
      "+-",
      lapply(sdSham, function(x)
        round(x, 2))
    ),
    paste(
      lapply(meansActive, function(x)
        round(x, 2)),
      "+-",
      lapply(sdActive, function(x)
        round(x, 2))
    ),
    baselineDiffpvalTxt
  ),
  nrow = length(scoresPar),
  ncol = 3,
  dimnames = list(scoresPar, c(
    paste("Sham (N =", shamN, ")"),
    paste("Active (N =", activeN, ")"),
    "Difference p-val"
  ))
)
# ==================================================================
# BELIEF OF BEING PLACEBO OR REAL
# ==================================================================
beliefsDiff = CrossTable(tDCSdata$stimulation, tDCSdata$belief, prop.chisq = FALSE,
           chisq = TRUE, format="SPSS")
# ==================================================================
# OUTPUT
# ==================================================================
resultsBaseline = rbind(resultsGender, resultsNonp, resultsPar)

print(resultsBaseline)

#write.table(resultsBaseline, file = "table1.txt")
