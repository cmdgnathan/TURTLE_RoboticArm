function WebcamApp_Gui()

clear('cam');
clearvars;
close all;


% Key Parameters
foreground_v_background = 1;
dynamic_background = 0 & foreground_v_background;
bluetooth_On = 0;
rot90_On = 0;

% Create Webcam Object
cam = webcam('USB2.0 VGA UVC WebCam');
%cam = webcam('USB Video Device');
%cam = webcam('USB Camera');


% Reduce Webcam Resolution
%cam.Resolution = cam.AvailableResolutions(2);

% Autofocus
%cam.BacklightCompensation = 0;


% BLUETOOTH
if(bluetooth_On)
    instrreset;
    bt = Bluetooth('HC-05',1);
    fopen(bt);
end

% Parameters
img.resize = 0.25; % Image Resize Factor
img.hist_n = 3;%5;    % Number of Histogram Regions

img.hist_pad = 10; 
img.hist_step = 1;

img.hist_bins = 256; % Number of Histogram Bins
img.hist_thresh = 0.8; % Threshold Proportion of Maximum Value
img.hist_width = round(40/img.hist_n); % 20 Intensity Value to Left and Right

img.hist_i = 1; % Histogram Iterator

% GUI
[hFig, hAxes] = createFigureAndAxes();
[hText] = insertButtons(hFig, hAxes, cam);


% INITIAL (RUN ONCE)

% IMAGE CAPTURE          
hand = imresize(snapshot(cam), img.resize); 
if(rot90_On)
    hand = rot90(hand,2);
end
hand_g = rgb2gray(hand);        
[img.h, img.w] = size(hand_g); % Height and Width of Image

% BACKGROUND SUBTRACTION
alpha = 0.1;
background = hand_g;

% ARC PARAMETERS
img.arc_n = 10; % Number of Arcs for Finger Detection  
img.arc_outer = img.arc_n; % Outer Ring of Arc
img.arc_min = img.h/16.0; % Minimum Arc Radius
img.arc_max = img.h/4.0; % Maximum Arc Radius

img.arc_crossing = zeros(img.arc_n,1);

img.thick = 1; % Arc Thickness
img.norm_arc = 100; % Number of Normalized Arc Samples    

% FINGER NODES
img.node_n = 500;
img.node_id = 0;
for n=img.node_n:-1:1
    img.node(n).arc = 0;
    img.node(n).left = 0;
    img.node(n).right = 0;
    img.node(n).parent = 0;
    img.node(n).base = false;
    img.node(n).id = 0;
end

% FINGER TIPS
img.finger_n = 10;
img.finger_width = 10;
for f=img.finger_n:-1:1
    img.finger(f).left = 0;
    img.finger(f).right = 0;
    img.finger(f).index = 0;
    img.finger(f).value = 0;
end

%DETERMINE THE MAX OF EACH FINGER (TO BE OVERWRITTEN)

thumb_max = 1;
index_max = 1;
middle_max = 1;
ring_max = 1;
pinky_max = 1;

% ITERABLE CIRCLE LUT SERIES
[ img ] = IterableCircle( img );

% NORMALIZE ITERABLE CIRCLE
[ img ] = NormalizeCircle( img );

