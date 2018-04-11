function love.load()
  x = 50 y = 200
  w = 200 h = 150
  ret = {retangulo(x,y,w,h), retangulo(x+100,y+100,w,h), retangulo(x+200,y+200,w,h), retangulo(x+300,y+300,w,h)}
end

function naimagem (mx, my, x, y) 
  return (mx>x) and (mx<x+w) and (my>y) and (my<y+h)
end

function retangulo (x,y,w,h)
  local originalx, originaly, rx, ry, rw, rh = x,y,x,y,w,h
  return {
  draw = function ()
    love.graphics.rectangle("line", rx,ry,rw,rh)
  end,
  keypressed = function (key)
    local mx, my = love.mouse.getPosition() 
    if love.keyboard.isDown("up")  and naimagem(mx, my, rx, ry)  then
      ry = ry - 10
    end
    if love.keyboard.isDown("down")  and naimagem(mx, my, rx, ry)  then
      ry = ry + 10
    end
    if love.keyboard.isDown("left")  and naimagem(mx, my, rx, ry)  then
      rx = rx - 10
    end
    if love.keyboard.isDown("right")  and naimagem(mx, my, rx, ry)  then
      rx = rx + 10
    end
    if key == 'b' and naimagem (mx,my, rx, ry) then
      ry = originaly
      rx = originalx
    end
  end
  }  
end

function love.keypressed(key)
  for i=1, #ret do
    ret[i].keypressed(key)
  end
end

function love.update (dt)
end

function love.draw ()
  for i=1, #ret do
    ret[i].draw()
  end
end
