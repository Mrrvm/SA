% Data vector contains
% data.odom is a matrix [fwAngle, fwVelocity, bwAngle, bwVelocity] * nTimestamps
% % fw is front wheels, bw is back wheels
% data.landmark is a vector of structures
% data.landmark(t) contains {nLandmarksSeen, landmarkSeen[]}
% data.landmark(t).landmarkSeen(i) = [landmarkID, landmarkDist, landmarkAngle] 
% nLandmarksSeen is the number of landmarks observed in one image
data = load(data.mat);

%% Static Variables
nTimestamps = data.nTimestamps;
nLandmarksTotal = data.nLandmarks;
wheeldistance = 0; % todo
rNoise = zeros(4, 1); % todo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Dynamic Variables 
stateMean = zeros(3+2*nLandmarksTotal, 1);
stateCov = zeros(3+2*nLandmarksTotal, 3+2*nLandmarksTotal);

rJacobian = zeros(3,3);
rNoiseJacobian = zeros(2,2);
lJacobian = zeros(2,3);
lNoiseJacobian = zeros(2,2);

nLandmarksSeen = 0
nLandmarksCurrent = 0;
landmarkRaw = zeros(3, 1);
landmarkXY = zeros(3, 1);
landmarkList = zeros(nLandmarksTotal, 1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for t = 1:nTimestamps

	%% Prediction step
	[stateMean(1:3), rJacobian, rNoiseJacobian] = ...
		movement_model(stateMean(1:3), data.odom(1:4, t) , rNoise(:), wheeldistance);
	% Calculate new stateCov
	% todo

	%% Landmark Observation
    
    nLandmarksSeen = data.landmark(t).nLandmarksSeen;
    if nLandmarksSeen > 0
        for i = 1:nLandmarksSeen
            landmarkRaw = data.landmark(t).landmarkSeen(i);
            if ~ismember(landmarkRaw(1), landmarkList)
                %% Add new landmark
                landmarkXY = new_landmark(landmarkRaw(2:3), stateMean(1:3));
                landmarkList(nLandmarksCurrent) = landmarkRaw(1);
                nLandmarksCurrent = nLandmarksCurrent + 1;
            else
                location = find(landmarkRaw(1), landmarkList);
                landmarkXY
            end
            %% Correction step
            stateMean(3+nLandmarksCurrent*2+1) = landmark(1);
            stateMean(3+nLandmarksCurrent*2+2) = landmark(2);
            % Calculate new stateCov ??
        end
    end
end