library(plm)

panel_F1 <- panel_stima %>%
  filter(time >= as.Date("2000-01-01"),
         time <= as.Date("2007-12-01")) %>%
  pdata.frame(index = c("country", "time"))

mod_F1 <- plm(
  spread ~ IP_PAESE_GER + reer + vix + bid_ask +
    DF_liv + EDP + DEBT_DIFF + OB_DIFF + CAB_DIFF,
  data  = panel_F1,
  model = "within"
)
cat("\n========== F1 — PRE-CRISI 2000-2007 ==========\n")
cat("N =", nrow(model.frame(mod_F1)), "| R2 =", round(summary(mod_F1)$r.squared["rsq"], 4), "\n")
print(summary(mod_F1))

panel_F2 <- panel_stima %>%
  filter(time >= as.Date("2008-01-01"),
         time <= as.Date("2019-12-01")) %>%
  pdata.frame(index = c("country", "time"))

mod_F2 <- plm(
  spread ~ IP_PAESE_GER + reer + vix + bid_ask +
    DF_liv + QE1 + CBPP1 + D_CBPP2 + APP_aggregato +
    EDP + DEBT_DIFF + OB_DIFF + CAB_DIFF,
  data  = panel_F2,
  model = "within"
)
cat("\n========== F2 — CRISI + QE 2008-2019 ==========\n")
cat("N =", nrow(model.frame(mod_F2)), "| R2 =", round(summary(mod_F2)$r.squared["rsq"], 4), "\n")
print(summary(mod_F2))

panel_F3 <- panel_stima %>%
  filter(time >= as.Date("2020-01-01"),
         time <= as.Date("2025-04-01")) %>%
  pdata.frame(index = c("country", "time"))

mod_F3 <- plm(
  spread ~ IP_PAESE_GER + reer + vix + bid_ask +
    DF_liv + APP_aggregato + PEPP +
    EDP + DEBT_DIFF + OB_DIFF + CAB_DIFF,
  data  = panel_F3,
  model = "within"
)
cat("\n========== F3 — PANDEMIA + RIALZI 2020-2025 (CON COVID) ==========\n")
cat("N =", nrow(model.frame(mod_F3)), "| R2 =", round(summary(mod_F3)$r.squared["rsq"], 4), "\n")
print(summary(mod_F3))

cat("\n========== CONFRONTO R² (CON COVID) ==========\n")
data.frame(
  Finestra = c("Completo 2000-2025 (con COVID)", "F1 2000-2007", "F2 2008-2019", "F3 2020-2025 (con COVID)"),
  N  = c(nrow(model.frame(mod_full)), nrow(model.frame(mod_F1)),
         nrow(model.frame(mod_F2)),   nrow(model.frame(mod_F3))),
  R2 = round(c(
    summary(mod_full)$r.squared["rsq"],
    summary(mod_F1)$r.squared["rsq"],
    summary(mod_F2)$r.squared["rsq"],
    summary(mod_F3)$r.squared["rsq"]
  ), 4)
) |> print()
