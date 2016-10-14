function WebcamApp_Gui()

clear('cam');
clearvars;
close all;

% Create Webcam Object
cam = webcam('WebCam');

% Parameters
img.resize = 0.25; % Image Resize Factor
img.hist_n = 5;    % Number of Histogram Regions

img.hist_pad = 10; 
img.hist_step = 1;

img.hist_bins = 256; % Number of Histogram Bins
img.hist_thresh = 0.8; % Threshold Proportion of Maximum Value
img.hist_width = 10; % 20 Intensity Value to Left and Right

img.hist_i = 1; % Histogram Iterator

% GUI
[hFig, hAxes] = createFigureAndAxes();
insertButtons(hFig, hAxes, cam);


% INITIAL (RUN ONCE)

% IMAGE CAPTURE          
hand = imresize(snapshot(cam), img.resize); 
hand_hsv = rgb2hsv(hand);
hand_g = rgb2gray(hand);        
[img.h, img.w] = size(hand_g); % Height and Width of Image

% ARC PARAMETERS
img.arc_n = 8; % Number of Arcs for Finger Detection  
img.arc_min = img.h/16.0; % Minimum Arc Radius
img.arc_max = img.h/4.0; % Maximum Arc Radius

img.thick = 2; % Arc Thickness
img.norm_arc = 100; % Number of Normalized Arc Samples    


% ITERABLE CIRCLE LUT SERIES
[ img ] = IterableCircle( img );



% Main
state = 0;
while(1)
    if(state == 0)
        % Resize and Show Image
        hand = imresize(snapshot(cam), img.resize); 
        hand_hsv = rgb2hsv(hand);
        hand_h = uint8(floor(255*hand_hsv(:,:,1)));
        imshow(hand_h, 'Parent', hAxes.axis1);
        
        
    elseif(state == 1)
        
        % Resize and Show Image
        hand = imresize(snapshot(cam), img.resize); 
        hand_hsv = rgb2hsv(hand);
        hand_g = rgb2gray(hand);        
        [img.h, img.w] = size(hand_g); % Height and Width of Image
        
        imshow(hand, 'Parent', hAxes.axis1);    
        
        % MASK IMAGE (COLOR HISTOGRAM)
        hand_mask = false(img.h,img.w);    
        for i=1:img.hist_n
            img.hist_i = i;            
            [ img, hand_mask_bw ] = MaskImage( img, hand );
            hand_mask = hand_mask | hand_mask_bw;
        end   
        
        % FIND LARGEST BLOB (COLOR REGION)
        BW = hand_mask;
        CC = bwconncomp(BW);
        numPixels = cellfun(@numel,CC.PixelIdxList);
        [biggest,idx] = max(numPixels);
        BW(CC.PixelIdxList{idx}) = 0;
        palm_blob = hand_mask - BW;
        
        % CALCULATE CENTROID
        [ img ] = Centroid( img, palm_blob );

        % ITERABLE CIRCLES
        mask = false(2*img.circle(end).radius+1, 2*img.circle(end).radius+1);
        for i=1:length(img.circle(:))
            img.circle(i).intersection = zeros(img.circle(i).iter_n, 1);            
            for j=1:img.circle(i).iter_n

                x = img.x_cent - img.circle(i).radius + uint16(img.circle(i).iter_x(j));
                y = img.y_cent - img.circle(i).radius + uint16(img.circle(i).iter_y(j));

                if(x>0 && x<=img.h && y>0 && y<=img.w)
                    %hand_marked(x,y,:) = 256;

                    % Angular Plot as Line
                    img.circle(i).intersection(j) = hand_mask(x,y);

                    % Radar Plot
                    if(hand_mask(x,y))
                        x = img.circle(end).radius - img.circle(i).radius + img.circle(i).iter_x(j);
                        y = img.circle(end).radius - img.circle(i).radius + img.circle(i).iter_y(j);
                        mask(x,y) = 1;                    
                    end
                end
            end
        end    

        % Normalized Intersection Signal 
        img.intersection_norm_avg = zeros(img.norm_arc,1);
        for i=1:length(img.circle(:))
            temp = resample(img.circle(i).intersection, img.norm_arc, img.circle(i).iter_n);
            img.circle(i).intersection_norm = temp(1:img.norm_arc);
            img.intersection_norm_avg = img.intersection_norm_avg + img.circle(i).intersection_norm;

        end           
        
        
        
        
        % BLOB BOUNDING BOX
        st = regionprops(palm_blob, 'BoundingBox');
        hand_rect = st.BoundingBox;
        
        
        
            

        
        
        % FIND LARGEST INTERSECTING CONTOUR (CANNY)
