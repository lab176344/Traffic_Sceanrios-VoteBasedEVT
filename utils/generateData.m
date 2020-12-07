%%% EXTRACT SCENARIOS FROM highD DATASET %%%
%%% DATA FOR TRAINING OF MACHINE LEARNING ALGORITHMS FOR POG ESTIMATION %%%

clearvars; clc; close all;

% Add the necessary folders to path
currentFolder = pwd;
addpath([currentFolder '\data'], [currentFolder '\utils'])

% Exclude scenarios with anomaly in data
load([currentFolder '\utils\errorID_list.mat']);

%% Parameters for generation of data
% No of videos data
nVideos = 60;

% Parameters for choosing scenarios
TTCthr = 8; % in seconds (TTC Threshold for selection of scenarios)
frameRate = 25;
ScLength = 3; % in seconds (Length of the scenario)

% Number of training scenarios to be generated
noOfScenarios = 1;

% Max number of vehicle to be included for training
noOfVehicle = 1:3;

% Meta Daten
LocationID = zeros(1,nVideos);
LocationIDList = [1, 3, 4]; % locations that have 3 lanes
ySign = -1;
counter1 = 0;

%% Start reading data from videos
for i = 4 %1:nVideos % 60 tracks available
    
    disp(['Running videoString = ', num2str(i), ' | in percent: ',...
        num2str(i/nVideos*100), '%']);
    clear videoString iStr tracksFileName tracksStaticFilename...
        tracks Scenarios toDelete Veh_ID
    iStr = num2str(i);
    if i < 10
        videoString = strcat("0",iStr); %add a "0" before 1...9[01, 02, 03]
    else
        videoString = iStr;
    end
    tracksFilename = sprintf('data/%s_tracks.csv', videoString);
    tracksStaticFilename = sprintf('data/%s_tracksMeta.csv', videoString);
    
    [tracks] = readInTracksCsv(tracksFilename, tracksStaticFilename);
    
    % Read video meta data from video meta file
    videoMetaFilename = sprintf('data/%s_recordingMeta.csv', videoString);
    videoMeta = readInVideoCsv(videoMetaFilename);
    
    %Store some Meta Data
    LocationID(i) = videoMeta.locationId;
    
    if ~any(LocationIDList == LocationID(i))
        continue
    end
    
    % START loop over tracks
    for j = 1 : length(tracks)
        % START delete error Veh IDs
        ErrorFound = 0;
        if ismember(i,error_ID_list(:,1)) && ismember(j,error_ID_list(:,2))
            for k = 1:length(error_ID_list)
                if i == error_ID_list(k,1) && j == error_ID_list(k,2)
                    ErrorFound = 1;
                end
            end
        end
        if ErrorFound == 1
            continue
        end
        
        % Get EGO data
        DriveDir = tracks(j).drivingDirection;
        InitialFrame = tracks(j).initialFrame;
        FinalFrame = tracks(j).finalFrame;
        LengthOfFrames = FinalFrame - InitialFrame + 1;
        TTCVec = tracks(j).ttc;
        VxVec = tracks(j).xVelocity;
        VyVec = tracks(j).yVelocity;
        AxVec = tracks(j).xAcceleration;
        AyVec = tracks(j).yAcceleration;
        bboxVec = tracks(j).bbox;
        Width = bboxVec(1,4);
        Length = bboxVec(1,3);
        LaneVec = tracks(j).lane;
        class = tracks(j).class;
        
        % The last value should be deleted
        TTCVec(end) = [];
        VxVec(end) = [];
        VyVec(end) = [];
        AxVec(end) = [];
        AyVec(end) = [];
        bboxVec(end,:) = [];
        LaneVec(end) = [];
        
        % Condition based on TTC threshold
        TTCVec(TTCVec<=0) = TTCthr +1;
        TTCidx = [];
        if any(TTCVec < TTCthr)
            TTCidx = find(TTCVec < TTCthr, 1, 'first');
        else
            continue
        end
        TTCidxGlobal = TTCidx + InitialFrame - 1;
        
        
        % Condition based on the position of the EGO
        if DriveDir == 1
            if bboxVec(TTCidx,1) > 370 || bboxVec(TTCidx,1) < 100
                continue
            end
            if LaneVec(TTCidx) ~= 3
                continue
            end
        else
            if bboxVec(TTCidx,1) < 40 || bboxVec(TTCidx,1) > 310
                continue
            end
            if LaneVec(TTCidx) ~= 7
                continue
            end
        end
        
        % Condition based on the existence of the EGO on the frame
        if TTCidxGlobal > FinalFrame - frameRate*ScLength
            continue
        end
        
        % Resetting the counter for the target vehicle for each scenario
        counter2 = 0;
        
        % START loop over the target vehicles
        for k = 1 : length(tracks)
            
            % Skip the EGO
            if j == k
                continue
            end
            DriveDirTG = tracks(k).drivingDirection;
            InitialFrameTG = tracks(k).initialFrame;
            FinalFrameTG = tracks(k).finalFrame;
            bboxVecTG = tracks(k).bbox;
            VxVecTG = tracks(k).xVelocity;
            VyVecTG = tracks(k).yVelocity;
            AxVecTG = tracks(k).xAcceleration;
            AyVecTG = tracks(k).yAcceleration;
            classTG = tracks(k).class;
            VxVecTG(end) = [];
            VyVecTG(end) = [];
            AxVecTG(end) = [];
            AyVecTG(end) = [];
            bboxVecTG(end,:) = [];
            LengthOfFramesTG = FinalFrame - InitialFrame + 1;
            TTCidxTG = TTCidxGlobal - InitialFrameTG + 1;
            TTCidxTGGlobal = TTCidxTG + InitialFrameTG -1;
            
            % Skip the target in the other driving direction
            if DriveDirTG ~= DriveDir
                continue
            end
            
            % Skip the target if it is not in the same EGO frame
            if InitialFrameTG > TTCidxGlobal || FinalFrameTG < TTCidxGlobal
                continue
            end
            
            % Skip the target if it is not in the frame for more than
            % scenario length
            if TTCidxTGGlobal > FinalFrameTG - frameRate*ScLength
                continue
            end
            
            % Skip the target if it is far than a distance from the EGO
            if DriveDirTG == 1
                distRel = bboxVec(TTCidx,1) - bboxVecTG(TTCidxTG,1);
            else
                distRel = bboxVecTG(TTCidxTG,1) - bboxVec(TTCidx,1);
            end
            
            if distRel > 90 || distRel < -30
                continue
            end
            
            % Number of target vehicles
            counter2= counter2+1;
            
            if counter2 == 0
                continue
            elseif counter2 == 1
                counter1 = counter1+1;
            end
            % Storing the target vehicle information
            scenario(counter1).Target(counter2).bbox = ...
                bboxVecTG(TTCidxTG:TTCidxTG+frameRate*ScLength-1,:);
            scenario(counter1).Target(counter2).Vx = ...
                VxVecTG(TTCidxTG:TTCidxTG+frameRate*ScLength-1,:);
            scenario(counter1).Target(counter2).Vy = ...
                VyVecTG(TTCidxTG:TTCidxTG+frameRate*ScLength-1,:);
            scenario(counter1).Target(counter2).Ax = ...
                AxVecTG(TTCidxTG:TTCidxTG+frameRate*ScLength-1,:);
            scenario(counter1).Target(counter2).Ay = ...
                AyVecTG(TTCidxTG:TTCidxTG+frameRate*ScLength-1,:);
            scenario(counter1).Target(counter2).xCG = ...
                scenario(counter1).Target(counter2).bbox(:,1)+...
                (scenario(counter1).Target(counter2).bbox(:,3)./2);
            scenario(counter1).Target(counter2).yCG = ...
                ySign*(scenario(counter1).Target(counter2).bbox(:,2)+...
                (scenario(counter1).Target(counter2).bbox(:,4)./2));
            scenario(counter1).Target(counter2).class = classTG;
        end
        % END loop over the target vehicles
        
        % EGO satisfying the condition
        if counter2~=0
            scenario(counter1).EGO.bbox =...
                bboxVec(TTCidx: TTCidx+(frameRate*ScLength)-1,:);
            scenario(counter1).EGO.Vx = ...
                VxVec(TTCidx: TTCidx+(frameRate*ScLength)-1);
            scenario(counter1).EGO.Vy = ...
                VyVec(TTCidx: TTCidx+(frameRate*ScLength)-1);
            scenario(counter1).EGO.Ax = ...
                AxVec(TTCidx: TTCidx+(frameRate*ScLength)-1);
            scenario(counter1).EGO.Ay = ...
                AyVec(TTCidx: TTCidx+(frameRate*ScLength)-1);
            scenario(counter1).EGO.xCG = ...
                scenario(counter1).EGO.bbox(:,1)+...
                (scenario(counter1).EGO.bbox(:,3)./2);
            scenario(counter1).EGO.yCG = ...
                ySign*(scenario(counter1).EGO.bbox(:,2)+...
                (scenario(counter1).EGO.bbox(:,4)./2));
            scenario(counter1).EGO.DriveDir = DriveDir;
            scenario(counter1).videoMeta = videoMeta;
            scenario(counter1).EGO.class = class;
        end
    end
    % END loop over the tracks
