# Despertador

#### Fazendo-se uso de interrupção e variaveis de estado para controlar o fluxo de códico

## Descrição

O sistema começa totalmente zerado, porem, funcional. Ou seja, você não precisa configurar o relógio para que ele funcione, pois na ligação o tempo já começa a passar, pardindo de zero. 
Atraves dos botões, configura-se as horas do relogio e despertador, alem de ativar ou desativar o despertador, sendo visivel e/ou audivel alguns feedbacks do aparelho. Inicialmente, quando todos os leds estão apagados, significa que nenhum modo de configuração está ativado, alem do despertador também estar desativado.

### Botão 1

O botão 1 é responsavel por entrar em modo de configuração do relogio ou incrementar as horas, vai depender se algum modo de configuração está ativado. Estando nenhum modo de configuração ativado, ao ser apertado, ele entra em modo de configuração do relogio, acendendo o led 1. Nesse estado, apertando-se o botão 1, incrementa-se as horas, o botão 2, incrementa-se os minutos, e o botão 3 cancela a configuração, sem salvar quaisquer alterações.

### Botão 2

Analogo ao botão 1, ele é responsavel por entrar em modo de configuração do despertador, acendendo o led 2, ou incrementar os minutos, dependendo se algum modo está ativo. Novamente, estando com seu modo de configuração ativado, pode-se alterar as horas, minutos ou cancelar a configuração, assim como no botão 1.

### Botão 3

Diferente dos outros botões, ele só é responsavel por cancelar configurações e ativar ou desativar o despertador, dependendo se há algum modo de configuração ativo no momento. Resumidamente, se algum modo de configuração estiver ativo, ao ser apertado, ele cancela quaisquer alterações e volta ao estado original, antes da configuração. Se não, ele ativa ou desativa o despertador, acendendo o led 4 caso o despertador esteja ativado.

Para que as configurações sejam salvas, é necessario aguardar dois segundos. Após esse tempo, todas as configurações serão salvas em suas respectivas areas, será emitido um alerta sonoro e então o respectivo led apagará.
