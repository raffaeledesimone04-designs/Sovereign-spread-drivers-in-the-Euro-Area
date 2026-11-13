# ============================================================
# 06 — GRAFICI della tesi
# Tesi: Gli spread sovrani nell'UEM (2000-2025) — Raffaele De Simone
# Legge i dati dei grafici della tesi da data/ e salva in figure/ (SVG e PNG):
#   data/Grafici spread sovrani.xlsx           (spread mensili vs Bund)
#   data/Italia_Controfattuale3.xlsx           (controfattuale APP e PEPP, foglio "Scomposizione paesi")
# ============================================================

library(readxl)
library(dplyr)
library(tidyr)
library(ggplot2)

dir.create("figure", showWarnings = FALSE)

file_spread <- "data/Grafici spread sovrani.xlsx"
file_cf     <- "data/Italia_Controfattuale3.xlsx"

# -----------------------------------------------
# Stile comune
# -----------------------------------------------
colori <- c(
  "Italia" = "#2a78d6", "Spagna" = "#eb6834", "Portogallo" = "#1baf7a",
  "Grecia" = "#eda100", "Francia" = "#6250d6", "Belgio" = "#e87ba4",
  "Austria" = "#008300", "Paesi Bassi" = "#e34948", "Finlandia" = "#52514e"
)
# Strumenti di politica monetaria della BCE (date di avvio/annuncio come nella tesi)
eventi <- data.frame(
  data  = as.Date(c("2009-07-01", "2010-05-01", "2011-12-01", "2012-09-01",
                    "2015-03-01", "2020-03-01", "2022-07-01")),
  label = c("CBPP1", "SMP", "CBPP2 / LTRO", "OMT", "APP", "PEPP", "TPI"),
  riga  = c(1, 2, 3, 4, 1, 1, 1)   # etichette sfalsate dove le date sono vicine
)
crisi  <- data.frame(inizio = as.Date(c("2010-05-01", "2020-03-01")),
                     fine   = as.Date(c("2012-09-01", "2021-06-01")))
fonte  <- "Fonte: elaborazione dell'autore su dati Investing.com, BCE e stime del modello panel a effetti fissi (bAPP = -0,0176; bPEPP = -5,41)."

tema <- theme_minimal(base_size = 12, base_family = "sans") +
  theme(
    plot.title.position = "plot",
    plot.title       = element_text(face = "bold", size = 15),
    plot.subtitle    = element_text(colour = "grey35", margin = margin(b = 8)),
    plot.caption     = element_text(colour = "grey45", hjust = 0, size = 8.5),
    plot.caption.position = "plot",
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.grid.major.y = element_line(colour = "grey90"),
    axis.title.y     = element_text(colour = "grey35", size = 10),
    legend.position  = "top",
    legend.justification = "left",
    legend.title     = element_blank(),
    strip.text       = element_text(face = "bold", hjust = 0, size = 11),
    plot.background  = element_rect(fill = "white", colour = NA),
    plot.margin      = margin(12, 16, 10, 12)
  )

eventi_layer <- function(con_etichette = TRUE, dal = as.Date("2000-01-01")) {
  crisi  <- filter(crisi, inizio >= dal)
  eventi <- filter(eventi, data >= dal)
  l <- list(
    geom_rect(data = crisi, inherit.aes = FALSE,
              aes(xmin = inizio, xmax = fine, ymin = -Inf, ymax = Inf), fill = "grey94"),
    geom_vline(data = eventi, aes(xintercept = data),
               linetype = "dashed", colour = "grey60", linewidth = 0.35)
  )
  if (con_etichette) l <- c(l, list(
    geom_label(data = eventi, inherit.aes = FALSE,
               aes(x = data, y = Inf, label = label, vjust = 1.3 + 1.45 * (riga - 1)),
               hjust = 0, size = 2.9, colour = "grey30", fill = "white",
               label.size = 0, label.padding = unit(0.12, "lines"), label.r = unit(0, "lines"))
  ))
  l
}

