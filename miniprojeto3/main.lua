local mqtt = require("mqtt_library")
local gui_objects = require("gui_objects")
local json = require("json")

-- Variáveis
topico = ''
mensagem = ''
mensagem_raw = ''

local mqtt_nome_cliente = "cliente_love"

local PedidoLocal_CanalEnvio = "requisicao_geolocalizacao"
local PedidoLocal_CanalEndereco = "requisicao_endereco"
local PedidoLocal_CanalResposta = "requisicao_geolocalizacao_r"
local PedidoLocal_CanalEnvio_textbox = nil
local PedidoLocal_CanalResposta_textbox = nil
local PedidoLocal_CanalEnderecoEnvio_textbox = nil
local PedidoLocal_CanalCoordenadas_textbox = nil
local PedidoLocal_Pedir_button = nil
local PedidoLocal_PedirEndereco_button = nil
-- 0=ok, 1=aguardando, 2=timeout, 3=abortado 
local PedidoLocal_flag = 0
local PedidoLocal_timerFlag = 0

local Monitoramento_Canal = "Nenhum"
local Monitoramento_Canal_textbox = nil
local Monitoramento_Mudar_button = nil

local APIKey_Chave_textbox = nil
local APIKey_Canal_textbox = nil
local APIKey_Mudar_button = nil

-- Funções
--  GUI
--    Pedido de Localização
local function PedidoLocal_Pedir()
  PedidoLocal_flag = 1
  -- sai do antigo canal de resposta
  mqtt_client:unsubscribe({PedidoLocal_CanalResposta})
  -- obtem novos canais
  PedidoLocal_CanalEnvio = PedidoLocal_CanalEnvio_textbox.getText()
  PedidoLocal_CanalResposta = PedidoLocal_CanalResposta_textbox.getText()
  -- se vazio coloca como Nenhum
  if PedidoLocal_CanalEnvio == "" then PedidoLocal_CanalEnvio = "Nenhum" end
  if PedidoLocal_CanalResposta == "" then PedidoLocal_CanalResposta = "Nenhum" end
  -- se inscreve no canal de resposta e publica pedido
  mqtt_client:subscribe({PedidoLocal_CanalResposta})
  mqtt_client:publish(PedidoLocal_CanalEnvio, PedidoLocal_CanalResposta)
end
local function PedidoLocal_PedirEndereco()
  local coordenadas = PedidoLocal_CanalCoordenadas_textbox.getText()
  if coordenadas then
    PedidoLocal_flag = 1
    -- sai do antigo canal de resposta
    mqtt_client:unsubscribe({PedidoLocal_CanalResposta})
    -- obtem novos canais
    PedidoLocal_CanalEndereco = PedidoLocal_CanalEnderecoEnvio_textbox.getText()
    PedidoLocal_CanalResposta = PedidoLocal_CanalResposta_textbox.getText()
    -- se vazio coloca como Nenhum
    if PedidoLocal_CanalEndereco == "" then PedidoLocal_CanalEnderecoEnvio = "Nenhum" end
    if PedidoLocal_CanalResposta == "" then PedidoLocal_CanalResposta = "Nenhum" end
    -- se inscreve no canal de resposta e publica pedido
    mqtt_client:subscribe({PedidoLocal_CanalResposta})
    mqtt_client:publish(PedidoLocal_CanalEndereco, coordenadas..";"..PedidoLocal_CanalResposta)
  else
    mensagem = "Você precisa ter inserido ou obtido coordenadas antes de pedir um endereço."
  end
end
local function PedidoLocal_Abortar()
  mqtt_client:unsubscribe({PedidoLocal_CanalResposta})
  PedidoLocal_flag = 3
  PedidoLocal_timerFlag = 0
end


--    Monitoramento
local function Monitoramento_Mudar()
  -- remove inscrição no canal antigo e obtem novo canal
  mqtt_client:unsubscribe({Monitoramento_Canal})
  Monitoramento_Canal = Monitoramento_Canal_textbox.getText()
  -- trata caso vazio para evitar erro do mqtt handler
  if Monitoramento_Canal == "" then Monitoramento_Canal = "Nenhum" end
  --inscreve no novo canal
  mqtt_client:subscribe({Monitoramento_Canal})
