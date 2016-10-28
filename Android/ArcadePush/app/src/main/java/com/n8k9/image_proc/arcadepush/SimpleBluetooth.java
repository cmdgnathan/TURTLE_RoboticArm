package com.n8k9.image_proc.arcadepush;

import android.app.Activity;
import android.app.ProgressDialog;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.Context;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Vibrator;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

import java.io.IOException;
import java.util.UUID;

public class SimpleBluetooth extends Activity {

    TextView textView;

    Button btn_Transmit, btn_Receive, btn_Disconnect;

    TextView txt_Timer;

    String Line_1;
    String Line_2;
    String Line_3;
    String Line_4;
    String Line_5;

    public Vibrator v;

    String address = null;
    private ProgressDialog progress;
    BluetoothAdapter myBluetooth = null;
    BluetoothSocket btSocket = null;
    private boolean isBtConnected = false;

    //SPP UUID. Look for it
    static final UUID myUUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB");

    @Override
    protected void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);

        Intent newint = getIntent();
        address = newint.getStringExtra(BluetoothActivity.EXTRA_ADDRESS); //receive the address of the bluetooth device

        // Setup Layout View
        setContentView(R.layout.activity_simple_bluetooth);





        // Call Widgets
        btn_Transmit = (Button)findViewById(R.id.buttonTransmit);
        btn_Receive = (Button)findViewById(R.id.buttonReceive);
        btn_Disconnect = (Button)findViewById(R.id.buttonDisconnect);


        // Initialize Vibration
        v = (Vibrator) this.getSystemService(Context.VIBRATOR_SERVICE);

        new ConnectBT().execute(); //Call the class to connect


        btn_Transmit.setOnClickListener(new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                msg("Hi");
                //Transmit();
            }
        });

        btn_Receive.setOnClickListener(new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                Receive();
            }
        });

        btn_Disconnect.setOnClickListener(new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                Disconnect(); //close connection
            }
        });


    }

    private void Receive()
    {
        if (btSocket!=null)
        {
            try
            {
                // For Reading
                byte[] buffer = new byte[1024];
                int bytes;

                bytes = btSocket.getInputStream().read(buffer);

                String value = new String(buffer, "UTF-8");
                msg("Read: "+value);


            }
            catch (IOException e)
            {
                msg("Error");
            }
        }
    }


    private void Transmit()
    {
//        timer_sequence();

        if (btSocket!=null)
        {
            try
            {


                String string_Transmit = "HELLO";
                btSocket.getOutputStream().write(string_Transmit.toString().getBytes());
                msg("Sent: "+string_Transmit);
            }
            catch (IOException e)
            {
                msg("Error");
            }
        }

    }




    private void Disconnect()
    {
        if (btSocket!=null) //If the btSocket is busy
        {
            try
            {
                btSocket.close(); //close connection
            }
            catch (IOException e)
            { msg("Error");}
        }
        finish(); //return to the first layout
    }

    // fast way to call Toast
    private void msg(String s)
    {
        Toast.makeText(getApplicationContext(), s, Toast.LENGTH_LONG).show();
    }

    /*
    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_calibration, menu);
        return true;
    }


    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        //noinspection SimplifiableIfStatement
        if (id == R.id.action_settings) {
            return true;
        }

        return super.onOptionsItemSelected(item);
    }
    */

    private class ConnectBT extends AsyncTask<Void, Void, Void>  // UI thread
    {
        private boolean ConnectSuccess = true; //if it's here, it's almost connected

        @Override
        protected void onPreExecute()
        {
            progress = ProgressDialog.show(SimpleBluetooth.this, "Connecting...", "Please wait!!!");  //show a progress dialog
        }

        @Override
        protected Void doInBackground(Void... devices) //while the progress dialog is shown, the connection is done in background
        {
            try
            {
                if (btSocket == null || !isBtConnected)
                {
                    myBluetooth = BluetoothAdapter.getDefaultAdapter();//get the mobile bluetooth device
                    BluetoothDevice dispositivo = myBluetooth.getRemoteDevice(address);//connects to the device's address and checks if it's available
                    btSocket = dispositivo.createInsecureRfcommSocketToServiceRecord(myUUID);//create a RFCOMM (SPP) connection
                    BluetoothAdapter.getDefaultAdapter().cancelDiscovery();
                    btSocket.connect();//start connection
                }
            }
            catch (IOException e)
            {
                ConnectSuccess = false;//if the try failed, you can check the exception here
            }
            return null;
        }
        @Override
        protected void onPostExecute(Void result) //after the doInBackground, it checks if everything went fine
        {
            super.onPostExecute(result);

            if (!ConnectSuccess)
            {
                msg("Connection Failed. Is it a SPP Bluetooth? Try again.");
                finish();
            }
            else
            {
                msg("Connected.");
                isBtConnected = true;
            }
            progress.dismiss();
        }
    }

}