leggi_spread <- function(foglio) {
  suppressMessages(read_excel(file_spread, sheet = foglio, skip = 2)) %>%
    rename(time = 1) %>%
    mutate(time = as.Date(time)) %>%
    filter(!is.na(time)) %>%
    select(time, any_of(names(colori))) %>%
    pivot_longer(-time, names_to = "country", values_to = "spread") %>%
    filter(!is.na(spread))
}

grafico_spread <- function(dati, titolo, sottotitolo) {
  ggplot(dati, aes(time, spread, colour = country)) +
    eventi_layer() +
    geom_line(linewidth = 0.7) +
    scale_colour_manual(values = colori) +
    scale_y_continuous(expand = expansion(mult = c(0.02, 0.22))) +
    scale_x_date(breaks = seq(as.Date("2000-01-01"), as.Date("2024-01-01"), by = "4 years"),
                 date_labels = "%Y", expand = c(0.01, 0)) +
    labs(title = titolo, subtitle = sottotitolo, x = NULL, y = "Punti base") +
    tema
}

# -----------------------------------------------
# Figura 1 — Spread dei Paesi periferici
# -----------------------------------------------
perif <- leggi_spread("2000-2025 periferici") %>%
  mutate(country = factor(country, levels = c("Italia", "Spagna", "Portogallo", "Grecia")))

# Come nella tesi: Italia e Spagna sull'asse sinistro, Portogallo e Grecia sull'asse destro
fattore <- ceiling(max(perif$spread[perif$country %in% c("Portogallo", "Grecia")]) /
                   max(perif$spread[perif$country %in% c("Italia", "Spagna")]))
perif <- perif %>%
  mutate(y_plot = ifelse(country %in% c("Portogallo", "Grecia"), spread / fattore, spread),
         country = factor(country, levels = c("Italia", "Spagna", "Portogallo", "Grecia"),
                          labels = c("Italia (asse sinistro)", "Spagna (asse sinistro)",
                                     "Portogallo (asse destro)", "Grecia (asse destro)")))
colori_perif <- setNames(colori[c("Italia", "Spagna", "Portogallo", "Grecia")], levels(perif$country))

fig1 <- ggplot(perif, aes(time, y_plot, colour = country)) +
  eventi_layer() +
  geom_line(linewidth = 0.7) +
  scale_colour_manual(values = colori_perif) +
  scale_y_continuous(name = "Italia e Spagna (punti base)",
                     expand = expansion(mult = c(0.02, 0.22)),  # spazio in alto per le etichette BCE
                     sec.axis = sec_axis(~ . * fattore, name = "Portogallo e Grecia (punti base)")) +
  scale_x_date(breaks = seq(as.Date("2000-01-01"), as.Date("2024-01-01"), by = "4 years"),
               date_labels = "%Y", expand = c(0.01, 0)) +
  labs(title = "Spread sovrani dei Paesi periferici",
       subtitle = "Differenziale del decennale rispetto al Bund tedesco, 2000-2025", x = NULL) +
  tema +
  theme(axis.title.y.right = element_text(colour = "grey35", size = 10)) +
  guides(colour = guide_legend(nrow = 2))

# -----------------------------------------------
# Figura 2 — Spread dei Paesi core
# -----------------------------------------------
core <- leggi_spread("2000-2025 core") %>%
  mutate(country = factor(country, levels = c("Francia", "Belgio", "Austria", "Paesi Bassi", "Finlandia")))

fig2 <- grafico_spread(core, "Spread sovrani dei Paesi core",
                       "Differenziale del decennale rispetto al Bund tedesco, 2000-2025")

# -----------------------------------------------
# Figura 3 — Controfattuale per Paese (2015-2025)
# -----------------------------------------------
paesi_cf <- c("Italia", "Spagna", "Portogallo", "Grecia")
sigle    <- c("Italia" = "IT", "Spagna" = "ES", "Portogallo" = "PT", "Grecia" = "GR")

# Foglio "Scomposizione paesi": per ogni Paese spread osservato, componente APP,
# componente PEPP e spread controfattuale (bAPP = -0,0176; bPEPP = -5,41), gen 2015 - dic 2025
scomp <- suppressMessages(read_excel(file_cf, sheet = "Scomposizione paesi"))
scomp$time <- seq(as.Date("2015-01-01"), by = "month", length.out = nrow(scomp))

