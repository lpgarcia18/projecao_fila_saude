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

Foram estabelecidos, ainda, 60 meses para simulação.

O modelo foi construido para o **cálculo de pessoas na fila** em cada um dos 60 meses, simulando-se de um até o número máximo de profissioanis escolhidos. Assumiu-se que, no início da simulação, há uma **demanda inicial** (represada e que não ocorrerá nos meses seguintes) e uma **demanda recorrente** (que se repetirpa todo mês). A soma dessas duas demandas, gera a **demanda extera**. No primeiro ciclo, não há retornos, mas, após este ciclo, a soma da **demanda externa** com a **demanda por retornos** gerará a **demanda**. O que resta da **demanda externa** e da **demanda** sem **marcação** em cada ciclo, gerará a **fila**, que, por sua vez, constituirá a **demanda acumulada**. Se a **demanda acumulada** é maior que a **capacidade** de atendimento (dada pela multiplicação do número de **profissionais** atendendo pela capacidade de geração de **procedimentos** de cada profissional), a **marcação** de procediemntos será igual à **capacidade** de atendimento; se for menor ou igual, toda a **demanda acumulada** será atendida. As **marcações** serão, então, subtraidas da **fila**.  O número de **atendimentos** realizados será igual à quantidade **marcações** menos a quantidade de **faltas**.  As **faltas**, por sua vez, serão iguais aos **atendimentos** vezes a **taxa de faltas**. Após os **atendimentos**, os pacientes poderão ter **alta** (**atendimentos** vezes a **taxa de alta**) ou poderão tornar-se um **retorno** (**atendeimentos** vezes **taxa de retorno**). Os **retornos** transofrmar-se-ão em **demanda por retorno**, que será somada à **demanda externa**, fechando o ciclo a cada iteração. (Figura 1)

_Figura 1 - Cálculo de pessoas na fila em cada um dos 60 meses de simulação_

![image](https://user-images.githubusercontent.com/21002844/151802592-b35b5597-8fa9-43b4-bfb4-4fb7d9f2c8da.png)

Desse modo, é possível se estimar, para uma coorte de pacientes que entrou no primeiro mês da simulação, quantos foram atendidos no mês dois, quantos no mês três e assim sucessivamentes. Para se estimar o tempo de atendimento em cada um dos 60 meses, variando-se o número de profissionais de 1 até o número máximo estabelecido, realizou-se a média ponderada do tempo de atendimentos para cada coorte.

O número de profissionais necessários para o controle foi estimado como sendo o número mínimo de profissionais que promovel o controle da fila no tempo determinado (Ex.: Número de profissionais necessários para controlar a fila em 6 meses). O número de profissionais necessários para mantero o controle foi calculado como aquele suficientes para realizar o volume da demanda de manutenção ([**demanda recorrente** * (1 + **taxa de retorno**)]-(**demanda recorrente** * **taxa de falta**)).

## Avaliação das Projeções

Esse algoritmo terá a aderência de suas projeções avaliada projeto-piloto com dados reais até julho de 2022. 

## Termo de Responsabilidade

Os dados constantes nesse painél encontram-se sob validação e sua utilização, bem como a utilização de qualquer parte do código, ocorre sob total responsabilidade do usuário.



