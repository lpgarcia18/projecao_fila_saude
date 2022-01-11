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
		
		proced_selec <- base %>% 
			subset(nome_procedimento == input$procedimento) %>%
			subset(mes_ano == as.Date(mondate("2021-12-01")-1))  #Quando for colocar em produção, substituir por sisdate
		
		
		
		states <- c(fila_regulacao = proced_selec$fila_total[1])
		
		fila <- function(t, y, parms) {
			with(as.list(c(y, parms)), {
				marcacao <- ifelse(fila_regulacao > capacidade, capacidade, fila_regulacao)
				atendimento <- ifelse(fila_regulacao > capacidade, capacidade, fila_regulacao)*(1-tx_falta) 
				alta <- (1-tx_retorno)*(ifelse(fila_regulacao > capacidade, capacidade, fila_regulacao)*(1-tx_falta)) 
				retorno <- (tx_retorno)*(ifelse(fila_regulacao > capacidade, capacidade, fila_regulacao)*(1-tx_falta))
				dReg <- demanda + retorno - ifelse(fila_regulacao > capacidade, capacidade, fila_regulacao)
				
				return(list(c(dReg),
					    atendimento = atendimento,
					    alta = alta,
					    retorno = retorno,
					    marcacao = marcacao, 
					    demanda = demanda, 
					    capacidade = capacidade))
				
			})
		}
		
		parms <- c(
			tx_retorno=proced_selec$tx_retorno[1], 
			tx_falta=proced_selec$tx_falta[1],
			demanda = proced_selec$solic_total[1],
			capacidade = capacidade
		)
		
		times <- seq(1, 60, 1)
		
		out <- deSolve::ode(y = states, times, parms, func =  fila)
		out <- as.data.frame(out)
		out$"Tempo de Espera" <- out$fila_regulacao/out$atendimento
		
		graf_tempo <- ggplot(out, aes(time, `Tempo de Espera`, group = 1))+
			geom_line()+
			theme_bw()
		
		ggplotly(graf_tempo)
		
		
		
	})
	
}


###########################################################################################
#Aplicação
###########################################################################################
shinyApp(ui, server)