end
% END loop over the videos

%% Extracting the data corresponding to the algorithm coordinate frame
% START loop over the scenarios
for i = 1:size(scenario,2)
    if i == 1 || rem(i,10) == 0
        disp(['Extracting the data in algorithm'...
            'coordinate frame | in percent: ',...
            num2str(i/size(scenario,2)*100), '%']);
    end
    % Road data
    upperLanes = scenario(i).videoMeta.upperLanes;
    lowerLanes = scenario(i).videoMeta.lowerLanes;
    
    % EGO CoG
    xCG_EGO = scenario(i).EGO.xCG;
    yCG_EGO = scenario(i).EGO.yCG;
    xCG_EGO_New = zeros(size(xCG_EGO,1),1);
    yCG_EGO_New = zeros(size(yCG_EGO,1),1);
    
    % EGO dimensions
    width_EGO = scenario(i).EGO.bbox(1,4);
    length_EGO = scenario(i).EGO.bbox(1,3);
    
    % New EGO's CoG
    xCG_EGO_New(1) = 30;
    yCG_EGO_New(1) = 7.5;
    
    % Class of EGO
    class_EGO = scenario(i).EGO.class;
    
    if scenario(i).EGO.DriveDir == 1 % right to left
        
        % Road points
        x_Road = repmat(0:0.5:200, 4, 1);
        y_RoadPoints = (yCG_EGO(1)+upperLanes) + yCG_EGO_New(1);
        y_Road(1,:) = repmat(y_RoadPoints(1), 1, size(x_Road,2));
        y_Road(2,:) = repmat(y_RoadPoints(2), 1, size(x_Road,2));
        y_Road(3,:) = repmat(y_RoadPoints(3), 1, size(x_Road,2));
        y_Road(4,:) = repmat(y_RoadPoints(4), 1, size(x_Road,2));
        % width and length
        
        width_EGO_new = scenario(i).EGO.bbox(1,4);
        length_EGO_new = scenario(i).EGO.bbox(1,3);
        % Convert the velocity coordinate
        Vx_EGO_New = -scenario(i).EGO.Vx;
        Vy_EGO_New = scenario(i).EGO.Vy;
        V_EGO_New = sqrt(Vx_EGO_New.^2+Vx_EGO_New.^2);
        
        % Orientation of the EGO
        Psi_EGO_New = atan2d(Vy_EGO_New, Vx_EGO_New);
        
        % Acceleration of the EGO
        Ax_EGO_New = -scenario(i).EGO.Ax;
        Ay_EGO_New = scenario(i).EGO.Ay;
        
        % START loop over the scenario length
        for j = 2:size(xCG_EGO,1)
            xCG_EGO_New(j) = (xCG_EGO(j-1)-xCG_EGO(j))+xCG_EGO_New(j-1);
            yCG_EGO_New(j) = (yCG_EGO(j-1)-yCG_EGO(j))+yCG_EGO_New(j-1);
        end
        
        % START loop over the target vehicles
        for k = 1:size(scenario(i).Target,2)
            
            % Class of target
            class_Target{1,k} = scenario(i).Target(k).class;
            
            % Target dimensions
            width_Target(1,k) = scenario(i).Target(k).bbox(1,4);
            length_Target(1,k) = scenario(i).Target(k).bbox(1,3);
            
            % Target CoG
            xCG_Target(:,k) = scenario(i).Target(k).xCG;
            yCG_Target(:,k) = scenario(i).Target(k).yCG;
            
            % Update the CoG relative to EGO
            xCG_Target_New(1,k) = (xCG_EGO(1)-xCG_Target(1,k))+...
                xCG_EGO_New(1);
            yCG_Target_New(1,k) = (yCG_EGO(1)-yCG_Target(1,k))+...
                yCG_EGO_New(1);
            
            % Update the velocity coordinate for target
            Vx_Target_New = -scenario(i).Target(k).Vx;
            Vy_Target_New = scenario(i).Target(k).Vy;
            V_Target_New(:,k) = sqrt(Vx_Target_New.^2+Vy_Target_New.^2);
            
            % Orientation of the target
            Psi_Target_New(:,k) = atan2d(Vy_Target_New, Vx_Target_New);
            
            % Acceleration of the target
            Ax_Target_New(:,k) = -scenario(i).Target(k).Ax;
            Ay_Target_New(:,k) = scenario(i).Target(k).Ay;
            
            % START loop over the scenario length
            for l = 2:size(xCG_Target,1)
                % Transform target vehicles relative to new CoG of EGO
                xCG_Target_New(l,k) = (xCG_Target(l-1,k)-...
                    xCG_Target(l,k))+xCG_Target_New(l-1,k);
                yCG_Target_New(l,k) = (yCG_Target(l-1,k)-...
                    yCG_Target(l,k))+yCG_Target_New(l-1,k);
            end
            % END loop over the scenario length
            scenario(i).Target(k).xCG_New = xCG_Target_New(:,k);
            scenario(i).Target(k).yCG_New = yCG_Target_New(:,k);
            scenario(i).Target(k).v_New = V_Target_New(:,k);
            scenario(i).Target(k).psi_New = Psi_Target_New(:,k);
            scenario(i).Target(k).ax_New = Ax_Target_New(:,k);
            scenario(i).Target(k).ay_New = Ay_Target_New(:,k);
        end
        % END loop over the target vehicles
        
    elseif scenario(i).EGO.DriveDir == 2
        
        % Road points
        x_Road = repmat(0:0.5:200, 4, 1);
        y_RoadPoints = [1.7 5.4 9.1 12.8];
        y_Road(1,:) = repmat(y_RoadPoints(1), 1, size(x_Road,2));
        y_Road(2,:) = repmat(y_RoadPoints(2), 1, size(x_Road,2));
        y_Road(3,:) = repmat(y_RoadPoints(3), 1, size(x_Road,2));
        y_Road(4,:) = repmat(y_RoadPoints(4), 1, size(x_Road,2));
        
        % width and length
        
        width_EGO_new = scenario(i).EGO.bbox(1,4);
        length_EGO_new = scenario(i).EGO.bbox(1,3);
        
        % Convert the velocity coordinate for EGO
        Vx_EGO_New = scenario(i).EGO.Vx;
        Vy_EGO_New = -scenario(i).EGO.Vy;
        V_EGO_New = sqrt(Vx_EGO_New.^2+Vx_EGO_New.^2);
        
        % Orientation of the EGO
        Psi_EGO_New = atan2d(Vy_EGO_New, Vx_EGO_New);
        
        % Acceleration of the EGO
        Ax_EGO_New = -scenario(i).EGO.Ax;
        Ay_EGO_New = scenario(i).EGO.Ay;
        
        % START loop over the scenario length
        for j = 2:size(xCG_EGO,1)
            xCG_EGO_New(j) = (xCG_EGO(j)-xCG_EGO(j-1))+xCG_EGO_New(j-1);
            yCG_EGO_New(j) = (yCG_EGO(j)-yCG_EGO(j-1))+yCG_EGO_New(j-1);
        end
        % END loop over the scenario length
        % START loop over the target vehicles
        for k = 1:size(scenario(i).Target,2)
            % Class of target
            class_Target{1,k} = scenario(i).Target(k).class;
            
            % Target dimensions
            width_Target(1,k) = scenario(i).Target(k).bbox(1,4);
            length_Target(1,k) = scenario(i).Target(k).bbox(1,3);
            
            % Target CoG
            xCG_Target(:,k) = scenario(i).Target(k).xCG;
            yCG_Target(:,k) = scenario(i).Target(k).yCG;
            
            % Update the CoG relative to EGO
            xCG_Target_New(1,k) = (xCG_Target(1,k)-xCG_EGO(1))+...
                xCG_EGO_New(1);
            yCG_Target_New(1,k) = (yCG_Target(1,k)-yCG_EGO(1))+...
                yCG_EGO_New(1);
            
            % Update the velocity coordinate
            Vx_Target_New = scenario(i).Target(k).Vx;
            Vy_Target_New = -scenario(i).Target(k).Vy;
            V_Target_New(:,k) = sqrt(Vx_Target_New.^2+Vy_Target_New.^2);
            
            % Orientation of the target
            Psi_Target_New(:,k) = atan2d(Vy_Target_New, Vx_Target_New);
            
            % Acceleration of the target
            Ax_Target_New(:,k) = scenario(i).Target(k).Ax;
            Ay_Target_New(:,k) = -scenario(i).Target(k).Ay;
            
            % START loop over the scenario length
            for l = 2:size(xCG_Target,1)
                % Transform target vehicles relative to new CoG of EGO
                xCG_Target_New(l,k) = (xCG_Target(l,k)-...
                    xCG_Target(l-1,k))+xCG_Target_New(l-1,k);
                yCG_Target_New(l,k) = (yCG_Target(l,k)-...
                    yCG_Target(l-1,k))+yCG_Target_New(l-1,k);
            end
            % END loop over the scenario length
            scenario(i).Target(k).xCG_New = xCG_Target_New(:,k);
            scenario(i).Target(k).yCG_New = yCG_Target_New(:,k);
            scenario(i).Target(k).v_New = V_Target_New(:,k);
            scenario(i).Target(k).psi_New = Psi_Target_New(:,k);
            scenario(i).Target(k).ax_New = Ax_Target_New(:,k);
            scenario(i).Target(k).ay_New = Ay_Target_New(:,k);
        end
        % END loop over the target vehicles
    end
    scenario(i).EGO.xCG_New = xCG_EGO_New;
    scenario(i).EGO.yCG_New = yCG_EGO_New;
    scenario(i).EGO.v_New = V_EGO_New;
    scenario(i).EGO.psi_New = Psi_EGO_New;
    scenario(i).EGO.ax_New = Ax_EGO_New;
    scenario(i).EGO.ay_New = Ay_EGO_New;
    scenario(i).Road.x = x_Road;
    scenario(i).Road.y = y_Road;