% Main
state = 0;
totHz = tic;
plotHz = tic;
while(1)        
    
    % Update Text Boxes
        % Histogram Width
            entry = sprintf('%d',img.hist_width);
            set(hText.HistWidth, 'String', strcat('Histogram Acceptance...',entry));    
        % Overall Rate
            entry = sprintf('%10.5f',(1/toc(totHz)));
            set(hText.totHz, 'String', strcat('Overall Rate...',entry));    
            totHz = tic;
       
            
            
            
    
            
    % STATE MACHINE
    if(state == 0)
        % Resize and Show Image
        hand = imresize(snapshot(cam), img.resize); 

        if(rot90_On)
            hand = rot90(hand,2);        
        end

        hand_g = rgb2gray(hand);             
        imshow(hand, 'Parent', hAxes.axis1);
        
        % BACKGROUND SUBTRACTION 
        
        
        if(dynamic_background)
            foreground = imabsdiff(background,hand_g);
            fg_mask = imbinarize(foreground,50/255);

            background = (1-alpha)*background + alpha*hand_g;
            imshow(fg_mask, 'Parent', hAxes.axis2);
        end
        
    elseif(state == 1)
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        % PROCESSING TIMER
        procHz = tic;
                  
        % Resize Image
        hand = imresize(snapshot(cam), img.resize); 
        if(rot90_On)
            hand = rot90(hand,2); % Rotate Image
        end
        hand_g = rgb2gray(hand);        
        [img.h, img.w] = size(hand_g); % Height and Width of Image

        
        % BACKGROUND SUBTRACTION                
        if(dynamic_background)
            foreground = imabsdiff(background,hand_g);
            fg_mask = imbinarize(foreground,50/255);

            background = (1-alpha)*background + alpha*hand_g;
            imshow(fg_mask, 'Parent', hAxes.axis2);
        end
        
        
        % MASK IMAGE (COLOR HISTOGRAM)
        hand_mask = false(img.h,img.w);    
        for i=1:img.hist_n
            img.hist_i = i;            
            [ img, hand_mask_bw ] = MaskImage( img, hand );
            hand_mask = hand_mask | hand_mask_bw;
        end   
        
        if(foreground_v_background)
            hand_mask = ~hand_mask;
        end
     
