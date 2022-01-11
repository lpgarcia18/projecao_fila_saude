# Projeção de Tempo de Fila para Consultas e Procedimentos em Saúde

A análise de recursos necessários para controle do tempo de filas para consultas e procedimentos em saúde pode auxiliar na prestação de serviços em tempo oportuno e no controle de desperdício, evitando-se que se tenham prestadores em excesso ou em falta. Essa aplicação visa a ajudar os gestores de saúde na análise do número de consultas e procedimentos necessários para manterem o tempo de espera dos procedimentos sob controle. Para tanto, utilizamos os seguintes parâmetros calculados para cada consulta ou procedimento:

-Taxa de retorno  = número de retornos em um dado mês/número de solicitações no mesmo mês<br />
-Taxa de falta  = número de faltas em um dado mês/número de solicitações no mesmo mês<br />
-Fila atual = número de pacientes na fila no último dia de uma dado mês<br />
-Demanda = número de solicitações em um dado mês<br />

Esses parâmetros precisam ser calculados a partir de dados reais da instituição de saúde. São utilizadas, ainda, as seguntes variáveis: 

-Profissionais = número de profissionais em um dado mês <br />
-Consultas = número de consultas (or procedimentos) que um profissional é capaz de realizar em um dado mês <br />


