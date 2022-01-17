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
	
		iteracoes <- 60
		demanda_inicial <- 10000
		demanda_recorrente <- 500
		profissionais <- 50
		consulta <- 50
		capacidade <- profissionais*consulta
		tx_falta <- 0.0
		tx_retorno <- 0.0
		retorno <- 0
		falta <- 0
		
		fila <- matrix(nrow = iteracoes+1, ncol = iteracoes+1)
		tempos <- list()
		
		for(i in 1:iteracoes){
			demanda_por_retorno <- retorno
			demanda <- demanda_inicial + demanda_recorrente + demanda_por_retorno 
			demanda_inicial <- 0
			fila[i,i] <- demanda
			demanda_acumulada <- sum(fila[i,], na.rm = T) 
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
		
		tempo_entrada <- c(1:iteracoes+1)
		tempo_atendidos <- c(1:iteracoes+1)
		tempo_nao_atendidos <- c(1:iteracoes+1)
		tempo_mes <- c(1:iteracoes+1)
		
		for(i in 1:iteracoes){
			for(j in i:iteracoes){
				tempo_entrada[i] <- tempo_entrada[i] + (j-i+1)*(fila[j,i]-fila[j+1,i])	
			}
			tempo_entrada[i] <- tempo_entrada[i]/fila[i,i]
			denominador_atendidos <- 0
			denominador_nao_atendidos <- 0
			denominador_mes <- 0
			for(j in 1:i){
				denominador_atendidos <- denominador_atendidos + fila[i,j] - fila[i+1,j] 
				denominador_nao_atendidos <- denominador_nao_atendidos + fila[i+1,j] 
				denominador_mes <- denominador_mes + fila[i,j]
				tempo_atendidos[i] <- tempo_atendidos[i] + (i-j+1) * (fila[i,j] - fila[i+1,j])
				tempo_nao_atendidos[i] <- tempo_nao_atendidos[i] +  (i-j+1) *  fila[i+1,j]
				tempo_mes[i] <- tempo_mes[i] + (i-j+1) * fila[i,j]
			}
			tempo_atendidos[i] <- tempo_atendidos[i]/denominador_atendidos 
			tempo_nao_atendidos[i] <- tempo_nao_atendidos[i]/denominador_nao_atendidos 
			tempo_mes[i] <- tempo_mes[i]/denominador_mes 
		}
		
		
		out <- do.call(rbind, tempos)
		out <- data.frame("Tempo de Espera" = out, time = c(1:iteracoes))
		
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