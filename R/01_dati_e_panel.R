# ============================================================
# 01 — DATI: lettura del dataset e costruzione del panel
# Tesi: Gli spread sovrani nell'UEM (2000-2025) — Raffaele De Simone
# Produce panel_stima (9 Paesi, gen 2000 - apr 2025). Eseguire per primo.
# ============================================================

library(readxl)
library(dplyr)
library(tidyr)
library(plm)

# File Excel con tutti i dati
file_excel <- "data/master_dataset_europa.xlsx"

# Paesi (la Germania serve solo per i differenziali)
paesi <- c(
  "Italia",
  "Spagna",
  "Francia",
  "Portogallo",
  "Grecia",
  "Belgio",
  "Austria",
  "Paesi Bassi",
  "Finlandia",
  "Germania"
)

# Legge i fogli con una colonna per Paese (formato lungo: Paese, mese, valore)
leggi_serie <- function(nome_foglio, nome_variabile) {
  read_excel(file_excel, sheet = nome_foglio) %>%
    select(Data, any_of(paesi)) %>%
    pivot_longer(
      cols = -Data,
      names_to = "country",
      values_to = nome_variabile
    ) %>%
    transmute(
      country = country,
      time = as.Date(Data),
      !!nome_variabile := .data[[nome_variabile]]
    )
}

# Legge i fogli con una sola serie comune a tutti i Paesi
leggi_comune <- function(nome_foglio, nome_variabile) {
  read_excel(file_excel, sheet = nome_foglio) %>%
    transmute(
      time = as.Date(.[[1]]),
      !!nome_variabile := as.numeric(.[[2]])
    ) %>%
    filter(!is.na(time)) %>%
    distinct(time, .keep_all = TRUE)
}

# -----------------------------------------------
# Lettura dei dati
# -----------------------------------------------
# Variabili specifiche per Paese
ip       <- leggi_serie("IP",         "ip")          # produzione industriale (indice)
reer     <- leggi_serie("REER",       "reer")        # tasso di cambio effettivo reale
spread   <- leggi_serie("Spread_10Y", "spread")      # spread decennale vs Bund (pb)
vix      <- leggi_serie("VIX",        "vix")         # indice di volatilità (uguale per tutti)
bid_ask  <- leggi_serie("BID_ASK",    "bid_ask")     # differenziale denaro-lettera
bid_ask$bid_ask <- bid_ask$bid_ask * 100             # da punti percentuali a punti base
edp      <- leggi_serie("EDP",        "EDP")         # procedura per disavanzo eccessivo (+1/-1/0)
debt_gdp <- leggi_serie("Debt_GDP",   "debt_gdp")    # debito pubblico / PIL
ob       <- leggi_serie("OB",         "OB")          # saldo di bilancio / PIL
cab      <- leggi_serie("CAB",        "CAB")         # saldo delle partite correnti / PIL
pepp     <- leggi_serie("PEPP",       "PEPP")        # acquisti netti mensili PEPP per Paese

# Variabili comuni a tutti i Paesi (politica monetaria BCE)
df_liv        <- leggi_comune("DF_liv",        "DF_liv")          # tasso sui depositi, livello di fine mese
ltro          <- leggi_comune("D_LTRO",        "D_LTRO")          # stock LTRO (mld €)
cbpp1         <- leggi_comune("CBPP1",         "CBPP1")           # stock CBPP1 (mld €)
cbpp2         <- leggi_comune("CBPP2",         "CBPP2")           # stock CBPP2 (mld €)
app_aggregato <- leggi_comune("APP_aggregato", "APP_aggregato")   # acquisti netti mensili APP
# APP: dagli acquisti mensili allo stock cumulato detenuto dalla BCE
app_aggregato <- app_aggregato %>% arrange(time) %>% mutate(APP_aggregato = cumsum(replace_na(APP_aggregato, 0)))

# -----------------------------------------------
# Unione delle serie in un unico panel
# -----------------------------------------------
panel_data <- ip %>%
  full_join(reer,    by = c("country", "time")) %>%
  full_join(spread,  by = c("country", "time")) %>%
  full_join(vix,     by = c("country", "time")) %>%
  full_join(bid_ask, by = c("country", "time")) %>%
  arrange(time, country)

IP_Germania <- panel_data %>%
  filter(country == "Germania") %>%
  select(time, IP_Germania = ip)

panel_data <- panel_data %>%
  left_join(IP_Germania, by = "time") %>%
  arrange(country, time)

# Produzione industriale relativa alla Germania (differenza dei log x 100)
panel_data$Log_IP          <- log(panel_data$ip)
panel_data$Log_IP_Germania <- log(panel_data$IP_Germania)
panel_data$IP_PAESE_GER    <- (panel_data$Log_IP - panel_data$Log_IP_Germania) * 100

# REER e VIX entrano in livello, come in Afonso et al. (2020)

# Valori tedeschi per i differenziali fiscali
DEBT_Germania <- debt_gdp %>% filter(country == "Germania") %>% select(time, DEBT_GER = debt_gdp)
OB_Germania   <- ob       %>% filter(country == "Germania") %>% select(time, OB_GER = OB)
CAB_Germania  <- cab      %>% filter(country == "Germania") %>% select(time, CAB_GER = CAB)

# Panel di stima (senza Germania)
panel_stima <- panel_data %>%
  filter(country != "Germania") %>%
  select(country, time, spread, IP_PAESE_GER, reer, vix, bid_ask) %>%
  arrange(country, time) %>%
  left_join(df_liv,        by = "time") %>%
  left_join(ltro,          by = "time") %>%
  left_join(cbpp1,         by = "time") %>%
  left_join(cbpp2,         by = "time") %>%
  left_join(app_aggregato, by = "time") %>%
  left_join(pepp,          by = c("country", "time")) %>%
  left_join(edp,           by = c("country", "time")) %>%
  left_join(debt_gdp,      by = c("country", "time")) %>%
  left_join(DEBT_Germania, by = "time") %>%
  left_join(ob,            by = c("country", "time")) %>%
  left_join(OB_Germania,   by = "time") %>%
  left_join(cab,           by = c("country", "time")) %>%
  left_join(CAB_Germania,  by = "time") %>%
  # Differenziali fiscali rispetto alla Germania (punti di PIL)
  mutate(
    DEBT_DIFF = debt_gdp - DEBT_GER,
    OB_DIFF   = OB       - OB_GER,
    CAB_DIFF  = CAB      - CAB_GER
  ) %>%
  # Programma non attivo o dato mancante = 0
  mutate(across(
    c(D_LTRO, CBPP1, CBPP2, PEPP, APP_aggregato,
      EDP, debt_gdp, DEBT_GER, DEBT_DIFF,
      OB, OB_GER, OB_DIFF,
      CAB, CAB_GER, CAB_DIFF),
    ~ replace_na(.x, 0)
  )) %>%
  # Periodo di analisi: gennaio 2000 - aprile 2025
  filter(time >= as.Date("2000-01-01"),
         time <= as.Date("2025-04-01")) %>%
  mutate(
    # QE1: programmi di prima generazione (stock in mld €)
    QE1 = CBPP1 + CBPP2 + D_LTRO,
    # Dummy = 1 nei mesi di attività del CBPP2
    D_CBPP2 = as.integer(time >= as.Date("2011-11-01") &
                           time <= as.Date("2012-10-01"))
  ) %>%
  # Si tolgono i mesi senza spread (Austria a inizio 2000)
  filter(!is.na(spread))
