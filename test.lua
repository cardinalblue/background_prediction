require 'nn'
require 'nngraph'

local Loader = require 'Loader'

local net = torch.load("net.t7")

local loader = Loader.create("lm_bg_0_200.json", net.width, net.height)
local model = net.model

local numTests = 100
local corrects = 0
for i = 1,numTests do
  local input, target = loader:nextBatch()

  local logProbs = model:forward(input)
  local probs = torch.exp(logProbs):squeeze()
  local pred = torch.multinomial(probs, 1)[1]
  if pred == target then
    corrects = corrects + 1
  end

  print(string.format("pred: %d, target: %d", pred, target))
end

print(string.format("correctness: %.1f%%", corrects / numTests * 100))
