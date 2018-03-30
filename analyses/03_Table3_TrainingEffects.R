library(BayesFactor)
library(xtable) # for html formatted table

# import the data
tDCSdata = read.csv(file = "tDCSraw.csv", header = T)

# make stimulation a factor
tDCSdata$stimulation = factor(tDCSdata$stimulation,
                              levels = c(0, 1),
                              labels = c("sham", "active"))

# group sample sizes
shamN       = table(tDCSdata$stimulation)["sham"]
activeN     = table(tDCSdata$stimulation)["active"]

# Bayes Factor support for the effect (H1), based on Jeffreys
support = c("anecdotal", "substantial", "strong", "very strong", "decisive")
cuts    = c(1, 3, 10, 30, 100, Inf)
supportTXT = function(bf10, bf01)
  mapply(function(x, y)
  {
    ifelse(
      x > 1
      ,
      paste(as.character(cut(
        x, breaks = cuts, labels = support
      )), "evidence for the effect")
      ,
      paste(as.character(cut(
        y, breaks = cuts, labels = support
      )), "evidence against the effect")
    )
  }
  , bf10, bf01)
# ==================================================================
# CALCULATE NECCESSARY VARIABLES
# ==================================================================
# mean Accuracy
tDCSdata$meanAcc     = rowMeans(subset(tDCSdata, select 
                                       = c(D1Acc, D2Acc, D3Acc, D4Acc)))
# UN TR difference
tDCSdata$ITPreDiff    = tDCSdata$ITPreUN / tDCSdata$ITPreTR - 1
tDCSdata$ITPostDiff   = tDCSdata$ITPostUN / tDCSdata$ITPostTR - 1
tDCSdata$ITRetDiff    = tDCSdata$ITRetUN / tDCSdata$ITRetTR - 1

tDCSdata$ETPreDiff    = tDCSdata$ETPreUN / tDCSdata$ETPreTR - 1
tDCSdata$ETPostDiff   = tDCSdata$ETPostUN / tDCSdata$ETPostTR - 1
tDCSdata$ETRetDiff    = tDCSdata$ETRetUN / tDCSdata$ETRetTR - 1

tDCSdata$ErrPreDiff   = tDCSdata$ErrPreUN - tDCSdata$ErrPreTR
tDCSdata$ErrPostDiff  = tDCSdata$ErrPostUN - tDCSdata$ErrPostTR
tDCSdata$ErrRetDiff   = tDCSdata$ErrRetUN - tDCSdata$ErrRetTR

# which scores (columns) to process
scoresPre   = c("ITPreDiff", "ITPreDiff", "ETPreDiff", "ETPreDiff", "ErrPreDiff", "ErrPreDiff")
scoresPost  = c("ITPostDiff", "ITRetDiff", "ETPostDiff", "ETRetDiff", "ErrPostDiff", "ErrRetDiff")

scN = length(scoresPost) # how many scores
# ==================================================================
# TRAINING EFFECT
# ==================================================================
# Linear regression of PostDiff(y) ~ PreDiff(x)
trEffect = mapply(function(post, pre, stim)
{
  f = paste(post, "~", pre)
  summary(lm(as.formula(f), data = subset(tDCSdata, stimulation ==
                                            stim)))
},
scoresPost, scoresPre, c(rep("sham", scN), rep("active", scN)))

trEffect_tvals = sapply(1:dim(trEffect)[2], function(x)
  round(coef(trEffect[, x])["(Intercept)", "t value"], 2))
trEffect_pvals = sapply(1:dim(trEffect)[2], function(x)
  round(coef(trEffect[, x])["(Intercept)", "Pr(>|t|)"], 3))/2
trEffect_pvalsTXT = lapply(trEffect_pvals, function(x)
  ifelse(x < 0.001, "< 0.001", paste("=", round(x, 3))))
trEffect_dz = round(c(trEffect_tvals[1:scN] / sqrt(shamN),
                      trEffect_tvals[(scN + 1):(scN * 2)] / sqrt(activeN)
), 2)

trEffect_Est = sapply(1:dim(trEffect)[2], function(x)
  round(coef(trEffect[, x])["(Intercept)", "Estimate"], 2) * 100)

# format results as txt strings
resTrainingTXT = mapply(
  function(df, t, p, B0, d)
    sprintf("t(%d) = %.2f, p %s, B0 = %.0f%%, dz = %.2f.",
            df, t, p, B0, d),
  c(rep(shamN - 2, scN), rep(activeN - 2, scN)),
  # df = N - 1 - 1regressor(PreDiff)
  trEffect_tvals,
  trEffect_pvalsTXT,
  trEffect_Est,
  trEffect_dz
)
# put sham and active results in separate columns
resTrainingTXT2 = matrix(
  resTrainingTXT,
  nrow = scN,
  ncol = 2,
  dimnames = list(scoresPost, c("sham", "active"))
)
# ==================================================================
# STIMULATION EFFECT
# ==================================================================
# Comparing Sham and Active Post~Pre Intercepts
# See: http://rcompanion.org/rcompanion/e_04.html

# t and p
lmPost =  mapply(function(post, pre)
{
  f = paste(post, "~", pre, "+ stimulation")
  summary(lm(as.formula(f), data = tDCSdata))
},
scoresPost, scoresPre)

df = lmPost[, 1]$df[2]

tvals = sapply(1:dim(lmPost)[2], function(x)
  coef(lmPost[, x])["stimulationactive", "t value"])
