Background Prediction
-----

This project uses Convolutional Neural Networks to train a model to predict backgrounds of collages. The training data is the list of featured collages.

## Train
`th train.lua`

## Test
`th test.lua`

## Trained results
The resulting model is https://s3.amazonaws.com/piccollage-development/backgroundPrediction/net.t7 , which achieves a 99% accuracy on the training data.
The last `paramVariance` of the training algorithm used, adagrad, is https://s3.amazonaws.com/piccollage-development/backgroundPrediction/adagrad.t7 .

## HTTP based API
Run `th server.lua` that starts a web server on listening 0.0.0.0:1463 , and that exposes an API that can be accessed from for example
`curl -X POST -F "f=@img/122663668.jpeg" http://127.0.0.1:1463/`.
