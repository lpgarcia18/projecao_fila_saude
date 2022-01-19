options(encoding = "UTF-8")

########################################################################################### 
#pacotes 
###########################################################################################
library(shiny)
library(ggplot2)
library(shinydashboard)
library(tidyverse)
library(htmltools)
library(stringr)
library(DT)
library(plotly)
library(reshape2)
library(deSolve)
library(mondate)

########################################################################################### 
#Dados 
###########################################################################################
base <- read_delim("bases/base_fila_20211230.csv", 
		   delim = ";", escape_double = FALSE, locale = locale(encoding = "WINDOWS-1252"), 
		   trim_ws = TRUE)

base$tx_retorno <- base$solic_retorno / base$solic_total
base$tx_falta <- base$faltas / base$solic_total

procedimento <- unique(base$nome_procedimento) 
procedimento <- as.list(strsplit(procedimento, ","))
names(procedimento) <- unique(base$nome_procedimento)

########################################################################################### 
#UI
###########################################################################################
########################################################################################### 
ui <- dashboardPage(skin = "blue",
		    ########################################################################################### 
		    dashboardHeader(title = "Análise de Filas", titleWidth = 230),
		    ########################################################################################### 
		    dashboardSidebar(
		    	########################################################################################### 
		    	sidebarMenu(
		    		menuItem("Projeções",tabName = "projecoes", icon = icon("dashboard")),
		    		menuItem("Instruções", icon = icon("question-circle"),
		    			 href = "https://github.com/lpgarcia18/projecao_fila_saude"),
		    		menuItem("Código-fonte", icon = icon("code"), 
		    			 href = "https://github.com/lpgarcia18/projecao_fila_saude/blob/main/app.R"),
		    		menuItem("Licença de Uso", icon = icon("cc"), 
		    			 href = "https://github.com/lpgarcia18/projecao_fila_saude/blob/main/LICENSE")
		    		
		    	)
		    ),
		    ########################################################################################### 
		    dashboardBody(
		    	tabItems(
		    		########################################################################################### 
		    		#Proejeção de tempo
		    		###########################################################################################
		    		tabItem(tabName = "projecoes", h2("Projeção de tempo de espera"),
		    			fluidRow(
		    				box(selectInput(
		    					inputId="procedimento",
		    					label="Tipo de Procedimento",
		    					choices= procedimento),
		    					width = 12, status = "primary")),
		    			fluidRow(
		    				tabBox(title = "Variáveis", width=12,
		    				       splitLayout(
		    				       	numericInput("profissional", label = "Número de Profissionais", value = 10),
		    				       	numericInput("consulta", label = "Consultas por Profissional/Mês", value = 100)))),
		    			fluidRow(
		    				tabBox(title = "Gráfico", width=12,
		    				       splitLayout(
		    				       	tableOutput("table"),
		    				       	plotlyOutput(outputId = "fila"),)))
		    			
		    			
		    		)
		    	)
		    )
)
########################################################################################### 
server <- function(input, output, session) {
	###########################################################################################
	
	base$mes_ano <- format(base$mes_ano, '%Y-%m-%d')
	#tabela 	
	output$table <- renderTable(base %>%
				    	subset(nome_procedimento == input$procedimento) %>%
				    	subset(mes_ano == as.Date(mondate("2021-12-01")-1)) %>% #Quando for colocar em produção, substituir por sisdate
				    	select("Procediemnto" = nome_procedimento,
				    	       "Mês e Ano" = mes_ano,
				    	       "Taxa de Retorno" = tx_retorno,
				    	       "Taxa de Faltas" = tx_falta,
				    	       "Fila Atual" = fila_total,
				    	       "Demanda" = solic_total))	
	
	#gráfico 	
	output$fila <- renderPlotly({
		profissional <- input$profissional
		consulta <- input$consulta
		capacidade <- profissional * consulta
		
		# proced_selec <- base %>% 
		# 	subset(nome_procedimento == input$procedimento) %>%
		# 	subset(mes_ano == as.Date(mondate("2021-12-01")-1))  #Quando for colocar em produção, substituir por sisdate
		# 
		# states <- c(demanda = proced_selec$solic_total[1], 
		# 	    fila = proced_selec$fila_total[1])
		# parms <- c(tx_retorno=proced_selec$tx_retorno[1], 
		# 	   tx_falta=proced_selec$tx_falta[1],
		# 	   capacidade = capacidade)
		# times <- seq(1, 60, 1)
		
		
		
		#Usar como parâmetro o tempo aceitável de fila e quanto tempo para chegar lá.
		#Isso deve gerar o número de profissionais para controlar e o número para manter controlado.
		#Estimar redução de desperdício e número de pacientes com melhor controle
		#Analisar o que tem demanda reprimida e capacidade sobrando
		
		
		
		#Quantidade de profissionais necessários após estabilização = demanda recorrente + retorno - falta
	
		iteracao <- 60
		demanda_inicial <- 10000
		demanda_recorrente <- 500
		profissional <- 50
		consulta <- 50
		tx_falta <- 0.0
		tx_retorno <- 0.0
		retorno <- 0
		falta <- 0
		
		profissionais_controle <- rep(0, profissional+1)
		tempo_para_controle <- 3
		tempo_adequado <- 1
		
		fila <- matrix(nrow = iteracao+1, ncol = iteracao+1)
		
		
		tempo_entrada <- rep(0, iteracao+1) #Tempo médio da solicitação do procedimento até o atendimento (ex. Qual foi o tempo médio de espera de quem entrou em março de 2021?)
		tempo_atendido <- rep(0, iteracao+1) #Tempo médio da espera somente daqueles que já foram atendido em um dado mês (ex. em março de 2021, qual foi o tempo médio de espera dos atendido?)
		tempo_nao_atendido <- rep(0, iteracao+1) #Tempo médio da espera somente daqueles que não foram atendido em um dado mês (ex. em março de 2021, qual foi o tempo médio de espera dos não atendido?)
		tempo_mes <- rep(0, iteracao+1) #Tempo médio de espera dos que foram e dos que ainda não foram atendido em um dado mês (ex. em março de 2021, qual foi o tempo médio de espera dos atendido e dos não atendido?)
		
		
		for(h in 1:profissional){
		
		
			for(i in 1:iteracao){
				demanda_por_retorno <- retorno
				demanda <- demanda_inicial + demanda_recorrente + demanda_por_retorno 
				demanda_inicial <- 0
				fila[i,i] <- demanda
				demanda_acumulada <- sum(fila[i,], na.rm = T) 
				capacidade <- profissional[h] * consulta
				marcacao <- min(capacidade,demanda_acumulada)
				atendimento <- marcacao - falta
				falta <- tx_falta * atendimento
				retorno <- tx_retorno * atendimento
				alta <- (1 - tx_retorno) * atendimento
				remocao <- marcacao
				for(j in 1:i){
					if(remocao > fila[i,j]){
						fila[i+1,j] <- 0
						remocao <- remocao - fila[i,j]
					} else{
						fila[i+1,j] <- fila[i,j] - remocao
						remocao <- 0
					}
				}
			}
			
			for(i in 1:iteracao){
				for(j in i:iteracao){
					tempo_entrada[i] <- tempo_entrada[i] + (j-i+1)*(fila[j,i]-fila[j+1,i])	
				}
				tempo_entrada[i] <- tempo_entrada[i]/fila[i,i]
				denominador_atendido <- 0
				denominador_nao_atendido <- 0
				denominador_mes <- 0
				for(j in 1:i){
					denominador_atendido <- denominador_atendido + fila[i,j] - fila[i+1,j] 
					denominador_nao_atendido <- denominador_nao_atendido + fila[i+1,j] 
					denominador_mes <- denominador_mes + fila[i,j]
					tempo_atendido[i] <- tempo_atendido[i] + (i-j+1) * (fila[i,j] - fila[i+1,j])
					tempo_nao_atendido[i] <- tempo_nao_atendido[i] +  (i-j+1) *  fila[i+1,j]
					tempo_mes[i] <- tempo_mes[i] + (i-j+1) * fila[i,j]
				}
				tempo_atendido[i] <- tempo_atendido[i]/denominador_atendido 
				tempo_nao_atendido[i] <- tempo_nao_atendido[i]/denominador_nao_atendido 
				tempo_mes[i] <- tempo_mes[i]/denominador_mes 
			}
		}
		
		out <- do.call(rbind, tempos)
		out <- data.frame("Tempo de Espera" = out, time = c(1:iteracao))
		
		graf_tempo <- ggplot(out, aes(time, Tempo.de.Espera, group = 1))+
			geom_line()+
			theme_bw()
		
		ggplotly(graf_tempo)
		
		
		
	})
	
}
###########################################################################################
#Aplicação
###########################################################################################
shinyApp(ui, server)