local GUI_Objects = {}



function GUI_Objects:newButton(x, y, text)
    local pX = x
    local pY = y
    local name = text
    -- 20px + tamanho texto
    local width  = 20 + 5*string.len(name)
    local height = 50
    local button_clicked = false
    local cor_fundo = {0.7,0.7,0.7}
    local cor_texto = {0, 0, 0, 255}
  
    return {
      mousepressed = function (x, y, key)
        if x >= pX and x <= pX+width and y >= pY and y <= pY+height then
          button_clicked = true
        end
        return button_clicked
      end,
      mousereleased = function (x, y, key)
        button_clicked = false
      end,
      draw = function ()
        if button_clicked then
          cor_fundo = {50,50,50}
          --cor_texto = {0.7,0.7,0.7}
        else
          cor_fundo = {0.7,0.7,0.7}
          --cor_texto = {0, 0, 0, 255}
        end
        -- background
        love.graphics.setColor(unpack(cor_fundo))
        love.graphics.rectangle("fill", pX, pY, width, height)
        -- text
        love.graphics.setColor(unpack(cor_texto))
        love.graphics.print(name, pX+5, pY+18)
      end,
    }
  end
  
  function GUI_Objects:newTextbox(x, y, placeholder)
    local pX = x
    local pY = y
    local text = placeholder or ""
    -- 20px + tamanho texto
    local width  = 200
    local height = 50
    
    local active = false
    
    local function mouseSobre()
      local mX = love.mouse.getX()
      local mY = love.mouse.getY()
  
      if mX >= pX and mX <= pX+width and mY >= pY and mY <= pY+height then
        return true
      end
      return false
    end
    
    return {
    draw = 
      function ()
        -- background
        love.graphics.setColor(0.7,0.7,0.7)
        love.graphics.rectangle("line", pX, pY, width, height)
        -- text
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.printf(text, pX, pY, width, "left")
      end,
    trigger = 
      function (key)
        if mouseSobre() then
          active = true
        else
          active = false
        end
      end,
    textinput = 
      function (newText)
        if active then
          text = text .. newText
        end
      end,
    keypressed = 
      function (key)
        if active and key=="backspace" then
          text = string.sub(text, 0, string.len(text)-1)
        end
      end,
    getText = 
      function ()
        return text
      end
    }
  end
return GUI_Objects