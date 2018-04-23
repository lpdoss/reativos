-- variaveis globais da aplicação
local bolas = {}
local bolasFora = {}
local ataques = {}
local ataquesFora = {}
local ataquesInterceptados = {}
local ataquesRecebidos = {}
local intervaloAtaques = 5
local ultimoAtaque = 0
local tolerancia = 10
local terminou = false
local clicks = 10


-- Tabelas para objetos da aplicação
--[[ bola:
    - Tabela responsável por controlar os disparos efetuados pelo personagem, cada disparo 'instancia' uma bola que vai na direção onde o mouse foi clicado. Caso esse disparo acerte o disparo inimigo, tanto a bola quanto o disparo inimigo desaparecem e é incrementado um placar de acertos.
    - X e Y recebidos como parametros equivalem as coordenadas do topo do personagem que efetuou o disparo.
    - Possui alem dos metodos draw (responsavem por desenhar o objeto na tela), update (responsavel por atualizar os atributos do objeto) e mousepressed (responsavel por tratar eventos de click do objeto), os metodos getEstaFora, que retorna se a bola saiu ou não da tela, e getLocalização, que retorna as coordenadas atuais do disparo.
]]
local bola = function(x, y)
    local x = x
    local y = y
    local velocidadeX = nil
    local velocidadeY = nil
    local altura = 10
    local largura = 10
    local deslocamento = 20
    local estaFora = false
            
    return {
        draw = function()
            love.graphics.setColor(0, 255, 0)
            love.graphics.circle("fill", x, y, largura, altura)
        end,
        update = function()
            if x>-largura and x<(love.graphics.getWidth()+largura) and y<(love.graphics.getHeight()+altura) and y>-altura then
                x = x + velocidadeX
                y = y + velocidadeY
            else
                estaFora = true
            end
        end,
        mousepressed = function(direcaoX, direcaoY)
            local angulo = math.abs(math.atan((y-direcaoY)/(direcaoX-x)))
            if direcaoX > x then
                velocidadeX = deslocamento*math.cos(angulo)
            else
                velocidadeX = -deslocamento*math.cos(angulo)
            end
            if direcaoY > y then
                velocidadeY = deslocamento*math.sin(angulo)
            else
                velocidadeY = -deslocamento*math.sin(angulo)
            end
        end,
        getEstaFora = function()
            return estaFora
        end,
        getLocalizacao = function()
            return x+(largura/2), y-(altura/2)
        end
    }
end

--[[ inimigo
    - Tabela responsável por controlar os disparos efetuados pelo inimigo. O personagem sempre é o alvo.
    - PX e PY recebidos como parametros equivalem as coordenadas do personagem.
    - Possui alem dos metodos draw e update, analogo aos outros, os metodos publicos getEstaFora, que retorna se o disparo inimigo saiu ou não da tela, e getLocalização, que retorna as coordenadas atuais do disparo inimigo. Tambem há um metodo privado iniciaVelocidades, que calcula as componentes de velocidade de deslocamento em X e Y do disparo inimigo.
]]
local inimigo = function(px, py)
    local x = math.random(0, love.graphics.getWidth())
    local y = 0
    local destinoX = px
    local destinoY = py
    local altura = 10
    local largura = 10
    local deslocamento = 5
    local estaFora = false
    local velocidadeX = nil
    local velocidadeY = nil
    
    -- metodos privados
    local iniciaVelocidades = function()
        local angulo = math.abs(math.atan((y-destinoY)/(x-destinoX)))
        if destinoX > x then
            velocidadeX = deslocamento*math.cos(angulo)
        else
            velocidadeX = -deslocamento*math.cos(angulo)
        end
        if destinoY > y then
            velocidadeY = deslocamento*math.sin(angulo)
        else
            velocidadeY = -deslocamento*math.sin(angulo)
        end
    end
    iniciaVelocidades()
    
    -- metodos publicos
    return {
        draw = function()
            love.graphics.setColor(255, 0, 0)
            love.graphics.circle("fill", x, y, largura, altura)
        end,
        update = coroutine.wrap(function()
            while true do
                if x>-largura and x<(love.graphics.getWidth()+largura) and y<(love.graphics.getHeight()+altura) and y>-altura then
                    x = x + velocidadeX
                    y = y + velocidadeY
                else
                    estaFora = true
                end
                coroutine.yield()
            end
        end),
        getEstaFora = function()
            return estaFora
        end,
        getLocalizacao = function()
            return x+(largura/2), y-(altura/2)
        end
    }
end

