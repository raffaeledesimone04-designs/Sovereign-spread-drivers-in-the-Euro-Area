library(dplyr)

coef_app  <- coef(mod_full)["APP_aggregato"]
coef_pepp <- coef(mod_full)["PEPP"]

cat("Coefficiente APP_aggregato:", round(coef_app, 5), "\n")
cat("Coefficiente PEPP         :", round(coef_pepp, 5), "\n")

df_cf <- panel_stima %>%
  mutate(
    effetto_app    = coef_app  * APP_aggregato,
    effetto_pepp   = coef_pepp * PEPP,
    spread_no_app  = spread - effetto_app,
    spread_no_pepp = spread - effetto_pepp
  )

paesi_periferici <- c("Italia", "Spagna", "Portogallo", "Grecia")
df_perif <- df_cf %>% filter(country %in% paesi_periferici)

tab_riepilogo <- df_perif %>%
  group_by(country) %>%
  summarise(
    spread_medio_osservato = round(mean(spread, na.rm = TRUE), 1),
    effetto_APP_medio      = round(mean(effetto_app, na.rm = TRUE), 1),
    effetto_APP_ultimo     = round(last(effetto_app), 1),
    effetto_PEPP_medio     = round(mean(effetto_pepp, na.rm = TRUE), 1),
    effetto_PEPP_ultimo    = round(last(effetto_pepp), 1),
    .groups = "drop"
  )
cat("\n===== TABELLA RIEPILOGO PER PAESE =====\n")
print(tab_riepilogo)

tab_serie_completa <- df_perif %>%
  select(country, time, spread, effetto_app, spread_no_app,
         effetto_pepp, spread_no_pepp) %>%
  arrange(country, time)

cat("\n===== SERIE COMPLETA (prime 12 righe) =====\n")
print(head(tab_serie_completa, 12))
cat("\nOggetto disponibile in memoria: tab_serie_completa (", nrow(tab_serie_completa), "righe)\n")

tavola3 <- df_perif %>%
  filter(time %in% as.Date(c("2020-06-01", "2021-12-01", "2022-06-01"))) %>%
  transmute(country, time,
            spread_osservato      = round(spread, 1),
            compressione_APP      = round(-effetto_app, 1),
            compressione_PEPP     = round(-effetto_pepp, 1),
            spread_controfattuale = round(spread - effetto_app - effetto_pepp, 1)) %>%
  arrange(country, time)

cat("\n===== TAVOLA 3 — SPREAD OSSERVATO E CONTROFATTUALE =====\n")
print(as.data.frame(tavola3))
