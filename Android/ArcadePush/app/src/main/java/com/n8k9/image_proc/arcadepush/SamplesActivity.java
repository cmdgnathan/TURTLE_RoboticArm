package com.n8k9.image_proc.arcadepush;

import android.content.Intent;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.view.View;


public class SamplesActivity extends AppCompatActivity {

    Intent sampleIntent;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_samples);
    }

    public void imageManipulations(View v) {
        sampleIntent = new Intent(this, ImageManipulationsActivity.class);
        startActivity(sampleIntent);
    }

    public void pairBluetooth(View v) {
        sampleIntent = new Intent(this, BluetoothActivity.class);
        startActivity(sampleIntent);
    }

    public void imageTimer(View v) {
        sampleIntent = new Intent(this, ImageTimerActivity.class);
        startActivity(sampleIntent);
    }

    public void backgroundSubtraction(View v) {
        sampleIntent = new Intent(this, BackgroundSubtractionActivity.class);
        startActivity(sampleIntent);
    }



/*
    public void tutorial1(View v) {
        sampleIntent = new Intent(this, Tutorial1Activity.class);
        startActivity(sampleIntent);
    }

    public void tutorial2(View v) {
        sampleIntent = new Intent(this, Tutorial2Activity.class);
        startActivity(sampleIntent);
    }

    public void tutorial3(View v) {
        sampleIntent = new Intent(this, Tutorial3Activity.class);
        startActivity(sampleIntent);
    }

    public void faceDetection(View v) {
        sampleIntent = new Intent(this, FaceDetectionActivity.class);
        startActivity(sampleIntent);
    }

    public void colorBlobDetection(View v) {
        sampleIntent = new Intent(this, ColorBlobDetectionActivity.class);
        startActivity(sampleIntent);
    }

    public void cameraCalibration(View v) {
        sampleIntent = new Intent(this, CameraCalibrationActivity.class);
        startActivity(sampleIntent);
    }

    public void puzzle15(View v) {
        sampleIntent = new Intent(this, Puzzle15Activity.class);
        startActivity(sampleIntent);
    }
*/
}