--[[ personagem
    - Elemento principal do jogo, controlado pelas teclas w (cima), a (esquerda), s (baixo) e d (direita), alem dos disparos efetuados pelo mouse. Pode se mover por todos os cantos da tela, apenas na tela. Esse personagem possui até 4 unidades de saude, que quando atinge zero, finaliza o jogo.
    - Alem dos metodos draw, update e keypressed, possui os metodos getLocalizacao, decrementarSaude (que diminui uma unidade de saude do personagem), getSaude (que retorna a atual unidade de saude do personagem) e resetarPersonagem (que repõe os atributos iniciais do personagem).
]]
local personagem = function()
    local x = love.graphics.getWidth()/2
    local y = love.graphics.getHeight()
    local altura = 20
    local largura = 10
    local deslocamento = 15
    local saude = 4
            
    return {    
        draw = function()
            love.graphics.setColor(0, 0, 200)
            love.graphics.rectangle("fill", x, y-altura, largura, altura)
        end,
        update = function(dt)
        end,
        keypressed = function()
            if love.keyboard.isDown('a') and x > 0 then
                x = x - deslocamento
            end
            if love.keyboard.isDown('d') and (x+largura) < love.graphics.getWidth() then
                x = x + deslocamento
            end
            if love.keyboard.isDown('w') and (y-altura) > 0 then
                y = y - deslocamento
            end
            if love.keyboard.isDown('s') and y<love.graphics.getHeight() then
                y = y + deslocamento
            end
        end,
        getLocalizacao = function()
            return x+(largura/2), y-(altura)
        end,
        decrementarSaude = function()
            saude = saude - 1
        end,
        getSaude = function()
            return saude
        end,
        resetarPersonagem = function()
            x = love.graphics.getWidth()/2
            y = love.graphics.getHeight()
            saude = 4
        end
    }
end

--[[ placar
    - Tabela responsavel por exibir o tempo decorrido, os disparos acertados no inimigo e os records ao termino das partidas, caso haja um novo.
    - Possui os metodos draw, que é analogo aos outros, porem com o parametro saude do personagem, update (que só incrementa o tempo caso a partida esteja rolando), incrementarAcertps (que aumenta uma unidade a quantidade de acertos), resetarPlacar (que volta os atributos aos valores iniciais) e getAcertos (que retorna a quantidade de acertos do personagem).
]]
local placar = function()
    local x = 10
    local y = 10
    local tempo = 0
    local tempoRecord = 0
    local acertos = 0
    local acertosRecord = 0
    local houveTempoRecord = false
    local houveAcertosRecord = false
    
    local terminarPartida = function()
        if tempo*acertos > tempoRecord then            
            tempoRecord = tempo*acertos
            houveTempoRecord = true
        end
        if acertos > acertosRecord then
            acertosRecord = acertos
            houveAcertosRecord = trued
        end
    end
    
    return {
        draw = function(saude)
            love.graphics.setColor(0,0,0)
            love.graphics.print(string.format('Tempo decorrido: %.2f', tempo), x, y, 0, 1.2)
            love.graphics.print(string.format('Núm. de acertos: %d', acertos), x, y+22, 0, 1.2)
            love.graphics.print(string.format('Saúde: %d', saude), love.graphics.getWidth()-120, 10, 0, 2)
            if terminou then
                love.graphics.print(string.format('Fim de jogo! Dê %d click(s) para voltar...', clicks), 10, love.graphics.getHeight()/2 - 60, 0, 3)
                terminarPartida()
            end
            if houveTempoRecord then
                love.graphics.print(string.format('Novo Record -> Tempo sobrevivido + bonus de acertos: %.2f', tempoRecord), 10, love.graphics.getHeight()/2, 0, 1.6)
            end
            if houveAcertosRecord then
                love.graphics.print(string.format('Novo Record -> Núm. de acertos: %d', acertosRecord), 10, love.graphics.getHeight()/2 + 60, 0, 1.6)
            end
        end,
        update = function(dt)
            if terminou==false then
                tempo = tempo + dt
            end
        end,
        incrementarAcertos = function()
            acertos = acertos + 1
            if acertos > 0 and acertos % 5 == 0 and intervaloAtaques > 1 then -- no minimo, deixar esperar 1 segundo para o proximo ataque inimigo
                intervaloAtaques = intervaloAtaques - 1
            end
        end,
        resetarPlacar = function()
            tempo = 0
            acertos = 0
            houveTempoRecord = false
            houveAcertosRecord = false
        end,
        getAcertos = function()
            return acertos
        end
    }
end



