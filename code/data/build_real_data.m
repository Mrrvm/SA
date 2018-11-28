iterdata = load('/home/imarcher/Dropbox/Tecnico/SA/code/data/ITERdata/iterdata.mat');
matObj = matfile('/home/imarcher/Dropbox/Tecnico/SA/code/data/ITERdata/iterdata.mat');
details = whos(matObj);
aux = details.size;
iterdataSize = aux(1);

cameraDataFile = fopen('/home/imarcher/Dropbox/Tecnico/SA/code/data/CameraData/landmark.txt','r');

i = 1;
while true
  thisline = fgetl(cameraDataFile);
  if ~ischar(thisline)
      break; 
  end  
  brokenline = strsplit(thisline);
  [m, r] = strtok(brokenline(1), '.');
  hour = str2double(m);
  [m, r] = strtok(r, '.');
  min = str2double(m);
  [m, r] = strtok(r, '.');
  sec = str2double(strcat(m,r));
  cam(i).date = hour*3600+min*60+sec;
  cam(i).landmarksSeen =  str2double(brokenline(2));

  c = 3;
  for j = 1:cam(i).landmarksSeen
      cam(i).landmark(j, :) = [str2double(brokenline(c)) str2double(brokenline(c+1)) str2double(brokenline(c+2))];
      c = c+3;  
  end
  
  i = i+1;
end
fclose(cameraDataFile);

cameradataSize = i-1;


for i=1:iterdataSize
    iterdata.time(i, 1) = iterdata.date(i).hour*3600 + iterdata.date(i).min*60 + iterdata.date(i).seg;
end

