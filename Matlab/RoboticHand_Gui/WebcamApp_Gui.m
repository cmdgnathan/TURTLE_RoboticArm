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
img.hist_width = 40/img.hist_n; % 20 Intensity Value to Left and Right

img.hist_i = 1; % Histogram Iterator

% GUI
[hFig, hAxes] = createFigureAndAxes();
[hText] = insertButtons(hFig, hAxes, cam);


% INITIAL (RUN ONCE)

% IMAGE CAPTURE          
hand = imresize(snapshot(cam), img.resize); 
hand_g = rgb2gray(hand);        
[img.h, img.w] = size(hand_g); % Height and Width of Image

% ARC PARAMETERS
img.arc_n = 10; % Number of Arcs for Finger Detection  
img.arc_outer = img.arc_n; % Outer Ring of Arc
img.arc_min = img.h/16.0; % Minimum Arc Radius
img.arc_max = img.h/4.0; % Maximum Arc Radius

img.arc_crossing = zeros(img.arc_n,1);

img.thick = 1; % Arc Thickness
img.norm_arc = 100; % Number of Normalized Arc Samples    


% ITERABLE CIRCLE LUT SERIES
[ img ] = IterableCircle( img );

% NORMALIZE ITERABLE CIRCLE
[ img ] = NormalizeCircle( img );

% Main
state = 0;
frameRate = tic;
while(1)        
    
    % Update Text Boxes
    
        % Frame Rate
            Hz = sprintf('%10.5f',(1/toc(frameRate)));
            set(hText.Hz, 'String', strcat('Frame Rate...',Hz));    
            frameRate = tic;
            
            
            
            
    
            
    % STATE MACHINE
    if(state == 0)
        % Resize and Show Image
        hand = imresize(snapshot(cam), img.resize); 
        imshow(hand, 'Parent', hAxes.axis1);
        
    elseif(state == 1)
        
        % Resize Image
        hand = imresize(snapshot(cam), img.resize); 
        hand_g = rgb2gray(hand);        
        [img.h, img.w] = size(hand_g); % Height and Width of Image
                
        % MASK IMAGE (COLOR HISTOGRAM)
        hand_mask = false(img.h,img.w);    
        for i=1:img.hist_n
            img.hist_i = i;            
            [ img, hand_mask_bw ] = MaskImage( img, hand );
            hand_mask = hand_mask | hand_mask_bw;
        end   
     
%             [ img, hand_mask_bw ] = MaskImageAvg( img, hand );
%             hand_mask = hand_mask_bw;


        % FIND LARGEST BLOB (COLOR REGION)
        BW = hand_mask;
        CC = bwconncomp(BW);
        numPixels = cellfun(@numel,CC.PixelIdxList);
        [biggest,idx] = max(numPixels);
        BW(CC.PixelIdxList{idx}) = 0;
        palm_blob = hand_mask - BW;
        
        % MEDIAN FILTER
        palm_med = medfilt2(palm_blob,[3 3]);       
        
        
        % CALCULATE CENTROID
        %[ img ] = Centroid( img, palm_blob );
        [ img ] = Centroid( img, palm_med );

        
        % ITERABLE CIRCLES
        mask = false(2*img.circle(end).radius+1, 2*img.circle(end).radius+1);
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
        
        % BLOB BOUNDING BOX
        st = regionprops(palm_blob, 'BoundingBox');
        hand_rect = st.BoundingBox;
                                                               
        
        %%%%%%%%%%%%%%
        % GUI OUTPUT %
        %%%%%%%%%%%%%%
            % AXIS 1
                cla(hAxes.axis1,'reset');       
                imshow(hand, 'Parent', hAxes.axis1);   
                rectangle('Position',hand_rect,'EdgeColor','r','LineWidth',2, 'Parent', hAxes.axis1);         
            % AXIS 2
%                 cla(hAxes.axis2,'reset');       
%                 imshow(palm_blob, 'Parent', hAxes.axis2);
            % AXIS 3
                cla(hAxes.axis3,'reset');       
                imshow(mask, 'Parent', hAxes.axis3);     
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
                plot(img.intersect, 'Color', 'Red', 'Parent', hAxes.axis6);
                set(hAxes.axis6,'Color','Black');
            % AXIS 7
                cla(hAxes.axis7,'reset');               
                plot(img.arc_crossing, 'Color', 'Red', 'Parent', hAxes.axis7);
                set(hAxes.axis7,'Color','Black');

        %%%%%%%%%%%%%%
        % NEXT STATE %
        %%%%%%%%%%%%%%
        state = 1;                                                   
        
    elseif(state == 2)
        
        % Resize and Show Image            
        hand = imresize(snapshot(cam), img.resize); 
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
               %'position',[680 678 480 240]);
                
        % Create axes and titles
        hAxes.axis1 = createPanelAxisTitle(hFig,[0.00 0.20 0.50 0.80],'Raw Image'); % [X Y W H]
        hAxes.axis2 = createPanelAxisTitle(hFig,[0.50 0.60 0.25 0.40],'Processed');
        hAxes.axis3 = createPanelAxisTitle(hFig,[0.75 0.60 0.25 0.40],'Processed');
        hAxes.axis4 = createPanelAxisTitle(hFig,[0.50 0.20 0.25 0.40],'Processed');
        hAxes.axis5 = createPanelAxisTitle(hFig,[0.75 0.20 0.25 0.40],'Processed');

        
        hAxes.axis6 = createPanelAxisTitle(hFig,[0.00 0.05 0.50 0.15],'Processed');
        hAxes.axis7 = createPanelAxisTitle(hFig,[0.50 0.05 0.50 0.15],'Processed');

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

    function [hText] = insertButtons(hFig,hAxes,cam)

        % Capture Image for Histogram Analysis
        uicontrol(hFig,'unit','pixel','style','pushbutton','string','Capture',...
                'position',[10 10 75 25], 'tag','pb1','callback', ...
                {@captureCallback,cam,hAxes});

        % Exit Button
        uicontrol(hFig,'unit','pixel','style','pushbutton','string','Exit',...
                'position',[100 10 50 25],'callback', ...
                {@exitCallback,cam,hFig});
            
        % Threshold Width Slider
        txt = uicontrol('Style','text',...
            'Position',[400 25 120 15],...
            'String','Histogram Acceptance');
        
        sld = uicontrol('Style', 'slider',...
            'Min',1,'Max',50,'Value',img.hist_width,...
            'Position', [400 5 120 20],...
            'Callback', @sliderCB1);  
        
        % TEXTBOX
        
        % Frame Rate
        hText.Hz = uicontrol('Style','text',...
            'Position',[600 25 200 15],...
            'String','Frame Rate: 0');        
        
        hText.PlotT = uicontrol('Style','text',...
            'Position',[600 5 200 15],...
            'String','Frame Rate: 0');          
            
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