%             [ img, hand_mask_bw ] = MaskImageAvg( img, hand );
%             hand_mask = hand_mask_bw;

        % COMBINE BACKGROUND SUBTRACTION AND COLOR SEGMENTATION
        %hand_mask = hand_mask & fg_mask;
        
        
        % FIND LARGEST BLOB (COLOR REGION)
        BW = hand_mask;
        CC = bwconncomp(BW);
        numPixels = cellfun(@numel,CC.PixelIdxList);
        [~,idx] = max(numPixels);
        BW(CC.PixelIdxList{idx}) = 0;
        palm_blob = hand_mask - BW;
        
        % MEDIAN FILTER

        palm_med = ordfilt2(palm_blob, 5, true(3,3));                  

        %palm_med = ordfilt2(palm_blob, 13, true(5,5));
        

        % CALCULATE CENTROID
        %[ img ] = Centroid( img, palm_blob );
        [ img ] = Centroid( img, palm_med );

        
        % ITERABLE CIRCLES

        mask = false(round(2*img.circle(end).radius+1), round(2*img.circle(end).radius+1));

        for i=1:length(img.circle(:))
            img.circle(i).intersection_norm = false(img.norm_arc, 1);            
            for j=1:img.norm_arc

                x = img.x_cent - img.circle(i).radius + uint16(img.circle(i).iter_x_norm(j));
                y = img.y_cent - img.circle(i).radius + uint16(img.circle(i).iter_y_norm(j));

                if(x>0 && x<=img.h && y>0 && y<=img.w)

                    % Angular Plot as Line
                    img.circle(i).intersection_norm(j) = palm_med(x,y);

                    % Radar Plot
                    %if(hand_mask(x,y))
                    if(palm_med(x,y))
                        x = img.circle(end).radius - img.circle(i).radius + img.circle(i).iter_x_norm(j);
                        y = img.circle(end).radius - img.circle(i).radius + img.circle(i).iter_y_norm(j);
                        mask(x,y) = 1;                    
                    end
                end
            end
        end    
        
        % COUNTER FINGERS
        for i=1:length(img.circle(:))
            a1 = img.circle(i).intersection_norm(1:end-1);
            a2 = img.circle(i).intersection_norm(2:end);
            
            img.arc_crossing(i) = nnz(~(a1 .* a2) .* a1); % Positive Edge Crossings            
        end
        
        % DETERMINE OUTERMOST RING
        for i=length(img.circle(:)):-1:1
            if(img.arc_crossing(i)>3)
                img.arc_outer = i;
            end                        
        end
        
        % AGGREGATE RINGS
        img.intersect = zeros(img.norm_arc,1);        
        for a=img.arc_n:-1:1
            img.intersect = img.intersect + a^2*img.circle(a).intersection_norm;
        end                                     
        % DETERMINE FINGERS
        %[ img ] = Fingering( img );        
        
        % BLOB BOUNDING BOX
        st = regionprops(palm_blob, 'BoundingBox');
        hand_rect = st.BoundingBox;  
        
        % FINGER EXTRACTION
        data = img.intersect;
        original_data = data;
        fingers_i = zeros(10,1);
        fingers = zeros(10,1);
        for i = 1:length(fingers)
            [value,index] = max(data);
            
            range = index + ( -round(img.finger_width/2) : round(img.finger_width/2) );
            
            if(min(range)<=0)
                range = range + abs(min(range))+1;                
            elseif(max(range)>length(data))
                range = range - (max(range)-100) - 1;
            end
                        
            data(range) = 0;
            
            fingers(i) = value;
            fingers_i(i) = index;            
        end

        [~,I] = sort(fingers_i);
        
        img.fingers(:).value = fingers(I);
        img.fingers(:).index = fingers_i(I);
          
        display_data = original_data - data;
        
        thumb=  fingers(1);
        index=  fingers(2);
        middle= fingers(3);
        ring=   fingers(4);
        pinky=  fingers(5);
            

            %DETERMINE THE NEW MAX OF EACH FINGER
            
            thumb_max = max(thumb, thumb_max);
            index_max=max(index, index_max);
            middle_max=max(middle,middle_max);
            ring_max=max(ring,ring_max);
            pinky_max=max(pinky,pinky_max);
            
            %NORMALIZE THE CURRENT VALUE BY COMPARING IT TO THE MAX VALUE 
            
            
            thumb_norm = thumb/thumb_max;
            index_norm = index/index_max;
            middle_norm = middle/middle_max;
            ring_norm = ring/ring_max;
            pinky_norm = pinky/pinky_max;
                        
            
        % DATA FORMAT
        Tx_0 = strcat( '0:', sprintf('%02.0f',99*thumb_norm) );
        Tx_1 = strcat( '1:', sprintf('%02.0f',99*index_norm) );
        Tx_2 = strcat( '2:', sprintf('%02.0f',99*middle_norm) );
        Tx_3 = strcat( '3:', sprintf('%02.0f',99*ring_norm) );
        Tx_4 = strcat( '4:', sprintf('%02.0f',99*pinky_norm) );
            

        % TEXTBOX OUTPUT
        set(hText.fingers, 'String', strcat(Tx_0,'-',Tx_1,'-',Tx_2,'-',Tx_3,'-',Tx_4));                  
            
        % BLUETOOTH OUTPUT            
        if(bluetooth_On)
            fwrite(bt, strcat(Tx_0));
            fwrite(bt, char(10));
            fwrite(bt, strcat(Tx_1));
            fwrite(bt, char(10));
            fwrite(bt, strcat(Tx_2));
            fwrite(bt, char(10));
            fwrite(bt, strcat(Tx_3));
            fwrite(bt, char(10));
            fwrite(bt, strcat(Tx_4));
            fwrite(bt, char(10));
        end
        
        % PROCESSING TIMER
        entry = sprintf('%10.5f',(1/toc(procHz)));
        set(hText.procHz, 'String', strcat('Processing Rate...',entry));         
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%%%%%%%%%%%%%
        % GUI OUTPUT %
        %%%%%%%%%%%%%%

        % PLOTTING TIMER
        plotHz = tic; 

            % AXIS 1
%                 cla(hAxes.axis1,'reset');       
%                 imshow(hand, 'Parent', hAxes.axis1);   
%                 rectangle('Position',hand_rect,'EdgeColor','r','LineWidth',2, 'Parent', hAxes.axis1);         
            % AXIS 2
            %    cla(hAxes.axis2,'reset');       
            %    imshow(hand_mask, 'Parent', hAxes.axis2);
            % AXIS 3
                cla(hAxes.axis2,'reset');       
                imshow(hand_mask, 'Parent', hAxes.axis2);
%             AXIS 3
%                 cla(hAxes.axis3,'reset');       
%                 imshow(mask, 'Parent', hAxes.axis3);     
            % AXIS 4
                cla(hAxes.axis4,'reset');       
                imshow(palm_med, 'Parent', hAxes.axis4);    
            % AXIS 5
