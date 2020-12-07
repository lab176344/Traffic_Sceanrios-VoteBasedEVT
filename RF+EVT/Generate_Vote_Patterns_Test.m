%------------------------------------------------------------------------
% Untrained data with RF Check
% ------------------------------------------------------------------------
clear all; clc;close all
%-------------------------------------------------------------------------
% Variable declaration
% Generate Calibration Dataset
d1 = ['Test\'];
addpath(d1);
d2=['OSR_Models\'];
addpath(d2);
mat = dir([d1,'*.mat']);
mat2=dir([d2,'*.mat']);
Calib=false;

for q = 1:5
    histgrm=true;
    outputRF=[];
    confidence=[];
    XInput=[];
    
    %-------------------------------------------------------------------
    % Load the model
    load(mat2(q).name);
    my_RF_ENS=rf_model{1};
    nTrees=size(my_RF_ENS,2);
    %------------------------------------------------------------------------
    % Load the data
    load(mat(q).name);
    if(Calib)
        TrainDataSet = XCalib;
        TrainTarget = yCalib;
    else
        TrainDataSet = XTest;
        TrainTarget = yTest;
        
    end
    TrainDataSet=reshape(TrainDataSet,size(TrainDataSet,1),1020);
    [SortTarget,idx]=sort(TrainTarget);
    XInput=TrainDataSet(idx,:);
    %-------------------------------------------------------------------
    % Model Variables
    if(histgrm)
        figure;
        m_falseclacification=0;
        for test_idx=1:size(XInput, 1)
            for tree_id=1:nTrees
                tree_output(tree_id) = Tree_Output(XInput(test_idx, :), my_RF_ENS{tree_id});
            end
            h=histogram(tree_output);
            confidence_test=h.Values;
            confidence(test_idx,:)=max(max(confidence_test));
            outputRF(test_idx) = mode(tree_output);
        end
    end
    
    % confidence_check=confidence;
    saveName=strcat('EVTCalib\',mat(q).name,'Test.mat');
    save(saveName,'confidence','outputRF','TrainTarget');
end







