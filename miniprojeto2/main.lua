-- variaveis globais da aplicação
local bolas = {}
local bolasFora = {}



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
        end
    }
end

local alvo = function()
    local x = nil
    local y = nil
    local velocidadeX = nil
    local velocidadeY = nil
    local altura = 10
    local largura = 10
    local deslocamento = 20
    local fora = false
            
    return {
        draw = function()
            love.graphics.setColor(0, 0, 255)
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



-- metodos principais da aplicação
function love.load()
    love.keyboard.setKeyRepeat(true)
    p = personagem()
end

function love.update(dt)
    -- atualiza o personagem
    p.update(dt)
    
    -- atualiza as bolas
    for i=1,#bolas do
        bolas[i].update(dt)
        if bolas[i].foraDaTela() then
            table.insert(bolasFora, i)
        end
    end
    
    -- remove as bolas que já saíram da tela
    for i=1,#bolasFora do
        table.remove(bolas, bolasFora[i])
    end
    
    -- volta a lista de bolas fora da tela ao estado inicial
    bolasFora = {}
end

function love.draw()
    p.draw()
    for i=1,#bolas do
        bolas[i].draw()
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