end

%% Generate data

% Number of target in every extracted scenario
for i = 1:size(scenario,2)
    targetCount(i) = size(scenario(i).Target,2);
end

% Randomly select the values based on the scenario parameters
vehNo = noOfVehicle(randi(length(noOfVehicle),1,noOfScenarios));

for i = 1:noOfScenarios
    
    % Finding a scenario in the dataset with same number of targets
    id = find(targetCount==vehNo(i));
    
    % Randomly choose a scenario for position, type and orientation
    id1 = id(randi(length(id),1));
    
    % Position
    vehPosX = [];
    vehPosY = [];
    % Type of vehicle
    vehType = [];
    % Orientation
    vehPsi = [];
    % Lateral acceleration
    vehAy = [];
    % Lane position
    vehLanePos = [];
    % Vehicle length
    vehLength = [];
    % Vehicle width
    vehWidth = [];
    
    % Road points
    x_Road = scenario(id1).Road.x;
    y_Road = scenario(id1).Road.y+0.01;
    
    % Excluding the inner lanes
    x_Road(2:3,:) = [];
    y_Road(2:3,:) = [];
    
    % START loop over the target to sample position, type & orientation
    for j = 1:size(scenario(id1).Target,2)
        x = scenario(id1).Target(j).xCG_New(1);
        y = scenario(id1).Target(j).yCG_New(1);
        psi = scenario(id1).Target(j).psi_New(1);
        ay = scenario(id1).Target(j).ay_New(1);
        l = scenario(id1).Target(j).bbox(1,3);
        w = scenario(id1).Target(j).bbox(1,4);
        if (l > 8)
            type = 2;
        else
            type = 1;
        end
        % Lane positioning
        if y > 0 && y <= 5.8
            lane = 1;
        elseif y > 5.8 && y <= 9.47
            lane = 2;
        elseif y > 9.47 && y <=13.2
            lane = 3;
        end
        vehLength = [vehLength l];
        vehWidth = [vehWidth w];
        vehLanePos = [vehLanePos lane];
        vehPsi = [vehPsi psi];
        vehAy = [vehAy ay];
        vehType = [vehType type];
        vehPosX = [vehPosX x];
        vehPosY = [vehPosY y];
    end
    % END loop over the target to sample position, type and orientation
    
    % EGO vehicle information
    EGO.PosX = scenario(id1).EGO.xCG_New(1);
    EGO.PosY = scenario(id1).EGO.yCG_New(1);
    EGO.Vel = scenario(id1).EGO.v_New(1);
    EGO.Psi = scenario(id1).EGO.psi_New(1);
    EGO.Ax = scenario(id1).EGO.ax_New(1);
    EGO.Ay = scenario(id1).EGO.ay_New(1);
    if scenario(id1).EGO.bbox(3) > 8
        EGO.Type = 2;
    else
        EGO.Type = 1;
    end
    
    % Randomly choose a scenario for velocity
    id1 = id(randi(length(id),1));
    % Velocity
    vehVel = [];
    % START loop over the target to sample velocity
    for j = 1:size(scenario(id1).Target,2)
        v = scenario(id1).Target(j).v_New(1);
        if vehType(j) == 2 && v >= 28
            v = 28;
        end
        vehVel = [vehVel v];
    end
    % END loop over the target to sample velocity
    
    % Randomly choose a scenario for longitudinal acceleration
    id1 = id(randi(length(id),1));
    % Longitudinal acceleration
    vehAx = [];
    % START loop over the target to sample velocity
    for j = 1:size(scenario(id1).Target,2)
        ax = scenario(id1).Target(j).ax_New(1);
        vehAx = [vehAx ax];
    end
    % END loop over the target to sample velocity
    
    tic
    % Assignment of probabilities to the main hypotheses
    targetProbabilities = probEstimate(vehPosX, vehPosY, vehPsi,...
        vehVel, vehAx, vehAy, vehLanePos, vehType, EGO);
    
    % Two track model simulation
    % Simulation time
    T = 0.02;
    totalTime = 3.0;
    N=ceil(totalTime/T)+1;
    
    % Range of slip value
    maxMinSlip = -0.08:0.008:0.05;
    
    % START loop over the target to estimate their future positions
    for j = 1:size(vehPosX,2)
        % START loop over the multiple paths (lateral)
        for k = 1:9
            % Desired path
            % Distance that will be travelled longitudinally in 2s
            xDist = vehPosX(j)+vehVel(j)*3;
            xDes_Lane(k,:) = [linspace(vehPosX(j), xDist, 100)...
                linspace(xDist, 250, 200)];
            if k <=3
                yDes_Lane(k,:) = [linspace(vehPosY(j), 2+(0.95*k),...
                    100) repmat(2+(0.95*k),1, 200)];
            elseif k > 3 && j <=6
                yDes_Lane(k,:) = [linspace(vehPosY(j),...
                    5.8+(0.95*(k-3)), 100) repmat(5.8+(0.95*(k-3)),...
                    1, 200)];
            else
                yDes_Lane(k,:) = [linspace(vehPosY(j),...
                    9.47+(0.95*(k-6)), 100)...
                    repmat(9.47+(0.95*(k-6)),1, 200)];
            end
            p_fit = polyfit(xDes_Lane(k,:), yDes_Lane(k,:), 3);
            yDes_Lane(k,:) = polyval(p_fit, xDes_Lane(k,:));
            
            
            % START loop over the possible accelerations (longitudinal)
            for l = 1:size(maxMinSlip,2)
                % Vehicle lane position
                % Follow lane and left lane change
                if vehLanePos(j) == 1
                    vehicleDatabase(j,k,l) = Vehicle;
                    if k > 6
                        continue
                    end
                    % START loop over the time steps
                    for n = 2:N
                        vehicleDatabase(j,k,l).drive(vehPosX(j),...
                            vehPosY(j), deg2rad(vehPsi(j)), ...
                            vehVel(j), vehAx(j), vehAy(j),...
                            xDes_Lane(k,:), yDes_Lane(k,:),...
                            maxMinSlip(l), T, n, vehType(j),...
                            vehLength(j), vehWidth(j));
                    end
                    % END loop over the time steps
                    % Follow lane, left and right lane change
                elseif vehLanePos(j) == 2
                    vehicleDatabase(j,k,l) = Vehicle;
                    % START loop over the time steps
                    for n = 2:N
                        vehicleDatabase(j,k,l).drive(vehPosX(j),...
                            vehPosY(j), deg2rad(vehPsi(j)),...
                            vehVel(j), vehAx(j), vehAy(j),...
                            xDes_Lane(k,:), yDes_Lane(k,:),...
                            maxMinSlip(l), T, n, vehType(j),...
                            vehLength(j), vehWidth(j));
                    end
                    % END loop over the time steps
                    % Follow lane and right lane change
                else
                    vehicleDatabase(j,k,l) = Vehicle;
                    if k <=3
                        continue
                    end
                    % START loop over the time steps
                    for n = 2:N
                        vehicleDatabase(j,k,l).drive(vehPosX(j),...
                            vehPosY(j), deg2rad(vehPsi(j)),...
                            vehVel(j), vehAx(j), vehAy(j),...
                            xDes_Lane(k,:), yDes_Lane(k,:),...
                            maxMinSlip(l), T, n, vehType(j),...
                            vehLength(j), vehWidth(j));
                    end
                    % END loop over the time steps
                end
            end
            % END loop over the possible accelerations (longitudinal)
        end
        % END loop over the multiple paths (lateral)
    end
    % END loop over the target to estimate their future positions
    
    %% Assignment of probabilities to the hypotheses
    intervalPOG = 4:4:N;
    for n = 1:size(intervalPOG,2)
        probAssign(vehicleDatabase, targetProbabilities,...
            intervalPOG(n));
    end
    
    % Parameters for evaluation
    timeModelBased(i) = toc;
    vehicleCount(i) = j;
    
    %% Generation of AOGs and POGs
    AOG(i,:,:,:) = generateAOG(x_Road, y_Road,...
        vehicleDatabase);
    for l1 = 1:size(vehicleDatabase,1)
        for l2 = 1:size(vehicleDatabase,2)
            for l3 = 1:size(vehicleDatabase,3)
                vehicleDatabase1(l1,l2,l3).xCoordinates =...
                    vehicleDatabase(l1,l2,l3).xCoordinates;
                vehicleDatabase1(l1,l2,l3).yCoordinates =...
                    vehicleDatabase(l1,l2,l3).yCoordinates;
                if ~isempty(vehicleDatabase(l1,l2,l3).minProb)
                    vehicleDatabase1(l1,l2,l3).minProb =...
                        vehicleDatabase(l1,l2,l3).minProb;
                else
                    vehicleDatabase1(l1,l2,l3).minProb = 0;
                end
            end
        end
    end
    parfor n =1: size(intervalPOG,2)
        warning('off');
        generatedPOG(n,:,:) = generatePOG_mex(x_Road, y_Road,...
            vehicleDatabase1, intervalPOG(n));
    end
    POG(i,:,:,:) = generatedPOG;
    clear vehicleDatabase1 vehicleDatabase targetProbabilities
