library(plm)

panel_stima_no2020 <- panel_stima %>%
  filter(format(time, "%Y") != "2020")

mod_full_no2020 <- plm(
  spread ~ IP_PAESE_GER + reer + vix + bid_ask +
    DF_liv + QE1 + APP_aggregato + PEPP +
    EDP + DEBT_DIFF + OB_DIFF + CAB_DIFF,
  data  = pdata.frame(panel_stima_no2020, index = c("country", "time")),
  model = "within"
)
cat("\n========== CAMPIONE COMPLETO 2000-2025 (escluso 2020) ==========\n")
cat("N =", nrow(model.frame(mod_full_no2020)), "| R2 =", round(summary(mod_full_no2020)$r.squared["rsq"], 4), "\n")
print(summary(mod_full_no2020))

mod_F3_no2020 <- plm(
  spread ~ IP_PAESE_GER + reer + vix + bid_ask +
    DF_liv + APP_aggregato + PEPP +
    EDP + DEBT_DIFF + OB_DIFF + CAB_DIFF,
  data  = panel_stima_no2020 %>%
    filter(time >= as.Date("2021-01-01"),
           time <= as.Date("2025-04-01")) %>%
    pdata.frame(index = c("country", "time")),
  model = "within"
)
cat("\n========== F3 — POST-COVID + RIALZI 2021-2025 (escluso 2020) ==========\n")
cat("N =", nrow(model.frame(mod_F3_no2020)), "| R2 =", round(summary(mod_F3_no2020)$r.squared["rsq"], 4), "\n")
print(summary(mod_F3_no2020))

cat("\n========== CONFRONTO R² (CON E SENZA COVID) ==========\n")
data.frame(
  Modello  = c("Completo 2000-2025", "F3 2020-2025 / 2021-2025"),
  R2_con   = round(c(summary(mod_full)$r.squared["rsq"],        summary(mod_F3)$r.squared["rsq"]), 4),
  R2_senza = round(c(summary(mod_full_no2020)$r.squared["rsq"], summary(mod_F3_no2020)$r.squared["rsq"]), 4),
  N_con    = c(nrow(model.frame(mod_full)),        nrow(model.frame(mod_F3))),
  N_senza  = c(nrow(model.frame(mod_full_no2020)), nrow(model.frame(mod_F3_no2020)))
) |> print()
