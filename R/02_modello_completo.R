# ============================================================
# 02 — MODELLO PRINCIPALE: panel a effetti fissi 2000-2025
# Tesi: Gli spread sovrani nell'UEM (2000-2025) — Raffaele De Simone
# Richiede 01_dati_e_panel.R. Stima mod_full (Tavola 1).
# ============================================================

library(plm)

# =======================================================
# CAMPIONE COMPLETO 2000-2025
# =======================================================

# Formato panel: unità = Paese, tempo = mese
panel_full <- pdata.frame(panel_stima, index = c("country", "time"))

# Stima a effetti fissi di Paese (within)
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