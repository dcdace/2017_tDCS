library(plyr) # for function 'count'
library(xtable)

# import the data
tDCSdata = read.csv(file = "tDCSraw.csv", header = T)

# ==================================================================
# how many felt any sensations on any of the four days
# ==================================================================
anySensations = count(rowSums(subset(tDCSdata, select 
                                     = c(max1, max2, max3, max4))) > 0)
anySensations = subset(anySensations, anySensations$x == TRUE)$freq
anySensTXT = sprintf(
  "%d (%d%%) participants felt some sensations on at least one of the sessions.",
  anySensations,
  round(anySensations / dim(tDCSdata)[1] * 100,0)
)
# ==================================================================
# how many were affected on any of the four days
# ==================================================================
anyAffectedSh = count(rowSums(subset(
  tDCSdata,
  stimulation == 0,
  select = c(affected1, affected2, affected3, affected4)
)) > 0)

shN = sum(anyAffectedSh$freq)
anyAffectedSh = subset(anyAffectedSh, anyAffectedSh$x == TRUE)$freq

anyAffectedAc = count(rowSums(subset(
  tDCSdata,
  stimulation == 1,
  select = c(affected1, affected2, affected3, affected4)
)) > 0)

acN = sum(anyAffectedAc$freq)
anyAffectedAc = subset(anyAffectedAc, anyAffectedAc$x == TRUE)$freq

anyAffectedTXT = sprintf(
  "%d (%d%%) sham and %d (%d%%) active group participants were affected on at least one of the sessions.",
  anyAffectedSh,
  round(anyAffectedSh / shN * 100,0),
  anyAffectedAc,
  round(anyAffectedAc / acN * 100,0)
)
# ==================================================================
# Reported frequencies
# ==================================================================
# get variable names that will be processed
var_names = c(
  lapply(1:4, function(x)
    paste("max", x, sep = "")),
  lapply(1:4, function(x)
    paste("affected", x, sep = "")),
  lapply(1:4, function(x)
    paste("stop", x, sep = ""))
)
#-- Get frequency tables
resSham = lapply(as.character(var_names), function(x)
  table(subset(tDCSdata, tDCSdata$stimulation == 0)[, x])
  )
resActive = lapply(as.character(var_names), function(x)
  table(subset(tDCSdata, tDCSdata$stimulation == 1)[, x])
)
#-- Convert tables to strings
resValSham = lapply(1:12, function(x)
  toString(as.data.frame(resSham[x])[, "Var1"])
  )
resFreqSham = lapply(1:12, function(x)
  toString(as.data.frame(resSham[x])[, "Freq"])
)
resValActive = lapply(1:12, function(x)
  toString(as.data.frame(resActive[x])[, "Var1"])
)
resFreqActive = lapply(1:12, function(x)
  toString(as.data.frame(resActive[x])[, "Freq"])
)
#-- Put results into matrix
results = matrix(
  rbind(resValSham, resFreqSham, resValActive, resFreqActive),
  nrow = 4, ncol=12,
  dimnames = list(c("sh:Val", "sh:Freq", "ac:Val", "acFreq"),
                  var_names)
)
# ==================================================================
# output
# ==================================================================
print(anySensTXT)
print(anyAffectedTXT)
print(results)

write.table(results, file = "#table1.txt")

formattedresults = print(xtable(results), type="html")
write.table(formattedresults, file = "#table1.html")
