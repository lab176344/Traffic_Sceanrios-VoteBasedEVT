%------------------------------------------------------------------------
% RF - 5 class
% Convolution output as input
% -----------------------------------------------------------------------
clear all; close all; clc
d1 = ['Train\'];
mat = dir([d1,'*.mat']);

for q = 1:5
      loadMat=strcat(d1,mat(q).name);
      load(loadMat);
      %% Varible declaration
      nTrees=200;
      TrainTarget = yTrain;
      TrainDataSet = XTrain;
      TrainTarget=bsxfun(@plus, TrainTarget', 1);
      % Training and evaluation
      [rf_model] = RF_SmallData(TrainDataSet,TrainTarget,nTrees, 'oobe', 'y', 'vi', 'n','term_criteria','minleafsize','Method', 'Classification');
      my_RF_ENS = rf_model {1,1};
      saveName=strcat('OSR_Models\',mat(q).name,'model.mat');
      save(saveName,'rf_model')
end





