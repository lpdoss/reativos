local mqtt = require("mqtt_library")
local gui_objects = require("gui_objects")
local json = require("json")

topico = ''
mensagem = ''

-- Botões e ações
local button_PedirLocal
local CanalPedidoLocal = "nodemcu_casa_meier"
local CanalRespostaLocal = "testes_casa_meier_resposta"
local function PedirLocal()
  mqtt_client:publish(CanalPedidoLocal, CanalRespostaLocal)
end

local textbox_NovoCanal = nil
local CanalEscolhido = "Nenhum"

local button_MudarCanal
local function MudarCanal()
  mqtt_client:unsubscribe({CanalEscolhido})
  CanalEscolhido = textbox_NovoCanal.getText()
  if CanalEscolhido == "" then
    CanalEscolhido = "Nenhum"
  end
  mqtt_client:subscribe({CanalEscolhido})
end




-- Callback executa no recebimento de uma mensagem
function mqttcb(topic, message)
    topico = topic
    mensagem = message
  if topic == CanalEscolhido then
    print(CanalEscolhido)
  elseif topic == CanalRespostaLocal then
    print(CanalRespostaLocal)
  end
   
end

function love.keypressed(key)
  if key == 'escape' then
    love.event.quit(0)
  end
  if key == 'z' then
    mqtt_client:publish(CanalEscolhido, "Teste Local")
  end
  
  -- Se ativa apaga o texto da caixa
  textbox_NovoCanal.keypressed(key)
end

function love.mousepressed(x, y, key)
  textbox_NovoCanal.trigger(key)
    if button_PedirLocal.mouseSobre() then
      PedirLocal()
    end
    if button_MudarCanal.mouseSobre() then
      MudarCanal()
    end
end

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  love.graphics.setBackgroundColor(255,255,255)
  
  
  mqtt_client = mqtt.client.create("test.mosquitto.org", 1883, mqttcb)
  mqtt_client:connect("leleledafederal")
  mqtt_client:subscribe({"testes_casa_meier_resposta"})
  
  textbox_NovoCanal = gui_objects:newTextbox(10, (love.graphics.getHeight()/4), "NodeMCU")
  button_MudarCanal = gui_objects:newButton(230, (love.graphics.getHeight()/4), "Alterar Canal")
  
  button_PedirLocal = gui_objects:newButton(10, 2*(love.graphics.getHeight()/4), "Pedir Localização")
end

function love.draw()
  love.graphics.setColor(0, 0, 0)
  love.graphics.printf("Recebido do canal: " .. topico .. "\nMensagem:" .. mensagem,
    
    10, 2*(love.graphics.getHeight()/4)+60, 600, "left", 0 , 2, 2)
  
  love.graphics.print("Canal selecionado: " .. CanalEscolhido, 10, love.graphics.getHeight()/4 - 50, 0, 2, 2)
  textbox_NovoCanal.draw()
  button_MudarCanal.draw()
  
  button_PedirLocal.draw()
  love.graphics.printf("Os pedidos são enviados para '" .. CanalPedidoLocal .. "' e as respostas ouvidas em '" .. CanalRespostaLocal .. "'.",
                        150, 2*(love.graphics.getHeight()/4), 450, "left", 0, 1.5, 1.5)
end

function love.update(dt)
  mqtt_client:handler()  
end

function love.textinput(text)
  textbox_NovoCanal.textinput(text)
end
