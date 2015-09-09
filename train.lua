require 'image'
require 'optim'

require 'nn'
require 'nngraph'

local Loader = require 'Loader'

local width = 100
local height = 100
local loader = Loader.create("lm_bg_0_200.json", width, height)

local input = nn.Identity()()
local conv1 = nn.SpatialConvolutionMap(nn.tables.random(3, 16, 1), 15, 15)(input)
local tanh1 = nn.Tanh()(conv1)
local pool1 = nn.SpatialLPPooling(16,2,6,6,6,6)(tanh1)
local norm1 = nn.SpatialSubtractiveNormalization(16, image.gaussian1D(7))(pool1)

local size = 16 * 14 * 14
local reshape = nn.Reshape(size)(norm1)
local linear1 = nn.Linear(size, 128)(reshape)
local nonl = nn.Tanh()(linear1)
local outputSize = #loader.klasses + 1 -- plus 1 for the Unknown class
local output = nn.LogSoftMax()(nn.Linear(128, outputSize)(nonl))
local model = nn.gModule({input}, {output})
local criterion = nn.ClassNLLCriterion()

local params, grads = model:getParameters()
params:uniform(-0.5, 0.5)

function feval(x)
  if x ~= params then
    params:copy(x)
  end
  grads:zero()

  local input, target = loader:nextBatch()

  local logProbs = model:forward(input)
  local err = criterion:forward(logProbs, target)
  local df = criterion:backward(logProbs, target)
  model:backward(input, df)

  return err, grads
end

for i = 1,1000000 do
  local _, loss = optim.adagrad(feval, params, {learningRate = 1e-3})
  print(string.format("iteration %d, loss %f", i, loss[1]))

  if i % 100 == 0 then
    local net = {width = width, height = height, model = model}
    torch.save("net.t7", net)
    print("saved!")
  end
end