%                 cla(hAxes.axis5,'reset');  
%                 axes(hAxes.axis5);
%                 for a=img.arc_n:-1:1
%                     plot(1:img.norm_arc, 1.0*img.circle(a).intersection_norm+a); hold on;  
%                 end
%                 hold off;
            % AXIS 6        
                cla(hAxes.axis6,'reset');       
                plot(img.intersect, 'Color', 'Red', 'Parent', hAxes.axis6); hold on;
                %set(hAxes.axis6,'Color','Black');
                
%                 % PLOT FINGER LOCATIONS
%                 for i = 1:img.finger_n
%                     patch([(img.finger(i).index-img.finger_width) (img.finger(i).index+img.finger_width) ...
%                             (img.finger(i).index+img.finger_width) (img.finger(i).index-img.finger_width)], ...
%                             [0 0 1 1], 'b', ...
%                             'Parent', hAxes.axis6);
%                     %alpha(0.2, 'Parent', hAxes.axis6);                       
%                 end
                
                
            % AXIS 7
                cla(hAxes.axis7,'reset');  
                plot(display_data, 'Color', 'Red', 'Parent', hAxes.axis7); hold on;                
                %set(hAxes.axis7,'Color','Black');
%                 cla(hAxes.axis7,'reset');    
%                 for f=1:img.node_id
%                     x=false(img.norm_arc);
%                     x(img.finger(f).left:img.finger(f).right) = true;
%                     plot(1.0*x, 'Color', 'Red', 'Parent', hAxes.axis7); hold on;
%                 end
%                 set(hAxes.axis7,'Color','Black');
                
                
                
%                 for f=1:img.f_n
%                     bar(f, img.finger(f).top.radius); hold on;  
%                 end
%                 hold off;
                
                
                                    
        % PLOTTING TIMER
        entry = sprintf('%10.5f',(1/toc(plotHz)));
        set(hText.plotHz, 'String', strcat('Plotting Rate.....',entry));                    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%
        % NEXT STATE %
        %%%%%%%%%%%%%%
        state = 1;                                                   
        
    elseif(state == 2)
        
        % Resize and Show Image            
        hand = imresize(snapshot(cam), img.resize);
        if(rot90_On)
            hand = rot90(hand,2);        
        end
        hand_g = rgb2gray(hand);        
        [img.h, img.w] = size(hand_g); % Height and Width of Image
                         
        % HISTOGRAMS
        hand_mask = false(img.h,img.w);    
        for hn = img.hist_n:-1:1
            position = []; 
            
            % Input Histogram ROI
            while(isempty(position))
                hRect = imrect(hAxes.axis1);
                position = wait(hRect);

                if(~isempty(position))
                    % Mark On Image
                    rectangle('Position',position,'EdgeColor','r','LineWidth',2); hold on;                                                            
                end
                delete(hRect);                                    
            end
            
            % Store Rectangle ROI in Container
            hist_crop = imcrop(hand, position);
            img.hist_i = hn;
            [ img ] = HistogramProfile( img, hist_crop ); 
            
            % Mask Image
            [ img, hand_mask_bw ] = MaskImage( img, hand );
            hand_mask = hand_mask | hand_mask_bw;  
                        
            % Plot Masked Image
            cla(hAxes.axis2,'reset');                        
            imshow(hand_mask, 'Parent', hAxes.axis2);  
            
            % Plot Collected Histogram
            cla(hAxes.axis6,'reset');
            plot(img.hist(img.hist_i).color(1).x,img.hist(img.hist_i).color(1).yHist, 'Red', ...
                img.hist(img.hist_i).color(2).x,img.hist(img.hist_i).color(2).yHist, 'Green', ...
                img.hist(img.hist_i).color(3).x,img.hist(img.hist_i).color(3).yHist, 'Blue', ...
                'Parent',hAxes.axis6);           
        end
        
   
        %%%%%%%%%%%%%%
        % NEXT STATE %
        %%%%%%%%%%%%%%
        state = 1;                                               
    end
