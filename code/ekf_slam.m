% Data vector contains
% data.odom(t).date  data.odom(t).fwAngle data.odom(t).fwVelocity data.odom(t).bwAngle data.odom(t).bwVelocity]
% % fw is front wheels, bw is back wheels
% data.landmark(t) contains {nLandmarksSeen, landmarkSeen[]}
% data.landmark(t).landmarkSeen(i) = [landmarkID, landmarkDist, landmarkAngle]
% nLandmarksSeen is the number of landmarks observed in one image
%load('data.mat');

%% Static Variables
nTimestamps = length(data);
nLandmarksTotal = 12;
wheeldistance = 0.21;
rNoise = zeros(4, 1);
online = 0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Dynamic Variables
stateMean = zeros(3, 1);
stateCov = zeros(3,3);
%TODO --> Avoid overwrite before matching step

Rn = zeros(3,3); % Robot noise
lQ = eye(2); % Landmark noise

last_odom = zeros(1, 4);
last_time = data(1).time;

nLandmarksSeen = 0;
nLandmarksCurrent = 0;
landmarkRaw = zeros(3, 1);
landmarkXY = zeros(2, 1);
landmarkList = -ones(nLandmarksTotal, 1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for t = 1:nTimestamps
    %% Prediction step
    %TODO --> Calculate Rn
    
    [stateMean(1:3), rJacob, nJacob] = ...
        movement_model(stateMean(1:3)', [last_odom last_time], rNoise(:), data(t).time, ...
        wheeldistance, nLandmarksCurrent, Rn);
    last_time = data(t).time;

    
    stateCov = rJacob*stateCov*rJacob' + nJacob;
	%% Correction step
    if data(t).option == 1
        nLandmarksSeen = data(t).landmarksSeen;
        if nLandmarksSeen > 0
            for i = 1:nLandmarksSeen
                landmarkRaw = data(t).landmark(i, :); % Get [landmarkID, landmarkDist, landmarkAngle]
                %lQ = [var(landmarkRaw(2)) 0; 0 var(landmarkRaw(3))];
                if ~ismember(landmarkRaw(1), landmarkList) % If never seen before, add new Landmark
                    landmarkXY = ...
                        new_landmark([landmarkRaw(3) landmarkRaw(2)], stateMean(1:3)); % Get [landmarkX, landmarkY]
                    landmarkList(nLandmarksCurrent+1) = landmarkRaw(1); % Add ID to list of landmarks
                    stateMean(3+nLandmarksCurrent*2+1) = landmarkXY(1); % Add X to state mean
                    stateMean(3+nLandmarksCurrent*2+2) = landmarkXY(2); % Add Y to state mean
                    stateCov = [stateCov zeros(3+nLandmarksCurrent*2, 2)]; %Add 2 collums to state cov
                    stateCov = [stateCov; zeros(2, 3+nLandmarksCurrent*2+2)]; %Add 2 rows to state cov
                    nLandmarksCurrent = nLandmarksCurrent + 1;
                    location = nLandmarksCurrent;
                else
                    location = find(landmarkList==landmarkRaw(1));
                end
                [z, H] = observation_model(stateMean(1:3), ...
                    [stateMean(3+location*2-1) stateMean(3+location*2)], ...
                    location, nLandmarksCurrent); % Get z = [landmarkDist, landmarkAngle] and jacobian
                K = stateCov*(H')*inv(H*stateCov*(H')+lQ);
                stateMean = stateMean + K*([landmarkRaw(3) landmarkRaw(2)]' - z');
                aux = K*H;
                stateCov = (eye(size(aux))-aux)*stateCov;
            end
        end
    else
        last_odom = data(t).odom; %save last odometry measurement
    end
end
