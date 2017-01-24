package com.n8k9.image_proc.arcadepush;

import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.WindowManager;

import org.opencv.android.BaseLoaderCallback;
import org.opencv.android.CameraBridgeViewBase;
import org.opencv.android.LoaderCallbackInterface;
import org.opencv.android.OpenCVLoader;
import org.opencv.core.Core;
import org.opencv.core.CvType;
import org.opencv.core.Mat;
import org.opencv.core.Size;
import org.opencv.imgproc.Imgproc;

import org.opencv.core.Point;



public class BackgroundSubtractionActivity extends AppCompatActivity implements CameraBridgeViewBase.CvCameraViewListener2 {
    private static final String  TAG                 = "ImageTimer";


    private CameraBridgeViewBase mOpenCvCameraView;

    private Mat rgba;
    private Mat gray;

    private Mat fgMask;

    private Mat background;
    private Mat backImage;
    private Mat foreground;






    private BaseLoaderCallback mLoaderCallback = new BaseLoaderCallback(this) {
        @Override
        public void onManagerConnected(int status) {
            switch (status) {
                case LoaderCallbackInterface.SUCCESS:
                {
                    Log.i(TAG, "OpenCV loaded successfully");
                    mOpenCvCameraView.enableView();
                } break;
                default:
                {
                    super.onManagerConnected(status);
                } break;
            }
        }
    };

    public BackgroundSubtractionActivity() {
        Log.i(TAG, "Instantiated new " + this.getClass());
    }

    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        Log.i(TAG, "called onCreate");
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        setContentView(R.layout.activity_background_subtraction);

        mOpenCvCameraView = (CameraBridgeViewBase) findViewById(R.id.background_subtraction_surface_view);
        mOpenCvCameraView.setCvCameraViewListener(this);
    }

    @Override
    public void onPause()
    {
        super.onPause();
        if (mOpenCvCameraView != null)
            mOpenCvCameraView.disableView();
    }

    @Override
    public void onResume()
    {
        super.onResume();
        if (!OpenCVLoader.initDebug()) {
            Log.d(TAG, "Internal OpenCV library not found. Using OpenCV Manager for initialization");
            OpenCVLoader.initAsync(OpenCVLoader.OPENCV_VERSION_3_0_0, this, mLoaderCallback);
        } else {
            Log.d(TAG, "OpenCV library found inside package. Using it!");
            mLoaderCallback.onManagerConnected(LoaderCallbackInterface.SUCCESS);
        }
    }

    public void onDestroy() {
        super.onDestroy();
        if (mOpenCvCameraView != null)
            mOpenCvCameraView.disableView();
    }





    public void onCameraViewStarted(int width, int height) {
        rgba = new Mat();
        gray = new Mat();

        fgMask = new Mat();

        background = new Mat();
        backImage = new Mat();
        foreground = new Mat();

        // Disable Autofocus
        mOpenCvCameraView.setFocusable(false);
    }

    public void onCameraViewStopped() {
        // Explicitly deallocate Mats
        if (rgba != null)
            rgba.release();

        if (gray != null)
            gray.release();

        if (fgMask != null)
            fgMask.release();

        if (background != null)
            background.release();

        if (backImage != null)
            backImage.release();

        if (foreground != null)
            foreground.release();




        rgba = null;
        gray = null;
        fgMask = null;
        background = null;
        backImage = null;
        foreground = null;
    }

    public Mat onCameraFrame(CameraBridgeViewBase.CvCameraViewFrame inputFrame) {
        // Input Frames
        rgba = inputFrame.rgba();
        gray = inputFrame.gray();

        ////////////////////////////////////////////////////////////////////////////////////////////
        // BACKGROUND SUBTRACTION
        ////////////////////////////////////////////////////////////////////////////////////////////

        // Initialize Background to First Frame
        if(background.empty()){
            gray.convertTo(background, CvType.CV_32F);
        }

        // Convert Background to 8U
        background.convertTo(backImage, CvType.CV_8U);

        // Compute Difference Between Current Image and Background
        Core.absdiff(backImage, gray, foreground);

        Imgproc.threshold(foreground, fgMask, 50, 255, Imgproc.THRESH_BINARY);


        Imgproc.accumulateWeighted(gray, background, 0.01);//, outputFrame);

        ////////////////////////////////////////////////////////////////////////////////////////////



        ////////////////////////////////////////////////////////////////////////////////////////////
        // COLOR THRESHOLDING
        ////////////////////////////////////////////////////////////////////////////////////////////



        ////////////////////////////////////////////////////////////////////////////////////////////


        //return foreground;
        return fgMask;
    }





    @Override
    public void onBackPressed() {
        super.onBackPressed();
        finish();
    }

    //class ColorProfile



}