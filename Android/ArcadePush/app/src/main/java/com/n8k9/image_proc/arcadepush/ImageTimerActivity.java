package com.n8k9.image_proc.arcadepush;

import android.annotation.SuppressLint;
import android.os.Bundle;
import android.os.Environment;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;
import android.widget.Toast;

import org.opencv.android.BaseLoaderCallback;
import org.opencv.android.CameraBridgeViewBase;
import org.opencv.android.CameraBridgeViewBase.CvCameraViewFrame;
import org.opencv.android.CameraBridgeViewBase.CvCameraViewListener2;
import org.opencv.android.LoaderCallbackInterface;
import org.opencv.android.OpenCVLoader;
import org.opencv.core.Core;
import org.opencv.core.CvType;
import org.opencv.core.Mat;
import org.opencv.core.MatOfFloat;
import org.opencv.core.MatOfInt;
import org.opencv.core.Point;
import org.opencv.core.Scalar;
import org.opencv.core.Size;
import org.opencv.imgproc.Imgproc;

import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Date;

public class ImageTimerActivity extends AppCompatActivity implements CvCameraViewListener2, View.OnTouchListener {
    private static final String  TAG                 = "ImageTimer";

    public static final int      VIEW_MODE_RGBA      = 0;
    public static final int      VIEW_MODE_HIST      = 1;
    public static final int      VIEW_MODE_CANNY     = 2;
    public static final int      VIEW_MODE_SEPIA     = 3;
    public static final int      VIEW_MODE_SOBEL     = 4;
    public static final int      VIEW_MODE_ZOOM      = 5;
    public static final int      VIEW_MODE_PIXELIZE  = 6;
    public static final int      VIEW_MODE_POSTERIZE = 7;

    private MenuItem             mItemPreviewRGBA;
    private MenuItem             mItemPreviewHist;
    private MenuItem             mItemPreviewCanny;
    private MenuItem             mItemPreviewSepia;
    private MenuItem             mItemPreviewSobel;
    private MenuItem             mItemPreviewZoom;
    private MenuItem             mItemPreviewPixelize;
    private MenuItem             mItemPreviewPosterize;
    private CameraBridgeViewBase mOpenCvCameraView;

    private Size                 mSize0;

    private Mat                  mIntermediateMat;
    private Mat                  mMat0;
    private MatOfInt             mChannels[];
    private MatOfInt             mHistSize;
    private int                  mHistSizeNum = 25;
    private MatOfFloat           mRanges;
    private Scalar               mColorsRGB[];
    private Scalar               mColorsHue[];
    private Scalar               mWhilte;
    private Point                mP1;
    private Point                mP2;
    private float                mBuff[];
    private Mat                  mSepiaKernel;

    public static int           viewMode = VIEW_MODE_RGBA;

    static private boolean      first_time = true;
    static private boolean      first_time_L = true;
    static private boolean      first_time_R = true;

    private float               touchX = 0;
    private float               touchY = 0;

    private int                 hist_thickness;
    private int                 hist_offset;

    private Mat                 mZoomWindow_L;
    private int                 hist_thickness_L;
    private int                 hist_offset_L;
    private Mat                 hist_L;
    private Point               mP1_L;
    private Point               mP2_L;
    private float               mBuff_L[];

    private Mat                 mZoomWindow_R;
    private int                 hist_thickness_R;
    private int                 hist_offset_R;
    private Mat                 hist_R;
    private Point               mP1_R;
    private Point               mP2_R;
    private float               mBuff_R[];

    private Mat                 hist_reticle;
    private double              left_comp, right_comp;


    //private Mat                 zoomCorner_L;
    //static private boolean      useZoomCorner_L = false;
    //private Mat                 zoomCorner_R;
    //static private boolean      useZoomCorner_R = false;

    //private int zoomCorner_L_x1 = 0;
    //private int zoomCorner_L_x2 = 0;
    //private int zoomCorner_L_y1 = 0;
    //private int zoomCorner_L_y2 = 0;

    //private int zoomCorner_R_x1 = 0;
    //private int zoomCorner_R_x2 = 0;
    //private int zoomCorner_R_y1 = 0;
    //private int zoomCorner_R_y2 = 0;

