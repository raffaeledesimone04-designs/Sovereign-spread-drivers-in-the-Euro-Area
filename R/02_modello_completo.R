library(plm)

panel_full <- pdata.frame(panel_stima, index = c("country", "time"))

mod_full <- plm(
  spread ~ IP_PAESE_GER + reer + vix + bid_ask +
    DF_liv + QE1 + APP_aggregato + PEPP +
    EDP + DEBT_DIFF + OB_DIFF + CAB_DIFF,
  data  = panel_full,
  model = "within"
)

cat("\n========== CAMPIONE COMPLETO 2000-2025 (CON COVID) ==========\n")
cat("N =", nrow(model.frame(mod_full)), "| R2 =", round(summary(mod_full)$r.squared["rsq"], 4), "\n")
print(summary(mod_full))
