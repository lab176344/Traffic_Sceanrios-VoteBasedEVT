clear all;
clc;
close all;
%% INIT VARIABLES
load('error_ID_list.mat');
currentFolder = pwd;
addpath([currentFolder '\data'], [currentFolder '\utils']);
frameRate = 25;
ScLengthMin = 2; %unit: seconds
ySign = -1;
% Define Criticallity Measures
THW_thr = 4;
CritMeasures = [THW_thr];
critUsed = THW_thr;
counter1 = 0;

cntType1 = 1;  % Lane Change EGO
cntType2 = 1;  % Dec Following
cntType3 = 1;  % Left Cut-In
cntType4 = 1;  % Right Cut-In
cntType5 = 1;  % Acc Following
cntType6 = 1;  % Normal Following
cntType7 = 1;  % Lane Change Left
cntType8 = 1;  % Left Lane Cutout
cntType9 = 1;  % Right Lane Cutout

withoutFollow = 1;
foundLakshScenario = 1;
scenario_lnchange = struct;
scenario_following = struct;
scenario_cutin = struct;

scenario_lnchangeright_plot_no = [];
scenario_lnchangeleft_plot_no = [];
scenario_following_plot_no = [];
scenario_leftcutin_plot_no = [];
scenario_rightcutin_plot_no = [];
scenario_followingacc_plot_no = [];
scenario_followingdec_plot_no = [];
scenario_rightcutout_plot_no = [];
scenario_leftcutout_plot_no = [];

Veh_ID_Record = [];
Features = [];
FeaturesRecord = [];
Scenarios_Frames_Record = [];
Simulation_Frames_Record = [];
nTracks = 2;

