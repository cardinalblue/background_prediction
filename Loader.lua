local gm = require 'graphicsmagick'
require 'json'

local Loader = {}
Loader.__index = Loader

function Loader.create(data, cache, width, height)
  local self = {}
  setmetatable(self, Loader)

  if data == "" then
    self.data = { {url = "http://pic-collage.com:80/api/assets?key=cfad601d38d4a673b84a95cbf5fc051b", background_path = "c_02.png", id = "123479840"} }
  else
    self.data = json.load(data)
  end
  self.cache = cache
  if self.cache:sub(#self.cache) ~= "/" then
    self.cache = self.cache.."/"
  end
  self.width = width
  self.height = height

  self.klasses = {
"vday_1.png",
"c_29.png",
"c_26.png",
"xmas_redstar.png",
"blue.png",
"c_32.png",
"dot_4_bg.png",
"bg_18.png",
"c_33.png",
"c_16.png",
"vday_3.png",
"pastelyellow.png",
"c_28.png",
"bg_25.png",
"vday_7.png",
"briteyellow.png",
"dot_2_b.png",
"bg_14.png",
"bbypink.png",
"mustache_1_y.png",
"c_21.png",
"drop_1_o.png",
"stripe_v_1.png",
"c_11.png",
"c_06.png",
"navyblue.png",
"bg_07.png",
"orangepink.png",
"celosia_orange.png",
"vday_6.png",
"c_30.png",
"c_18.png",
"dot_4_rp.png",
"c_14.png",
"cayenne.png",
"hemlock.png",
"orange.png",
"bg_19.png",
"lightppl.png",
"skyblue.png",
"c_23.png",
"c_07.png",
"comfrey.png",
"blackppr.png",
"mustache_1_lb.png",
"bg_04.png",
"spring_cubes.png",
"bokeh_1_w.png",
"vday_2.png",
"dot_1_rw.png",
"c_24.png",
"bg_13.png",
"bg_06.png",
"cross_1_bn.png",
"bluegreen.png",
"brightpink.png",
"paloma.png",
"vday_4.png",
"violet_tulip.png",
"dot_1_lg.png",
"blkwds.png",
"pink.png",
"c_22.png",
"bg_02.png",
"bg_03.png",
"dot_1_rb.png",
"darkgrey.png",
"sand.png",
"c_19.png",
"dazzling_blue.png",
"vday_5.png",
"c_34.png",
"xmas_redline.png",
"bg_spring_yellow.png",
"vday_2015_02.png",
"bg_spring_green.png",
"c_15.png",
"bg_2015_07.png",
"dot_3_p.png",
"pinegreen.png",
"c_05.png",
"dot_1_p.png",
"bg_12.png",
"whitewds.png",
"winter_snow.png",
"offwhite.png",
"bg_old_01.png",
"dot_2_o.png",
"c_17.png",
"xmas_trees.png",
"c_27.png",
"c_03.png",
"c_02.png",
"vday_8.png",
"red.png",
"xmas_bluesnow.png",
"bg_2015_06.png",
"freesla.png",
"c_04.png",
"bg_2015_12.png",
"bg_01.png",
"bg_17.png",
"bg_spring_pink.png",
"c_13.png",
"c_08.png",
"c_10.png",
"xmas_redcube.png",
"bg_spring_cubes.png",
"darkbrown.png",
"bg_15.png",
"bg_16.png",
"spring_pink.png",
"bg_spring_orange.png",
"default.png",
"c_12.png",
"bbyblue.png",
"dot_1_lb.png",
"bg_05.png",
"vday_2015_01.png",
"radicant_orchid.png",
"dot_1_y.png",
"c_01.png",
"vday_9.png",
"star_1_p.png",
"c_20.png",
"placid.png",
  }
  self.klassesRev = {}
  for idx, k in pairs(self.klasses) do
    self.klassesRev[k] = idx
  end

  self.i = 1
  self.shuffle = torch.randperm(#self.data)

  return self
end

function Loader:numClasses()
  return #self.klasses + 1
end

function Loader:klassName(klassIdx)
  local name = self.klasses[klassIdx]
  if name ~= nil then
    return name
  end

  return "unknown"
end

function Loader:get()
  local i = self.shuffle[self.i]
  self.i = self.i + 1
  if self.i > self.shuffle:size()[1] then
    self.i = 1
    self.shuffle = torch.randperm(#self.data)
    return self:get()
  end

  -- load the image as a Tensor
  local imgT
  local fname = self.cache..self.data[i]["id"]..".t7"
  local _, err = pcall(function() imgT = torch.load(fname) end)
  if err ~= nil then
    local img = gm.Image(self.data[i]["url"])
    imgT = self:process(img)
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
--    input:mul(-1 + a)
--    return input, 2
--  else
--    local input = torch.ones(3, self.width, self.height)
--    local a = torch.uniform(-0.1, 0.1)
--    input:mul(1 + a)
--    return input, 1
--  end
--end

-- process takes a graphicsmagick.Image, processes it, and transforms it into a torch.Tensor.
function Loader:process(img)
  local _, err = pcall(function() img:size(self.width, self.height) end)
  if err ~= nil then
    return torch.zeros(3, self.width, self.height), err
  end

  local imgT = img:toTensor()
  imgT = imgT:transpose(1,3) -- make the color channel the first dimension
  imgT = imgT:float()

  -- normalize using the mean and variance calculated from 1000 training images.
  local mean = {181.40322916667, 170.12656519608, 167.27086446078}
  local std = {81.145678478329, 81.676893603989, 82.498848024362}
  for cn = 1,3 do
    imgT[{ cn, {}, {} }]:add(-mean[cn])
    imgT[{ cn, {}, {} }]:div(std[cn])
  end

  return imgT, nil
end

return Loader
