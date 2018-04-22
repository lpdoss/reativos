-- variaveis globais da aplicação
local bolas = {}
local bolasFora = {}
local ataques = {}
local ataquesFora = {}
local ataquesInterceptados = {}
local intervaloAtaques = 5
local ultimoAtaque = 0
local tolerancia = 10


-- objetos da aplicação
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
        update = function(dt)
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
            love.graphics.setColor(255, 255, 255)
            love.graphics.circle("fill", x, y, largura, altura)
        end,
        update = function(dt)
            if x>-largura and x<(love.graphics.getWidth()+largura) and y<(love.graphics.getHeight()+altura) and y>-altura then
                x = x + velocidadeX
                y = y + velocidadeY
            else
                fora = true
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

local personagem = function()
    local x = love.graphics.getWidth()/2
    local y = love.graphics.getHeight()
    local altura = 40
    local largura = 10
    local deslocamento = 20
            
    return {    
        draw = function()
            love.graphics.setColor(255, 0, 0)
            love.graphics.rectangle("fill", x, y-altura, largura, altura)
        end,
        update = function(dt)
            --print(dt)
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
        end
    }
end



-- metodos privados
local procurarColisoes = function()
    for i=1,#bolas do
        for j=1,#ataques do
            local bolax, bolay = bolas[i].getLocalizacao()
            local ataquex, ataquey = ataques[j].getLocalizacao()
            if math.abs(bolax-ataquex)<tolerancia and math.abs(bolay-ataquey)<tolerancia then
                table.insert(ataquesInterceptados, {i, j})
            end
        end
    end
end

local removerColididos = function()
    for i=1,#ataquesInterceptados do
        table.remove(bolas, ataquesInterceptados[i][1])
        table.remove(ataques, ataquesInterceptados[i][2])
    end
    ataquesInterceptados = {}
end



-- metodos principais da aplicação
function love.load()
    love.keyboard.setKeyRepeat(true)
    p = personagem()
end

function love.update(dt)
    -- atualiza o personagem
    p.update(dt)
    
    ultimoAtaque = ultimoAtaque + dt
    if ultimoAtaque > intervaloAtaques then  
        ultimoAtaque = 0
        table.insert(ataques, inimigo(p.getLocalizacao()))
    end
    
    -- atualiza as bolas
    for i=1,#bolas do
        bolas[i].update(dt)
        if bolas[i].foraDaTela() then
            table.insert(bolasFora, i)
        end
    end
    
    -- atualiza os ataques
    for i=1,#ataques do
        ataques[i].update(dt)
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

function love.draw()
    p.draw()
    for i=1,#bolas do
        bolas[i].draw()
    end
    for i=1,#ataques do
        ataques[i].draw()
    end
end

function love.keypressed(key)
    p.keypressed()
end

function love.mousepressed(x, y)
    local bola = bola(p.getLocalizacao())
    bola.mousepressed(x, y)
    table.insert(bolas, bola)
end
