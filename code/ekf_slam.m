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
rNoise = [0.1; 1; 0.1; 1];
Rn = diag(rNoise.^2);   %probably wrong
sim = 1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Dynamic Variables
stateMean = zeros(3, 1);
stateCov = zeros(3,3);
%TODO --> Avoid overwrite before matching step

q = [.01;.1];
lQ = diag(q.^2); % Landmark noise

Jr = zeros(2,3);
Jl = zeros(2);

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
    if sim == 1
        noise = rNoise .* randn(4,1);
    else
        noise = zeros(4,1);
    end
    
    [stateMean(1:3), rJacob, nJacob] = ...
        movement_model(stateMean(1:3)', [last_odom last_time], noise, data(t).time, ...
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
                    [landmarkXY, Jr, Jl] = ...
                        new_landmark([landmarkRaw(3) landmarkRaw(2)], stateMean(1:3)); % Get [landmarkX, landmarkY]
                    landmarkList(nLandmarksCurrent+1) = landmarkRaw(1); % Add ID to list of landmarks
                    stateMean(3+nLandmarksCurrent*2+1) = landmarkXY(1); % Add X to state mean
                    stateMean(3+nLandmarksCurrent*2+2) = landmarkXY(2); % Add Y to state mean
                    P_lx = Jr*stateCov(1:3,:);
                    P_ll = Jr*stateCov(1:3,1:3)*Jr' + Jl*lQ*Jl';
                    stateCov = [stateCov P_lx']; %Add 2 collums to state cov
                    stateCov = [stateCov; P_lx P_ll]; %Add 2 rows to state cov
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
    xPose(t) = stateMean(1);
    yPose(t) = stateMean(2);
end

figure(); hold on;
plot(xPose(1),yPose(1),'og')
plot(xPose, yPose)
for i=1:length(landmarkList)
    if ~(landmarkList(i) == -1)
        plot(stateMean(3+2*i-1),stateMean(3+2*i),'xr')
    end
end
title('EKF Plot');