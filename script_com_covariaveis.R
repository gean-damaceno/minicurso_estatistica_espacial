################################################################################
# Script de Geoestatística com Covariáveis (Krigagem Universal/Deriva Externa)
# Baseado na metodologia de Oliveira (2003) usando o pacote geoR
################################################################################

# 1. Instalação e Carregamento do Pacote
if(!require(geoR)) install.packages("geoR")
library(geoR)

# --- SIMULAÇÃO DE DADOS (Apenas para exemplo) ---
# Se tiver os seus próprios dados, pule esta parte e carregue o seu CSV/Excel
n_amostras <- 100
# Criar coordenadas X e Y
coords <- matrix(runif(n_amostras * 2, 0, 100), ncol = 2)
# Criar covariáveis (Argila e Materia Organica)
argila <- runif(n_amostras, 20, 60)
mo <- runif(n_amostras, 1, 5)
# Criar variável Z (Cálcio) com dependência das covariáveis + erro espacial
z_calcio <- 2 + 0.1 * argila + 0.5 * mo + rnorm(n_amostras, 0, 1)
# Juntar tudo num data.frame
minha_tabela <- data.frame(X = coords[,1], Y = coords[,2], 
                           Teor_Calcio = z_calcio, 
                           Argila = argila, Mat_Organica = mo)

# --- INÍCIO DA ANÁLISE ---

# 2. Criação do Objeto geodata
# Importante: Definir quais colunas são as covariáveis em covar.col
dados_geo <- as.geodata(minha_tabela, 
                        coords.col = 1:2,            # Colunas de X e Y
                        data.col = 3,                # Coluna da variável resposta (Z)
                        covar.col = c("Argila", "Mat_Organica")) # Nomes das covariáveis

# Visualizar resumo dos dados
plot(dados_geo)

# 3. Ajuste do Modelo (Variograma + Tendência) via REML
# O argumento 'trend' define a relação linear com as covariáveis
modelo_fit <- likfit(dados_geo, 
                     trend = ~ Argila + Mat_Organica, # Fórmula da tendência
                     ini.cov.pars = c(1, 20),         # Chute inicial (Sill, Range)
                     cov.model = "spherical",         # Modelo teórico (esférico, exp, etc)
                     method.lik = "REML")             # Máxima Verossimilhança Restrita

# Ver os resultados do ajuste (Betas das covariáveis e parâmetros do variograma)
summary(modelo_fit)

# 4. Preparação do Grid de Predição
# O grid OBRIGATORIAMENTE precisa ter os valores das covariáveis em cada ponto
# Aqui criamos um grid regular simples e simulamos as covariáveis para ele
grid_pred <- expand.grid(X = seq(0, 100, l = 50), Y = seq(0, 100, l = 50))

# ATENÇÃO: Na prática, você traria esses valores de um mapa raster ou interpolação prévia
# Aqui, simulamos valores apenas para o script rodar
grid_pred$Argila <- runif(nrow(grid_pred), 20, 60)
grid_pred$Mat_Organica <- runif(nrow(grid_pred), 1, 5)

# 5. Predição (Krigagem com Deriva Externa)
# A função krige.conv usa o modelo ajustado para prever no novo grid
resultado_krigagem <- krige.conv(dados_geo, 
                                 locations = grid_pred[, 1:2], # Apenas X e Y do grid
                                 krige = krige.control(
                                   obj.model = modelo_fit,   # Modelo ajustado no passo 3
                                   trend.d = ~ Argila + Mat_Organica, # Tendência nos dados
                                   trend.l = ~ Argila + Mat_Organica  # Tendência no grid (locations)
                                 ))

# 6. Visualização do Mapa Final
image(resultado_krigagem, main = "Mapa de Krigagem com Deriva Externa", 
      col = heat.colors(20))
contour(resultado_krigagem, add = TRUE)

# Se quiser visualizar o erro da predição (Incerteza)
image(resultado_krigagem, val = sqrt(resultado_krigagem$krige.var), 
      main = "Desvio Padrão da Predição (Erro)")