end

--    API Key
local function APIKey_Mudar()
  local canal_envio = APIKey_Canal_textbox.getText()
  if canal_envio == "" then canal_envio = "Nenhum" end
  mqtt_client:publish(canal_envio, APIKey_Chave_textbox.getText())
end

--  MQTT 
function mqtt_cb(topic, message)
  -- se foi um pedido apaga loading
  PedidoLocal_flag = 0
  PedidoLocal_timerFlag = 0
  
  topico = topic
  mensagem_raw = message
  if string.sub(message, 1, 1) == "{" then
    mensagem = json.decode(message)
    if mensagem.location ~= nil then
      PedidoLocal_CanalCoordenadas_textbox.setText(mensagem.location.lat..","..mensagem.location.lng)
    end
  elseif string.sub(message, 1, string.len("Falha")) == "Falha" then
    mensagem = message
  else 
    mensagem = "Erro desconhecido. Detalhes: " .. message
  end
  if topic == Monitoramento_Canal then
    print(Monitoramento_Canal)
  elseif topic == PedidoLocal_CanalResposta then
    print(PedidoLocal_CanalResposta)
  end
end

function mqtt_conect(nome_conexao)
  mqtt_client = mqtt.client.create("test.mosquitto.org", 1883, mqtt_cb)
  mqtt_client:connect(nome_conexao)
end

--  LOVE
function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  love.graphics.setBackgroundColor(255,255,255)
  
  mqtt_conect(mqtt_nome_cliente)
  
  APIKey_Canal_textbox = gui_objects:newTextbox(10, 70, "requisicao_alterar_chave")
  APIKey_Chave_textbox = gui_objects:newTextbox(220, 70, "aeeRE25KAOVMTPEQS")
  APIKey_Mudar_button = gui_objects:newButton(430, 70, "Enviar")
  
  Monitoramento_Canal_textbox = gui_objects:newTextbox(10, (love.graphics.getHeight()/5) + 80, "NodeMCU")
  Monitoramento_Mudar_button = gui_objects:newButton(220, (love.graphics.getHeight()/5) + 80, "Alterar Canal")
  
  PedidoLocal_CanalEnvio_textbox = gui_objects:newTextbox(10, (love.graphics.getHeight()/5)*2 + 90, PedidoLocal_CanalEnvio)
  PedidoLocal_CanalResposta_textbox = gui_objects:newTextbox(220, (love.graphics.getHeight()/5)*2 + 90, PedidoLocal_CanalResposta)
  PedidoLocal_Pedir_button = gui_objects:newButton(430, (love.graphics.getHeight()/5)*2 + 90, "Pedir Localização")
  PedidoLocal_CanalEnderecoEnvio_textbox = gui_objects:newTextbox(10, (love.graphics.getHeight()/5)*2 + 140, PedidoLocal_CanalEndereco)
  PedidoLocal_CanalCoordenadas_textbox = gui_objects:newTextbox(220, (love.graphics.getHeight()/5)*2 + 140, "-22.45,-44.324")
  PedidoLocal_PedirEndereco_button = gui_objects:newButton(430, (love.graphics.getHeight()/5)*2 + 140, "Pedir Endereco")
end

function love.update(dt)
  mqtt_client:handler()
  
  -- Elementos de interface
  Monitoramento_Canal_textbox.update(dt)
  Monitoramento_Mudar_button:update(dt)
  
  PedidoLocal_CanalEnvio_textbox.update(dt)
  PedidoLocal_CanalResposta_textbox.update(dt)
  PedidoLocal_CanalCoordenadas_textbox.update(dt)
  PedidoLocal_Pedir_button:update(dt)
  PedidoLocal_CanalEnderecoEnvio_textbox.update(dt)
  PedidoLocal_CanalCoordenadas_textbox.update(dt)
  PedidoLocal_PedirEndereco_button:update(dt)
  
  APIKey_Canal_textbox.update(dt)
  APIKey_Chave_textbox.update(dt)
  APIKey_Mudar_button:update(dt)
  
  -- flag envio
  if PedidoLocal_flag == 1 then
    PedidoLocal_timerFlag = PedidoLocal_timerFlag + dt
    if PedidoLocal_timerFlag > 180 then
      PedidoLocal_flag = 2
      PedidoLocal_timerFlag = 0
    end
  end