%         [B,L,N] = bwboundaries(palm_blob);
%         for k=1:length(B),
%            boundary = B{k};
%            if(k > N)
%              plot(hAxes.axis2, boundary(:,2), boundary(:,1), 'g','LineWidth',2);
%            else
%              plot(hAxes.axis2, boundary(:,2), boundary(:,1), 'r','LineWidth',2);
%            end
%         end             
        

        % GUI OUTPUT

        imshow(hand, 'Parent', hAxes.axis1);   


        axes(hAxes.axis1);
        rectangle('Position',hand_rect,'EdgeColor','r','LineWidth',2);         

        imshow(palm_blob, 'Parent', hAxes.axis2);
        
        
        imshow(mask, 'Parent', hAxes.axis3);    
        
        axes(hAxes.axis6);
        plot(1:100, img.circle(3).intersection_norm);

        axes(hAxes.axis7);
        plot(1:100, img.circle(6).intersection_norm);
                
        
                                                           

        
    elseif(state == 2)
        
        % Resize and Show Image            
        hand = imresize(snapshot(cam), img.resize); 
        hand_g = rgb2gray(hand);        
        [img.h, img.w] = size(hand_g); % Height and Width of Image
        
                 
        % Get Rectangular Regions
        hand_mask = false(img.h,img.w);    
        for xxx = 1:1%hn = img.hist_n:-1:1
            position = [];            
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
            
            [ img, hand_mask_bw ] = MaskImage( img, hand );
            hand_mask = hand_mask | hand_mask_bw;  
            
            cla(hAxes.axis2,'reset');            
            imshow(hand_mask, 'Parent', hAxes.axis2);   
            
        end
        
        cla(hAxes.axis1,'reset');
        cla(hAxes.axis2,'reset');
        
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
               %'position',[680 678 480 240]);
                
        % Create axes and titles
        hAxes.axis1 = createPanelAxisTitle(hFig,[0.00 0.20 0.50 0.80],'Raw Image'); % [X Y W H]
        hAxes.axis2 = createPanelAxisTitle(hFig,[0.50 0.60 0.25 0.40],'Processed');
        hAxes.axis3 = createPanelAxisTitle(hFig,[0.75 0.60 0.25 0.40],'Processed');
        hAxes.axis4 = createPanelAxisTitle(hFig,[0.50 0.20 0.25 0.40],'Processed');
        hAxes.axis5 = createPanelAxisTitle(hFig,[0.75 0.20 0.25 0.40],'Processed');

        
        hAxes.axis6 = createPanelAxisTitle(hFig,[0.00 0.05 0.50 0.20],'Processed');
        hAxes.axis7 = createPanelAxisTitle(hFig,[0.50 0.05 0.50 0.20],'Processed');

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
%         titlePos = [pos(1)+0.02 pos(2)+pos(3)+0.3 0.3 0.07];
%         uicontrol('style','text',...
%             'String', axisTitle,...
%             'Units','Normalized',...
%             'Parent',hFig,'Position', titlePos,...
%             'BackgroundColor',hFig.Color);
    end

    function insertButtons(hFig,hAxes,cam)

        % Capture Image for Histogram Analysis
        uicontrol(hFig,'unit','pixel','style','pushbutton','string','Capture',...
                'position',[10 10 75 25], 'tag','pb1','callback', ...
                {@captureCallback,cam,hAxes});

        % Exit button with text Exit
        uicontrol(hFig,'unit','pixel','style','pushbutton','string','Exit',...
                'position',[100 10 50 25],'callback', ...
                {@exitCallback,cam,hFig});
            
        % Threshold Width Slider
        sld = uicontrol('Style', 'slider',...
            'Min',1,'Max',50,'Value',10,...
            'Position', [400 20 120 20],...
            'Callback', @sliderCB1);         
            
    end

    function captureCallback(hObject,~,cam,hAxes)
        
        state = 2; % Capture State
        
    end

    function sliderCB1(hObject,~)
        
        img.hist_width = hObject.Value;        
    end


    function exitCallback(~,~,cam,hFig)

        % Close the webcam
        clear('cam');
        % Close the figure window
        close(hFig);
    end

end