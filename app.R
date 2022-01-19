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
		    		tabItem(tabName = "projecoes", h2("Projeção de Necessidade de Profissionais"),
		    			fluidRow(
		    				box(selectInput(
		    					inputId="procedimento",
		    					label="Tipo de Procedimento",
		    					choices= procedimento),
		    					width = 12, status = "primary")),
		    			fluidRow(
		    				tabBox(title = "Variáveis", width=12,
		    				       splitLayout(
		    				       	numericInput("tempo", label = "Tempo para Controle", value = 12),
		    				       	numericInput("n_profissional", label = "Número de Profissionais para Simulação", value = 500),
		    				       	numericInput("consulta", label = "Consultas por Profissional/Mês", value = 100)))),
		    		
		    			fluidRow(
		    				tabBox(title = "Parâmetros", width=12,
		    				       splitLayout(
		    				       	tableOutput("table"),
		    				       	plotlyOutput(outputId = "fila"),))),
		    			fluidRow(
		    				tabBox(title = "Projeções", width=12,
		    				       splitLayout(
		    				       	valueBoxOutput("controle", width = 12),
		    				       	valueBoxOutput("manutencao", width = 12))))
		    			
		    			
	    		)
	    	)
	)
)



########################################################################################### 
server <- function(input, output, session) {
	###########################################################################################
	
	base$mes_ano <- format(base$mes_ano, '%Y-%m-%d')
	
	
	######################################################################################
	#Projeções
	######################################################################################	
	profissional <- input$n_profissional
	consulta <- input$consulta
	
	proced_selec <- base %>%
		subset(nome_procedimento == input$procedimento) %>%
		subset(mes_ano == as.Date(mondate("2021-12-01")-1))  #Quando for colocar em produção, substituir por sisdate
	

	iteracoes <- 60
	retorno <- 0
	falta <- 0
	
	# Parâmetros para simulação
	# demanda_inicial <- 10000
	# demanda_recorrente <- 500
	# profissionais <- 50
	# consulta <- 50
	# capacidade <- profissionais*consulta
	# tx_falta <- 0.0
	# tx_retorno <- 0.0

	tempo_entrada <- array(0, dim = c(iteracoes+1, profissional))
	tempo_atendido <- array(0, dim = c(iteracoes+1, profissional))
	tempo_nao_atendido <- array(0, dim = c(iteracoes+1, profissional))
	tempo_mes <- array(0,dim = c(iteracoes+1, profissional))
	demanda_externa <- c(demanda_inicial+demanda_recorrente, rep(demanda_recorrente, iteracoes+1))
	
	profissional_controle <- c(1:profissional)
	fila <- array(0, dim = c(iteracoes+1, iteracoes+1, profissional))
	
	for(g in 1:profissional){
		for(h in 1:iteracoes){
			demanda_por_retorno <- retorno
			demanda <- demanda_externa[h] + demanda_por_retorno 
			fila[h,h,g] <- demanda
			fila[1,1,g] <- demanda_externa[1]
			demanda_acumulada <- sum(fila[h,,g], na.rm = T) 
			marcacao <- min((profissional_controle[g]*consulta),demanda_acumulada)
			atendimento <- marcacao - falta
			falta <- tx_falta * atendimento
			retorno <- tx_retorno * atendimento
			alta <- (1 - tx_retorno) * atendimento
			remocao <- marcacao
			for(i in 1:h){
				if(remocao > fila[h,i,g]){
					fila[h+1,i,g] <- 0
					remocao <- remocao - fila[h,i,g]
				} else{
					fila[h+1,i,g] <- fila[h,i,g] - remocao
					remocao <- 0
				}
				
			}
			
		}	
	}
	
	for(j in 1:profissional){	
		for(k in 1:iteracoes){
			for(l in k:iteracoes){
				tempo_entrada[k,j] <- tempo_entrada[k,j] + (l-k+1)*(fila[l,k,j]-fila[l+1,k,j])	
			}
			tempo_entrada[k,j] <- tempo_entrada[k,j]/fila[k,k,j]
			denominador_atendido <- 0
			denominador_nao_atendido <- 0
			denominador_mes <- 0
			for(m in 1:k){
				denominador_atendido <- denominador_atendido + fila[k,m,j] - fila[k+1,m,j] 
				denominador_nao_atendido <- denominador_nao_atendido + fila[k+1,m,j] 
				denominador_mes <- denominador_mes + fila[k,m,j]
				tempo_atendido[k,j] <- tempo_atendido[k,j] + (k-m+1) * (fila[k,m,j] - fila[k+1,m,j])
				tempo_nao_atendido[k,j] <- tempo_nao_atendido[k,j] +  (k-m+1) *  fila[k+1,m,j]
				tempo_mes[k,j] <- tempo_mes[k,j] + (k-m+1) * fila[k,m,j]
			}
			tempo_atendido[k,j] <- tempo_atendido[k,j]/denominador_atendido 
			tempo_nao_atendido[k,j] <- tempo_nao_atendido[k,j]/denominador_nao_atendido 
			tempo_mes[k,j] <- tempo_mes[k,j]/denominador_mes 
		}
	}		
	
	
	

	#Menor número de profissionais em que o tempo para controle seja atingido
	#tempo para controle = número de meses até que o controle seja atingido
	tempo_para_controle <- 12
	
	profissional_para_controle <- tempo_entrada[(tempo_para_controle+1):nrow(tempo_entrada),]
	profissional_para_controle <- round(profissional_para_controle, 1)
	profissional_para_controle <- profissional_para_controle <= 1 &  profissional_para_controle !=0
	profissional_para_controle <- head(profissional_para_controle,-1)
	profissional_para_controle <- colMeans(profissional_para_controle)
	profissional_para_controle <- min(which(profissional_para_controle == 1))
	

	
	#Para manter o controle, a capacidade deve ser igual à demanda + retorno - falta
	
	demanda_manutencao <- (demanda_recorrente * (1+tx_retorno))-(demanda_recorrente * tx_falta)
	profissional_manutencao <- demanda_manutencao/consulta
	
	#Curva de controle
	tempo_grafico <- tempo_entrada[,profissional_para_controle]
	
	######################################################################################
	#Outputs
	######################################################################################	
	#Tabela 	
	output$table <- renderTable(base %>%
				    	subset(nome_procedimento == input$procedimento) %>%
				    	subset(mes_ano == as.Date(mondate("2021-12-01")-1)) %>% #Quando for colocar em produção, substituir por sisdate
				    	select("Procediemnto" = nome_procedimento,
				    	       "Mês e Ano" = mes_ano,
				    	       "Taxa de Retorno" = tx_retorno,
				    	       "Taxa de Faltas" = tx_falta,
				    	       "Fila Atual" = fila_total,
				    	       "Demanda" = solic_total))	
	
	#Gráfico 	
	output$fila <- renderPlotly({
		
		out <- data.frame("Tempo de Espera" = round(head(tempo_grafico,-1),1), time = c(1:iteracoes))
		
		graf_tempo <- ggplot(out, aes(time, Tempo.de.Espera, group = 1))+
			geom_line()+
			geom_vline(xintercept = 13, color = "red")+
			theme_bw()
		
		ggplotly(graf_tempo)
		
		
		
	})
	
	#ValueBox
	output$controle <- renderValueBox({
		req(input$choix_ligne)
		if(input$choix_ligne == "ALL"){
			titre <- NVALDTOT_STAT_CATJOUR_LIGNE %>% 
				filter(CAT_JOUR2 %in% type_jour_r$x)
		} else {
			titre <- NVALDTOT_STAT_CATJOUR_LIGNE %>% 
				filter(LIGNE == input$choix_ligne & CAT_JOUR2 %in% type_jour_r$x)
		}
		titre %>% 
			filter(NB_VALD_STAT_CATJ_2017 == max(NB_VALD_STAT_CATJ_2017)) %>% 
			pull(NOM_ARRET) %>% 
			str_to_title %>% 
			valueBox(
				subtitle = "Profissionais para Controle",
				icon = icon("map-marker"),
				color = "navy"
			)
	})
	
}

#Analisar o que tem demanda reprimida e capacidade sobrando (precisa dos dados do número de profissionais)


###########################################################################################
#Aplicação
###########################################################################################
shinyApp(ui, server)