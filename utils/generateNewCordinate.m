function [scenario]= generateNewCordinate(scenario)
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
    %     if(size(upperLanes,3)~=4)
    %         continue;
    %     end
    
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
    x_Road = [];
    y_Road = [];
    if scenario(i).EGO.DriveDir == 1 % right to left
        y_CG_Displacement = yCG_EGO_New(1)-yCG_EGO(1);
        % Road points
        x_Road = repmat(0:0.5:200, size(upperLanes,2), 1);
        y_RoadPoints = (y_CG_Displacement(1)- upperLanes) ;
        diff_lanes = yCG_EGO_New(1) - y_RoadPoints;
        diff_lanes = -diff_lanes;
        y_RoadPoints = yCG_EGO_New(1) - diff_lanes;
        y_Road(1,:) = repmat(y_RoadPoints(1), 1, size(x_Road,2));
        y_Road(2,:) = repmat(y_RoadPoints(2), 1, size(x_Road,2));
        y_Road(3,:) = repmat(y_RoadPoints(3), 1, size(x_Road,2));
        if(size(upperLanes,2)==4)
            y_Road(4,:) = repmat(y_RoadPoints(4), 1, size(x_Road,2));
        elseif(size(upperLanes,2)>4)
            y_Road(4,:) = repmat(y_RoadPoints(4), 1, size(x_Road,2));
            y_Road(5,:) = repmat(y_RoadPoints(5), 1, size(x_Road,2));
        end
        
        width_EGO_new = scenario(i).EGO.bbox(1,4);
        length_EGO_new = scenario(i).EGO.bbox(1,3);
        
        % Convert the velocity coordinate for EGO
        Vx_EGO_New = scenario(i).EGO.Vx;
        Vy_EGO_New = -scenario(i).EGO.Vy;
        V_EGO_New = sqrt(Vx_EGO_New.^2+Vy_EGO_New.^2);
        
        % Orientation of the EGO
        Psi_EGO_New = atan2d(Vy_EGO_New, Vx_EGO_New);
        
        
        % START loop over the scenario length
        for j = 2:size(xCG_EGO,1)
            xCG_EGO_New(j) = (xCG_EGO(j-1)-xCG_EGO(j))+xCG_EGO_New(j-1);
            yCG_EGO_New(j) = (yCG_EGO(j-1)-yCG_EGO(j))+yCG_EGO_New(j-1);
        end
        
        % START loop over the target vehicles
        for k = 1:size(scenario(i).Target,2)
            if(isempty(scenario(i).Target(k).bbox))
                continue;
            end
            % Class of target
            class_Target = scenario(i).Target(k).class;
            
            % Target dimensions
            width_Target(1) = scenario(i).Target(k).bbox(1,4);
            length_Target(1) = scenario(i).Target(k).bbox(1,3);
            % Target CoG
            xCG_Target = scenario(i).Target(k).xCG;
            yCG_Target = scenario(i).Target(k).yCG;
            
            % Update the velocity coordinate for target
            Vx_Target_New = -scenario(i).Target(k).Vx;
            Vy_Target_New = scenario(i).Target(k).Vy;
            V_Target_New = sqrt(Vx_Target_New.^2+Vy_Target_New.^2);
            
            % Orientation of the target
            Psi_Target_New = atan2d(Vy_Target_New, Vx_Target_New);
            xCG_Target_New = [];
            yCG_Target_New = [];
            % Update the CoG relative to EGO
            xCG_Target_New(1) = (xCG_EGO(1)-xCG_Target(1))+...
                xCG_EGO_New(1);
            yCG_Target_New(1) = (yCG_EGO(1)-yCG_Target(1))+...
                yCG_EGO_New(1);
            
            
            % START loop over the scenario length
            for l = 2:size(xCG_Target,1)
                % Transform target vehicles relative to new CoG of EGO
                xCG_Target_New(l) = (xCG_Target(l-1)-...
                    xCG_Target(l))+xCG_Target_New(l-1);
                yCG_Target_New(l) = (yCG_Target(l-1)-...
                    yCG_Target(l))+yCG_Target_New(l-1);
            end
            % END loop over the scenario length
            scenario(i).Target(k).xCG_New = xCG_Target_New;
            scenario(i).Target(k).yCG_New = yCG_Target_New;
            scenario(i).Target(k).bbox_New = yCG_Target_New;
            scenario(i).Target(k).Psi_Target_New = Psi_Target_New;
            scenario(i).Target(k).width_new = width_Target;
            scenario(i).Target(k).length_new = length_Target;
        end
        % END loop over the target vehicles
        
    elseif scenario(i).EGO.DriveDir == 2
        
        y_CG_Displacement = yCG_EGO_New(1)-yCG_EGO(1);

        % Road points
        x_Road = repmat(0:0.5:200, size(lowerLanes, 2), 1);
        y_RoadPoints = (y_CG_Displacement(1)-lowerLanes);
        y_Road(1,:) = repmat(y_RoadPoints(1), 1, size(x_Road,2));
        y_Road(2,:) = repmat(y_RoadPoints(2), 1, size(x_Road,2));
        y_Road(3,:) = repmat(y_RoadPoints(3), 1, size(x_Road,2));
        if(size(lowerLanes,2)==4)
            y_Road(4,:) = repmat(y_RoadPoints(4), 1, size(x_Road,2));
        elseif(size(lowerLanes,2)>4)
            y_Road(4,:) = repmat(y_RoadPoints(4), 1, size(x_Road,2));
            y_Road(5,:) = repmat(y_RoadPoints(5), 1, size(x_Road,2));     
        end
        % width and length
        width_EGO_new = scenario(i).EGO.bbox(1,4);
        length_EGO_new = scenario(i).EGO.bbox(1,3);
        
        % Convert the velocity coordinate for EGO
        Vx_EGO_New = scenario(i).EGO.Vx;
        Vy_EGO_New = -scenario(i).EGO.Vy;
        V_EGO_New = sqrt(Vx_EGO_New.^2+Vy_EGO_New.^2);
        
        % Orientation of the EGO
        Psi_EGO_New = atan2d(Vy_EGO_New, Vx_EGO_New);
        
        % START loop over the scenario length
        for j = 2:size(xCG_EGO,1)
            xCG_EGO_New(j) = (xCG_EGO(j)-xCG_EGO(j-1))+xCG_EGO_New(j-1);
            yCG_EGO_New(j) = (yCG_EGO(j)-yCG_EGO(j-1))+yCG_EGO_New(j-1);
        end
        % END loop over the scenario length
        % START loop over the target vehicles
        for k = 1:size(scenario(i).Target,2)
            if(isempty(scenario(i).Target(k).bbox))
                continue;
            end
            % Class of target
            class_Target = scenario(i).Target(k).class;
            
            % Target dimensions
            width_Target(1) = scenario(i).Target(k).bbox(1,4);
            length_Target(1) = scenario(i).Target(k).bbox(1,3);
            
            % Update the velocity coordinate
            Vx_Target_New = scenario(i).Target(k).Vx;
            Vy_Target_New = -scenario(i).Target(k).Vy;
            V_Target_New = sqrt(Vx_Target_New.^2+Vy_Target_New.^2);
            
            % Orientation of the target
            Psi_Target_New = atan2d(Vy_Target_New, Vx_Target_New);
            
            xCG_Target_New = [];
            yCG_Target_New = [];
            % Target CoG
            xCG_Target = scenario(i).Target(k).xCG;
            yCG_Target = scenario(i).Target(k).yCG;
            
            % Update the CoG relative to EGO
            xCG_Target_New(1) = (xCG_Target(1)-xCG_EGO(1))+...
                xCG_EGO_New(1);
            yCG_Target_New(1) = (yCG_Target(1)-yCG_EGO(1))+...
                yCG_EGO_New(1);
            
            
            % START loop over the scenario length
            for l = 2:size(xCG_Target,1)
                % Transform target vehicles relative to new CoG of EGO
                xCG_Target_New(l) = (xCG_Target(l)-...
                    xCG_Target(l-1))+xCG_Target_New(l-1);
                yCG_Target_New(l) = (yCG_Target(l)-...
                    yCG_Target(l-1))+yCG_Target_New(l-1);
            end
            % END loop over the scenario length
            scenario(i).Target(k).xCG_New = xCG_Target_New;
            scenario(i).Target(k).yCG_New = yCG_Target_New;
            scenario(i).Target(k).Psi_Target_New = Psi_Target_New;
            scenario(i).Target(k).width_new = width_Target;
            scenario(i).Target(k).length_new = length_Target;
        end
        % END loop over the target vehicles
    end
    scenario(i).EGO.xCG_New = xCG_EGO_New;
    scenario(i).EGO.yCG_New = yCG_EGO_New;
    scenario(i).Road.x = x_Road;
    scenario(i).Road.y = y_Road;
    scenario(i).EGO.Psi_EGO_New = Psi_EGO_New;
    scenario(i).EGO.width_new = width_EGO_new;
    scenario(i).EGO.length_new = length_EGO_new;
end
end