%% LOAD TRACK DATA
for i = 1:nTracks
    % 60 tracks available
    display(['Running videoString = ', num2str(i), ' | in percent: ', num2str(i/nTracks*100), '%']);
    clear videoString iStr tracksFileName tracksStaticFilename tracks Scenarios toDelete Veh_ID
    %get videoString (videoString = "01" ... "60")
    iStr = num2str(i);
    if i < 10
        videoString = strcat("0",iStr); %add a "0" before 1...9 [01, 02, 03]
    else
        videoString = iStr;
    end
    tracksFilename = sprintf('data/%s_tracks.csv', videoString);
    tracksStaticFilename = sprintf('data/%s_tracksMeta.csv', videoString);
    
    [tracks] = readInTracksCsv(tracksFilename, tracksStaticFilename);
    
    % Read video meta data from video meta file
    videoMetaFilename = sprintf('data/%s_recordingMeta.csv', videoString);
    videoMeta = readInVideoCsv(videoMetaFilename);
    
    %% START LOOP OVER ALL TRACKS PER VIDEO
    cnt = 1;
    cnt2 = 1;
    toDelete = [];
    Veh_ID = [];
    Scenarios = tracks;
    
    for j = 1 : length(tracks)
        if tracks(j).minTHW > THW_thr || tracks(j).minTHW < 0
            toDelete(cnt,1) = j;
            cnt = cnt+1;
            continue
        elseif ismember(i,error_ID_list(:,1)) && ismember(j,error_ID_list(:,2)) %delete error datapoints
            toDelete(cnt,1) = j;
            cnt = cnt+1;
            continue
        else
            Veh_ID(cnt2,1) = i; %videostram ID
            Veh_ID(cnt2,2) = j; %veh ID within videostream
            cnt2 = cnt2 + 1;
            
            %% START ADD PARTHAS CODE FOR EASY VIZUALIZATION (output: "scenarios" variable)
            % Get EGO data
            DriveDir = tracks(j).drivingDirection;
            InitialFrame = tracks(j).initialFrame;
            FinalFrame = tracks(j).finalFrame;
            LengthOfFrames = FinalFrame - InitialFrame + 1;
            TTCVec = tracks(j).ttc;
            THWVec = tracks(j).thw;
            DHWVec = tracks(j).dhw;
            VxVec = tracks(j).xVelocity;
            VyVec = tracks(j).yVelocity;
            AxVec = tracks(j).xAcceleration;
            AyVec = tracks(j).yAcceleration;
            bboxVec = tracks(j).bbox;
            tsVec = tracks(j).frames;
            Width = bboxVec(1,4);
            Length = bboxVec(1,3);
            LaneVec = tracks(j).lane;
            class = tracks(j).class;
            
            % The last value should be deleted
            TTCVec(end) = [];
            THWVec(end) = [];
            DHWVec(end) = [];
            VxVec(end) = [];
            VyVec(end) = [];
            AxVec(end) = [];
            AyVec(end) = [];
            bboxVec(end,:) = [];
            tsVec(end) = [];
            LaneVec(end) = [];
            class(end) = [];
            
            %Find Global Index for Scenario Start (FK Code):
            ScEnd = [];
            ScEnd = find(THWVec<=THW_thr & THWVec>0, 1,'last'); % find last frame fullfilling conditions
            ScEndIdxGlobal = InitialFrame + ScEnd -1;
            ScStart = ScEnd - ScLengthMin*frameRate; % 25fps
            ScLength = (ScEnd - ScStart + 1) / frameRate;
            
            if (ScLength) < ScLengthMin
                toDelete(cnt,1) = j;
                cnt = cnt+1;
                continue
            end
            
            ScStartIdx = ScStart;
            ScStartIdxGlobal = InitialFrame + ScStart -1;
            
            if ScStartIdxGlobal < tracks(j).initialFrame
                toDelete(cnt,1) = j;
                cnt = cnt+1;
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
                tsVecTG = tracks(k).frames;
                IDTG = tracks(k).id;
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
                tsVecTG(end) = [];
                classTG(end) = [];
                LengthOfFramesTG = FinalFrameTG - InitialFrameTG + 1;
                ScStartIdxTG = ScStartIdxGlobal - InitialFrameTG + 1;
                ScStartIdxTGGlobal = ScStartIdxTG + InitialFrameTG -1;
                
                % Skip the target in the other driving direction
                if DriveDirTG ~= DriveDir
                    continue
                end
                
                % Skip the target if it is not in the same EGO frame
                if InitialFrameTG > ScStartIdxGlobal || FinalFrameTG < ScStartIdxGlobal
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
                
                if ScStartIdxTG+frameRate*ScLength-1 > tracks(k).numFrames -1
                    TGfinalFrameRecord = round(tracks(k).numFrames - 1);  %added round to make it a integer, avoid warning message
                else
                    TGfinalFrameRecord = round(ScStartIdxTG+frameRate*ScLength-1); %added round to make it a integer, avoid warning message
                end
                
                scenario(counter1).Target(counter2).id = ...
                    IDTG;
                scenario(counter1).Target(counter2).bbox = ...
                    bboxVecTG(ScStartIdxTG:TGfinalFrameRecord,:);
                scenario(counter1).Target(counter2).timestamp = ...
                    tsVecTG(ScStartIdxTG:TGfinalFrameRecord,:);
                scenario(counter1).Target(counter2).Vx = ...
                    VxVecTG(ScStartIdxTG:TGfinalFrameRecord,:);
                scenario(counter1).Target(counter2).Vy = ...
                    VyVecTG(ScStartIdxTG:TGfinalFrameRecord,:);
                scenario(counter1).Target(counter2).Ax = ...
                    AxVecTG(ScStartIdxTG:TGfinalFrameRecord,:);
                scenario(counter1).Target(counter2).Ay = ...
                    AyVecTG(ScStartIdxTG:TGfinalFrameRecord,:);
                scenario(counter1).Target(counter2).xCG = ...
                    scenario(counter1).Target(counter2).bbox(:,1)+...
                    (scenario(counter1).Target(counter2).bbox(:,3)./2);
                scenario(counter1).Target(counter2).yCG = ...
                    ySign*(scenario(counter1).Target(counter2).bbox(:,2)+...
                    (scenario(counter1).Target(counter2).bbox(:,4)./2));
                scenario(counter1).Target(counter2).class = classTG;
                
            end
            
            % Number of EGO satisfying the condition
            if counter2~=0
                scenario(counter1).EGO.timestamp =...
                    tsVec(ScStartIdx: ScStartIdx+round(frameRate*ScLength)-1,:);  %added round to make it a integer, avoid warning message
                scenario(counter1).EGO.bbox =...
                    bboxVec(ScStartIdx: ScStartIdx+round(frameRate*ScLength)-1,:);  %added round to make it a integer, avoid warning message
                scenario(counter1).EGO.Vx = ...
                    VxVec(ScStartIdx: ScStartIdx+round(frameRate*ScLength)-1);
                scenario(counter1).EGO.Vy = ...
                    VyVec(ScStartIdx: ScStartIdx+round(frameRate*ScLength)-1);
                scenario(counter1).EGO.Ax = ...
                    AxVec(ScStartIdx: ScStartIdx+round(frameRate*ScLength)-1);
                scenario(counter1).EGO.Ay = ...
                    AyVec(ScStartIdx: ScStartIdx+round(frameRate*ScLength)-1);
                scenario(counter1).EGO.ttc = ...
                    TTCVec(ScStartIdx: ScStartIdx+round(frameRate*ScLength)-1);
                scenario(counter1).EGO.thw = ...
                    THWVec(ScStartIdx: ScStartIdx+round(frameRate*ScLength)-1);
                scenario(counter1).EGO.dhw = ...
                    DHWVec(ScStartIdx: ScStartIdx+round(frameRate*ScLength)-1);
                scenario(counter1).EGO.xCG = ...
                    scenario(counter1).EGO.bbox(:,1)+...
                    (scenario(counter1).EGO.bbox(:,3)./2);
                scenario(counter1).EGO.yCG = ...
                    ySign*(scenario(counter1).EGO.bbox(:,2)+...
                    (scenario(counter1).EGO.bbox(:,4)./2));
                scenario(counter1).EGO.DriveDir = DriveDir;
                scenario(counter1).videoMeta = videoMeta;
                scenario(counter1).EGO.class = class;
                
                %% STORE LAKSHMAN DATA
                if Scenarios(j).numLaneChanges > 0
                    LaneVec = tracks(j).lane;
                    LaneVecSc = LaneVec(ScStart:ScEnd);
                    LaneVecScUnique = unique(LaneVecSc);
                    if length(LaneVecScUnique) > 1
                        if(Scenarios(j).drivingDirection==1)
                            
                            if(Scenarios(j).yVelocity(ScEnd)<0)
                                scenario_lnchangeleft(cntType1).EGO.bbox = scenario(counter1).EGO.bbox;
                                scenario_lnchangeleft(cntType1).EGO.timestamp = scenario(counter1).EGO.timestamp;
                                scenario_lnchangeleft(cntType1).EGO.xCG = scenario(counter1).EGO.bbox(:,1)+(scenario(counter1).EGO.bbox(:,3)./2);
                                scenario_lnchangeleft(cntType1).EGO.yCG = ySign*(scenario(counter1).EGO.bbox(:,2)+...
                                    (scenario(counter1).EGO.bbox(:,4)./2));
                                scenario_lnchangeleft(cntType1).EGO.DriveDir = DriveDir;
                                scenario_lnchangeleft(cntType1).videoMeta = videoMeta;
                                scenario_lnchangeleft(cntType1).EGO.Vx = scenario(counter1).EGO.Vx;
                                scenario_lnchangeleft(cntType1).EGO.Vy = scenario(counter1).EGO.Vy;
                                scenario_lnchangeleft(cntType1).EGO.class = class;
                                
                                for q = 1 : length(scenario(counter1).Target)
                                    scenario_lnchangeleft(cntType1).Target(q).bbox = scenario(counter1).Target(q).bbox;
                                    scenario_lnchangeleft(cntType1).Target(q).timestamp = scenario(counter1).Target(q).timestamp;
                                    scenario_lnchangeleft(cntType1).Target(q).xCG = ...
                                        scenario(counter1).Target(q).bbox(:,1)+...
                                        (scenario(counter1).Target(q).bbox(:,3)./2);
                                    scenario_lnchangeleft(cntType1).Target(q).yCG = ...
                                        ySign*(scenario(counter1).Target(q).bbox(:,2)+...
                                        (scenario(counter1).Target(q).bbox(:,4)./2));
                                    scenario_lnchangeleft(cntType1).Target(q).class = classTG;
                                    scenario_lnchangeleft(cntType1).Target(q).Vx = scenario(counter1).Target(q).Vx;
                                    scenario_lnchangeleft(cntType1).Target(q).Vy = scenario(counter1).Target(q).Vy;
                                end
                                cntType1 = cntType1 + 1;
                                scenario_lnchangeleft_plot_no = [scenario_lnchangeleft_plot_no, counter1];
                                foundLakshScenario = foundLakshScenario + 1;
                            else
                                scenario_lnchangeright(cntType7).EGO.bbox = scenario(counter1).EGO.bbox;
                                scenario_lnchangeright(cntType7).EGO.timestamp = scenario(counter1).EGO.timestamp;
                                scenario_lnchangeright(cntType7).EGO.xCG = scenario(counter1).EGO.bbox(:,1)+(scenario(counter1).EGO.bbox(:,3)./2);
                                scenario_lnchangeright(cntType7).EGO.yCG = ySign*(scenario(counter1).EGO.bbox(:,2)+...
                                    (scenario(counter1).EGO.bbox(:,4)./2));
                                scenario_lnchangeright(cntType7).EGO.DriveDir = DriveDir;
                                scenario_lnchangeright(cntType7).videoMeta = videoMeta;
                                scenario_lnchangeright(cntType7).EGO.Vx = scenario(counter1).EGO.Vx;
                                scenario_lnchangeright(cntType7).EGO.Vy = scenario(counter1).EGO.Vy;
                                scenario_lnchangeright(cntType7).EGO.class = class;
                                
                                for q = 1 : length(scenario(counter1).Target)
                                    scenario_lnchangeright(cntType7).Target(q).bbox = scenario(counter1).Target(q).bbox;
                                    scenario_lnchangeright(cntType7).Target(q).timestamp = scenario(counter1).Target(q).timestamp;
                                    scenario_lnchangeright(cntType7).Target(q).xCG = ...
                                        scenario(counter1).Target(q).bbox(:,1)+...
                                        (scenario(counter1).Target(q).bbox(:,3)./2);
                                    scenario_lnchangeright(cntType7).Target(q).yCG = ...
                                        ySign*(scenario(counter1).Target(q).bbox(:,2)+...
                                        (scenario(counter1).Target(q).bbox(:,4)./2));
                                    scenario_lnchangeright(cntType7).Target(q).class = classTG;
                                    scenario_lnchangeright(cntType7).Target(q).Vx = scenario(counter1).Target(q).Vx;
                                    scenario_lnchangeright(cntType7).Target(q).Vy = scenario(counter1).Target(q).Vy;
                                end
                                cntType7 = cntType7 + 1;
                                scenario_lnchangeright_plot_no = [scenario_lnchangeright_plot_no, counter1];
                                foundLakshScenario = foundLakshScenario + 1;
                            end
                        else
                            if(Scenarios(j).yVelocity(ScEnd)>0)
                                scenario_lnchangeleft(cntType1).EGO.bbox = scenario(counter1).EGO.bbox;
                                scenario_lnchangeleft(cntType1).EGO.timestamp = scenario(counter1).EGO.timestamp;
                                scenario_lnchangeleft(cntType1).EGO.xCG = scenario(counter1).EGO.bbox(:,1)+(scenario(counter1).EGO.bbox(:,3)./2);
                                scenario_lnchangeleft(cntType1).EGO.yCG = ySign*(scenario(counter1).EGO.bbox(:,2)+...
                                    (scenario(counter1).EGO.bbox(:,4)./2));
                                scenario_lnchangeleft(cntType1).EGO.DriveDir = DriveDir;
                                scenario_lnchangeleft(cntType1).videoMeta = videoMeta;
                                scenario_lnchangeleft(cntType1).EGO.Vx = scenario(counter1).EGO.Vx;
                                scenario_lnchangeleft(cntType1).EGO.Vy = scenario(counter1).EGO.Vy;
                                scenario_lnchangeleft(cntType1).EGO.class = class;
                                
                                for q = 1 : length(scenario(counter1).Target)
                                    scenario_lnchangeleft(cntType1).Target(q).bbox = scenario(counter1).Target(q).bbox;
                                    scenario_lnchangeleft(cntType1).Target(q).timestamp = scenario(counter1).Target(q).timestamp;
                                    scenario_lnchangeleft(cntType1).Target(q).xCG = ...
                                        scenario(counter1).Target(q).bbox(:,1)+...
                                        (scenario(counter1).Target(q).bbox(:,3)./2);
                                    scenario_lnchangeleft(cntType1).Target(q).yCG = ...
                                        ySign*(scenario(counter1).Target(q).bbox(:,2)+...
                                        (scenario(counter1).Target(q).bbox(:,4)./2));
                                    scenario_lnchangeleft(cntType1).Target(q).class = classTG;
                                    scenario_lnchangeleft(cntType1).Target(q).Vx = scenario(counter1).Target(q).Vx;
                                    scenario_lnchangeleft(cntType1).Target(q).Vy = scenario(counter1).Target(q).Vy;
                                end
                                cntType1 = cntType1 + 1;
                                scenario_lnchangeleft_plot_no = [scenario_lnchangeleft_plot_no, counter1];
                                foundLakshScenario = foundLakshScenario + 1;
                            else
                                scenario_lnchangeright(cntType7).EGO.bbox = scenario(counter1).EGO.bbox;
                                scenario_lnchangeright(cntType7).EGO.timestamp = scenario(counter1).EGO.timestamp;
                                scenario_lnchangeright(cntType7).EGO.xCG = scenario(counter1).EGO.bbox(:,1)+(scenario(counter1).EGO.bbox(:,3)./2);
                                scenario_lnchangeright(cntType7).EGO.yCG = ySign*(scenario(counter1).EGO.bbox(:,2)+...
                                    (scenario(counter1).EGO.bbox(:,4)./2));
                                scenario_lnchangeright(cntType7).EGO.DriveDir = DriveDir;
                                scenario_lnchangeright(cntType7).videoMeta = videoMeta;
                                scenario_lnchangeright(cntType7).EGO.Vx = scenario(counter1).EGO.Vx;
                                scenario_lnchangeright(cntType7).EGO.Vy = scenario(counter1).EGO.Vy;
                                scenario_lnchangeright(cntType7).EGO.class = class;
                                
                                for q = 1 : length(scenario(counter1).Target)
                                    scenario_lnchangeright(cntType7).Target(q).bbox = scenario(counter1).Target(q).bbox;
                                    scenario_lnchangeright(cntType7).Target(q).timestamp = scenario(counter1).Target(q).timestamp;
                                    scenario_lnchangeright(cntType7).Target(q).xCG = ...
                                        scenario(counter1).Target(q).bbox(:,1)+...
                                        (scenario(counter1).Target(q).bbox(:,3)./2);
                                    scenario_lnchangeright(cntType7).Target(q).yCG = ...
                                        ySign*(scenario(counter1).Target(q).bbox(:,2)+...
                                        (scenario(counter1).Target(q).bbox(:,4)./2));
                                    scenario_lnchangeright(cntType7).Target(q).class = classTG;
                                    scenario_lnchangeright(cntType7).Target(q).Vx = scenario(counter1).Target(q).Vx;
                                    scenario_lnchangeright(cntType7).Target(q).Vy = scenario(counter1).Target(q).Vy;
                                end
                                cntType7 = cntType7 + 1;
                                scenario_lnchangeright_plot_no = [scenario_lnchangeright_plot_no, counter1];
                                foundLakshScenario = foundLakshScenario + 1;
                            end
                        end
                    end
                elseif (Scenarios(j).precedingId(ScStart) == Scenarios(j).precedingId(ScEnd)) && Scenarios(j).precedingId(ScStart) > 0
                    speed_follow = Scenarios(j).precedingXVelocity(ScStart:ScEnd);
                    speed_diff = abs(speed_follow(1)) - abs(speed_follow(end));
                    if(speed_diff <=-2)
                        scenario_followingdec(cntType2).EGO.bbox = scenario(counter1).EGO.bbox;
                        scenario_followingdec(cntType2).EGO.timestamp = scenario(counter1).EGO.timestamp;
                        scenario_followingdec(cntType2).EGO.xCG = scenario(counter1).EGO.bbox(:,1)+(scenario(counter1).EGO.bbox(:,3)./2);
                        scenario_followingdec(cntType2).EGO.yCG = ySign*(scenario(counter1).EGO.bbox(:,2)+...
                            (scenario(counter1).EGO.bbox(:,4)./2));
                        scenario_followingdec(cntType2).EGO.DriveDir = DriveDir;
                        scenario_followingdec(cntType2).videoMeta = videoMeta;
                        scenario_followingdec(cntType2).EGO.class = class;
                        scenario_followingdec(cntType2).EGO.Vx = scenario(counter1).EGO.Vx;
                        scenario_followingdec(cntType2).EGO.Vy = scenario(counter1).EGO.Vy;
                        
                        for q = 1 : length(scenario(counter1).Target)
                            scenario_followingdec(cntType2).Target(q).bbox = scenario(counter1).Target(q).bbox;
                            scenario_followingdec(cntType2).Target(q).timestamp = scenario(counter1).Target(q).timestamp;
                            scenario_followingdec(cntType2).Target(q).xCG = ...
                                scenario(counter1).Target(q).bbox(:,1)+...
                                (scenario(counter1).Target(q).bbox(:,3)./2);
                            scenario_followingdec(cntType2).Target(q).yCG = ...
                                ySign*(scenario(counter1).Target(q).bbox(:,2)+...
                                (scenario(counter1).Target(q).bbox(:,4)./2));
                            scenario_followingdec(cntType2).Target(q).class = class;
                            scenario_followingdec(cntType2).Target(q).Vx = scenario(counter1).Target(q).Vx;
                            scenario_followingdec(cntType2).Target(q).Vy = scenario(counter1).Target(q).Vy;
                        end
                        cntType2 = cntType2 + 1;
                        scenario_followingdec_plot_no = [scenario_followingdec_plot_no, counter1];
                        foundLakshScenario = foundLakshScenario + 1;
                    elseif(speed_diff>2)
                        scenario_followingacc(cntType5).EGO.bbox = scenario(counter1).EGO.bbox;
                        scenario_followingacc(cntType5).EGO.timestamp = scenario(counter1).EGO.timestamp;
                        scenario_followingacc(cntType5).EGO.xCG = scenario(counter1).EGO.bbox(:,1)+(scenario(counter1).EGO.bbox(:,3)./2);
                        scenario_followingacc(cntType5).EGO.yCG = ySign*(scenario(counter1).EGO.bbox(:,2)+...
                            (scenario(counter1).EGO.bbox(:,4)./2));
                        scenario_followingacc(cntType5).EGO.DriveDir = DriveDir;
                        scenario_followingacc(cntType5).videoMeta = videoMeta;
                        scenario_followingacc(cntType5).EGO.class = class;
                        scenario_followingacc(cntType5).EGO.Vx = scenario(counter1).EGO.Vx;
                        scenario_followingacc(cntType5).EGO.Vy = scenario(counter1).EGO.Vy;
                        for q = 1 : length(scenario(counter1).Target)
                            scenario_followingacc(cntType5).Target(q).bbox = scenario(counter1).Target(q).bbox;
                            scenario_followingacc(cntType5).Target(q).timestamp = scenario(counter1).Target(q).timestamp;
                            scenario_followingacc(cntType5).Target(q).xCG = ...
                                scenario(counter1).Target(q).bbox(:,1)+...
                                (scenario(counter1).Target(q).bbox(:,3)./2);
                            scenario_followingacc(cntType5).Target(q).yCG = ...
                                ySign*(scenario(counter1).Target(q).bbox(:,2)+...
                                (scenario(counter1).Target(q).bbox(:,4)./2));
                            scenario_followingacc(cntType5).Target(q).class = class;
                            scenario_followingacc(cntType5).Target(q).Vx = scenario(counter1).Target(q).Vx;
                            scenario_followingacc(cntType5).Target(q).Vy = scenario(counter1).Target(q).Vy;
                        end
                        cntType5 = cntType5 + 1;
                        scenario_followingacc_plot_no = [scenario_followingacc_plot_no, counter1];
                        foundLakshScenario = foundLakshScenario + 1;
                    else
                        scenario_following(cntType6).EGO.bbox = scenario(counter1).EGO.bbox;
                        scenario_following(cntType6).EGO.timestamp = scenario(counter1).EGO.timestamp;
                        scenario_following(cntType6).EGO.xCG = scenario(counter1).EGO.bbox(:,1)+(scenario(counter1).EGO.bbox(:,3)./2);
                        scenario_following(cntType6).EGO.yCG = ySign*(scenario(counter1).EGO.bbox(:,2)+...
                            (scenario(counter1).EGO.bbox(:,4)./2));
                        scenario_following(cntType6).EGO.DriveDir = DriveDir;
                        scenario_following(cntType6).videoMeta = videoMeta;
                        scenario_following(cntType6).EGO.class = class;
                        scenario_following(cntType6).EGO.Vx = scenario(counter1).EGO.Vx;
                        scenario_following(cntType6).EGO.Vy = scenario(counter1).EGO.Vy;
                        for q = 1 : length(scenario(counter1).Target)
                            scenario_following(cntType6).Target(q).bbox = scenario(counter1).Target(q).bbox;
                            scenario_following(cntType6).Target(q).timestamp = scenario(counter1).Target(q).timestamp;
                            scenario_following(cntType6).Target(q).xCG = ...
                                scenario(counter1).Target(q).bbox(:,1)+...
                                (scenario(counter1).Target(q).bbox(:,3)./2);
                            scenario_following(cntType6).Target(q).yCG = ...
                                ySign*(scenario(counter1).Target(q).bbox(:,2)+...
                                (scenario(counter1).Target(q).bbox(:,4)./2));
                            scenario_following(cntType6).Target(q).class = class;
                            scenario_following(cntType6).Target(q).Vx = scenario(counter1).Target(q).Vx;
                            scenario_following(cntType6).Target(q).Vy = scenario(counter1).Target(q).Vy;
                            
                            
                        end
                        cntType6 = cntType6 + 1;
                        scenario_following_plot_no = [scenario_following_plot_no, counter1];
                        foundLakshScenario = foundLakshScenario + 1;
                    end
                    
                elseif(Scenarios(j).precedingId(ScStart) ~= Scenarios(j).precedingId(ScEnd)) && Scenarios(j).precedingId(ScStart) > 0
                    IDleader = Scenarios(j).precedingId(ScStart);
                    findIdxScEndLeader = find(Scenarios(IDleader).frames == ScEndIdxGlobal); %global timestamp must equal
                    findIdyScStartLeader = find(Scenarios(IDleader).frames == ScStartIdxGlobal);
                    LnLeaderScEnd = Scenarios(IDleader).lane(findIdxScEndLeader);
                    lnLeaderStart = Scenarios(IDleader).lane(findIdyScStartLeader);
                    leftAlong = any(Scenarios(j).precedingId(ScStart) == Scenarios(j).leftAlongsideId);
                    leftBack = any(Scenarios(j).precedingId(ScStart) == Scenarios(j).leftFollowingId);
                    leftPreceeding = any(Scenarios(j).precedingId(ScStart) == Scenarios(j).leftPrecedingId);
                    rightAlong = any(Scenarios(j).precedingId(ScStart) == Scenarios(j).rightAlongsideId);
                    rightBack = any(Scenarios(j).precedingId(ScStart) == Scenarios(j).rightFollowingId);
                    rightPreceeding = any(Scenarios(j).precedingId(ScStart) == Scenarios(j).rightPrecedingId);
                    
                    
                    if(leftAlong || leftBack || leftPreceeding || rightAlong || rightBack || rightPreceeding)
                        
                        if isempty(LnLeaderScEnd) || LnLeaderScEnd ~= Scenarios(j).lane(ScEnd) && Scenarios(IDleader).drivingDirection == Scenarios(j).drivingDirection
                            if(Scenarios(IDleader).drivingDirection==1)
                                if(Scenarios(IDleader).yVelocity(findIdxScEndLeader)<0)
                                    scenario_leftcutout(cntType9).EGO.bbox = scenario(counter1).EGO.bbox;
                                    scenario_leftcutout(cntType9).EGO.timestamp = scenario(counter1).EGO.timestamp;
                                    scenario_leftcutout(cntType9).EGO.xCG = scenario(counter1).EGO.bbox(:,1)+(scenario(counter1).EGO.bbox(:,3)./2);
                                    scenario_leftcutout(cntType9).EGO.yCG = ySign*(scenario(counter1).EGO.bbox(:,2)+...
                                        (scenario(counter1).EGO.bbox(:,4)./2));
                                    scenario_leftcutout(cntType9).EGO.DriveDir = DriveDir;
                                    scenario_leftcutout(cntType9).videoMeta = videoMeta;
                                    scenario_leftcutout(cntType9).EGO.class = class;
                                    scenario_leftcutout(cntType9).EGO.Vx = scenario(counter1).EGO.Vx;
                                    scenario_leftcutout(cntType9).EGO.Vy = scenario(counter1).EGO.Vy;
                                    
                                    for q = 1 : length(scenario(counter1).Target)
                                        
                                        scenario_leftcutout(cntType9).Target(q).bbox = scenario(counter1).Target(q).bbox;
                                        scenario_leftcutout(cntType9).Target(q).timestamp = scenario(counter1).Target(q).timestamp;
                                        scenario_leftcutout(cntType9).Target(q).xCG = ...
                                            scenario(counter1).Target(q).bbox(:,1)+...
                                            (scenario(counter1).Target(q).bbox(:,3)./2);
                                        scenario_leftcutout(cntType9).Target(q).yCG = ...
                                            ySign*(scenario(counter1).Target(q).bbox(:,2)+...
                                            (scenario(counter1).Target(q).bbox(:,4)./2));
                                        scenario_leftcutout(cntType9).Target(q).class = class;
                                        scenario_leftcutout(cntType9).Target(q).Vx = scenario(counter1).Target(q).Vx;
                                        scenario_leftcutout(cntType9).Target(q).Vy = scenario(counter1).Target(q).Vy;
                                    end
                                    cntType9 = cntType9 + 1;
                                    scenario_leftcutout_plot_no = [scenario_leftcutout_plot_no, counter1];
                                    foundLakshScenario = foundLakshScenario + 1;
                                else
                                    scenario_rightcutout(cntType8).EGO.bbox = scenario(counter1).EGO.bbox;
                                    scenario_rightcutout(cntType8).EGO.timestamp = scenario(counter1).EGO.timestamp;
                                    scenario_rightcutout(cntType8).EGO.xCG = scenario(counter1).EGO.bbox(:,1)+(scenario(counter1).EGO.bbox(:,3)./2);
                                    scenario_rightcutout(cntType8).EGO.yCG = ySign*(scenario(counter1).EGO.bbox(:,2)+...
                                        (scenario(counter1).EGO.bbox(:,4)./2));
                                    scenario_rightcutout(cntType8).EGO.DriveDir = DriveDir;
                                    scenario_rightcutout(cntType8).videoMeta = videoMeta;
                                    scenario_rightcutout(cntType8).EGO.class = class;
                                    scenario_rightcutout(cntType8).EGO.Vx = scenario(counter1).EGO.Vx;
                                    scenario_rightcutout(cntType8).EGO.Vy = scenario(counter1).EGO.Vy;
                                    
                                    for q = 1 : length(scenario(counter1).Target)
                                        
                                        scenario_rightcutout(cntType8).Target(q).bbox = scenario(counter1).Target(q).bbox;
                                        scenario_rightcutout(cntType8).Target(q).timestamp = scenario(counter1).Target(q).timestamp;
                                        scenario_rightcutout(cntType8).Target(q).xCG = ...
                                            scenario(counter1).Target(q).bbox(:,1)+...
                                            (scenario(counter1).Target(q).bbox(:,3)./2);
                                        scenario_rightcutout(cntType8).Target(q).yCG = ...
                                            ySign*(scenario(counter1).Target(q).bbox(:,2)+...
                                            (scenario(counter1).Target(q).bbox(:,4)./2));
                                        scenario_rightcutout(cntType8).Target(q).class = class;
                                        scenario_rightcutout(cntType8).Target(q).Vx = scenario(counter1).Target(q).Vx;
                                        scenario_rightcutout(cntType8).Target(q).Vy = scenario(counter1).Target(q).Vy;
                                    end
                                    cntType8 = cntType8 + 1;
                                    scenario_rightcutout_plot_no = [scenario_rightcutout_plot_no, counter1];
                                    foundLakshScenario = foundLakshScenario + 1;
                                end
                            else
                                if(Scenarios(IDleader).yVelocity(findIdxScEndLeader)>0)
                                    scenario_leftcutout(cntType9).EGO.bbox = scenario(counter1).EGO.bbox;
                                    scenario_leftcutout(cntType9).EGO.timestamp = scenario(counter1).EGO.timestamp;
                                    scenario_leftcutout(cntType9).EGO.xCG = scenario(counter1).EGO.bbox(:,1)+(scenario(counter1).EGO.bbox(:,3)./2);
                                    scenario_leftcutout(cntType9).EGO.yCG = ySign*(scenario(counter1).EGO.bbox(:,2)+...
                                        (scenario(counter1).EGO.bbox(:,4)./2));
                                    scenario_leftcutout(cntType9).EGO.DriveDir = DriveDir;
                                    scenario_leftcutout(cntType9).videoMeta = videoMeta;
                                    scenario_leftcutout(cntType9).EGO.class = class;
                                    scenario_leftcutout(cntType9).EGO.Vx = scenario(counter1).EGO.Vx;
                                    scenario_leftcutout(cntType9).EGO.Vy = scenario(counter1).EGO.Vy;
                                    
                                    for q = 1 : length(scenario(counter1).Target)
                                        
                                        scenario_leftcutout(cntType9).Target(q).bbox = scenario(counter1).Target(q).bbox;
                                        scenario_leftcutout(cntType9).Target(q).timestamp = scenario(counter1).Target(q).timestamp;
                                        scenario_leftcutout(cntType9).Target(q).xCG = ...
                                            scenario(counter1).Target(q).bbox(:,1)+...
                                            (scenario(counter1).Target(q).bbox(:,3)./2);
                                        scenario_leftcutout(cntType9).Target(q).yCG = ...
                                            ySign*(scenario(counter1).Target(q).bbox(:,2)+...
                                            (scenario(counter1).Target(q).bbox(:,4)./2));
                                        scenario_leftcutout(cntType9).Target(q).class = class;
                                        scenario_leftcutout(cntType9).Target(q).Vx = scenario(counter1).Target(q).Vx;
                                        scenario_leftcutout(cntType9).Target(q).Vy = scenario(counter1).Target(q).Vy;
                                    end
                                    cntType9 = cntType9 + 1;
                                    scenario_leftcutout_plot_no = [scenario_leftcutout_plot_no, counter1];
                                    foundLakshScenario = foundLakshScenario + 1;
                                else
                                    scenario_rightcutout(cntType8).EGO.bbox = scenario(counter1).EGO.bbox;
                                    scenario_rightcutout(cntType8).EGO.timestamp = scenario(counter1).EGO.timestamp;
                                    scenario_rightcutout(cntType8).EGO.xCG = scenario(counter1).EGO.bbox(:,1)+(scenario(counter1).EGO.bbox(:,3)./2);
                                    scenario_rightcutout(cntType8).EGO.yCG = ySign*(scenario(counter1).EGO.bbox(:,2)+...
                                        (scenario(counter1).EGO.bbox(:,4)./2));
                                    scenario_rightcutout(cntType8).EGO.DriveDir = DriveDir;
                                    scenario_rightcutout(cntType8).videoMeta = videoMeta;
                                    scenario_rightcutout(cntType8).EGO.class = class;
                                    scenario_rightcutout(cntType8).EGO.Vx = scenario(counter1).EGO.Vx;
                                    scenario_rightcutout(cntType8).EGO.Vy = scenario(counter1).EGO.Vy;
                                    
                                    for q = 1 : length(scenario(counter1).Target)
                                        
                                        scenario_rightcutout(cntType8).Target(q).bbox = scenario(counter1).Target(q).bbox;
                                        scenario_rightcutout(cntType8).Target(q).timestamp = scenario(counter1).Target(q).timestamp;
                                        scenario_rightcutout(cntType8).Target(q).xCG = ...
                                            scenario(counter1).Target(q).bbox(:,1)+...
                                            (scenario(counter1).Target(q).bbox(:,3)./2);
                                        scenario_rightcutout(cntType8).Target(q).yCG = ...
                                            ySign*(scenario(counter1).Target(q).bbox(:,2)+...
                                            (scenario(counter1).Target(q).bbox(:,4)./2));
                                        scenario_rightcutout(cntType8).Target(q).class = class;
                                        scenario_rightcutout(cntType8).Target(q).Vx = scenario(counter1).Target(q).Vx;
                                        scenario_rightcutout(cntType8).Target(q).Vy = scenario(counter1).Target(q).Vy;
                                    end
                                    cntType8 = cntType8 + 1;
                                    scenario_rightcutout_plot_no = [scenario_rightcutout_plot_no, counter1];
                                    foundLakshScenario = foundLakshScenario + 1;
                                end
                            end
                        end
                    end
                elseif (Scenarios(j).precedingId(ScStart) ~= Scenarios(j).precedingId(ScEnd)) && Scenarios(j).precedingId(ScEnd) > 0
                    IDleader = Scenarios(j).precedingId(ScEnd);
                    findIdxScEndLeader = find(Scenarios(IDleader).frames == ScEndIdxGlobal); %global timestamp must equal
                    findIdyScStartLeader = find(Scenarios(IDleader).frames == ScStartIdxGlobal);
                    LnLeaderScEnd = Scenarios(IDleader).lane(findIdxScEndLeader);
                    lnLeaderStart = Scenarios(IDleader).lane(findIdyScStartLeader);
                    leftAlong = any(Scenarios(j).precedingId(ScEnd) == Scenarios(j).leftAlongsideId);
                    leftBack = any(Scenarios(j).precedingId(ScEnd) == Scenarios(j).leftFollowingId);
                    leftPreceeding = any(Scenarios(j).precedingId(ScEnd) == Scenarios(j).leftPrecedingId);
                    rightAlong = any(Scenarios(j).precedingId(ScEnd) == Scenarios(j).rightAlongsideId);
                    rightBack = any(Scenarios(j).precedingId(ScEnd) == Scenarios(j).rightFollowingId);
                    rightPreceeding = any(Scenarios(j).precedingId(ScEnd) == Scenarios(j).rightPrecedingId);
                    if(leftAlong || leftBack || leftPreceeding || rightAlong || rightBack || rightPreceeding)
                        if LnLeaderScEnd == Scenarios(j).lane(ScEnd) && Scenarios(IDleader).drivingDirection == Scenarios(j).drivingDirection
                            
                            if(Scenarios(IDleader).drivingDirection==1)
                                if(Scenarios(IDleader).yVelocity(findIdxScEndLeader)<0)
                                    scenario_leftcutin(cntType3).EGO.bbox = scenario(counter1).EGO.bbox;
                                    scenario_leftcutin(cntType3).EGO.timestamp = scenario(counter1).EGO.timestamp;
                                    scenario_leftcutin(cntType3).EGO.xCG = scenario(counter1).EGO.bbox(:,1)+(scenario(counter1).EGO.bbox(:,3)./2);
                                    scenario_leftcutin(cntType3).EGO.yCG = ySign*(scenario(counter1).EGO.bbox(:,2)+...
                                        (scenario(counter1).EGO.bbox(:,4)./2));
                                    scenario_leftcutin(cntType3).EGO.DriveDir = DriveDir;
                                    scenario_leftcutin(cntType3).videoMeta = videoMeta;
                                    scenario_leftcutin(cntType3).EGO.class = class;
                                    scenario_leftcutin(cntType3).EGO.Vx = scenario(counter1).EGO.Vx;
                                    scenario_leftcutin(cntType3).EGO.Vy = scenario(counter1).EGO.Vy;
                                    
                                    for q = 1 : length(scenario(counter1).Target)
                                        
                                        scenario_leftcutin(cntType3).Target(q).bbox = scenario(counter1).Target(q).bbox;
                                        scenario_leftcutin(cntType3).Target(q).timestamp = scenario(counter1).Target(q).timestamp;
                                        scenario_leftcutin(cntType3).Target(q).xCG = ...
                                            scenario(counter1).Target(q).bbox(:,1)+...
                                            (scenario(counter1).Target(q).bbox(:,3)./2);
                                        scenario_leftcutin(cntType3).Target(q).yCG = ...
                                            ySign*(scenario(counter1).Target(q).bbox(:,2)+...
                                            (scenario(counter1).Target(q).bbox(:,4)./2));
                                        scenario_leftcutin(cntType3).Target(q).class = class;
                                        scenario_leftcutin(cntType3).Target(q).Vx = scenario(counter1).Target(q).Vx;
                                        scenario_leftcutin(cntType3).Target(q).Vy = scenario(counter1).Target(q).Vy;
                                    end
                                    cntType3 = cntType3 + 1;
                                    scenario_leftcutin_plot_no = [scenario_leftcutin_plot_no, counter1];
                                    foundLakshScenario = foundLakshScenario + 1;
                                else
                                    scenario_rightcutin(cntType4).EGO.bbox = scenario(counter1).EGO.bbox;
                                    scenario_rightcutin(cntType4).EGO.timestamp = scenario(counter1).EGO.timestamp;
                                    scenario_rightcutin(cntType4).EGO.xCG = scenario(counter1).EGO.bbox(:,1)+(scenario(counter1).EGO.bbox(:,3)./2);
                                    scenario_rightcutin(cntType4).EGO.yCG = ySign*(scenario(counter1).EGO.bbox(:,2)+...
                                        (scenario(counter1).EGO.bbox(:,4)./2));
                                    scenario_rightcutin(cntType4).EGO.DriveDir = DriveDir;
                                    scenario_rightcutin(cntType4).videoMeta = videoMeta;
                                    scenario_rightcutin(cntType4).EGO.class = class;
                                    scenario_rightcutin(cntType4).EGO.Vx = scenario(counter1).EGO.Vx;
                                    scenario_rightcutin(cntType4).EGO.Vy = scenario(counter1).EGO.Vy;
                                    
                                    for q = 1 : length(scenario(counter1).Target)
                                        
                                        scenario_rightcutin(cntType4).Target(q).bbox = scenario(counter1).Target(q).bbox;
                                        scenario_rightcutin(cntType4).Target(q).timestamp = scenario(counter1).Target(q).timestamp;
                                        scenario_rightcutin(cntType4).Target(q).xCG = ...
                                            scenario(counter1).Target(q).bbox(:,1)+...
                                            (scenario(counter1).Target(q).bbox(:,3)./2);
                                        scenario_rightcutin(cntType4).Target(q).yCG = ...
                                            ySign*(scenario(counter1).Target(q).bbox(:,2)+...
                                            (scenario(counter1).Target(q).bbox(:,4)./2));
                                        scenario_rightcutin(cntType4).Target(q).class = class;
                                        scenario_rightcutin(cntType4).Target(q).Vx = scenario(counter1).Target(q).Vx;
                                        scenario_rightcutin(cntType4).Target(q).Vy = scenario(counter1).Target(q).Vy;
                                    end
                                    cntType4 = cntType4 + 1;
                                    scenario_rightcutin_plot_no = [scenario_rightcutin_plot_no, counter1];
                                    foundLakshScenario = foundLakshScenario + 1;
                                    
                                end
                            else
                                if(Scenarios(IDleader).yVelocity(findIdxScEndLeader)>0)
                                    scenario_leftcutin(cntType3).EGO.bbox = scenario(counter1).EGO.bbox;
                                    scenario_leftcutin(cntType3).EGO.timestamp = scenario(counter1).EGO.timestamp;
                                    scenario_leftcutin(cntType3).EGO.xCG = scenario(counter1).EGO.bbox(:,1)+(scenario(counter1).EGO.bbox(:,3)./2);
                                    scenario_leftcutin(cntType3).EGO.yCG = ySign*(scenario(counter1).EGO.bbox(:,2)+...
                                        (scenario(counter1).EGO.bbox(:,4)./2));
                                    scenario_leftcutin(cntType3).EGO.DriveDir = DriveDir;
                                    scenario_leftcutin(cntType3).videoMeta = videoMeta;
                                    scenario_leftcutin(cntType3).EGO.class = class;
                                    scenario_leftcutin(cntType3).EGO.Vx = scenario(counter1).EGO.Vx;
                                    scenario_leftcutin(cntType3).EGO.Vy = scenario(counter1).EGO.Vy;
                                    
                                    for q = 1 : length(scenario(counter1).Target)
                                        
                                        scenario_leftcutin(cntType3).Target(q).bbox = scenario(counter1).Target(q).bbox;
                                        scenario_leftcutin(cntType3).Target(q).timestamp = scenario(counter1).Target(q).timestamp;
                                        scenario_leftcutin(cntType3).Target(q).xCG = ...
                                            scenario(counter1).Target(q).bbox(:,1)+...
                                            (scenario(counter1).Target(q).bbox(:,3)./2);
                                        scenario_leftcutin(cntType3).Target(q).yCG = ...
                                            ySign*(scenario(counter1).Target(q).bbox(:,2)+...
                                            (scenario(counter1).Target(q).bbox(:,4)./2));
                                        scenario_leftcutin(cntType3).Target(q).class = class;
                                        scenario_leftcutin(cntType3).Target(q).Vx = scenario(counter1).Target(q).Vx;
                                        scenario_leftcutin(cntType3).Target(q).Vy = scenario(counter1).Target(q).Vy;
                                    end
                                    cntType3 = cntType3 + 1;
                                    scenario_leftcutin_plot_no = [scenario_leftcutin_plot_no, counter1];
                                    foundLakshScenario = foundLakshScenario + 1;
                                else
                                    scenario_rightcutin(cntType4).EGO.bbox = scenario(counter1).EGO.bbox;
                                    scenario_rightcutin(cntType4).EGO.timestamp = scenario(counter1).EGO.timestamp;
                                    scenario_rightcutin(cntType4).EGO.xCG = scenario(counter1).EGO.bbox(:,1)+(scenario(counter1).EGO.bbox(:,3)./2);
                                    scenario_rightcutin(cntType4).EGO.yCG = ySign*(scenario(counter1).EGO.bbox(:,2)+...
                                        (scenario(counter1).EGO.bbox(:,4)./2));
                                    scenario_rightcutin(cntType4).EGO.DriveDir = DriveDir;
                                    scenario_rightcutin(cntType4).videoMeta = videoMeta;
                                    scenario_rightcutin(cntType4).EGO.class = class;
                                    scenario_rightcutin(cntType4).EGO.Vx = scenario(counter1).EGO.Vx;
                                    scenario_rightcutin(cntType4).EGO.Vy = scenario(counter1).EGO.Vy;
                                    
                                    for q = 1 : length(scenario(counter1).Target)
                                        
                                        scenario_rightcutin(cntType4).Target(q).bbox = scenario(counter1).Target(q).bbox;
                                        scenario_rightcutin(cntType4).Target(q).timestamp = scenario(counter1).Target(q).timestamp;
                                        scenario_rightcutin(cntType4).Target(q).xCG = ...
                                            scenario(counter1).Target(q).bbox(:,1)+...
                                            (scenario(counter1).Target(q).bbox(:,3)./2);
                                        scenario_rightcutin(cntType4).Target(q).yCG = ...
                                            ySign*(scenario(counter1).Target(q).bbox(:,2)+...
                                            (scenario(counter1).Target(q).bbox(:,4)./2));
                                        scenario_rightcutin(cntType4).Target(q).class = class;
                                        scenario_rightcutin(cntType4).Target(q).Vx = scenario(counter1).Target(q).Vx;
                                        scenario_rightcutin(cntType4).Target(q).Vy = scenario(counter1).Target(q).Vy;
                                    end
                                    cntType4 = cntType4 + 1;
                                    scenario_rightcutin_plot_no = [scenario_rightcutin_plot_no, counter1];
                                    foundLakshScenario = foundLakshScenario + 1;
                                    
                                end
                                
                            end
                        end
                    end
                elseif(Scenarios(j).precedingId(ScStart)==0 && Scenarios(j).precedingId(ScEnd)==0)
                    IDleader = Scenarios(j).precedingId(ScEnd);
                    withoutFollow = withoutFollow+1;
                end
            end
        end
    end
    
    
    Scenarios(toDelete) = [];
    scenario_lnchangeleft_plot_no(scenario_lnchangeleft_plot_no==0) = [];  %delete all zero entries
    scenario_following_plot_no(scenario_following_plot_no==0) = [];
    scenario_rightcutin_plot_no(scenario_rightcutin_plot_no==0) = [];
    scenario_rightcutin_plot_no(scenario_rightcutin_plot_no==0) = [];
    

