clc;clear;close all;

load('HighDScenario.mat');
DataNum = 800;

ogLaneRight = shuffle_dataset(ogLaneRight);
ogLaneLeft = shuffle_dataset(ogLaneLeft);
ogLeftCut = shuffle_dataset(ogLeftCut);
ogLeftCutOut = shuffle_dataset(ogLeftCutOut);
ogRightCut = shuffle_dataset(ogRightCut);
ogFollDec = shuffle_dataset(ogFollDec);
ogFollAcc = shuffle_dataset(ogFollAcc);
ogRightCutOut = shuffle_dataset(ogRightCutOut);
ogFoll = shuffle_dataset(ogFoll);


%Training Data
X_train = [ogLaneRight(1:400,:,:,:)];
y_train = zeros(400,1);
X_train = [X_train; ogLaneLeft(1:400,:,:,:)];
y_train = [y_train; 1*ones(400,1)];
X_train = [X_train; ogLeftCut(1:400,:,:,:)];
y_train = [y_train; 2*ones(400,1)];
X_train = [X_train; ogLeftCutOut(1:400,:,:,:)];
y_train = [y_train; 3*ones(400,1)];
X_train = [X_train; ogRightCut(1:400,:,:,:)];
y_train = [y_train; 4*ones(400,1)];
% X_train = [X_train; ogFollDec(1:400,:,:,:)];
% y_train = [y_train; 7*ones(400,1)];
% X_train = [X_train; ogFollAcc(1:400,:,:,:)];
% y_train = [y_train; 5*ones(400,1)];
X_train = [X_train; ogRightCutOut(1:400,:,:,:)];
y_train = [y_train; 6*ones(400,1)];
X_train = [X_train; ogFoll(1:400,:,:,:)];
y_train = [y_train; 5*ones(400,1)];


X_test = [ogLaneRight(401:500,:,:,:)];
y_test = zeros(100,1);
X_test = [X_test; ogLaneLeft(401:500,:,:,:)];
y_test = [y_test; 1*ones(100,1)];
X_test = [X_test; ogLeftCut(401:500,:,:,:)];
y_test = [y_test; 2*ones(100,1)];
X_test = [X_test; ogLeftCutOut(401:500,:,:,:)];
y_test = [y_test; 3*ones(100,1)]; 
X_test = [X_test; ogRightCut(401:500,:,:,:)];
y_test = [y_test; 4*ones(100,1)]; 
% % X_test = [X_test; ogFollDec(401:500,:,:,:)];
% % y_test = [y_test; 7*ones(100,1)]; 
% X_test = [X_test; ogFollAcc(401:500,:,:,:)];
% y_test = [y_test; 5*ones(100,1)]; 
X_test = [X_test; ogRightCutOut(401:500,:,:,:)];
y_test = [y_test; 6*ones(100,1)];
X_test = [X_test; ogFoll(401:500,:,:,:)];
y_test = [y_test; 5*ones(100,1)];

x_openset = [ogLaneRight(501:650,:,:,:)];
y_openset = zeros(150,1);
x_openset = [x_openset; ogLaneLeft(501:650,:,:,:)];
y_openset = [y_openset; 1*ones(150,1)];
x_openset = [x_openset; ogLeftCut(501:650,:,:,:)];
y_openset = [y_openset; 2*ones(150,1)];
x_openset = [x_openset; ogLeftCutOut(501:607,:,:,:)];
y_openset = [y_openset; 3*ones(107,1)]; 
x_openset = [x_openset; ogRightCut(501:650,:,:,:)];
y_openset = [y_openset; 4*ones(150,1)]; 
% % x_openset = [x_openset; ogFollDec(501:650,:,:,:)];
% % y_openset = [y_openset; 7*ones(150,1)]; 
% x_openset = [x_openset; ogFollAcc(501:650,:,:,:)];
% y_openset = [y_openset; 5*ones(150,1)]; 
x_openset = [x_openset; ogRightCutOut(501:607,:,:,:)];
y_openset = [y_openset; 6*ones(107,1)];
x_openset = [x_openset; ogFoll(501:650,:,:,:)];
y_openset = [y_openset; 5*ones(150,1)];

save('HighDScenarioClass.mat','X_train','y_train','X_test','y_test','x_openset','y_openset');

function [Ogs_shuffled]=shuffle_dataset(Ogs)
rand_pos = randperm(size(Ogs,1)); %array of random positions
% new array with original data randomly distributed
    Ogs_shuffled = Ogs(rand_pos,:,:,:);
end



