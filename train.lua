require 'optim'

require 'cunn'
require 'nngraph'

local Loader = require 'Loader'

local width = 128
local height = 128
local loader = Loader.create("featured816.json", "cache", width, height)

--local model = torch.load("net.t7")
--local params, grads = model:getParameters()

function conv(numInPlanes, numOutPlanes, input)
  local conv1 = nn.SpatialConvolution(numInPlanes, numOutPlanes, 3, 3)(input)
  local relu1 = nn.ReLU()(conv1)
  local conv2 = nn.SpatialConvolution(numOutPlanes, numOutPlanes, 3, 3)(relu1)
  local relu2 = nn.ReLU()(conv2)
  local pool = nn.SpatialMaxPooling(2,2,2,2)(relu2)
  return conv1, conv2, pool
end

local input = nn.Identity()()

local numFilters1 = 32
local conv1_1, conv1_2, pool1 = conv(3, numFilters1, input)

local numFilters2 = 64
local conv2_1, conv2_2, pool2 = conv(numFilters1, numFilters2, pool1)

local numFilters3 = 128
local conv3_1, conv3_2, pool3 = conv(numFilters2, numFilters3, pool2)

local numFilters4 = 256
local conv4_1, conv4_2, pool4 = conv(numFilters3, numFilters4, pool3)

local size = numFilters4 * 4 * 4
local reshape = nn.Reshape(size)(pool4)

local layerSize1 =1024
local linear1 = nn.Linear(size, layerSize1)(reshape)
local nonl1 = nn.ReLU()(linear1)
local dropout1 = nn.Dropout(0.5)(nonl1)

local layerSize2 = 256
local linear2 = nn.Linear(layerSize1, layerSize2)(dropout1)
local nonl2 = nn.ReLU()(linear2)
local dropout2 = nn.Dropout(0.5)(nonl2)

local output = nn.LogSoftMax()(nn.Linear(layerSize2, loader:numClasses())(dropout2))
local model = nn.gModule({input}, {output}):cuda()
local params, grads = model:getParameters()
params:normal(0, 0.01)
-- Here we initialize our network according to the tips in
-- ImageNet Classification with Deep Convolutional Neural Networks, A. Krizhevsky, I. Sutskever, G. Hinton.
conv1_1.data.module.bias:fill(0)
conv1_2.data.module.bias:fill(0)
conv2_1.data.module.bias:fill(1)
conv2_2.data.module.bias:fill(1)
conv3_1.data.module.bias:fill(0)
conv3_2.data.module.bias:fill(0)
conv4_1.data.module.bias:fill(1)
conv4_2.data.module.bias:fill(1)
linear1.data.module.bias:fill(1)
linear2.data.module.bias:fill(1)
local criterion = nn.ClassNLLCriterion():cuda()

function feval(x)
  if x ~= params then
    params:copy(x)
  end
  grads:zero()

  -- get a batch of data
  local batchSize = 50
  local input = torch.zeros(batchSize, 3, width, height)
  local target = torch.zeros(batchSize)
  for i = 1,batchSize do
    input[i], target[i] = loader:get()
  end
  input = input:cuda()
  target = target:cuda()

  -- train by gradient descent
  local logProbs = model:forward(input)
  local err = criterion:forward(logProbs, target)
  local df = criterion:backward(logProbs, target)
  model:backward(input, df)

  return err, grads
end


local optimState = {learningRate = 1e-3}
--optimState.paramVariance = torch.load("adagrad.t7")
for i = 1,1000000 do
  local _, loss = optim.adagrad(feval, params, optimState)

  if i % 10 == 0 then
<<<<<<< Updated upstream
    local t = os.date("*t")
    local ds = ("%04d-%02d-%02d %02d:%02d:%02d"):format(t.year, t.month, t.day, t.hour, t.min, t.sec)
    print(string.format("%s iteration %d, loss %f", ds, i, loss[1]))
  end

  if i % 500 == 0 then
    torch.save("net.t7", model)
    torch.save("adagrad.t7", optimState.paramVariance)
=======
    collectgarbage()
    local net = {width = width, height = height, model = model}
    torch.save(string.format("net_%d_%f.t7", i, loss[1]), net)
>>>>>>> Stashed changes
    print("saved!")
  end
end