end
display('Processing done.');

%% Extracting the data corresponding to the algorithm coordinate frame
scenario_leftcutout = generateNewCordinate(scenario_leftcutout);
scenario_rightcutout = generateNewCordinate(scenario_rightcutout);
scenario_lnchangeleft = generateNewCordinate(scenario_lnchangeleft);
scenario_lnchangeright = generateNewCordinate(scenario_lnchangeright);
scenario_following = generateNewCordinate(scenario_following);
scenario_followingacc = generateNewCordinate(scenario_followingacc);
scenario_followingdec = generateNewCordinate(scenario_followingdec);
scenario_leftcutin = generateNewCordinate(scenario_leftcutin);
scenario_rightcutin = generateNewCordinate(scenario_rightcutin);

%% Generate OGs
ogLeftCutOut = generateOccupancy(scenario_leftcutout);
ogLaneLeft = generateOccupancy(scenario_lnchangeleft);
ogLaneRight = generateOccupancy(scenario_lnchangeright);
ogFoll = generateOccupancy(scenario_following(1:1000));
ogFollAcc = generateOccupancy(scenario_followingacc);
ogFollDec = generateOccupancy(scenario_followingdec);
ogLeftCut = generateOccupancy(scenario_leftcutin);
ogRightCut = generateOccupancy(scenario_rightcutin);
ogRightCutOut = generateOccupancy(scenario_rightcutout);
save('HighDScenario.mat','ogLeftCutOut','ogLaneLeft',...
    'ogLaneRight','ogFoll','ogFollAcc','ogFollDec',...
    'ogLeftCut','ogRightCut','ogRightCutOut');