cf <- bind_rows(lapply(paesi_cf, function(p) {
  s <- sigle[[p]]
  data.frame(time           = scomp$time,
             country        = p,
             osservato      = scomp[[paste(s, "oss")]],
             comp_app       = scomp[[paste(s, "APP")]],
             comp_pepp      = scomp[[paste(s, "PEPP")]],
             controfattuale = scomp[[paste(s, "cf")]])
})) %>%
  filter(!is.na(osservato)) %>%
  mutate(con_app = osservato + comp_app,
         country = factor(country, levels = paesi_cf))

fig3 <- ggplot(cf, aes(time)) +
  eventi_layer(dal = as.Date("2015-01-01")) +
  geom_ribbon(aes(ymin = osservato, ymax = con_app, fill = "Effetto APP")) +
  geom_ribbon(aes(ymin = con_app, ymax = controfattuale, fill = "Effetto PEPP")) +
  geom_line(aes(y = controfattuale, colour = "Spread senza APP e PEPP"), linewidth = 0.6, linetype = "22") +
  geom_line(aes(y = osservato, colour = "Spread osservato"), linewidth = 0.7) +
  facet_wrap(~ country, ncol = 2, scales = "free_y") +
  scale_fill_manual(values = c("Effetto APP" = "#9ec5f4", "Effetto PEPP" = "#f5b48f")) +
  scale_colour_manual(values = c("Spread osservato" = "#0b0b0b", "Spread senza APP e PEPP" = "#d03b3b"),
                      guide = guide_legend(override.aes = list(linetype = c("solid", "22")))) +
  scale_x_date(breaks = seq(as.Date("2015-01-01"), as.Date("2025-01-01"), by = "2 years"),
               date_labels = "%Y", expand = c(0.01, 0)) +
  labs(title = "Spread osservato e controfattuale in assenza di APP e PEPP",
       subtitle = "Paesi periferici, 2015-2025, punti base",
       x = NULL, y = "Punti base") +
  tema

# -----------------------------------------------
# Figura 4 — Compressione a giugno 2020 (picco degli acquisti PEPP)
# -----------------------------------------------
giugno20 <- cf %>%
  filter(time == as.Date("2020-06-01")) %>%
  select(country, comp_app, comp_pepp) %>%
  pivot_longer(-country, names_to = "programma", values_to = "pb") %>%
  mutate(programma = factor(ifelse(programma == "comp_app", "APP", "PEPP"), levels = c("PEPP", "APP")),
         country   = factor(country, levels = rev(paesi_cf)))

totali <- giugno20 %>% group_by(country) %>% summarise(pb = sum(pb))

fig4 <- ggplot(giugno20, aes(pb, country, fill = programma)) +
  geom_col(width = 0.6, colour = "white", linewidth = 0.6) +
  geom_text(data = totali, inherit.aes = FALSE,
            aes(x = pb, y = country, label = paste0(round(pb), " pb")),
            hjust = -0.15, size = 4, fontface = "bold") +
  scale_fill_manual(values = c("APP" = "#2a78d6", "PEPP" = "#eb6834"),
                    breaks = c("APP", "PEPP"), labels = c("APP (stock, uguale per tutti)", "PEPP (acquisti mirati)")) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Compressione degli spread a giugno 2020: contributo di APP e PEPP",
       subtitle = "Stima controfattuale per Paese, punti base",
       x = NULL, y = NULL) +
  tema +
  theme(panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(colour = "grey90"),
        axis.text.y = element_text(size = 12, colour = "grey15"))

# -----------------------------------------------
# Salvataggio
# -----------------------------------------------
salva <- function(grafico, nome, altezza) {
  ggsave(file.path("figure", paste0(nome, ".svg")), grafico, width = 9, height = altezza)
  ggsave(file.path("figure", paste0(nome, ".png")), grafico, width = 9, height = altezza, dpi = 200, bg = "white")
}
salva(fig1, "fig1_spread_periferici", 5.5)
salva(fig2, "fig2_spread_core", 5)
salva(fig3, "fig3_controfattuale_periferici", 7)
salva(fig4, "fig4_compressione_giugno2020", 4)

cat("Grafici salvati nella cartella figure/\n")
