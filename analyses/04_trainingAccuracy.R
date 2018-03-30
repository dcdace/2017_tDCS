library(tidyr)
library(ez)
library(BayesFactor)
 
# import the data
tDCSdata = read.csv(file = "tDCSraw.csv", header = T)

# calculate mean Accuracy
tDCSdata$meanAcc     = rowMeans(subset(tDCSdata, select 
                                       = c(D1Acc, D2Acc, D3Acc, D4Acc)))
# ==================================================================
# OVERALL ACCURACY
# ==================================================================
meanAccuracy = mean(tDCSdata$meanAcc) * 100
chanceLevel = 1 / 2 # yes/no answer

chanceDiff = t.test (tDCSdata$meanAcc, mu = chanceLevel)
pTXT = ifelse(chanceDiff$p.value < 0.001,
              "p < 0.001",
              paste("p = ", round(chanceDiff$p.value, 3), sep = ""))

overallAccTXT = sprintf(
  "Overall accuracy: M = %.0f%%; difference from chance (%.0f%%): t(%d) = %.2f, %s.",
  round(meanAccuracy, 0),
  round(chanceLevel * 100, 0),
  chanceDiff$parameter,
  round(chanceDiff$statistic, 2),
  pTXT
)
# ==================================================================
# AVERAGE ACCURACY PER GROUP
# ==================================================================
# means
meanSham = round(mean(tDCSdata$meanAcc[tDCSdata$stimulation == 0]) * 100, 0)
meanActive = round(mean(tDCSdata$meanAcc[tDCSdata$stimulation == 1]) * 100, 0)
# 95% CIs
CI95 = function(x)
  round(sd(x) / sqrt(length(x)) * 2.10 * 100, 0)
CISham = CI95(tDCSdata$meanAcc[tDCSdata$stimulation == 0])
CIActive = CI95(tDCSdata$meanAcc[tDCSdata$stimulation == 1])

shamTXT = paste("M sham = ", meanSham, "%, 95% CI [", meanSham - CISham, "%, ", meanSham + CISham, "%]", sep = "")
activeTXT = paste("M active = ", meanActive, "%, 95% CI [", meanActive - CIActive, "%, ", meanActive + CIActive, "%]", sep = "")

# t-test
diff = t.test(
  meanAcc ~ stimulation,
  data = tDCSdata,
  alternative = "two.sided"
)

diffTXT = paste(
  "t(",
  round(diff$parameter,2),
  ") = ",
  round(as.numeric(diff$statistic), 2),
  ", p = ",
  round(diff$p.value, 3),
  sep = "")
meanAccTXT = sprintf("%s \n %s \n %s", shamTXT, activeTXT, diffTXT)
# ==================================================================
# ACCURACY ANOVA (DAY,STIMULATION)
# ==================================================================
# Convert it to long format
data_longAcc = gather(tDCSdata, trDay, Acc, D1Acc:D4Acc)
data_longAcc$trDay = factor(data_longAcc$trDay)
data_longAcc$sID = factor(data_longAcc$sID)
data_longAcc$stimulation = factor(data_longAcc$stimulation)

# get ANOVAs
accANOVA = ezANOVA(
  data = data_longAcc,
  dv = Acc,
  wid = sID,
  within = .(trDay),
  between = stimulation,
  type = 2
)
txtSigDay = ifelse(accANOVA$ANOVA$p[2] < 0.05, "Significant", "No significant")
txtpvalDay = ifelse(accANOVA$ANOVA$p[2] < 0.001,
                    "p < 0.001",
                    paste("p = ", round(accANOVA$ANOVA$p[2], 3), sep = ""))

txtSigGroup = ifelse(accANOVA$ANOVA$p[1] < 0.05, "Significant", "No significant")
txtpvalGroup = ifelse(accANOVA$ANOVA$p[1] < 0.001,
                      "p < 0.001",
                      paste("p = ", round(accANOVA$ANOVA$p[1], 3), sep = ""))
# ==================================================================
# Correlation between meanACC and meanAffected
# ==================================================================
tDCSdata$affectedMean = rowMeans(subset(tDCSdata, select
                                        = c(
                                          affected1, affected2, affected3, affected4
                                        )))
acc_affCor = cor.test(tDCSdata$meanAcc, tDCSdata$affectedMean, method = "kendall")
acc_affCorTXT = sprintf(
  "Kendall's tau-b = %.3f, p = %.3f",
  acc_affCor$estimate,
  acc_affCor$p.value
)
# ==================================================================
# OUTPUT RESULTS
# ==================================================================
resTxt = c(
  "%s \n",
  "Means: %s \n",
  "Accuracy: %s main effect of Day, F(%d,%d) = %.2f, %s, ng = %.2f. \n"
  ,
  "%s main effect of Group, F(%d,%d) = %.2f, %s, ng = %.2f. \n"
  ,
  "Correlation between 'mean accuracy' and 'affected': %s"
)
resultsAcc = sprintf(
  paste(resTxt, collapse = "")
  ,
  overallAccTXT
  ,
  meanAccTXT
  ,
  txtSigDay,
  accANOVA$ANOVA$DFn[2],
  accANOVA$ANOVA$DFd[2],
  round(accANOVA$ANOVA$F[2], 2),
  txtpvalDay,
  round(accANOVA$ANOVA$ges[2], 2)
  ,
  txtSigGroup,
  accANOVA$ANOVA$DFn[1],
  accANOVA$ANOVA$DFd[1],
  round(accANOVA$ANOVA$F[1], 2),
  txtpvalGroup,
  round(accANOVA$ANOVA$ges[1], 2)
  ,
  acc_affCorTXT
)

print(resultsAcc)
#write.table(resultsAcc, file = "resultsTrainingAccuracy.txt")
