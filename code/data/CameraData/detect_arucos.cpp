#include "defs.hpp"
#include <iostream>
#include <fstream> 
#include <sstream>

#define N_SAMPLES 1
#define SAMPLES_DIR "test_images/1image.bmp"  
#define MarkersSide 0.15 //15 cm
#define WIDTH 2056
#define HEIGHT 1542

void GetCalibration(Mat& intrinsics, Mat& distCoeffs) {
    FileStorage fs("calib_arucoboard.xml", FileStorage::READ);
    if (fs.isOpened()) {
      fs["intrinsics"] >> intrinsics;
      fs["distCoeffs"] >> distCoeffs;
      fs.release();
    }
    else
        exit(0);
}

string FileName(const string& str) {
  size_t slash = str.find_last_of("/\\");
  size_t dot = str.find_last_of(".\\");
  size_t len = dot-slash;
  string name = str.substr(slash+1, len-1);
  return name;
}

int main(int argc, char const *argv[]) {

    ofstream outfile ("landmark.txt");

    cv::String path(SAMPLES_DIR);
    vector<cv::String> fn;
    vector<cv::Mat> data;
    cv::glob(path,fn,true);
    string timestamp;

    Mat inputImage, marker;
    vector<int> markerIds;
    vector<int> new_markerIds;
	vector<vector<cv::Point2f>> markerCorners;
	cv::Ptr<cv::aruco::Dictionary> dictionary = cv::aruco::getPredefinedDictionary(cv::aruco::DICT_4X4_50);

    vector<cv::Vec3d> rvecs, tvecs;
    Mat intrinsics, distCoeffs;
    GetCalibration(intrinsics, distCoeffs);

    double teta;
    double distance;
    Mat rMatrix;
    Mat tvecsCam;
    int markerIdsSize;

    int i = 0, j = 0;
    while(i < N_SAMPLES) {
        
        timestamp = FileName(fn[i]);

        //undistort(imread(fn[i]), inputImage, intrinsics, distCoeffs);
        //imshow("inputImage", inputImage);
        //waitKey(0);
        inputImage = imread(fn[i]);
        
        cv::aruco::detectMarkers(inputImage, dictionary, markerCorners, markerIds);
        
        cout << "Detected " << markerIds.size() << " arucos" << endl;
        
        if (markerIds.size() > 0) {
            cout << "IDs: " << markerIds[0] << endl;
            
            // The returned transformation is the one that transforms points from each marker coordinate 
            //  system to the camera coordinate system
            cv::aruco::estimatePoseSingleMarkers(markerCorners, MarkersSide, intrinsics, distCoeffs, rvecs, tvecs);
            

            markerIdsSize = 0;
            for(j=0; j<markerIds.size(); j++) {
            	if(markerIds[j] < 15) {
            		markerIdsSize++;
            	}
            }

            outfile << timestamp << " " << markerIdsSize << 	" ";
            cout << timestamp << endl;

            //cv::aruco::drawDetectedMarkers(inputImage, markerCorners, markerIds);
            
            for(j=0; j<markerIds.size(); j++) {

            	if(markerIds[j] < 15) {
	                cout << "Landmark[" << j << "]:" << endl;
	                                
	                //cout << "Translation vector in aruco's ref: " << endl << tvecs[j] << endl;

	                cv::Rodrigues(rvecs[j], rMatrix);
	                tvecsCam = -rMatrix.t()*Mat(tvecs[j]);
	                cout << "Translation vector: " << endl << tvecsCam << endl;
	                
	                double z = tvecsCam.at<double>(2);
					double x = tvecsCam.at<double>(0);

	                // Computation of distance to aruco through sqrt(a^2 + b^2)
	                distance = sqrt(z*z + x*x);
	                teta = atan2(x,z);

	                outfile << markerIds[j] << " " << teta << " " << distance << " ";
	                cout << "[id teta distance]" << endl << "[" << markerIds[j] << " " << teta << " " << distance << "] " << endl;

	                cv::aruco::drawAxis(inputImage, intrinsics, distCoeffs, rvecs[j], tvecs[j], 0.1);
	                cv::imshow("OutputImage", inputImage);
	                imwrite("OutputImage.png", inputImage);
	                waitKey(0);

	                rMatrix.release();
	                tvecsCam.release();
            	}
            }

            rvecs.clear();
            tvecs.clear();
            outfile << endl;
            cout << endl;

        }
        i++;
        inputImage.release();
    }
	
	return 0;
}