end
% END loop over number of scenarios

%% Pre processing of extracted data
% Scaling of AOG to lie within the interval [0,1]
AOG_Scaled = scaleAOG(AOG);
AOG_Scaled = single(AOG_Scaled);
POG = single(POG);
id_training = randsample(noOfScenarios, floor(0.7*noOfScenarios));
id_validation = setdiff(1:noOfScenarios, id_training);
AOG_Training = AOG_Scaled(id_training,:,:,:);
AOG_Validation = AOG_Scaled(id_validation,:,:,:);
POG_Train = POG(id_training,:,:,:);
POG_Validate = POG(id_validation,:,:,:);
% Reshaping to feed in as input to the network
POG_Training = [];
POG_Validation = [];
for i = 1:size(POG_Train,1)
    POG_Training = [POG_Training; squeeze(POG_Train(i,:,:,:))];
end
for i = 1:size(POG_Validate,1)
    POG_Validation = [POG_Validation; squeeze(POG_Validate(i,:,:,:))];
end

%% Saving the generated data
mkdir generatedData
saveDir = [pwd '\generatedData\'];
save([saveDir 'AOG_Training'], 'AOG_Training');
save([saveDir 'POG_Training'], 'POG_Training');
save([saveDir 'AOG_Validation'], 'AOG_Validation');
save([saveDir 'POG_Validation'], 'POG_Validation');
save([saveDir 'EvalMetric'], 'timeModelBased', 'vehicleCount');
