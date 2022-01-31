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

Foram estabelecidas, ainda, 60 iterações para simulação.

O modelo utilizado para o cálculo é o que se segue:

![image](https://user-images.githubusercontent.com/21002844/151796497-7dfbc805-778c-4ddc-847e-3274301b1dd2.png)


