local chave = "AIzaSyCxQP6A1zvlvIFuePn4DRJwY5CbxX7DwK0"
local usuario = ""
local senha = ""

local callback_simples = function(mensagem, custom_function)
    return function(tabela)
        print(mensagem)
        if custom_function == nil then
            for key, value in pairs(tabela) do
                print(key .. ', ' .. value)
            end
        else
            custom_function(tabela)
        end
    end
end

local configurar_wifi = function()
    local config = {
        ssid = login,
        pwd = senha,
        save = true,
        got_ip_cb = callback_simples("Configuração bem sucedida! Maiores informações abaixo:")
    }
    wifi.setmode(wifi.STATION)
    wifi.sta.config(config)
end

local conectar_wifi = function()
    wifi.sta.connect(callback_simples("Conexão bem sucedida! Maiores informações abaixo:"))
end

local desconectar_wifi = function()
    wifi.sta.disconnect(callback_simples("Desconexão bem sucedida! Maiores informações abaixo:"))
end

local obter_geolocalizacao = function(wifi_tables)
    local url = "https://www.googleapis.com/geolocation/v1/geolocate?key=" .. chave
    local headers = "Content-Type: application/json\r\n"
    local body = '{"wifiAccessPoints": [' .. wifi_tables .. ']}'
    local response = function(code, data)
        if (code < 0) then
            print("HTTP request failed: ", code)
        else
            print("Obtenção da localização bem sucedida! Maiores informações abaixo:")
            print(data)
        end
    end
    http.post(url, headers, body, response)
end

local solicitar_geolocalizacao = function()
    local callback = function(tabela)
        local wifi_tables = ""
        for key, value in pairs(tabela) do
            local _, signalStrength, macAddress, channel = string.match(value, "([^,]+),([^,]+),([^,]+),([^,]+)")
            wifi_table = '{"macAddress": "' .. macAddress .. '","signalStrength": ' .. signalStrength .. ', "channel": ' .. channel .. '},'
            wifi_tables = wifi_tables .. wifi_table
            print(key, value)
        end
        wifi_tables = string.sub(wifi_tables, 1, #wifi_tables-1)
        obter_geolocalizacao(wifi_tables)
    end
    wifi.sta.getap(callback_simples("Obtenção de wifis bem sucedida! Maiores informações abaixo:", callback))
end

local setup = function()
    configurar_wifi()
    conectar_wifi()
end
--setup()

local enviar_geolocalizacao = function()
end

local pedir_socorro = function()
    solicitar_geolocalizacao()
    print('Enviar pedido de socorro')
end
pedir_socorro()