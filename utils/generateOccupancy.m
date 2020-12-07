function [Ogs] = generateOccupancy(scenario)
visualize = false;
for i = 1:size(scenario,2) 
    if i == 1 || rem(i,10) == 0
        disp(['Generating Occupancy Grids'...
            'coordinate frame | in percent: ',...
            num2str(i/size(scenario,2)*100), '%']);
    end
    % Road points
    x_Road = scenario(i).Road.x;
    y_Road = scenario(i).Road.y+0.01;
    % Excluding the inner lanes
    %     x_Road(2:3,:) = [];
    %     y_Road(2:3,:) = [];
    generate_range = 1:5:50;
    occupancy_grids = [];
    for oc = 1:10
        currentstep = generate_range(oc);
        angleDir_Ego = deg2rad(scenario(i).EGO.Psi_EGO_New(currentstep));
        length_Ego = scenario(i).EGO.length_new;
        width_Ego =  scenario(i).EGO.width_new;
        ex=cos(angleDir_Ego);
        ey=sin(angleDir_Ego);
        exOrtho=ex*cos(pi/2)+ey*sin(pi/2);
        eyOrtho=-ex*sin(pi/2)+ey*cos(pi/2);
        xCG_ego = scenario(i).EGO.xCG_New(currentstep);
        yCG_ego = scenario(i).EGO.yCG_New(currentstep);
        [x_Data,y_Data] = generatebbox(xCG_ego,yCG_ego,width_Ego,length_Ego,ex,ey,exOrtho,eyOrtho);
        scenario(i).EGO.xCoordinates = ...
            [x_Data(1) x_Data(2) x_Data(3) x_Data(4) x_Data(1)];
        scenario(i).EGO.yCoordinates = ...
            [y_Data(1) y_Data(2) y_Data(3) y_Data(4) y_Data(1)];
        for k = 1:size(scenario(i).Target,2)
            if(currentstep <= size(scenario(i).Target(k).xCG,1))
                angleDir_Target = deg2rad(scenario(i).Target(k).Psi_Target_New(currentstep));
                length_Target = scenario(i).Target(k).length_new;
                width_Target =  scenario(i).Target(k).width_new;
                exTG=cos(angleDir_Target);
                eyTG=sin(angleDir_Target);
                exOrthoTG=ex*cos(pi/2)+ey*sin(pi/2);
                eyOrthoTG=-ex*sin(pi/2)+ey*cos(pi/2);
                xCG_TG = scenario(i).Target(k).xCG_New(currentstep);
                yCG_TG = scenario(i).Target(k).yCG_New(currentstep);
                [x_DataTG,y_DataTG] = generatebbox(xCG_TG,yCG_TG,width_Target,length_Target,exTG,eyTG,exOrthoTG,eyOrthoTG);
                scenario(i).Target(k).xCoordinates = ...
                    [x_DataTG(1) x_DataTG(2) x_DataTG(3) x_DataTG(4) x_DataTG(1)];
                scenario(i).Target(k).yCoordinates = ...
                    [y_DataTG(1) y_DataTG(2) y_DataTG(3) y_DataTG(4) y_DataTG(1)];            
            else
                scenario(i).Target(k).xCoordinates = ...
                    [];
                scenario(i).Target(k).yCoordinates = ...
                    []; 
            end
        end  
        occupancy_grids(:,:,oc) = generate_Grids(x_Road, y_Road, scenario(i));
    end
    Ogs(i,:,:,:) = occupancy_grids;
    if(visualize)
    for viz =1:10
        imagesc(reshape(occupancy_grids(:,:,viz),30,200))
        axis equal;
        pause(0.1)
    end
    end
end
end