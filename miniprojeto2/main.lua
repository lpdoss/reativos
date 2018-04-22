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


-- tabelas para objetos da aplicação
local bola = function(x, y)
    local x = x
    local y = y
    local velocidadeX = nil
    local velocidadeY = nil
    local altura = 10
    local largura = 10
    local deslocamento = 20
    local fora = false
            
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
                fora = true
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
        foraDaTela = function()
            return fora
        end,
        getLocalizacao = function()
            return x+(largura/2), y-(altura/2)
        end
    }
end

local inimigo = function(px, py)
    local x = math.random(0, love.graphics.getWidth())
    local y = 0
    local destinoX = px
    local destinoY = py
    local altura = 10
    local largura = 10
    local deslocamento = 5
    local fora = false
    local velocidadeX = nil
    local velocidadeY = nil
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
                    fora = true
                end
                coroutine.yield()
            end
        end),
        foraDaTela = function()
            return fora
        end,
        getLocalizacao = function()
            return x+(largura/2), y-(altura/2)
        end
    }
end

local personagem = function()
    local x = love.graphics.getWidth()/2
    local y = love.graphics.getHeight()
    local altura = 20
    local largura = 10
    local deslocamento = 20
    local saude = 4
            
    return {    
        draw = function()
            love.graphics.setColor(255, 0, 0)
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
        if tempo > tempoRecord then            
            tempoRecord = tempo
            houveTempoRecord = true
        end
        if acertos > acertosRecord then
            acertosRecord = acertos
            houveAcertosRecord = true
        end
    end
    
    return {
        draw = function(saude)
            love.graphics.setColor(0,0,0)
            love.graphics.print(string.format('Tempo decorrido: %.2f', tempo), x, y, 0, 1.2)
            love.graphics.print(string.format('Núm. de acertos: %d', acertos), x, y+22, 0, 1.2)
            love.graphics.print(string.format('Saúde: %d', saude), love.graphics.getWidth()-120, 10, 0, 2)
            if terminou then
                terminarPartida()
            end
            if houveTempoRecord then
                love.graphics.print(string.format('Novo Record -> Tempo decorrido: %.2f', tempoRecord), 10, love.graphics.getHeight()/2, 0, 3)
            end
            if houveAcertosRecord then
                love.graphics.print(string.format('Novo Record -> Núm. de acertos: %d', acertosRecord), 10, love.graphics.getHeight()/2 + 60, 0, 3)
            end
        end,
        update = function(dt)
            if terminou==false then
                tempo = tempo + dt
            end
        end,
        incrementarAcertos = function()
            acertos = acertos + 1
        end,
        resetarPlacar = function()
            tempo = 0
            acertos = 0
            houveTempoRecord = false
            houveAcertosRecord = false
        end,
    }
end



-- metodos privados
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

local novaPartida = function()
    personagem.resetarPersonagem()
    placar.resetarPlacar()
    terminou = false
end



-- metodos principais da aplicação
function love.load()
    love.graphics.setBackgroundColor(255,255,255)
    love.keyboard.setKeyRepeat(true)
    personagem = personagem()
    placar = placar()
end

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
            if bolas[i].foraDaTela() then
                table.insert(bolasFora, i)
            end
        end
        
        -- atualiza os ataques
        for i=1,#ataques do
            ataques[i].update()
            if ataques[i].foraDaTela() then
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

function love.keypressed(key)
    personagem.keypressed()
end

function love.mousepressed(x, y)
    if terminou == false then
        local bola = bola(personagem.getLocalizacao())
        bola.mousepressed(x, y)
        table.insert(bolas, bola)
    else
        novaPartida()
    end
end