end
    

    function [hFig, hAxes] = createFigureAndAxes()

        % Close figure opened by last run
        figTag = 'CVST_VideoOnAxis_9804532';
        close(findobj('tag',figTag));

        % Get Screensize
        screensize = get( groot, 'Screensize' );

        
        % Create new figure
        hFig = figure('numbertitle', 'off', ...
               'name', 'Video In Custom GUI', ...
               'menubar','none', ...
               'toolbar','none', ...
               'resize', 'on', ...
               'tag',figTag, ...
               'renderer','painters', ...
               'position',screensize + [10 45 -20 -75]);
                
        % Create axes and titles
        hAxes.axis1 = createPanelAxisTitle(hFig,[0.00 0.20 0.50 0.80],'Raw Image'); % [X Y W H]
        
        hAxes.axis2 = createPanelAxisTitle(hFig,[0.50 0.60 0.25 0.40],'Masked Image');
        hAxes.axis3 = createPanelAxisTitle(hFig,[0.75 0.60 0.25 0.40],'Polar Coordinate Conversion');
        hAxes.axis4 = createPanelAxisTitle(hFig,[0.50 0.20 0.25 0.40],'Blob Image');
        hAxes.axis5 = createPanelAxisTitle(hFig,[0.75 0.20 0.25 0.40],'Processed');
        
        hAxes.axis6 = createPanelAxisTitle(hFig,[0.00 0.05 0.50 0.15],'');
        hAxes.axis7 = createPanelAxisTitle(hFig,[0.50 0.05 0.50 0.15],'');

    end

    function hAxis = createPanelAxisTitle(hFig, pos, axisTitle)

        % Create panel
        hPanel = uipanel('parent',hFig,'Position',pos,'Units','Normalized');

        % Create axis
        hAxis = axes('position',[0 0 1 1],'Parent',hPanel);
        hAxis.XTick = [];
        hAxis.YTick = [];
        hAxis.XColor = [1 1 1];
        hAxis.YColor = [1 1 1];
        % Set video title using uicontrol. uicontrol is used so that text
        % can be positioned in the context of the figure, not the axis.
        if(~strcmp(axisTitle,''))        
            titlePos = [pos(1) pos(2) pos(3) 0.02];
            uicontrol('style','text',...
                'String', axisTitle,...
                'Units','Normalized',...
                'Parent',hFig,'Position', titlePos,...
                'BackgroundColor',hFig.Color);
        end
    end

    function [hText] = insertButtons(hFig,hAxes,cam)

        % BUTTONS
            % Capture Image for Histogram Analysis
            uicontrol(hFig,'unit','pixel','style','pushbutton','string','Capture',...
                    'position',[10 10 75 25], 'tag','pb1','callback', ...
                    {@captureCallback,cam,hAxes});
            % Exit Button
            uicontrol(hFig,'unit','pixel','style','pushbutton','string','Exit',...
                    'position',[100 10 50 25],'callback', ...
                    {@exitCallback,cam,hFig});
            
        % SLIDERS
            hText.HistWidth = uicontrol('Style','text',...
                'Position',[400 25 200 15],...
                'String','Histogram Acceptance');

            sld = uicontrol('Style', 'slider',...
                'Min',1,'Max',50,'Value',img.hist_width,...
                'SliderStep', [1/(50-1), 1/(50-1)],... 
                'Position', [400 5 200 20],...
                'Callback', @sliderCB1);  
        
        % DATA        
            % Overall Rate
            hText.totHz = uicontrol('Style','text',...
                'Position',[600 25 200 15],...
                'String','Overall Rate...0');        
            % Processing Rate           
            hText.procHz = uicontrol('Style','text',...
                'Position',[800 25 200 15],...
                'String','Processing Rate...0');          
            % Plotting Rate
            hText.plotHz = uicontrol('Style','text',...
                'Position',[800 5 200 15],...
                'String','Plotting Rate.....0');
            
            % Finger Positions      
            hText.fingers = uicontrol('Style','text',...
                'Position',[1000 25 200 15],...
                'String','1:0...2:0...3:0...4:0...5:0');               
    end

    function captureCallback(hObject,~,cam,hAxes)        
        state = 2; % Capture State        
    end

    function sliderCB1(hObject,~)        
        img.hist_width = uint8(hObject.Value);
    end

    function exitCallback(~,~,cam,hFig)
        % Close the webcam
        clear('cam');
        % Close the figure window
        close(hFig);
        % Close the bluetooth
        if(bluetooth_On)
            fclose(bt);
            clear('bt');
            instrreset;
        end
    end

end