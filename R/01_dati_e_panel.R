library(readxl)
library(dplyr)
library(tidyr)
library(plm)

file_excel <- "data/master_dataset_europa.xlsx"

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

leggi_comune <- function(nome_foglio, nome_variabile) {
  read_excel(file_excel, sheet = nome_foglio) %>%
    transmute(
      time = as.Date(.[[1]]),
      !!nome_variabile := as.numeric(.[[2]])
    ) %>%
    filter(!is.na(time)) %>%
    distinct(time, .keep_all = TRUE)
}

ip       <- leggi_serie("IP",         "ip")
reer     <- leggi_serie("REER",       "reer")
spread   <- leggi_serie("Spread_10Y", "spread")
vix      <- leggi_serie("VIX",        "vix")
bid_ask  <- leggi_serie("BID_ASK",    "bid_ask")
bid_ask$bid_ask <- bid_ask$bid_ask * 100
edp      <- leggi_serie("EDP",        "EDP")
debt_gdp <- leggi_serie("Debt_GDP",   "debt_gdp")
ob       <- leggi_serie("OB",         "OB")
cab      <- leggi_serie("CAB",        "CAB")
pepp     <- leggi_serie("PEPP",       "PEPP")

df_liv        <- leggi_comune("DF_liv",        "DF_liv")
ltro          <- leggi_comune("D_LTRO",        "D_LTRO")
cbpp1         <- leggi_comune("CBPP1",         "CBPP1")
cbpp2         <- leggi_comune("CBPP2",         "CBPP2")
app_aggregato <- leggi_comune("APP_aggregato", "APP_aggregato")
app_aggregato <- app_aggregato %>% arrange(time) %>% mutate(APP_aggregato = cumsum(replace_na(APP_aggregato, 0)))

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

panel_data$Log_IP          <- log(panel_data$ip)
panel_data$Log_IP_Germania <- log(panel_data$IP_Germania)
panel_data$IP_PAESE_GER    <- (panel_data$Log_IP - panel_data$Log_IP_Germania) * 100

DEBT_Germania <- debt_gdp %>% filter(country == "Germania") %>% select(time, DEBT_GER = debt_gdp)
OB_Germania   <- ob       %>% filter(country == "Germania") %>% select(time, OB_GER = OB)
CAB_Germania  <- cab      %>% filter(country == "Germania") %>% select(time, CAB_GER = CAB)

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
  mutate(
    DEBT_DIFF = debt_gdp - DEBT_GER,
    OB_DIFF   = OB       - OB_GER,
    CAB_DIFF  = CAB      - CAB_GER
  ) %>%
  mutate(across(
    c(D_LTRO, CBPP1, CBPP2, PEPP, APP_aggregato,
      EDP, debt_gdp, DEBT_GER, DEBT_DIFF,
      OB, OB_GER, OB_DIFF,
      CAB, CAB_GER, CAB_DIFF),
    ~ replace_na(.x, 0)
  )) %>%
  filter(time >= as.Date("2000-01-01"),
         time <= as.Date("2025-04-01")) %>%
  mutate(
    QE1 = CBPP1 + CBPP2 + D_LTRO,
    D_CBPP2 = as.integer(time >= as.Date("2011-11-01") &
                           time <= as.Date("2012-10-01"))
  ) %>%
  filter(!is.na(spread))
