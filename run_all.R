# ============================================================
# Esegue l'intera analisi nell'ordine corretto.
# Aprire il progetto nella cartella principale del repository
# (oppure setwd() sulla cartella) e lanciare: source("run_all.R")
#
# Pacchetti: install.packages(c("readxl", "dplyr", "tidyr", "plm", "ggplot2", "svglite"))
# ============================================================

source("R/01_dati_e_panel.R")       # dataset e panel
source("R/02_modello_completo.R")   # modello 2000-2025
source("R/03_finestre_temporali.R") # tre finestre temporali
source("R/04_robustezza_no2020.R")  # robustezza senza il 2020
source("R/05_controfattuale.R")     # controfattuale APP e PEPP
source("R/06_grafici.R")         # grafici (cartella figure/)
