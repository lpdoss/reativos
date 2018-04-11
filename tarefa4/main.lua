sleepTimeBlips = {}

function wait(segundos, meublip)
  sleepTimeBlips[meublip] = timer + segundos
  coroutine.yield()
end

function newblip (vel)
  local x, y = 0, 0
  return {
    update = coroutine.wrap (function ()
      while true do
        local width, height = love.graphics.getDimensions( )
        x = x+20
        if x > width then
        -- volta para a esquerda da janela
          x = 0
        end
        wait(vel, vel)
      end
    end),
    affected = function (pos)
      if pos>x and pos<x+10 then
      -- "pegou" o blip
        return true
      else
        return false
      end
    end,
    draw = function ()
      love.graphics.rectangle("line", x, y, 10, 10)
    end
  }
end

function newplayer ()
  local x, y = 0, 200
  local width, height = love.graphics.getDimensions( )
  return {
  try = function ()
    return x
  end,
  update = function (dt)
    x = x + 0.5
    if x > width then
      x = 0
    end
  end,
  draw = function ()
    love.graphics.rectangle("line", x, y, 30, 10)
  end
  }
end

function love.keypressed(key)
  if key == 'a' then
    pos = player.try()
    for i in ipairs(listabls) do
      local hit = listabls[i].affected(pos)
      if hit then
        table.remove(listabls, i) -- esse blip "morre" 
        table.remove(sleepTimeBlips, i)
        return -- assumo que apenas um blip morre
      end
    end
  end
end

function love.load()
  timer = 0
  player =  newplayer()
  listabls = {}
  for i = 1, 5 do
    listabls[i] = newblip(i)
    sleepTimeBlips[i] = 0
  end
end

function love.draw()
  player.draw()
  for i = 1,#listabls do
    listabls[i].draw()
  end
end

function love.update(dt)
  timer =  timer + dt
  
  player.update(dt)
  for i = 1,#listabls do
    if timer > sleepTimeBlips[i] then
      listabls[i].update()
    end
  end
end
  
