options(encoding = "UTF-8")
options(scipen=999)
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
library(readxl)

########################################################################################### 
#Dados 
###########################################################################################
# base <- read_delim("bases/calculo_fila_geral_01.csv", 
# 		   delim = ";", escape_double = FALSE, locale = locale(encoding = "WINDOWS-1252"), 
# 		   trim_ws = TRUE)


base <- read_excel("bases/calculo_fila_geral_01.xlsx")

base$tx_retorno <- base$solic_retorno / base$solic_total
base$tx_falta <- base$faltas / base$solic_total

procedimento <- unique(base$nome_procedimento) 
procedimento <- as.list(strsplit(procedimento, ","))
names(procedimento) <- unique(base$nome_procedimento)

########################################################################################### 
#UI
###########################################################################################

###########################################################################################
dbHeader <- dashboardHeader(title = "SMS - Florianópolis", 
			    tags$li(a(href = 'http://www.pmf.sc.gov.br/entidades/saude/index.php?cms=salas+de+situacao&menu=4&submenuid=152',
			    	  icon("power-off"),
			    	  title = "Sair"),
			    	class = "dropdown"),
			    tags$li(a(href = 'http://www.pmf.sc.gov.br/entidades/saude/index.php?cms=salas+de+situacao&menu=4&submenuid=152',
			    	  tags$img(src = 'logo_geinfo.png',
			    	  	 title = "Gerência de Inteligência e Informação", height = "30px"),
			    	  style = "padding-top:10px; padding-bottom:10px;padding-left:30px, padding-right:30px"),
			    	class = "dropdown"))