--[[
    Função responsavel por iterar sobre a localização dos objetos renderizados na tela e adicionar a respectiva tabela se houve colisão entre os disparos ou colisão entre o disparo inimigo e o personagem.
]]
local procurarColisoes = function()
    for j=1,#ataques do
        local ataquex, ataquey = ataques[j].getLocalizacao()
        local personagemx, personagemy = personagem.getLocalizacao()
        if math.abs(personagemx-ataquex)<tolerancia and math.abs(personagemy-ataquey)<tolerancia then
            table.insert(ataquesRecebidos, j)
        else
            for i=1,#bolas do
                local bolax, bolay = bolas[i].getLocalizacao()
                if math.abs(bolax-ataquex)<tolerancia and math.abs(bolay-ataquey)<tolerancia then
                    table.insert(ataquesInterceptados, {i, j})
                end
            end
        end
    end
end

--[[
    Função responsavel por iterar sobre as tabelas de colisões e remoção dos objetos colididos, com exceção do personagem, que é decrementado a saude até que não tenha mais, finalizando a partida.
]]
local removerColididos = function()
    for i=1,#ataquesInterceptados do
        table.remove(bolas, ataquesInterceptados[i][1])
        table.remove(ataques, ataquesInterceptados[i][2])
        placar.incrementarAcertos()
    end
    ataquesInterceptados = {}
    
    for i=1,#ataquesRecebidos do
        if personagem.getSaude()>1 then
            personagem.decrementarSaude()
        else
            personagem.decrementarSaude()
            terminou = true
        end
        table.remove(ataques, ataquesRecebidos[i])
    end
    ataquesInterceptados = {}
    ataquesRecebidos = {}
end

--[[
    Função responsavel por resetar os objetos principais do jogo, ou seja, o personagem e o placar, alem de atribuir o valor false a variavel terminou, que é a variavel de estado responsavel por manter alguns updates rodando, alem do tempo de espera entre os ataques inimigos.
]]
local novaPartida = function()
    personagem.resetarPersonagem()
    placar.resetarPlacar()
    intervaloAtaques = 5
    clicks = 10
    terminou = false
end



-- metodos principais da aplicação
--[[
    Metodo que carrega os principais elementos do jogo
]]
function love.load()
    love.graphics.setBackgroundColor(255,255,255)
    love.keyboard.setKeyRepeat(true)
    personagem = personagem()
    placar = placar()
end

--[[ Metodo responsavel por atualizar as informações dos elementos do jogo ]]
function love.update(dt)
    if terminou == false then
        -- atualiza o personagem
        personagem.update(dt)
        placar.update(dt)
        
        ultimoAtaque = ultimoAtaque + dt
        if ultimoAtaque > intervaloAtaques then  
            ultimoAtaque = 0
            table.insert(ataques, inimigo(personagem.getLocalizacao()))
        end
        
        -- atualiza as bolas
        for i=1,#bolas do
            bolas[i].update()
            if bolas[i].getEstaFora() then
                table.insert(bolasFora, i)
            end
        end
        
        -- atualiza os ataques
        for i=1,#ataques do
            ataques[i].update()
            if ataques[i].getEstaFora() then
                table.insert(ataquesFora, i)
            end
        end
        
        -- remove as bolas que já saíram da tela
        for i=1,#bolasFora do
            table.remove(bolas, bolasFora[i])
        end
        
        -- remove os ataques que já saíram da tela
        for i=1,#ataquesFora do
            table.remove(ataques, ataquesFora[i])
        end
        
        -- volta a lista de bolas e ataques fora da tela ao estado inicial
        bolasFora = {}
        ataquesFora = {}
        
        -- verifica se houve colisão, tratanto se for o caso
        procurarColisoes()
        removerColididos()
    end
end

--[[
    Método responsavel por desenhar na tela os elementos do jogo
]]
function love.draw()
    personagem.draw()
    placar.draw(personagem.getSaude())
    for i=1,#bolas do
        bolas[i].draw()
    end
    for i=1,#ataques do
        ataques[i].draw()
    end
end

--[[
    Método responsavel por detectar apertos nas teclas do telado, efetuando as ações necessarias
]]
function love.keypressed(key)
    personagem.keypressed()
end

--[[
    Método responsavel por detectar clicks no mouse, efetuando as ações necessarias
]]
function love.mousepressed(x, y)
    if terminou == false then
        local bola = bola(personagem.getLocalizacao())
        bola.mousepressed(x, y)
        table.insert(bolas, bola)
    elseif clicks > 1 then
        clicks = clicks - 1
    else
        novaPartida()
    end
end