    private BaseLoaderCallback  mLoaderCallback = new BaseLoaderCallback(this) {
        @Override
        public void onManagerConnected(int status) {
            switch (status) {
                case LoaderCallbackInterface.SUCCESS:
                {
                    Log.i(TAG, "OpenCV loaded successfully");
                    mOpenCvCameraView.enableView();
                    mOpenCvCameraView.setOnTouchListener(ImageTimerActivity.this);
                } break;
                default:
                {
                    super.onManagerConnected(status);
                } break;
            }
        }
    };

    public ImageTimerActivity() {
        Log.i(TAG, "Instantiated new " + this.getClass());
    }

    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        Log.i(TAG, "called onCreate");
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        setContentView(R.layout.activity_image_timer);

        mOpenCvCameraView = (CameraBridgeViewBase) findViewById(R.id.image_timer_activity_surface_view);
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

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        Log.i(TAG, "called onCreateOptionsMenu");
        mItemPreviewRGBA  = menu.add("Preview RGBA");
        mItemPreviewHist  = menu.add("Histograms");
        mItemPreviewCanny = menu.add("Canny");
        mItemPreviewSepia = menu.add("Sepia");
        mItemPreviewSobel = menu.add("Sobel");
        mItemPreviewZoom  = menu.add("Zoom");
        mItemPreviewPixelize  = menu.add("Pixelize");
        mItemPreviewPosterize = menu.add("Posterize");
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        Log.i(TAG, "called onOptionsItemSelected; selected item: " + item);
        if (item == mItemPreviewRGBA)
            viewMode = VIEW_MODE_RGBA;
        if (item == mItemPreviewHist)
            viewMode = VIEW_MODE_HIST;
        else if (item == mItemPreviewCanny)
            viewMode = VIEW_MODE_CANNY;
        else if (item == mItemPreviewSepia)
            viewMode = VIEW_MODE_SEPIA;
        else if (item == mItemPreviewSobel)
            viewMode = VIEW_MODE_SOBEL;
        else if (item == mItemPreviewZoom)
            viewMode = VIEW_MODE_ZOOM;
        else if (item == mItemPreviewPixelize)
            viewMode = VIEW_MODE_PIXELIZE;
        else if (item == mItemPreviewPosterize)
            viewMode = VIEW_MODE_POSTERIZE;
        else if (item.getItemId() == android.R.id.home)
            finish();

