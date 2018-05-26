-- Variaveis globais da aplicacao
---- Variavel contendo a chave para obter a localizacao com o Google
local chave = "AIzaSyDd7BIfb1wjikYXcitNt_wMwQXcz9jxqYw"

---- Variaveis para configuracao e conexao wifi
local configurar_rede = true
local usuario = ""
local senha = ""
    
---- Variaveis para configuracao do servidor mosquitto
local topico_requisicao_geolocalizacao = "requisicao_geolocalizacao"
local topico_geolocalizacao = "geolocalizacao"
local alterar_chave = "alterar_chave"
local nodemcu_topicos = {
    [topico_requisicao_geolocalizacao]=0, 
    [alterar_chave]=1
}
local mqtt_client = nil
local nome_cliente = "cliente_nodemcu"

---- Variaveis para configuracao do nodemcu
local led1 = 3
local led2 = 6


-- Funcoes gerais do projeto
---- Funcao responsavel por criar callbacks genericas para uso comum.
---- Pode receber um callback custom, caso desejar.
local callback_simples = function(mensagem, custom_function)
    return function(response)
        print(mensagem)
        if custom_function == nil then
            if type(response) == "table" then
                for key, value in pairs(response) do
                    print(key .. ', ' .. value)
                end
            end
        else
            custom_function(response)
        end
    end
end


-- Funcoes responsaveis pelas conexoes wifi
---- Funcao responsavel por configurar o wifi com o login e senha passados nas variaveis globais
local configurar_wifi = function()
    local config = {
        ssid = usuario,
        pwd = senha,
        save = true,
        got_ip_cb = callback_simples("Configuração bem sucedida! Maiores informações abaixo:")
    }
    wifi.setmode(wifi.STATION)
    wifi.sta.config(config)
    wifi.sta.autoconnect(1)
end

---- Funcao responsavel por conectar no wifi configurado
local conectar_wifi = function()
    wifi.sta.connect(callback_simples("Conexão bem sucedida! Maiores informações abaixo:"))
end

---- Funcao responsavel por desconectar do wifi conectado
local desconectar_wifi = function()
    wifi.sta.disconnect(callback_simples("Desconexão bem sucedida! Maiores informações abaixo:"))
end


-- Funcoes responsavel pelas localizacoes
---- Funcao responsavel por enviar o pedido para o servidor Google.
---- Recebe como parametro uma string contendo todos os wifis da redondeza e
---- um topico para respostas ao cliente que efetuou o pedido.
local obter_geolocalizacao = function(wifi_tables, topico)
    local url = "https://www.googleapis.com/geolocation/v1/geolocate?key=" .. chave
    local headers = "Content-Type: application/json\r\n"
    local body = '{"considerIp": "false","wifiAccessPoints": [' .. wifi_tables .. ']}'
    local response = function(code, data)
        local resposta_mensagem = ""
        local resposta_callback = nil
        if (code < 0) then
            resposta_mensagem = "Falha no pedido de geolocalizacao. Codigo: " .. code
            resposta_callback = callback_simples("Resposta de erro enviada")
        else
            resposta_mensagem = data
            resposta_callback = callback_simples("Resposta com a localizacao enviada")
        end
        print(resposta_mensagem)
        mqtt_client:publish(
            topico,
            resposta_mensagem,
            0,
            0,
            resposta_callback
        )
        gpio.write(led1, gpio.LOW)
    end
    http.post(url, headers, body, response)
end

---- Funcao responsavel por montar uma string de wifis da redondeza e passar para a funcao responsavel por obter a localizacao
local solicitar_geolocalizacao = function(topico)
    gpio.write(led1, gpio.HIGH)
    local callback = function(tabela)
        local wifi_tables = ""
        for key, value in pairs(tabela) do
            local _, signalStrength, macAddress, channel = string.match(value, "([^,]+),([^,]+),([^,]+),([^,]+)")
            wifi_table = '{"macAddress": "' .. macAddress .. '","signalStrength": ' .. signalStrength .. ', "channel": ' .. channel .. '},'
            wifi_tables = wifi_tables .. wifi_table
            print(key, value)
        end
        wifi_tables = string.sub(wifi_tables, 1, #wifi_tables-1) -- Remove a virgula do final
        obter_geolocalizacao(wifi_tables, topico)
    end
    wifi.sta.getap(callback_simples("Obtenção de wifis bem sucedida! Maiores informações abaixo:", callback))
end


-- Funcoes responsaveis pela comunicacao com o servidor mosquitto
---- Funcao responsavel por enviar mensagens para topicos especificados por parametro
local enviar_mensagem = function(topico, mensagem, callback)
    if callback == nil then
        callback = callback_simples("Mensagem enviada!")
    end
    mqtt_client:publish(topico, mensagem, 0, 0, callback)
end

---- Funcao responsavel por se inscrever nos topicos presentes na variavel global noemcu_topicos e
---- enviar uma mensagem a todos eles informando que o node esta pronto para receber mensagens
local seguir_topicos = function()
    local subscribeCallback = function(client)
        print("Inscricoes efetuadas com sucesso!")
        local messageCallback = function(cliente, topico, mensagem)
            print("Mensagem recebida! Detalhes: Topico->".. topico .. ", Mensagem->" .. mensagem)
            if topico == topico_requisicao_geolocalizacao then
                solicitar_geolocalizacao(mensagem)
            elseif topico == alterar_chave then
                chave = mensagem
                print("Chave alterada com sucesso!")
            end
        end
        mqtt_client:on("message", messageCallback)
    end
    mqtt_client:subscribe(nodemcu_topicos, subscribeCallback)
    --for topico, qos in pairs(nodemcu_topicos) do
    --    enviar_mensagem(topico, "Pronto para receber pedidos!")
    --end
end

---- Funcao responsavel por conectar ao servidor mosquitto, 
---- seguindo todos os topicos citados na variavel global caso tenha havido êxito
local conectar_servidor = function()
    local successCallback = function(client)
        print("Conectado com sucesso!")
        seguir_topicos() -- Função para seguir todos os topicos adicionados na tabela nodemcu_topicos
    end
    local errorCallback = function(client, reason)
        print("Erro ao tentar se conectar. Reason: "..reason)
    end
    mqtt_client:connect("test.mosquitto.org", 1883, 0, successCallback, errorCallback)
end


-- Funcao responsavel por inicializar todos os itens necessarios da aplicacao
local setup = function()
    -- Configuracao da conexao wifi
    if configurar_rede then
        configurar_wifi()
    end

    -- Inicializacao dos LEDs
    gpio.mode(led1, gpio.OUTPUT)
    gpio.mode(led2, gpio.OUTPUT)
    gpio.write(led2, gpio.LOW)
    gpio.write(led1, gpio.LOW)
    
    -- Inicializaca�o doa botoes
    gpio.mode(1,gpio.INT,gpio.PULLUP)
    gpio.mode(2,gpio.INT,gpio.PULLUP)

    -- Inicializacao do servidor mosquito
    mqtt_client = mqtt.Client(nome_cliente, 120)
    conectar_servidor()
end
setup()

local get_localization_button_callback = function()
    solicitar_geolocalizacao(topico_geolocalizacao)
end
gpio.trig(1, "down", get_localization_button_callback)