end

function love.draw()
  love.graphics.setColor(0, 0, 0)
  
  -- Seleção de chave da API
  love.graphics.print("Geolocation API", 10, 10, 0, 2, 2)
  love.graphics.print("-----------------------------------------------", 10, 30)
  love.graphics.printf("Canal para envio da chave:", 10, 50, 200, "left", 0, 1, 1)
  APIKey_Canal_textbox.draw()
  love.graphics.printf("Chave:", 220, 50, 200, "left", 0, 1, 1)
  APIKey_Chave_textbox.draw()
  APIKey_Mudar_button.draw()
  
  -- Seleção de canal de monitoramento
  love.graphics.print("Monitoramento de Canal", 10, (love.graphics.getHeight()/5) + 10, 0, 2, 2)
  love.graphics.print("--------------------------------------------------------------------------", 10, (love.graphics.getHeight()/5) + 30)
  love.graphics.print("Canal selecionado: " .. Monitoramento_Canal, 10, (love.graphics.getHeight()/5) + 50, 0, 1.5, 1.5)
  Monitoramento_Canal_textbox.draw()
  Monitoramento_Mudar_button.draw()
  
  -- Seleção de canal de pedido de envio de localização
  love.graphics.print("Pedido de localização", 10, (love.graphics.getHeight()/5)*2 + 10, 0, 2, 2)
  love.graphics.print("----------------------------------------------------------------", 10, (love.graphics.getHeight()/5)*2 + 30)
  love.graphics.printf("Canais para envio do pedido de localização e de endereço:", 10, (love.graphics.getHeight()/5)*2 + 50, 200, "left", 0, 1, 1)
  PedidoLocal_CanalEnvio_textbox.draw()
  love.graphics.printf("Canal para monitoramento da reposta e coordenadas:", 220, (love.graphics.getHeight()/5)*2 + 50, 200, "left", 0, 1, 1)
  PedidoLocal_CanalResposta_textbox.draw()
  PedidoLocal_Pedir_button.draw()
  PedidoLocal_CanalEnderecoEnvio_textbox.draw()
  PedidoLocal_CanalCoordenadas_textbox.draw()
  PedidoLocal_PedirEndereco_button.draw()
  love.graphics.print("Timeout: 180 segundos.", 430, (love.graphics.getHeight()/5)*2 + 50, 0, 1, 1)
  love.graphics.print("Aperte 'F2' para abortar.", 430, (love.graphics.getHeight()/5)*2 + 70, 0, 1, 1)
  
  -- Resposta
  love.graphics.print("Última resposta recebida:", 10, (love.graphics.getHeight()/5)*3 + 64, 0, 2, 2)
  love.graphics.print("-----------------------------------------------------------------------------", 10, (love.graphics.getHeight()/5)*3 + 90)
  if PedidoLocal_flag == 1 then
    local timer = math.floor(PedidoLocal_timerFlag)
    love.graphics.print("Aguardando resposta do pedido de localização (" .. timer .. " seg)..." , 10, (love.graphics.getHeight()/5)*3 + 110, 0, 1.5, 1.5)
  elseif PedidoLocal_flag == 2 then
    love.graphics.print("O tempo do pedido de localização expirou, tente novamente." , 10, (love.graphics.getHeight()/5)*3 + 110, 0, 1.5, 1.5)
  elseif PedidoLocal_flag == 3 then
    love.graphics.print("Pedido de localização abortado." , 10, (love.graphics.getHeight()/5)*3 + 110, 0, 1.5, 1.5)
  else
    love.graphics.print("Canal: ", 10, (love.graphics.getHeight()/5)*3 + 110, 0, 1.5, 1.5)
    love.graphics.printf(topico, 75, (love.graphics.getHeight()/5)*3 + 113, love.graphics.getWidth() - 10, "left", 0, 1.25, 1.25)
    love.graphics.print("Mensagem: ", 10, (love.graphics.getHeight()/5)*3 + 140, 0, 1.5, 1.5)
    if type(mensagem) == "table" then
      local posY = (love.graphics.getHeight()/5)*3 + 143
      if mensagem.error ~= nil then
        -- Código e mensagem de erro
        love.graphics.print("Erro", 120, posY, 0, 1.25, 1.25)
        posY = posY + 20
        love.graphics.print("Código: " .. mensagem.error.code .. " - " .. mensagem.error.message, 120, posY, 0, 1.25, 1.25)
        posY = posY + 20
        -- Domínio e razão
        love.graphics.print("Domain:", 120, posY, 0, 1.25, 1.25)
        for i=1, #(mensagem.error.errors), 1 do
          love.graphics.print(mensagem.error.errors[i].domain, 200, posY, 0, 1.25, 1.25)
          posY = posY + 20
        end
        love.graphics.print("Reason:", 120, posY, 0, 1.25, 1.25)
        for i=1, #(mensagem.error.errors), 1 do
          love.graphics.print(mensagem.error.errors[i].reason, 200, posY, 0, 1.25, 1.25)
          posY = posY + 20
        end
      elseif mensagem.location ~= nil then
        -- tratar sucesso
        love.graphics.print("Latitude: ", 120, posY, 0, 1.25, 1.25)
        love.graphics.print(mensagem.location.lat .. "º", 210, posY, 0, 1.25, 1.25)
        posY = posY + 20
        love.graphics.print("Longitude: ", 120, posY, 0, 1.25, 1.25)
        love.graphics.print(mensagem.location.lng .. "º", 210, posY, 0, 1.25, 1.25)
        posY = posY + 20
        love.graphics.print("Precisão: ", 120, posY, 0, 1.25, 1.25)
        love.graphics.print(mensagem.accuracy .. " m", 210, posY, 0, 1.25, 1.25)
      else
        love.graphics.print("Endereço: ", 120, posY, 0, 1.25, 1.25)
        love.graphics.print(mensagem.results[1].formatted_address, 210, posY, 0, 1.25, 1.25)
      end
    else
      -- valor inesperado
      love.graphics.printf(mensagem, 120, (love.graphics.getHeight()/5)*3 + 143, love.graphics.getWidth() - 10, "left", 0 , 1.25, 1.25)
    end
  end
