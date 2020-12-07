% Generation of Augmented Occupancy Grids
function augmentedOccupancyGrid = generate_Grids(x_Road, y_Road,...
    scenario_cutin)

% Construction of grids 1m x 0.5m
X=0:200;
Y=0:0.5:14.5;
k=1;
gridNew=zeros(2,2,6000);
for i=1:size(Y,2)-1
    for j=1:size(X,2)-1
        grid=[X(j) X(j+1); Y(i) Y(i+1)];
        gridNew(:,:,k)=grid;
        k=k+1;
    end
end

% Initialisation
occupancyGrid = zeros(1, 30000);
% 1 - occupancy, 2 - v, 3 - Phi, 4 - longAccln, 5 - latAccln
occ=1:5:30000;


% Vectorize the road points
x_Road = x_Road(:);
y_Road = y_Road(:);

% Probability to road points
% START loop over the grids
for m=1:6000
    xv = [gridNew(1,1,m) gridNew(1,2,m) gridNew(1,2,m) gridNew(1,1,m)...
        gridNew(1,1,m)];
    yv = [gridNew(2,1,m) gridNew(2,1,m) gridNew(2,2,m) gridNew(2,2,m)...
        gridNew(2,1,m)];
    in=inpolygon(x_Road,y_Road,xv,yv);
    if any(in)>=1
        occupancyGrid(occ(m))=1;
    end
end
% END loop over the grids

% EGO
% START loop over the grids
for m = 1:6000
    xv = [gridNew(1,1,m) gridNew(1,2,m) gridNew(1,2,m)...
        gridNew(1,1,m) gridNew(1,1,m)];
    yv = [gridNew(2,1,m) gridNew(2,1,m) gridNew(2,2,m)...
        gridNew(2,2,m) gridNew(2,1,m)];
    xVehicle = scenario_cutin.EGO.xCoordinates;
    yVehicle = scenario_cutin.EGO.yCoordinates;
    in=inpolygon(xVehicle, yVehicle, xv, yv);
    in1=inpolygon(xv, yv, xVehicle, yVehicle);
    if any(in)==1 || any(in1) == 1
        occupancyGrid(occ(m))=1;
    end
end
% END loop over the grids

for k = 1:size(scenario_cutin.Target,2)
    if(isempty(scenario_cutin.Target(k).bbox) || isempty(scenario_cutin.Target(k).xCoordinates))
        continue;
    end
    for m = 1:6000

    xv = [gridNew(1,1,m) gridNew(1,2,m) gridNew(1,2,m)...
        gridNew(1,1,m) gridNew(1,1,m)];
    yv = [gridNew(2,1,m) gridNew(2,1,m) gridNew(2,2,m)...
        gridNew(2,2,m) gridNew(2,1,m)];
    xVehicle = scenario_cutin.Target(k).xCoordinates;
    yVehicle = scenario_cutin.Target(k).yCoordinates;
    in=inpolygon(xVehicle, yVehicle, xv, yv);
    in1=inpolygon(xv, yv, xVehicle, yVehicle);
    if any(in)==1 || any(in1) == 1
        occupancyGrid(occ(m))=1;
    end
    end
end


% % END loop over the targets
augmentedOccupancyGrid(:,:) = rot90(reshape(occupancyGrid(1:5:30000),...
    [200 30]));
end
