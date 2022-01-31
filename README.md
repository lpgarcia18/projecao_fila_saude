# Projeção dos Recursos Necessários para Controle de Fila para Procedimentos em Saúde

## Introdução
A análise de recursos necessários para controle do tempo de filas para consultas e procedimentos em saúde pode auxiliar na prestação de serviços em tempo oportuno de forma a promover melhores resultados no cuidado em saúde. Esse controle é ainda fundamental para redução do desperdício dos recursos públicos, evitando-se que se tenham prestadores em excesso. Assim, essa aplicação tem como objetivo auxiliar os gestores de saúde na análise do número de rescursos necessários para atingir o controle no tempo de espera dos procedimentos e, em seguida, o número de recursos necessários para manter esse tempo sob controle. 

Sua construção foi realizada para a Secretaria de Saúde de Florianópolis e contou como apoio do Professor do Departamento de Matemática da Universidade Federal de Santa Catarina, Dr. Giuliano Boava (http://lattes.cnpq.br/4918706756138339).

A aplicação está licenciada sob GLP 3.0 (https://github.com/lpgarcia18/projecao_fila_saude/blob/main/LICENSE), de modo a permitir sua reutilização por outros municípios e o desenvolvimento conjuto. Sugestões e contribuições são muito bem vindas.

## Método


Para tanto, os seguintes **parâmetros** calculados para cada procedimento foram utilizados:

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
dRetorno/dT = Taxa de Retorno x se(Fila atual > Capacidade, Capacidade, Fila atual) x (1-Taxa de Falta) <br /> 
dFila/dt <- Demanda + Retorno - se(Fila atual > Capacidade, Capacidade, Fila atual) <br />

A duração em meses do tempo de espera é dada pela divisão do número de pessoas na **Fila** pelos **Atendimentos**. As projeções são realizadas para 60 meses.

