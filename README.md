# Projeção dos Recursos Necessários para Controle de Fila para Procedimentos em Saúde

## Introdução
A análise de recursos necessários para controle do tempo de filas para consultas e procedimentos em saúde pode auxiliar na prestação de serviços em tempo oportuno de forma a promover melhores resultados no cuidado em saúde. Esse controle é ainda fundamental para redução do desperdício dos recursos públicos, evitando-se que se tenham prestadores em excesso. Assim, essa aplicação tem como objetivo auxiliar os gestores de saúde na análise do número de rescursos necessários para atingir o controle no tempo de espera dos procedimentos e, em seguida, o número de recursos necessários para manter esse tempo sob controle. 

Sua construção foi realizada para a Secretaria de Saúde de Florianópolis e contou como apoio do Professor do Departamento de Matemática da Universidade Federal de Santa Catarina, Dr. Giuliano Boava (http://lattes.cnpq.br/4918706756138339).

A aplicação está licenciada sob GLP 3.0 (https://github.com/lpgarcia18/projecao_fila_saude/blob/main/LICENSE), de modo a permitir sua reutilização por outros municípios e o desenvolvimento conjuto. Sugestões e contribuições são muito bem vindas.

## Método
A aplicação permite o cálculo da quantidade de profissionais necessários para: 1) controlar e para 2) manter o controle da fila por um determinado procedimento em saúde. Esses cálculos são feitos a partir da definição do 1) tempo para o controle, 2) número máximo de profissionais para simulação (teto de profissionais que será utilizado para realizar os cálculos) e 3)média de procedimentos realizados por cada profissional. Toda a análise tem o mês como unidade de medida temporal.

Os seguintes dados do mês anteiror à projeção são utilizados nas projeções:

-_Demanda Inicial_ = número de pacientes na fila no último dia de uma dado mês<br />
-_Demanda Recorrente_ = número de solicitações em um dado mês<br />
-_Taxa de retorno_  = número de retornos em um dado mês/número de solicitações no mesmo mês<br />
-_Taxa de falta_  = número de faltas em um dado mês/número de solicitações no mesmo mês<br />

Foram estabelecidas, ainda, 60 meses para simulação.

O modelo foi construido para o **cálculo de pessoas na fila** em cada um dos 60 meses, simulando-se com 1 profissional até o número máximo de profissioanis escolhidos. Assumiu-se que, no início da simulação, há uma **demanda inicial** (represada e que não ocorrerá nos meses seguintes) e uma **demanda recorrente** (que se repete todo mês). A soma dessas duas demandas, gera a **demanda extera**. No primeiro ciclo não há retornos, mas, após este ciclo, a soma da **demanda externa** com a **demanda por retornos** gera a **demanda**. O que restou sem **marcação** da **demanda externa** e da **demanda** em cada ciclo, vai gerar a **fila**, que gera a **demanda acumulada**. Se a **demanda acumulada** é maior que a **capacidade** de atendimento (dada pela multiplicação dos **profissionais** atendendo pelo capacidade de geração de **procedimentos** de cada profissional), a **marcação** de procediemntos será igual à **capacidade**; se for menor ou igual, toda a **demanda acumulada** será atendida. As **marcações** são então subtraidas da **fila**.  O número de **atendimentos** realizados é igual à quantidade **marcações** menos a quantidade de **faltas**.  As **faltas**, por sua vez, são iguais aos **atendimentos** vezes a **taxa de faltas**. Após os **atendimentos**, os pacientes podem ter **alta** (**atendimentos** vezes a **taxa de alta**) ou podem ter um **retorno** (**atendeimentos** vezes **taxa de retorno**). Os **retornos** transofrma-se em **demanda por retorno**, que será somada à **demanda externa**, fechando o ciclo a cada iteração. 

![image](https://user-images.githubusercontent.com/21002844/151796497-7dfbc805-778c-4ddc-847e-3274301b1dd2.png)