pvals = sapply(1:dim(lmPost)[2], function(x)
  coef(lmPost[, x])["stimulationactive", "Pr(>|t|)"])/2
pvalsTXT = lapply(pvals, function(x)
  ifelse(x < 0.001, "< 0.001", paste("=", round(x, 3))))

ds = 2 * tvals/sqrt(df)

# Bayes Factors
# compares model with group factor with a model without a group factor
# see http://bayesfactorpcl.r-forge.r-project.org/#glm
generalBF = as.data.frame(mapply(function(post, pre)
{
  f = paste(post, "~", pre, "+ stimulation")
  generalTestBF(as.formula(f),
                data = tDCSdata,
                progress = FALSE)
},
scoresPost, scoresPre))
BF10vals = generalBF["ITPreDiff + stimulation", c(TRUE, rep(FALSE, 3))] /
  generalBF["ITPreDiff", c(TRUE, rep(FALSE, 3))]
BF01vals = 1 / BF10vals

# format results as txt strings
resTXT = mapply(function(df, t, p, d, supptxt, bf10, bf01)
  sprintf(
    "t(%d) = %.2f, p %s, d = %.2f, %s (BF10/BF01 = %.2f/%.2f).",
    df,t,p,d,supptxt,bf10,bf01),
  df,
  as.numeric(tvals,2),
  pvalsTXT,
  ds,
  supportTXT(BF10vals, BF01vals),
  as.numeric(BF10vals),
  as.numeric(BF01vals)
)
# put in matrix
resTXT2 = matrix(
  resTXT,
  nrow = scN,
  ncol = 1,
  dimnames = list(scoresPost, "stimulation effect (group difference)"))
# ==================================================================
# STIMULATION EFFECT, ACCOUNTING FOR MEAN_ACCURACY
# ==================================================================
# Comparing Sham and Active Post~Pre Intercepts
# See: http://rcompanion.org/rcompanion/e_04.html

# t and p
lmPost =  mapply(function(post, pre)
{
  f = paste(post, "~", pre, " + meanAcc + stimulation")
  summary(lm(as.formula(f), data = tDCSdata))
},
scoresPost, scoresPre)

df = lmPost[, 1]$df[2]

tvals = sapply(1:dim(lmPost)[2], function(x)
  coef(lmPost[, x])["stimulationactive", "t value"])
pvals = sapply(1:dim(lmPost)[2], function(x)
  coef(lmPost[, x])["stimulationactive", "Pr(>|t|)"])/2
pvalsTXT = lapply(pvals, function(x)
  ifelse(x < 0.001, "< 0.001", paste("=", round(x, 3))))

stimAccEffect_Est = sapply(1:dim(lmPost)[2], function(x)
  round(coef(lmPost[, x])["stimulationactive", "Estimate"], 2) * 100)
ds = 2 * tvals/sqrt(df)

# Bayes Factors
# compares model with group factor with a model without a group factor
# see http://bayesfactorpcl.r-forge.r-project.org/#glm
generalBF = as.data.frame(mapply(function(post, pre)
{
  f = paste(post, "~", pre, "+ meanAcc + stimulation")
  generalTestBF(as.formula(f),
                data = tDCSdata,
                progress = FALSE)
},
scoresPost, scoresPre))
BF10vals = generalBF["ITPreDiff + meanAcc + stimulation", c(TRUE, rep(FALSE, 3))] /
  generalBF["ITPreDiff + meanAcc", c(TRUE, rep(FALSE, 3))]
BF01vals = 1 / BF10vals

# format results as txt strings
resTXT = mapply(function(df, t, p, d, supptxt, bf10, bf01)
  sprintf(
    "t(%d) = %.2f, p %s, d = %.2f, %s (BF10/BF01 = %.2f/%.2f).",
    df,t,p,d,supptxt,bf10,bf01),
  df,
  as.numeric(tvals,2),
  pvalsTXT,
  ds,
  supportTXT(BF10vals, BF01vals),
  as.numeric(BF10vals),
  as.numeric(BF01vals)
)
# put in matrix
resTXT3 = matrix(
  resTXT,
  nrow = scN,
  ncol = 1,
  dimnames = list(scoresPost, "stimulation effect (group difference)")
)
# ==================================================================
# meanAcc effect on ITPostDiff
# ==================================================================
lmStand = summary(lm(
  scale(ITPostDiff) ~ scale(ITPreDiff) + scale(meanAcc) + stimulation,
  data = tDCSdata
))
standBetaMeanAccTxt = sprintf(
  "For ITPostDiff meanAcc standartised beta = %.3f, p = %.3f",
  lmStand$coefficients["scale(meanAcc)", "Estimate"],
  lmStand$coefficients["scale(meanAcc)", "Pr(>|t|)"]
)
# ==================================================================
# OUTPUT RESULTS
# ==================================================================
# put training results and stimulation results in the same matrix
results = cbind(resTrainingTXT2, resTXT2, resTXT3)
print(results)
print(standBetaMeanAccTxt)

#write.table(results, file = "table3.txt")

formattedresults = print(xtable(results), type="html")
#write.table(formattedresults, file = "table3.html")

# ==================================================================
# FOR EXCEL PLOTS
# ==================================================================
# Get ITPostDIff predicted values after adjustements
model = lm(ITPostDiff ~ ITPreDiff + meanAcc + stimulation, data = tDCSdata)
tDCSdata$ITPostDiffPred = predict.lm(model)