%% Visualization of the scenario
visualize = false;
plotCarPng = false;
%i_old = 1; % just an init value

if visualize
    simFig = figure;
    simFig.WindowState = 'maximized';
    textbox1 = uicontrol('Style', 'text', 'Units', 'norm', 'Position', [0.3 0.2 .1 .15], 'FontSize',12);   % position: [left bottom width height]
    
    % START loop over the scenarios
    
    
    for i = scenario_rightcutout_plot_no %size(scenario,2)
        %Clust = 20;
        %for ii = 1:size(dataPoints{1,Clust},2)
        %for ii = 1:size(ScenariosClustered{1,Clust},2)
        %i = dataPoints{1,Clust}(ii);
        %i = ScenariosClustered{1,Clust}(ii);
        
        %doesnt work properly..
        %         if ii > 1 && scenario(i).videoMeta.locationId == scenario(i_old).videoMeta.locationId
        %             disp('Skip road generation')
        %         else
        % Plot the highway
        clear upperLanes lowerLanes positionBackground
        upperLanes = scenario(i).videoMeta.upperLanes;
        lowerLanes = scenario(i).videoMeta.lowerLanes;
        
        laneThickness = 0.3; % Thickness of lane markings
        laneColor = [1 1 1]; % color of the lane markings (white)
        trackWidth = 408; % Width of the video frame
        streetColor = [0.6 0.6 0.6]; % The street color
        
        hold on;
        
        % First plot the lane markings
        positionBackground = [0 (-lowerLanes(size(lowerLanes, 2))...
            - 0.7) trackWidth (lowerLanes(size(lowerLanes, 2))...
            - upperLanes(1) + 2.0)];
        RoadPlotRect(1) = rectangle('Position', positionBackground, 'FaceColor',...
            streetColor, 'EdgeColor', [1 1 1]);
        
        % Upper lanes
        positionBackground = [0 -upperLanes(1) trackWidth laneThickness];
        RoadPlotRect(2) = rectangle('Position', positionBackground, 'FaceColor',...
            laneColor, 'EdgeColor', laneColor);
        for m = 2:size(upperLanes, 2) - 1
            RoadPlot1(m) =  plot([0 trackWidth], [-upperLanes(m) -upperLanes(m)], '--',...
                'Color', laneColor);
        end
        positionBackground = [0 -upperLanes(size(upperLanes, 2))...
            trackWidth laneThickness];
        RoadPlotRect(3) = rectangle('Position', positionBackground, 'FaceColor',...
            laneColor, 'EdgeColor', laneColor);
        
        % Lower lanes
        positionBackground = [0 -lowerLanes(1) trackWidth laneThickness];
        RoadPlotRect(4) = rectangle('Position', positionBackground, 'FaceColor',...
            laneColor, 'EdgeColor', laneColor);
        for m = 2:size(lowerLanes, 2) - 1
            RoadPlot2(m) = plot([0 trackWidth], [-lowerLanes(m) -lowerLanes(m)], '--',...
                'Color', laneColor);
        end
        positionBackground = [0 -lowerLanes(size(lowerLanes, 2))...
            trackWidth laneThickness];
        RoadPlotRect(5) = rectangle('Position', positionBackground, 'FaceColor',...
            laneColor, 'EdgeColor', laneColor);
          
        % Parameters for plotting the bounding boxes
        boundingBoxColorEGO = [1 0 0];
        boundingBoxColorTarget = [0 0 1];
        
        % We need to draw the bounding boxes from 0 to negative because image
        % coordinate origin is in the upper left corner.Hence, the bounding box
        % coordinates are mirrored.
        ySign = -1;
        %figure(1);
        xlim([0 410])
        ylim([-40 -10])
        axis equal
        dir = NaN;
        axis off;
        % START loop over the scenario length
        for j = 1:size(scenario(i).EGO.bbox,1)
            
            % Plot the bounding box
            positionBoundingBox = [scenario(i).EGO.bbox(j,1) ...
                ySign*scenario(i).EGO.bbox(j,2)+...
                ySign*scenario(i).EGO.bbox(j,4) ...
                scenario(i).EGO.bbox(j,3) ...
                scenario(i).EGO.bbox(j,4)];
            
            %Arrow/Triangle indicating driving direction
            if plotCarPng == false
                boundingBox = scenario(i).EGO.bbox(j,:);
                velocity = scenario(i).EGO.Vx(j);
                % Plot the triangle that represents the direction of the vehicle
                if scenario(i).EGO.DriveDir == 1
                    dir = 1;
                    front = boundingBox(1) + (boundingBox(3)*0.2);
                    triangleXPosition = [front-1 front-1 boundingBox(1)-1];
                    %Define x Limits for Zooming
                    xlim([positionBoundingBox(1)-100 positionBoundingBox(1)+20])
                    ylim([positionBoundingBox(2)-7.5 positionBoundingBox(2)+7.5])
                    
                else
                    dir = 2;
                    front = boundingBox(1) + boundingBox(3) - (boundingBox(3)*0.2);
                    triangleXPosition = [front+1 front+1 boundingBox(1)+boundingBox(3)+1];
                    %Define x Limits for Zooming
                    xlim([positionBoundingBox(1)-20 positionBoundingBox(1)+100])                
                    ylim([positionBoundingBox(2)-7.5 positionBoundingBox(2)+7.5])
                end
                triangleYPosition = [ySign*boundingBox(2) ...
                    ySign*boundingBox(2)+ySign*boundingBox(4)...
                    ySign*boundingBox(2)+ySign*(boundingBox(4)/2)];
                triangle = fill(triangleXPosition, triangleYPosition, [0 0 0]);
            end
            

            
            if plotCarPng
                [img,~,imgAlpha] = imread('ego.png');
                if scenario(i).EGO.DriveDir == 1
                    img = imrotate(img,180);
                    imgAlpha = imrotate(imgAlpha, 180);
                end
                plotEGO = image('CData', img, 'AlphaData',...
                    imgAlpha, 'XData', [positionBoundingBox(1)...
                    positionBoundingBox(1)+positionBoundingBox(3)],...
                    'YData',  [positionBoundingBox(2)...
                    positionBoundingBox(2)+positionBoundingBox(4)]);
            else
                rectEGO = rectangle('Position', positionBoundingBox, ...
                    'FaceColor', boundingBoxColorEGO, ...
                    'EdgeColor', [0 0 0]);
                % Plot the CoG of EGO
                %                 plotCGEGO = plot(scenario(i).EGO.xCG(j),...
                %                     scenario(i).EGO.yCG(j), 'y+');
            end
            
            % START loop over the targets
            for k = 1:size(scenario(i).Target,2)
                % Plot the bounding box if vehicle is still existent
                if j <= size(scenario(i).Target(k).bbox,1)
                    positionBoundingBox = [scenario(i).Target(k).bbox(j,1) ...
                        ySign*scenario(i).Target(k).bbox(j,2)+...
                        ySign*scenario(i).Target(k).bbox(j,4) ...
                        scenario(i).Target(k).bbox(j,3) ...
                        scenario(i).Target(k).bbox(j,4)];
                    if plotCarPng
                        
                        if strcmp(scenario(i).Target(k).class, 'Ca')
                            [img,~,imgAlpha] = imread('target.png');
                        else
                            [img,~,imgAlpha] = imread('truck.png');
                        end
                        if scenario(i).EGO.DriveDir == 1
                            img = imrotate(img, 180);
                            imgAlpha = imrotate(imgAlpha, 180);
                        end
                        plotTarget(k) = image('CData', img, 'AlphaData',...
                            imgAlpha, 'XData', [positionBoundingBox(1)...
                            positionBoundingBox(1)+positionBoundingBox(3)],...
                            'YData',  [positionBoundingBox(2)...
                            positionBoundingBox(2)+positionBoundingBox(4)]);
                        
                    else
                        rectTarget(k) = rectangle('Position', positionBoundingBox, ...
                            'FaceColor', boundingBoxColorTarget, ...
                            'EdgeColor', [0 0 0]);
         
                    end
                end
            end
            saveTempName = 'test_check.png';
            % END loop over the targets
            exportgraphics(gcf,saveTempName,'BackgroundColor','none')
            saveName = strcat('Scenario_',num2str(i),'_',num2str(j),'_','.png');
            if dir==1
                before_img = imread(saveTempName);
                before_img2 = flipdim(before_img,2);
                imwrite(before_img2, saveName);
                 nsjdnasdua = 0 ;
            else
                before_img = imread(saveTempName);
                imwrite(before_img, saveName);
            end

%             imwrite(getframe(gcf).cdata, 'myfilename.png')

            %Clean Up after each time step:
            if plotCarPng
                pause(0.01)
                delete(plotEGO)
                delete(plotTarget)
            else
                pause(0.08)
                delete(rectTarget)
                delete(rectEGO)
                % delete(plotCGEGO)
                % delete(plotCGTarget)
                delete(triangle)
                
            end
        end
        % END loop over the scenario length
        
        delete(RoadPlotRect)
        delete(RoadPlot1)
        delete(RoadPlot2)
        
    end
    % END loop over the scenarios
end


