clc;clear;close all;

load('Scenario_Hopefully_Correct.mat');


ogLeftCutOutAug =[];
ogRightCutOutAug = [];
ogLaneLeftAug = [];
ogLaneRightAug = [];
ogLeftCutAug = [];
ogRightCutAug = [];

ogLeftCutOutAug = generate_augGrids(ogRightCutOut);
ogRightCutOutAug = generate_augGrids(ogLeftCutOut);
ogLaneLeftAug = generate_augGrids(ogLaneRight);
ogLaneRightAug = generate_augGrids(ogLaneLeft);
ogLeftCutAug = generate_augGrids(ogRightCut);
ogRightCutAug = generate_augGrids(ogLeftCut);

ogRightCutOut = [ogRightCutOut; ogRightCutOutAug];
ogLeftCutOut = [ogLeftCutOut; ogLeftCutOutAug];
ogLaneLeft = [ogLaneLeft; ogLaneLeftAug];
ogLaneRight = [ogLaneRight; ogLaneRightAug];
ogLeftCut = [ogLeftCut; ogLeftCutAug];
ogRightCut = [ogRightCut; ogRightCutAug];

save('Scenario_Hopefully_CorrectAug.mat')

function [AugGrid] = generate_augGrids(oGs)
leftCutData = size(oGs);
for i = 1:leftCutData(1)
    occupancy_grids = oGs(i,:,:,:);
    for viz =1:10
        original_image = (reshape(occupancy_grids(1,:,:,viz),30,200));
        AugGrid(i,:,:,viz) = (flip(original_image));
    end
end
end