ui <- dashboardPage(
	########################################################################################### 
	dbHeader,
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
		tags$head(tags$style(HTML('
                          /* logo */
                          .skin-blue .main-header .logo {
                          background-color: rgb(255,255,255); color: rgb(14, 59, 79);
                          font-weight: bold;font-size: 20px;text-align: Right;
                          }

                          /* logo when hovered */

                          .skin-blue .main-header .logo:hover {
                          background-color: rgb(255,255,255);
                          }


                          /* navbar (rest of the header) */
                          .skin-blue .main-header .navbar {
                          background-color: rgb(255,255,255);
                          }

                          /* main sidebar */
                          .skin-blue .main-sidebar {
                          background-color: rgb(14, 59, 79);
                          }
                          

                          /* active selected tab in the sidebarmenu */
                          .skin-blue .main-sidebar .sidebar .sidebar-menu .active a{
                          background-color: rgb(14, 59, 79);
                          color: rgb(255,255,255);font-weight: bold;font-size: 18px;
                          }

                          /* other links in the sidebarmenu */
                          .skin-blue .main-sidebar .sidebar .sidebar-menu a{
                          background-color: rgb(14, 59, 79);
                          color: rgb(255,255,255);font-weight: bold;
                          }

                          /* other links in the sidebarmenu when hovered */
                          .skin-blue .main-sidebar .sidebar .sidebar-menu a:hover{
                          background-color: rgb(147,181,198);color: rgb(14, 59, 79);font-weight: bold;
                          }

                          /* toggle button color  */
                          .skin-blue .main-header .navbar .sidebar-toggle{
                          background-color: rgb(255,255,255);color:rgb(14, 59, 79);
                          }

                          /* toggle button when hovered  */
                          .skin-blue .main-header .navbar .sidebar-toggle:hover{
                          background-color: rgb(147,181,198);color:rgb(14, 59, 79);
                          }
                          
                          /* body */
                          .content-wrapper, .right-side {
                          background-color: rgb(147,181,198);
                          
                          
                          
                         

#                           '))),
		tags$style(".small-box.bg-blue { background-color: rgb(18, 34, 59) !important; color: rgb(255,255,255) !important; };"
		),
		tags$style(".fa-check {color:#B5500C}"),
		tags$style(".fa-check-double {color:#B5500C}"),
		tags$style(".box { background-color: rgb(255, 255, 255) !important; color: rgb(0, 0, ) !important; };"),
		
		tabItems(
			########################################################################################### 
			#Proejeção de tempo
			###########################################################################################
			tabItem(tabName = "projecoes", h3("Projeção de Necessidade de Procedimentos"),
				fluidRow(
					column(width = 12,
					       tabBox(title = "Seleção para Análise", width=12, height = 180,
					              column(width = 9, 
					                     box(width = 12,collapsible = F,  
					                         selectInput(
					                         	inputId="procedimento",
					                         	label="Tipo de Procedimento", 
					                         	choices= c(" ", procedimento),
					                         	selected = " "))),
					              column(width = 3, 
					                     box(width = 12,collapsible = F,
					                         numericInput("tempo_contr",
					                         	     label = "Tempo para Controle (Mês)",
					                         	     value = 12)))))),
				
				fluidRow(column(width = 12,
						tabBox(title = "Parâmetros", width=12, height = 300,
						       column(width = 8, 
						              tableOutput("table")),
						       column(width = 4, 
						              plotlyOutput(outputId = "fila",height = 250))))),
				fluidRow(column(width = 12,
						tabBox(title = "Projeções", width= 12, height = 200,
						       column(width = 6, 
						              valueBoxOutput("controle", width = 12)),
						       column(width = 6, 
						              valueBoxOutput("manutencao", width = 12)))))
				
				
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
	
	
	combo_output <- reactive({
		
		if (input$procedimento == " ")
			return(NULL)
		
		proced_selec <- base %>%
			subset(nome_procedimento == input$procedimento) %>%
			subset(mes_ano == as.Date(mondate("2021-12-01")-1))  #Quando for colocar em produção, substituir por sisdate
		
		demanda_recorrente <- proced_selec$solic_total[1]
		demanda_inicial <- proced_selec$fila_total[1]
		tx_retorno <- proced_selec$tx_retorno[1]
		tx_falta <- proced_selec$tx_falta[1]
		iteracoes <- 60
		retorno <- 0
		falta <- 0
		
		# Parâmetros para simulação
		# demanda_inicial <- 200
		# demanda_recorrente <- 500
		# tx_falta <- 0.0
		# tx_retorno <- 0.0
		n_simula_proced <- 200
		
		procedimentos_controle <- cumprod(c(1, rep(1.05,n_simula_proced)))
		
		demanda_externa <- c(demanda_inicial+demanda_recorrente, rep(demanda_recorrente, iteracoes+1))
		
		
		tempo_entrada <- array(0, dim = c(iteracoes+1, n_simula_proced))
		tempo_atendido <- array(0, dim = c(iteracoes+1, n_simula_proced))
		tempo_nao_atendido <- array(0, dim = c(iteracoes+1, n_simula_proced))
		tempo_mes <- array(0,dim = c(iteracoes+1, n_simula_proced))
		
		fila <- array(0, dim = c(iteracoes+1, iteracoes+1, n_simula_proced))
		
		for(g in 1:n_simula_proced){
			for(h in 1:iteracoes){
				demanda_por_retorno <- retorno
				demanda <- demanda_externa[h] + demanda_por_retorno 
				fila[h,h,g] <- demanda
				fila[1,1,g] <- demanda_externa[1]
				demanda_acumulada <- sum(fila[h,,g], na.rm = T) 
				marcacao <- min((procedimentos_controle[g]), demanda_acumulada)
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
		
		for(j in 1:n_simula_proced){	
			for(k in 1:iteracoes){
				for(l in k:iteracoes){
					tempo_entrada[k,j] <- tempo_entrada[k,j] + (l-k+1)*(fila[l,k,j]-fila[l+1,k,j])	
				}
				tempo_entrada[k,j] <- tempo_entrada[k,j]/fila[k,k,j]
			}
		}
		
		#Menor número de profissionais em que o tempo para controle seja atingido
		#tempo para controle = número de meses até que o controle seja atingido
		tempo_para_controle <- input$tempo_contr
		
		procedimento_para_controle_int <- tempo_entrada[(tempo_para_controle+1):nrow(tempo_entrada),]
		procedimento_para_controle_int <- round(procedimento_para_controle_int, 1)
		procedimento_para_controle_int <- procedimento_para_controle_int <= 1 &  procedimento_para_controle_int !=0
		procedimento_para_controle_int <- head(procedimento_para_controle_int,-1)
		procedimento_para_controle_int <- colMeans(procedimento_para_controle_int)
		procedimento_para_controle_int <- min(which(procedimento_para_controle_int == 1)) #Selecionando o número da simulação que gera controle 
		procedimento_para_controle <- procedimentos_controle[procedimento_para_controle_int] #Selecionando a quantos procedimentos essa simulação corresponde
		procedimento_para_controle <- round(procedimento_para_controle,0)
		#Para manter o controle, a capacidade deve ser igual à demanda + retorno - falta
		
		demanda_manutencao <- (demanda_recorrente * (1+tx_retorno))-(demanda_recorrente * tx_falta)
		procedimento_manutencao <- demanda_manutencao
		
		#Curva de controle
		tempo_grafico <- tempo_entrada[,procedimento_para_controle_int]
		
		combo <- list(procedimento = procedimento,
			      tempo_para_controle = tempo_para_controle,
			      iteracoes = iteracoes,
			      proced_selec = proced_selec, 
			      tempo_grafico = tempo_grafico,
			      procedimento_para_controle = procedimento_para_controle,
			      procedimento_manutencao = procedimento_manutencao)
		combo
		
	}) #fim da reactive
	
	
	
	######################################################################################
	#Outputs
	######################################################################################	
	#Tabela 	
	output$table <- renderTable({
		
		combo <- combo_output()
		tabela <- combo$proced_selec
		procedimento <- combo$procedimento
		if (is.null(procedimento))
			return(NULL)
		
		tabela %>%
			select("Procedimento" = nome_procedimento,
			       "Mês e Ano" = mes_ano,
			       "Taxa de Retorno" = tx_retorno,
			       "Taxa de Faltas" = tx_falta,
			       "Fila Atual" = fila_total,
			       "Demanda" = solic_total)
	})	
	
	#Gráfico 	
	output$fila <- renderPlotly({
		
		combo <- combo_output()
		tempo_controle <- combo$tempo_grafico
		tempo <- combo$iteracoes
		tempo_para_controle <- combo$tempo_para_controle
		procedimento <- combo$procedimento
		if (is.null(procedimento))
			return(NULL)
		
		#Base do gráfico
		out <- data.frame(Espera = round(head(tempo_controle,-1),1), Controle = c(1:tempo))
		
		
		graf_tempo <- ggplot(out, aes(Controle, Espera, group = 1))+
			geom_line()+
			geom_vline(xintercept = tempo_para_controle+1, color = "#CD6E10")+
			theme_light()
		
		ggplotly(graf_tempo)
		
		
		
	})
	
	#ValueBox
	output$controle <- renderValueBox({
		
		combo <- combo_output()
		prof_control <- combo$procedimento_para_controle
		procedimento <- combo$procedimento
		if (is.null(procedimento)){
			prof_control <- 0
		}
		
		valueBox(value = prof_control,
			 subtitle = "Procedimentos para Controle (Mês)",
			 icon = icon("check"),
			 color = "blue"
		)
	})
	
	#ValueBox
	output$manutencao <- renderValueBox({
		
		combo <- combo_output()
		prof_manu <- combo$procedimento_manutencao
		procedimento <- combo$procedimento
		procedimento <- combo$procedimento
		if (is.null(procedimento)){
			prof_manu <- 0
		}
		
		valueBox(value = prof_manu,
			 subtitle = "Procedimentos para Manutenção (Mês)",
			 icon = icon("check-double"),
			 color = "blue"
		)
	})
	
}

#Analisar o que tem demanda reprimida e capacidade sobrando (precisa dos dados do número de profissionais)


###########################################################################################
#Aplicação
###########################################################################################
shinyApp(ui, server)
