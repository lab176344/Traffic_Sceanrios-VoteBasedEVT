
clc;clear;close all;
load('Acceleration_Deceleration.mat');
% load('Promt.mat');
% ogRightCutOut = [ogRightCutOut; ogRightCutOutAug];
 generate_augGrids(ogFollDec);
% ogLeftCutOut
% ogLaneLeft
% ogRightCut 
% ogLeftCut
% ogLaneRight
function generate_augGrids(oGs)
leftCutData = size(oGs);
for i = 1:leftCutData(1)
    occupancy_grids = oGs(i,:,:,:);
    for viz =1:10
        original_image = (reshape(occupancy_grids(1,:,:,viz),30,200));
        imagesc(original_image)
        axis equal;
        pause(0.1);
    end
%     prompt = 'Save Scenario? ';
% saveyesno(i) = input(prompt);
% save('Promt','saveyesno');

end
end