        return true;
    }

    public void onCameraViewStarted(int width, int height) {
        mIntermediateMat = new Mat();
        mSize0 = new Size();
        mChannels = new MatOfInt[] { new MatOfInt(0), new MatOfInt(1), new MatOfInt(2) };
        mBuff = new float[mHistSizeNum];
        mHistSize = new MatOfInt(mHistSizeNum);
        mRanges = new MatOfFloat(0f, 256f);
        mMat0  = new Mat();
        mColorsRGB = new Scalar[] { new Scalar(200, 0, 0, 255), new Scalar(0, 200, 0, 255), new Scalar(0, 0, 200, 255) };
        mColorsHue = new Scalar[] {
                new Scalar(255, 0, 0, 255),   new Scalar(255, 60, 0, 255),  new Scalar(255, 120, 0, 255), new Scalar(255, 180, 0, 255), new Scalar(255, 240, 0, 255),
                new Scalar(215, 213, 0, 255), new Scalar(150, 255, 0, 255), new Scalar(85, 255, 0, 255),  new Scalar(20, 255, 0, 255),  new Scalar(0, 255, 30, 255),
                new Scalar(0, 255, 85, 255),  new Scalar(0, 255, 150, 255), new Scalar(0, 255, 215, 255), new Scalar(0, 234, 255, 255), new Scalar(0, 170, 255, 255),
                new Scalar(0, 120, 255, 255), new Scalar(0, 60, 255, 255),  new Scalar(0, 0, 255, 255),   new Scalar(64, 0, 255, 255),  new Scalar(120, 0, 255, 255),
                new Scalar(180, 0, 255, 255), new Scalar(255, 0, 255, 255), new Scalar(255, 0, 215, 255), new Scalar(255, 0, 85, 255),  new Scalar(255, 0, 0, 255)
        };
        mWhilte = Scalar.all(255);
        mP1 = new Point();
        mP2 = new Point();

        hist_L = new Mat();
        mBuff_L = new float[mHistSizeNum];
        mP1_L = new Point();
        mP2_L = new Point();

        hist_R = new Mat();
        mBuff_R = new float[mHistSizeNum];
        mP1_R = new Point();
        mP2_R = new Point();

        // Fill sepia kernel
        mSepiaKernel = new Mat(4, 4, CvType.CV_32F);
        mSepiaKernel.put(0, 0, /* R */0.189f, 0.769f, 0.393f, 0f);
        mSepiaKernel.put(1, 0, /* G */0.168f, 0.686f, 0.349f, 0f);
        mSepiaKernel.put(2, 0, /* B */0.131f, 0.534f, 0.272f, 0f);
        mSepiaKernel.put(3, 0, /* A */0.000f, 0.000f, 0.000f, 1f);

    }

    public void onCameraViewStopped() {
        // Explicitly deallocate Mats
        if (mIntermediateMat != null)
            mIntermediateMat.release();

        mIntermediateMat = null;
    }

    public Mat onCameraFrame(CvCameraViewFrame inputFrame) {
        Mat rgba = inputFrame.rgba();
        Size sizeRgba = rgba.size();

        Mat rgbaInnerWindow;

        int rows = (int) sizeRgba.height;
        int cols = (int) sizeRgba.width;

        int left = cols / 8;
        int top = rows / 8;

        int width = cols * 3 / 4;
        int height = rows * 3 / 4;

        switch (ImageTimerActivity.viewMode) {
            case ImageTimerActivity.VIEW_MODE_RGBA:
                int zoomCorner_L_top = 0;
                int zoomCorner_L_bottom = rows / 2 - rows / 10;
                int zoomCorner_L_left = 0;
                int zoomCorner_L_right = cols / 2 - cols / 10;

                int zoomCorner_R_top = 0;
                int zoomCorner_R_bottom = rows / 2 - rows / 10;
                int zoomCorner_R_left = cols / 2 + cols / 10;
                int zoomCorner_R_right = cols;



                // Pointer in Left Box
                if(touchY>zoomCorner_L_top && touchY<zoomCorner_L_bottom
                        && touchX>zoomCorner_L_left && touchX<zoomCorner_L_right)
                {
                    touchX = 0; touchY = 0; // Reset Pointer

                    // Freeze Frame
                    mZoomWindow_L.release();
                    mIntermediateMat.release();
                    mZoomWindow_L = rgba.submat(rows / 2 - 9 * rows / 100, rows / 2 + 9 * rows / 100, cols / 2 - 9 * cols / 100, cols / 2 + 9 * cols / 100).clone();

                    // Histogram
                    Size size_mZoomWindow_L = mZoomWindow_L.size();
                    Imgproc.cvtColor(mZoomWindow_L, mIntermediateMat, Imgproc.COLOR_RGB2HSV_FULL);

                    // Hue
                    Imgproc.calcHist(Arrays.asList(mIntermediateMat), mChannels[0], mMat0, hist_L, mHistSize, mRanges);
                    Core.normalize(hist_L, hist_L, size_mZoomWindow_L.height/2, 0, Core.NORM_INF);
                    hist_L.get(0, 0, mBuff_L);
                    first_time_L = false;
                }

                    // Pointer in Right Box
                if(touchY>zoomCorner_R_top && touchY<zoomCorner_R_bottom
                        && touchX>zoomCorner_R_left && touchX<zoomCorner_R_right)
                {
                    touchX = 0; touchY = 0; // Reset Pointer

                    // Freeze Frame
                    mZoomWindow_R.release();
                    mIntermediateMat.release();
                    mZoomWindow_R = rgba.submat(rows / 2 - 9 * rows / 100, rows / 2 + 9 * rows / 100, cols / 2 - 9 * cols / 100, cols / 2 + 9 * cols / 100).clone();

                    // Histogram
                    Size size_mZoomWindow_R = mZoomWindow_R.size();
                    Imgproc.cvtColor(mZoomWindow_R, mIntermediateMat, Imgproc.COLOR_RGB2HSV_FULL);

                    // Hue
                    Imgproc.calcHist(Arrays.asList(mIntermediateMat), mChannels[0], mMat0, hist_R, mHistSize, mRanges);
                    Core.normalize(hist_R, hist_R, size_mZoomWindow_R.height/2, 0, Core.NORM_INF);
                    hist_R.get(0, 0, mBuff_R);
                    first_time_R = false;
                }

                if(first_time)
                {
                    first_time = false;

                    mZoomWindow_L = rgba.submat(rows / 2 - 9 * rows / 100, rows / 2 + 9 * rows / 100, cols / 2 - 9 * cols / 100, cols / 2 + 9 * cols / 100).clone();
                    mZoomWindow_R = rgba.submat(rows / 2 - 9 * rows / 100, rows / 2 + 9 * rows / 100, cols / 2 - 9 * cols / 100, cols / 2 + 9 * cols / 100).clone();

                }



                // Position Zoom Windows in Large Frame
                Mat zoomCorner_L = rgba.submat(zoomCorner_L_top, zoomCorner_L_bottom, zoomCorner_L_left, zoomCorner_L_right);
                Mat zoomCorner_R = rgba.submat(zoomCorner_R_top, zoomCorner_R_bottom, zoomCorner_R_left, zoomCorner_R_right);

                // Copy Stored Zoom Frames into Zoom Window
                Imgproc.resize(mZoomWindow_L, zoomCorner_L, zoomCorner_L.size());
                Imgproc.resize(mZoomWindow_R, zoomCorner_R, zoomCorner_R.size());





                // Plot Rectangle Reticle
                Mat mZoomWindow = rgba.submat(rows / 2 - 9 * rows / 100, rows / 2 + 9 * rows / 100, cols / 2 - 9 * cols / 100, cols / 2 + 9 * cols / 100);
                Size wsize = mZoomWindow.size();
                Imgproc.rectangle(mZoomWindow, new Point(1, 1), new Point(wsize.width - 2, wsize.height - 2), new Scalar(255, 0, 0, 255), 2);

                // Histogram of Reticle
                Mat hist_reticle = new Mat();
                Imgproc.cvtColor(mZoomWindow, mIntermediateMat, Imgproc.COLOR_RGB2HSV_FULL);
                // Hue
                Imgproc.calcHist(Arrays.asList(mIntermediateMat), mChannels[0], mMat0, hist_reticle, mHistSize, mRanges);
                Core.normalize(hist_reticle, hist_reticle, wsize.height/2, 0, Core.NORM_INF);
                hist_reticle.get(0, 0, mBuff);

                // Compare Histograms
                if(!first_time_L)
                {
                    left_comp = Imgproc.compareHist( hist_reticle, hist_L, 0);
                    Imgproc.putText(rgba, Double.toString(left_comp), new Point(zoomCorner_L_left+50, zoomCorner_L_top+50), 3, 1, new Scalar(255, 0, 0, 255), 2);

                }

                if(!first_time_R)
                {
                    right_comp = Imgproc.compareHist( hist_reticle, hist_R, 0);
                    Imgproc.putText(rgba, Double.toString(right_comp), new Point(zoomCorner_R_left+50, zoomCorner_R_top+50), 3, 1, new Scalar(255, 0, 0, 255), 2);

                }

                if(!first_time_L && !first_time_R)
                {
                    if(left_comp>right_comp) Imgproc.rectangle(rgba, new Point(zoomCorner_L_left, zoomCorner_L_bottom), new Point(zoomCorner_L_right, zoomCorner_L_top), new Scalar(255, 0, 0, 255), 10);
                    else Imgproc.rectangle(rgba, new Point(zoomCorner_R_left, zoomCorner_R_bottom), new Point(zoomCorner_R_right, zoomCorner_R_top), new Scalar(255, 0, 0, 255), 10);

                }

                // Put Correlation Factor for Each Window



                // Plot Histograms
                for(int h=0; h<mHistSizeNum; h++) {

                    hist_thickness_L = (int) (mZoomWindow_L.size().width / (mHistSizeNum + 10));
                    hist_offset_L = (int) (zoomCorner_L_left)+1;

                    mP1_L.x = mP2_L.x = hist_offset_L + h * hist_thickness_L;
                    mP1_L.y = zoomCorner_L_bottom-1;
                    mP2_L.y = mP1_L.y - 2 - (int)mBuff_L[h];
                    Imgproc.line(rgba, mP1_L, mP2_L, mColorsHue[h], hist_thickness_L);

                    hist_thickness_R = (int) (mZoomWindow_R.size().width / (mHistSizeNum + 10));
                    hist_offset_R = (int) (zoomCorner_R_left)+1;

                    mP1_R.x = mP2_R.x = hist_offset_R + h * hist_thickness_R;
                    mP1_R.y = zoomCorner_R_bottom-1;
                    mP2_R.y = mP1_R.y - 2 - (int)mBuff_R[h];
                    Imgproc.line(rgba, mP1_R, mP2_R, mColorsHue[h], hist_thickness_R);

                    hist_thickness = (int) (rgba.size().width / (mHistSizeNum + 10));
                    hist_offset = (int) 1;

                    mP1.x = mP2.x = hist_offset + h * hist_thickness;
                    mP1.y = rgba.size().height-1;
                    mP2.y = mP1.y - 2 - (int)mBuff[h];
                    Imgproc.line(rgba, mP1, mP2, mColorsHue[h], hist_thickness);
                }

                // Release Temporary Variables
                zoomCorner_L.release();
                zoomCorner_R.release();
                mZoomWindow.release();
                hist_reticle.release();



                break;

            case ImageTimerActivity.VIEW_MODE_HIST:
                Mat hist = new Mat();
                int thikness = (int) (sizeRgba.width / (mHistSizeNum + 10) / 5);
                if(thikness > 5) thikness = 5;
                int offset = (int) ((sizeRgba.width - (5*mHistSizeNum + 4*10)*thikness)/2);
                // RGB
                for(int c=0; c<3; c++) {
                    Imgproc.calcHist(Arrays.asList(rgba), mChannels[c], mMat0, hist, mHistSize, mRanges);
                    Core.normalize(hist, hist, sizeRgba.height/2, 0, Core.NORM_INF);
                    hist.get(0, 0, mBuff);
                    for(int h=0; h<mHistSizeNum; h++) {
                        mP1.x = mP2.x = offset + (c * (mHistSizeNum + 10) + h) * thikness;
                        mP1.y = sizeRgba.height-1;
                        mP2.y = mP1.y - 2 - (int)mBuff[h];
                        Imgproc.line(rgba, mP1, mP2, mColorsRGB[c], thikness);
                    }
                }
                // Value and Hue
                Imgproc.cvtColor(rgba, mIntermediateMat, Imgproc.COLOR_RGB2HSV_FULL);
                // Value
                Imgproc.calcHist(Arrays.asList(mIntermediateMat), mChannels[2], mMat0, hist, mHistSize, mRanges);
                Core.normalize(hist, hist, sizeRgba.height/2, 0, Core.NORM_INF);
                hist.get(0, 0, mBuff);
                for(int h=0; h<mHistSizeNum; h++) {
                    mP1.x = mP2.x = offset + (3 * (mHistSizeNum + 10) + h) * thikness;
                    mP1.y = sizeRgba.height-1;
                    mP2.y = mP1.y - 2 - (int)mBuff[h];
                    Imgproc.line(rgba, mP1, mP2, mWhilte, thikness);
                }
                // Hue
                Imgproc.calcHist(Arrays.asList(mIntermediateMat), mChannels[0], mMat0, hist, mHistSize, mRanges);
                Core.normalize(hist, hist, sizeRgba.height/2, 0, Core.NORM_INF);
                hist.get(0, 0, mBuff);
                for(int h=0; h<mHistSizeNum; h++) {
                    mP1.x = mP2.x = offset + (4 * (mHistSizeNum + 10) + h) * thikness;
                    mP1.y = sizeRgba.height-1;
                    mP2.y = mP1.y - 2 - (int)mBuff[h];
                    Imgproc.line(rgba, mP1, mP2, mColorsHue[h], thikness);
                }
                break;

            case ImageTimerActivity.VIEW_MODE_CANNY:
                rgbaInnerWindow = rgba.submat(top, top + height, left, left + width);
                Imgproc.Canny(rgbaInnerWindow, mIntermediateMat, 80, 90);
                Imgproc.cvtColor(mIntermediateMat, rgbaInnerWindow, Imgproc.COLOR_GRAY2BGRA, 4);
                rgbaInnerWindow.release();
                break;

            case ImageTimerActivity.VIEW_MODE_SOBEL:
                Mat gray = inputFrame.gray();
                Mat grayInnerWindow = gray.submat(top, top + height, left, left + width);
                rgbaInnerWindow = rgba.submat(top, top + height, left, left + width);
                Imgproc.Sobel(grayInnerWindow, mIntermediateMat, CvType.CV_8U, 1, 1);
                Core.convertScaleAbs(mIntermediateMat, mIntermediateMat, 10, 0);
                Imgproc.cvtColor(mIntermediateMat, rgbaInnerWindow, Imgproc.COLOR_GRAY2BGRA, 4);
                grayInnerWindow.release();
                rgbaInnerWindow.release();
                break;

            case ImageTimerActivity.VIEW_MODE_SEPIA:
                rgbaInnerWindow = rgba.submat(top, top + height, left, left + width);
                Core.transform(rgbaInnerWindow, rgbaInnerWindow, mSepiaKernel);
                rgbaInnerWindow.release();
                break;

            case ImageTimerActivity.VIEW_MODE_ZOOM:
                Mat zoomCorner1 = rgba.submat(0, rows / 2 - rows / 10, 0, cols / 2 - cols / 10);
                Mat mZoomWindow1 = rgba.submat(rows / 2 - 9 * rows / 100, rows / 2 + 9 * rows / 100, cols / 2 - 9 * cols / 100, cols / 2 + 9 * cols / 100);
                Imgproc.resize(mZoomWindow1, zoomCorner1, zoomCorner1.size());
                Size wsize1 = mZoomWindow1.size();
                Imgproc.rectangle(mZoomWindow1, new Point(1, 1), new Point(wsize1.width - 2, wsize1.height - 2), new Scalar(255, 0, 0, 255), 2);
                zoomCorner1.release();
                mZoomWindow1.release();
                break;

            case ImageTimerActivity.VIEW_MODE_PIXELIZE:
                rgbaInnerWindow = rgba.submat(top, top + height, left, left + width);
                Imgproc.resize(rgbaInnerWindow, mIntermediateMat, mSize0, 0.1, 0.1, Imgproc.INTER_NEAREST);
                Imgproc.resize(mIntermediateMat, rgbaInnerWindow, rgbaInnerWindow.size(), 0., 0., Imgproc.INTER_NEAREST);
                rgbaInnerWindow.release();
                break;

            case ImageTimerActivity.VIEW_MODE_POSTERIZE:
            /*
            Imgproc.cvtColor(rgbaInnerWindow, mIntermediateMat, Imgproc.COLOR_RGBA2RGB);
            Imgproc.pyrMeanShiftFiltering(mIntermediateMat, mIntermediateMat, 5, 50);
            Imgproc.cvtColor(mIntermediateMat, rgbaInnerWindow, Imgproc.COLOR_RGB2RGBA);
            */
                rgbaInnerWindow = rgba.submat(top, top + height, left, left + width);
                Imgproc.Canny(rgbaInnerWindow, mIntermediateMat, 80, 90);
                rgbaInnerWindow.setTo(new Scalar(0, 0, 0, 255), mIntermediateMat);
                Core.convertScaleAbs(rgbaInnerWindow, mIntermediateMat, 1./16, 0);
                Core.convertScaleAbs(mIntermediateMat, rgbaInnerWindow, 16, 0);
                rgbaInnerWindow.release();
                break;

        }

        return rgba;
    }


    @SuppressLint("SimpleDateFormat")
    @Override
    public boolean onTouch(View v, MotionEvent event) {
        Log.i(TAG,"onTouch event");
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd_HH-mm-ss");
        String currentDateandTime = sdf.format(new Date());
        String fileName = Environment.getExternalStorageDirectory().getPath() +
                "/sample_picture_" + currentDateandTime + ".jpg";

        touchX = event.getX();
        touchY = event.getY();




        //mOpenCvCameraView.takePicture(fileName);

        //Toast.makeText(this, fileName + " saved", Toast.LENGTH_SHORT).show();

        Toast.makeText(this, "Left: "+left_comp+"\nRight: "+right_comp, Toast.LENGTH_SHORT).show();

        return false;
    }

    @Override
    public void onBackPressed() {
        super.onBackPressed();
        finish();
    }



}