end

function love.keypressed(key)
  if key == 'escape' then
    love.event.quit(0)
  end
  if key == 'f1' then
    mqtt_client:publish(Monitoramento_Canal, "Teste Local")
  end
  if key == 'f2' then
    PedidoLocal_Abortar()
  end
end

function love.mousereleased(x, y, key)
  Monitoramento_Canal_textbox.trigger(key)
  PedidoLocal_CanalEnvio_textbox.trigger(key)
  PedidoLocal_CanalResposta_textbox.trigger(key)
  PedidoLocal_CanalEnderecoEnvio_textbox.trigger(key)
  PedidoLocal_CanalCoordenadas_textbox.trigger(key)
  APIKey_Canal_textbox.trigger(key)
  APIKey_Chave_textbox.trigger(key)
  
  Monitoramento_Mudar_button.mousereleased()
  PedidoLocal_Pedir_button.mousereleased()
  PedidoLocal_PedirEndereco_button.mousereleased()
  APIKey_Mudar_button.mousereleased()
  if Monitoramento_Mudar_button.mouseSobre() then Monitoramento_Mudar() end
  if PedidoLocal_Pedir_button.mouseSobre() then PedidoLocal_Pedir() end
  if PedidoLocal_PedirEndereco_button.mouseSobre() then PedidoLocal_PedirEndereco() end
  if APIKey_Mudar_button.mouseSobre() then APIKey_Mudar() end
end

function love.textinput(text)
  Monitoramento_Canal_textbox.textinput(text)
  PedidoLocal_CanalEnvio_textbox.textinput(text)
  PedidoLocal_CanalResposta_textbox.textinput(text)
  PedidoLocal_CanalEnderecoEnvio_textbox.textinput(text)
  PedidoLocal_CanalCoordenadas_textbox.textinput(text)
  APIKey_Canal_textbox.textinput(text)
  APIKey_Chave_textbox.textinput(text)
end
