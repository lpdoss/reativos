local GUI_Objects = {}



function GUI_Objects:newButton(x, y, text)
    local r = 0.7
    local g = 0.7
    local b = 0.7
    
    local pX = x
    local pY = y
    local name = text
    -- 20px + tamanho texto
    local width  = 20 + 5*string.len(name)
    local height = 35
  
    return {
    mousereleased = 
      function ()
        r = 0.7
        g = 0.7
        b = 0.7
      end,
    mouseSobre = 
      function ()
        local mX = love.mouse.getX()
        local mY = love.mouse.getY()
        if mX >= pX and mX <= pX+width and mY >= pY and mY <= pY+height then
          return true
        end
        return false
      end,
    draw = 
      function ()
        -- background
        love.graphics.setColor(r,g,b)
        love.graphics.rectangle("fill", pX, pY, width, height)
        -- text
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.print(name, pX+5, pY+10)
      end,
    update =
      function (self, dt)
        if love.mouse.isDown(1) and self.mouseSobre() then
          r = 0.5
          g = 0.5
          b = 0.5
        end
      end, 
    }
  end
  
  function GUI_Objects:newTextbox(x, y, placeholder)
    local pX = x
    local pY = y
    local text = placeholder or ""

    -- 20px + tamanho texto
    local width  = 200
    local height = 35
    
    local active = false
    local timer = 0
    
    local function mouseSobre()
      local mX = love.mouse.getX()
      local mY = love.mouse.getY()
  
      if mX >= pX and mX <= pX+width and mY >= pY and mY <= pY+height then
        return true
      end
      return false
    end
    
    return {
    update = 
      function (dt)
        if active then
          timer = timer + 1
          if timer % 30 == 0 then 
            flag = not flag
            timer = 0
          end
          if timer % 5 == 0 then
            if love.keyboard.isDown("backspace") then
              text = string.sub(text, 0, string.len(text)-1)
            end
          end
        end
      end,
    draw = 
      function ()
        -- background
        if active then
          love.graphics.setColor(0.5, 0.5, 0.5)
        else
          love.graphics.setColor(0.7,0.7,0.7)
        end
        love.graphics.rectangle("line", pX, pY, width, height)
        -- text
        love.graphics.setColor(0, 0, 0, 255)
        local font = love.graphics.getFont()
        if text ~= "" then
          wWidth, wText = font:getWrap(text, width - 20)
          if active then
            if flag then
              love.graphics.printf(wText[#wText] .. "_", pX+5, pY+10, width-5, "left")  
            else
              love.graphics.printf(wText[#wText], pX+5, pY+10, width-5, "left")
            end
          else
            love.graphics.printf(wText[#wText], pX+5, pY+10, width-5, "left")
          end
        else
          if active then
            if flag then
              love.graphics.printf(text .. "_", pX+5, pY+10, width-5, "left")  
            else
              love.graphics.printf(text, pX+5, pY+10, width-5, "left")
            end
          else
            love.graphics.printf(text, pX+5, pY+10, width-5, "left")
          end
        end
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
    getText = 
      function ()
        return text
      end,
    setText =  
      function (new_text)
        text = new_text
      end
    }
  end
return GUI_Objects