require 'cunn'
require 'nngraph'
local gm = require 'graphicsmagick'
local async = require 'async'
local multipart = require 'multipart'
local Loader = require 'Loader'

local width = 128
local height = 128
local loader = Loader.create("", "cache", width, height)
local model = torch.load("net.t7")
model:evaluate()

local host = "http://0.0.0.0:1463"
async.http.listen(host, function(req, res)
  collectgarbage()
  local data = multipart(req.body, req.headers["content-type"])
  local f = data:get("f")
  if f == nil or f.value == nil then
    res(string.format('{"error":"%s"}', "no param f"), {["Content-Type"] = "application/json"})
    return
  end

  local img = gm.Image()
  img:fromString(f.value)
  local input = torch.zeros(1, 3, width, height)
  local err = nil
  collectgarbage()
  input[1], err = loader:process(img)
  if err ~= nil then
    print("loader:process error:", err)
    res(string.format('{"error":"%s"}', err), {["Content-Type"] = "application/json"})
    return
  end
  input = input:cuda()

  local logProbs = model:forward(input)
  local probs = torch.exp(logProbs):squeeze()
  local pred = torch.multinomial(probs, 1)[1]
  local background = loader:klassName(pred)

  res(string.format('{"bg":"%s"}', background), {["Content-Type"] = "application/json"})
end)

print(string.format("listening on %s", host))
async.go()

