# -----------------------------
# Pacotes
# -----------------------------
library(readxl)
library(sf)
library(dplyr)
library(ggplot2)

# -----------------------------
# Dados químicos (Excel)
# -----------------------------
dados <- read_excel("dados/Gean.xlsx") |>
  slice(-1) |>
  mutate(across(everything(), as.numeric)) |>
  rename(ponto = ...1)

# -----------------------------
# Dados espaciais (KML)
# -----------------------------
area <- st_read("dados/Area_Jernimo_Contorno.kml")
area1 <- area[-c(1:35),]
area2 <- area[-c(36),]|>
  st_zm() |> # removendo o Z dos dados
  mutate(Name = as.numeric(Name))

str(area)
str(area1)
str(area2)

pontos_sf <- area2 |>
  left_join(dados, by = c("Name" = "ponto"))
ggplot() +
  geom_sf(data = area1, fill = NA, color = "black", linewidth = 0.6) +
  geom_sf(data = pontos_sf, aes(color = S), size = 3) +
  scale_color_viridis_c(name = "S") +
  theme_light()
names(pontos_sf)

boxplot(
  st_drop_geometry(pontos_sf)[, c("N","P","K","Ca","Mg","S","Fe","Cu","Mn","Zn")],
  las = 2,
  #main = "Distribuição dos atributos químicos do solo",
  ylab = "Valores"
)

pontos_sf |>
  st_drop_geometry() |>
  select(N, P, K, Ca, Mg, S, Fe, Cu, Mn, Zn) |>
  tidyr::pivot_longer(everything(),
                      names_to = "Variavel",
                      values_to = "Valor") |>
  ggplot(aes(x = Variavel, y = Valor)) +
  geom_boxplot() +
  theme_minimal() +
  labs(
    title = "Distribuição dos atributos químicos do solo",
    x = "Atributos",
    y = "Valores"
  )

install.packages("RGeostats", repos = "http://rgeostats.free.fr/R", type = "source")
