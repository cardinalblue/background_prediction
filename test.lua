require 'cunn'
require 'nngraph'

local Loader = require 'Loader'

local width = 128
local height = 128
local loader = Loader.create("featured816.json", "cache", width, height)
local model = torch.load("net.t7")
model:evaluate()

local numTests = 100
local corrects = 0
for i = 1,numTests do
  local input = torch.zeros(1, 3, width, height)
  local target
  input[1], target = loader:get()
  input = input:cuda()

  local logProbsCUDA = model:forward(input)
  logProbs = logProbsCUDA:float()
  local probs = torch.exp(logProbs):squeeze()
  local pred = torch.multinomial(probs, 1)[1]
  if pred == target then
    corrects = corrects + 1
  end

  print(string.format("pred: %d, target: %d", pred, target))
end

print(string.format("correctness: %.1f%%", corrects / numTests * 100))
