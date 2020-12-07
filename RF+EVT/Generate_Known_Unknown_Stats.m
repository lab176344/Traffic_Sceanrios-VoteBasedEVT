%-----------------------------------------------------------------------------------
%   Script: To find the known and unknown data points 5 class and 4 class splitup
%-----------------------------------------------------------------------------------

clc;clear all;close all;
d1=['EVTCalib\'];
addpath(d1);
mat = dir([d1,'*Test.mat']);
mat2=dir([d1,'*Val.mat']);
EVTandRF=0;
outputF1=[];
% Threshold to filter out with respect to the number of trees
threshold=0:0.05:1;
num_trees = 200;
for i=1:size(threshold,2)

threshold_filter = num_trees*0.9;
% Threshold for EVT Filter
% Run through all the thrshold
Results={};
Results2={};
ScenarioNmae=strcat('ScenarioSplit4_3_', num2str(i));
mkdir(ScenarioNmae);
% Run through all the mat files of the experiments
for experiment=1:length(mat)
    % Load the calibration dataset results
    fileVal=strcat(mat2(experiment).name);
    load(fileVal);
    % Save the calibration confidence values which is the number of
    % trees for each class
    confidence_check=confidence; yCalib = TrainTarget; clear confidence outputRF TrainTarget;
    % Load the test data set--> Loads the confidence and the output
    % from RF for test dataset
    fileTest=strcat(mat(experiment).name);
    load(fileTest);
    yTest = TrainTarget;
    outputF1=zeros(1,964);
    outputknown=5*ones(1,964);
    unknownStart = sum(yTest<=3);
    [~,idxCalib,~] = unique(yCalib);
    [~,idxTest,~] = unique(yTest);
    idxCalib(5) = 400;
    % For each clas go through the test dataset and get statictics
    for classRun=1:4
        % The class to check
        ClassCheck=classRun;
        % Threshold for each EVT distribution
        ConidenceRatioEVT=threshold(i);
        % Test dataset sample numbers
        CheckLimit=964;
        %Unknown Data number
        LimitOtherData = (unknownStart+1):CheckLimit;
        % Normal Thresholding
        SumKnown=0;
        SumUnkown=0;
        SumKnownWrong=0;
        % EVT Based Thresholding
        SumKnownEVT=0;
        SumUnknownEVT=0;
        SumKnownWrongEVT=0;
        % Only EVT
        SumKnownUnkown=0;
        SumKnownUnkwonEVT=0;
        % Slect the appropriate data IDS for each class
        switch ClassCheck
            case 1
                limits=[1,CheckLimit];
                limits_claas=[1,idxTest(2)-1];
                limits_val=[1,idxCalib(2)-1];
                classCheck=1;
            case 2
                limits=[1,CheckLimit];
                limits_claas=[idxTest(2),idxTest(3)-1];
                limits_val=[idxCalib(2),idxCalib(3)-1];
                classCheck=2;
            case 3
                limits=[1,CheckLimit];
                limits_claas=[idxTest(3),idxTest(4)-1];
                limits_val=[idxCalib(3),idxCalib(4)-1];
                classCheck=3;
            case 4
                limits=[1,CheckLimit];
                limits_claas=[idxTest(4),idxTest(5)-1];
                limits_val=[idxCalib(4),idxCalib(5)-1];
                classCheck=4;
            case 5
                limits=[1,CheckLimit];
                limits_claas=[idxTest(5),idxTest(6)-1];
                limits_val=[idxCalib(5),idxCalib(6)-1];
                classCheck=5;
            case 6
                limits=[1,CheckLimit];
                limits_claas=[idxTest(5),idxTest(6)-1];
                limits_val=[idxCalib(5),idxCalib(6)-1];
                classCheck=6;
            case 7
                limits=[1,CheckLimit];
                limits_claas=[idxTest(6),idxTest(7)-1];
                limits_val=[idxCalib(6),idxCalib(7)-1];
                classCheck=7;
            case 8
                limits=[1,CheckLimit];
                limits_claas=[idxTest(7),idxTest(8)-1];
                limits_val=[idxCalib(7),idxCalib(8)-1];
                classCheck=8;
            case 9
                limits=[1,CheckLimit];
                limits_claas=[idxTest(8),idxTest(9)-1];
                limits_val=[idxCalib(8),idxCalib(9)-1];
                classCheck=9;
        end
        % Limit the tailsize depending on the number of minimum trees
        % to be selected
        LimitTailSize=sum(confidence_check(limits_val(1):limits_val(2))<threshold_filter);

             
        % Sort the set S_k and save the IDs and sorted array
        [ConfSort,idxSort]=sort(confidence_check(limits_val(1):limits_val(2)),'ascend');
        % The \tau number of datapoints for which the EVT has to be
        % fitted
        ConfFit=ConfSort(1:LimitTailSize);
        % Fit EVT
        parmhat =  wblfit(ConfFit);
        SumKnown2=0;
        SumKnownUnkown2=0;
        SumKnownWrong2=0;
        KnownID=[];
        % First filter to remove the highly confident known datapoints
        for j=limits(1):limits(2)
            ConfFilterEVT = wblcdf(confidence((j)),parmhat(1),parmhat(2),0);
            %Check if the output is the class and the IDs are within
            %the class numbers
            % TP-> Known classified as Known
            if(outputRF(1,j)==classCheck && j>=limits_claas(1)&&j<=limits_claas(2))
                % First filter
                % SumKnown-->TP
                if(ConfFilterEVT>=ConidenceRatioEVT)
                    outputF1(j)=1;
                    outputknown(j)=classCheck;
                end
                % For data points that are outside the ID range of the class
                % is considered unknown
                % check if the class is classified correctly as the
                % classRub
            elseif(outputRF(1,j)==classCheck && j>=LimitOtherData(1)&&j<=LimitOtherData(end))
                % If highly confident then
                % TN -> Unknown classified as known-->SumKnownUnkown
                if(ConfFilterEVT>=ConidenceRatioEVT)
                    outputF1(j)=1;
                    outputknown(j)=classCheck;
                end
                % if the testsamples are from known but classified wrongly
            elseif(outputRF(1,j)==classCheck)
                if(ConfFilterEVT>=ConidenceRatioEVT)
                    outputF1(j)=1;
                    outputknown(j)=classCheck;
                end
            end
            
        end 
    end
    outputTrue = bsxfun(@plus, yTest, 1);    
    save(strcat(ScenarioNmae,'\fcheck',num2str(experiment)),'outputF1','outputknown','outputTrue');
end
end
