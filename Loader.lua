local gm = require 'graphicsmagick'
require 'json'

local Loader = {}
Loader.__index = Loader

function Loader.create(data, cache, width, height)
  local self = {}
  setmetatable(self, Loader)

  self.data = json.load(data)
  self.cache = cache
  if self.cache:sub(#self.cache) ~= "/" then
    self.cache = self.cache.."/"
  end
  self.width = width
  self.height = height

  self.klasses = {
"vday_2015_01.png",
"vday_2015_02.png",
"vday_5.png",
"vday_3.png",
"xmas_redline.png",
"xmas_redcube.png",
"c_01.png",
"c_02.png",
"blackppr.png",
"offwhite.png",
"brightpink.png",
"bbypink.png",
"pink.png",
"default.png",
"orangepink.png",
"paloma.png",
"darkgrey.png",
"violet_tulip.png",
"radicant_orchid.png",
"skyblue.png",
"lightppl.png",
"bbyblue.png",
"blue.png",
"bluegreen.png",
"navyblue.png",
"hemlock.png",
"comfrey.png",
"grassgreen.png",
"pinegreen.png",
"pastelyellow.png",
"briteyellow.png",
"orange.png",
"red.png",
"sand.png",
"darkbrown.png",
"dot_2_o.png",
"dot_2_b.png",
"vday_2.png",
"vday_1.png",
"bg_12.png",
"bg_13.png",
"bg_06.png",
"bg_07.png",
"bg_16.png",
"bg_17.png",
"bg_25.png",
"vday_7.png",
"vday_8.png",
"vday_9.png",
"vday_4.png",
"vday_6.png",
"dot_1_rb.png",
"dot_1_rw.png",
"dot_1_p.png",
"dot_1_lg.png",
"dot_1_lb.png",
"dot_1_y.png",
"bg_14.png",
"bg_02.png",
"bg_03.png",
"bg_15.png",
"bg_05.png",
"bg_04.png",
"cross_1_bn.png",
"drop_1_o.png",
"bg_spring_orange.png",
"bg_spring_green.png",
"bg_spring_pink.png",
"bg_spring_yellow.png",
"bg_spring_cubes.png",
"stripe_v_1.png",
"mustache_1_lb.png",
"mustache_1_y.png",
"bokeh_1_w.png",
"dot_3_p.png",
"star_1_b.png",
"star_1_p.png",
"dot_4_bg.png",
"dot_4_rp.png" ,
  }
  self.klassesRev = {}
  for idx, k in pairs(self.klasses) do
    self.klassesRev[k] = idx
  end

  self.i = 1

  return self
end

function Loader:numClasses()
  return #self.klasses + 1
end

function Loader:get()
  local i = self.i
  self.i = self.i + 1
  if i > #self.data then
    self.i = 1
    return self:get()
  end

  -- load the image as a Tensor
  local imgT
  local fname = self.cache..self.data[i]["id"]..".t7"
  local _, err = pcall(function() imgT = torch.load(fname) end)
  if err ~= nil then
    local img = gm.Image(self.data[i]["url"])
    img:size(self.width, self.height)
    imgT = img:toTensor()
    imgT = imgT:transpose(1,3) -- make the color channel the first dimension
    imgT = imgT:double()

    torch.save(fname, imgT)
  end

  -- Find the background
  local bg = self.klassesRev[self.data[i]["background_path"]]
  if bg == nil then
    bg = #self.klasses + 1 -- the Unknown class
  end

  return imgT, bg
end

--function Loader:get()
--  local r = torch.uniform()
--  if r > 0.5 then
--    local input = torch.ones(3, self.width, self.height)
--    local a = torch.uniform(-0.1, 0.1)
--    input:mul(1 + a)
--    return input, 2
--  else
--    local input = torch.ones(3, self.width, self.height)
--    local a = torch.uniform(-0.1, 0.1)
--    input:mul(a)
--    return input, 1
--  end
--end

return Loader
