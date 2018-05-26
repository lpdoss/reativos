local mqtt = require("mqtt_library")
local gui_objects = require("gui_objects")
local json = require("json")


-- GUI
local caixa_de_texto = nil
local botao_topico = nil
local botao_pedido = nil
local tamanho_linhas = nil
local tamanho_colunas = nil


-- MQTT
local mqtt_client = nil
local nome_cliente = "cliente_love"
local topico_default = "requisicao_geolocalizacao"
local topico_default_response = "requisicao_geolocalizacao_response"
local mensagem_default = ""
local topico_usuario = ""
local topico_usuario_response = ""
local mensagem_usuario = ""

-- FUNÇÕES LOCAIS
local function PedirLocal()
  mqtt_client:publish(topico_default, topico_default_response)
end

local function MudarCanal()
  novo_topico_usuario = caixa_de_texto.getText()
  if novo_topico_usuario then
    if #topico_usuario>0 then
      mqtt_client:unsubscribe({topico_usuario})
    end
    mqtt_client:subscribe({novo_topico_usuario})
    topico_usuario = novo_topico_usuario
  end
end


-- LOVE
function love.load()
  local mqttCallback = function(t, m)
    print(t, m)
    if t == topico_default_response then
      mensagem_default = m
    elseif t == topico_usuario then
      mensagem_usuario = m
    end
  end
  mqtt_client = mqtt.client.create("test.mosquitto.org", 1883, mqttCallback)
  mqtt_client:connect(nome_cliente)
  mqtt_client:subscribe({topico_default_response})
  
  tamanho_linhas = love.graphics.getHeight()/10
  tamanho_colunas = love.graphics.getWidth()/2
  love.graphics.setDefaultFilter("nearest", "nearest")
  love.graphics.setBackgroundColor(255,255,255)
  caixa_de_texto = gui_objects:newTextbox(10, tamanho_linhas*2, "Topico para pedidos")
  botao_topico = gui_objects:newButton(10, tamanho_linhas*3, "Salvar topico")
  botao_pedido = gui_objects:newButton(10, tamanho_linhas*6, "Pedir localização")
end

function love.draw()
  love.graphics.setColor(0, 0, 0)
  
  -- Topicos e mensagens
  love.graphics.print("TÓPICO USUARIO: " .. topico_usuario, 10, tamanho_linhas)
  love.graphics.print("MENSAGEM: " .. mensagem_usuario, tamanho_colunas, tamanho_linhas)
  love.graphics.print("TÓPICO DEFAULT: " .. topico_default, 10, tamanho_linhas*5)
  love.graphics.print("MENSAGEM: " .. mensagem_default, tamanho_colunas, tamanho_linhas*5)
  
  -- Caixa de texto e botoes
  caixa_de_texto.draw()
  botao_topico.draw()
  botao_pedido.draw()
end

function love.update(dt)
  mqtt_client:handler()  
end

function love.keypressed(key)
  if key == 'escape' then
    love.event.quit(0)
  end
  
  
  -- Se ativa apaga o texto da caixa
  caixa_de_texto.keypressed(key)
end

function love.mousepressed(x, y, key)
  botao_pedido_clicado = botao_pedido.mousepressed(x, y, key)
  botao_topico_clicado = botao_topico.mousepressed(x, y, key)
  
  caixa_de_texto.trigger(key)
    if botao_pedido_clicado then
      PedirLocal()
    end
    if botao_topico_clicado then
      MudarCanal()
    end
end

function love.mousereleased( x, y, key)
  botao_pedido.mousereleased(x, y, key)
  botao_topico.mousereleased(x, y, key)
end

function love.textinput(text)
  caixa_de_texto.textinput(text)
end
