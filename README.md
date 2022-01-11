# Projeção de Tempo de Fila para Consultas e Procedimentos em Saúde

A análise de recursos necessários para controle do tempo de filas para consultas e procedimentos em saúde pode auxiliar na prestação de serviços em tempo oportuno e no controle de desperdício, evitando-se que se tenham prestadores em excesso ou em falta. Essa aplicação visa a ajudar os gestores de saúde na análise do número de consultas e procedimentos necessários para manterem o tempo de espera dos procedimentos sob controle. Para tanto, utilizamos os seguintes **parâmetros** calculados para cada consulta ou procedimento:

-_Taxa de retorno_  = número de retornos em um dado mês/número de solicitações no mesmo mês<br />
-_Taxa de falta_  = número de faltas em um dado mês/número de solicitações no mesmo mês<br />
-_Fila atual_ = número de pacientes na fila no último dia de uma dado mês<br />
-Demanda = número de solicitações em um dado mês<br />

Esses parâmetros precisam ser calculados a partir de dados reais da instituição de saúde. São utilizadas, ainda, as seguntes **variáveis**: 

-_Profissionais_ = número de profissionais em um dado mês <br />
-_Consultas_ = número de consultas (or procedimentos) que um profissional é capaz de realizar em um dado mês <br />

As variáveis são utilizadas para calcular a capacidade de atendimento (_Profissionais_ x _Consultas_) e devem ser preenchidas pelo gestor para encontrar o tempo de fila desejado.

Para se projetar o tempo de fila em meses, utilizaram-se as seguintes equações:

dAtendimento/dT = se(Fila atual > Capacidade, Capacidade, Fila atual) x (1-Taxa de Falta) <br /> 
dAlta/dT = (1-Taxa de Retorno) x se(Fila atual > Capacidade, Capacidade, Fila atual) x (1-Taxa de Falta) <br /> 
dRetorno/dT = (1-Taxa de Retorno) x se(Fila atual > Capacidade, Capacidade, Fila atual) x (1-Taxa de Falta) <br /> 
dFila/dt <- Demanda + Retorno - se(Fila atual > Capacidade, Capacidade, Fila atual) <br />

A duração em meses do tempo de espera é dada pela divisão do número de pessoas na **Fila** pelos **Atendimentos**. As projeções são realizadas para 60 meses.


