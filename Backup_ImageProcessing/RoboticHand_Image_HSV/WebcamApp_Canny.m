clear('cam');
clearvars;
close all;

% USER PARAMETERS
    symbol_width = 1;

    
    img.resize = 0.25;
    
    img.roi.x_w = 32.0; % Width of Histogram Box
    img.roi.y_h = 32.0; % Height of Histogram Box
    
    img.hist_pad = 10; 
    img.hist_step = 1;
    
    img.avg_win = 20;               
    
    img.hist_bins = 256; % Number of Histogram Bins
    img.hist_thresh = 0.8; % Threshold Proportion of Maximum Value
    img.hist_width = 30; % 20 Intensity Value to Left and Right
    
    
    img_step = 10;

    
    img.hist_n = 4; % Total Number of Different Histogram Samples
    img.hist_i = 1; % Histogram Iterator
    
    
% INITIAL (RUN ONCE)
    cam = webcam('WebCam');
    %preview(cam);

    % RESIZE IMAGE
    hand = imresize(snapshot(cam), img.resize);

    % CONVERT TO HSV
    hand_hsv = rgb2hsv(hand);
    
    % CONVERT TO GREYSCALE
    hand_g = rgb2gray(hand);
    hand_g_prev = hand_g;

    % SIZE PARAMETERS
    [img.h, img.w] = size(hand_g); % Height and Width of Image
    
    % ARC PARAMETERS
    img.arc_n = 8; % Number of Arcs for Finger Detection  
    img.arc_min = img.h/16.0; % Minimum Arc Radius
    img.arc_max = img.h/4.0; % Maximum Arc Radius
    
    img.thick = 2; % Arc Thickness
    img.norm_arc = 100; % Number of Normalized Arc Samples    
    
    
    % ITERABLE CIRCLE LUT SERIES
    disp('Instantiate Circle LUT');
    tic
    [ img ] = IterableCircle( img );
    toc
    
    
    
    % INITIAL CONDITIONS
    img.roi.x1 = round(img.w/2.0 - img.w/img.roi.x_w);
    img.roi.y1 = round(img.h/2.0 - img.h/img.roi.y_h);
    img.roi.x2 = round(img.w/2.0 + img.w/img.roi.x_w);
    img.roi.y2 = round(img.h/2.0 + img.h/img.roi.y_h);    
    
    img.x_cent = round(img.w/2.0);
    img.y_cent = round(img.h/2.0);
        
    for i = img.hist_n:-1:1
        img.hist(i).roi = img.roi;        
    end
    
    % PALM BLOB
    
    palm_blob = true(size(hand_g));

    dilate_palm_blob = palm_blob;
    
    %closePreview(cam);
    
% LOOP
figure;
iter = 0;
while(1)    
    hand = imresize(snapshot(cam), img.resize);
    hand_hsv = rgb2hsv(hand);
    hand_g = rgb2gray(hand);    
    hand_canny = edge(hand_g, 'Canny');

    % HISTOGRAM FOCUS
    disp('Histogram Profile Region');
    tic    
        % Calculate Centroid of Palm Blob
        [ img ] = Centroid( img, palm_blob );
        


     
    
        cond = ((img.x_cent - img.w/img.roi.x_w) > 0);
        img.roi.x1 = uint16(double(img.x_cent - img.w/img.roi.x_w)*(cond) + 1*(~cond));

        cond = (img.x_cent + img.w/img.roi.x_w) < img.w;
        img.roi.x2 = uint16(double(img.x_cent + img.w/img.roi.x_w)*(cond) + img.w*(~cond));        

        cond = (img.y_cent - img.h/img.roi.y_h) > 0;
        img.roi.y1 = uint16(double(img.y_cent - img.h/img.roi.y_h)*(cond) + 1*(~cond));

        cond = (img.y_cent + img.h/img.roi.y_h) < img.h;
        img.roi.y2 = uint16(double(img.y_cent + img.h/img.roi.y_h)*(cond) + img.h*(~cond));        




        img.hist_i = 1;
        for i = [-1,1]
            for j = [-1,1]
                img.hist(img.hist_i).roi.x1 = round(img.roi.x1 + i*img.w/img.roi.x_w);
                img.hist(img.hist_i).roi.x2 = round(img.roi.x2 + i*img.w/img.roi.x_w);
                img.hist(img.hist_i).roi.y1 = round(img.roi.y1 + j*img.w/img.roi.y_h);
                img.hist(img.hist_i).roi.y2 = round(img.roi.y2 + j*img.w/img.roi.y_h);

                img.hist_i = img.hist_i + 1;
            end
        end
    toc

    % PROFILE HISTOGRAM IN REGION
    disp('Profile Histogram Regions');        
    tic
        for i=1:img.hist_n
            img.hist_i = i;
            hand_roi = hand(img.roi.y1:img.roi.y2,img.roi.x1:img.roi.x2,:);
            [ img ] = HistogramProfile( img, hand_roi );                    
        end
    toc
    
    % MASK ORIGINAL IMAGE
    disp('Mask Original Image');
    tic
        hand_mask = false(img.h,img.w);    
        for i=1:img.hist_n
            img.hist_i = i;            
            [ img, hand_mask_bw ] = MaskImage( img, hand );
            hand_mask = hand_mask | hand_mask_bw;
        end
    toc
    
    % FIND LARGEST BLOB (COLOR REGION)
    BW = hand_mask;
    CC = bwconncomp(BW);
    numPixels = cellfun(@numel,CC.PixelIdxList);
    [biggest,idx] = max(numPixels);
    BW(CC.PixelIdxList{idx}) = 0;
    palm_blob = hand_mask - BW;    
    
    % DILATE PALM BLOB
    se = strel('disk',5);
    dilate_palm_blob = imdilate(palm_blob,se);    
    
    % FIND LARGEST INTERSECTING CONTOUR (CANNY)
    imshow(dilate_palm_blob); hold on;
[B,L,N] = bwboundaries(hand_canny);
for k=1:length(B),
   boundary = B{k};
   if(k > N)
     plot(boundary(:,2), boundary(:,1), 'g','LineWidth',2);
   else
     pp = false;
     for m=1:length(boundary(:,1));
         if( dilate_palm_blob(boundary(m,1),boundary(m,2)) ) 
             pp = true;
             break;
         end
     end
     
     if(pp)
        plot(boundary(:,2), boundary(:,1), 'r','LineWidth',2);
     end
   end
end     
    
    %hand_contour = bwboundaries(palm_blob);
    
    
    
    % CALCULATE CENTROID (FOR RECENTERING HISTOGRAM)
    disp('Calculate Centroid');
    tic
        [ img ] = Centroid( img, palm_blob );
    toc
    
    
    % MARK IMAGE 
    disp('Mark Image');
    tic
        hand_marked = hand;
    
        % Histogram Profile Region
        for i = 1:img.hist_n        
            hand_marked(img.hist(i).roi.y1:img.hist(i).roi.y2,uint16(img.hist(i).roi.x1-symbol_width):uint16(img.hist(i).roi.x1+symbol_width),:)=250;
            hand_marked(img.hist(i).roi.y1:img.hist(i).roi.y2,uint16(img.hist(i).roi.x2-symbol_width):uint16(img.hist(i).roi.x2+symbol_width),:)=250;
            hand_marked(uint16(img.hist(i).roi.y1-symbol_width):uint16(img.hist(i).roi.y1+symbol_width),img.hist(i).roi.x1:img.hist(i).roi.x2,:)=250;
            hand_marked(uint16(img.hist(i).roi.y2-symbol_width):uint16(img.hist(i).roi.y2+symbol_width),img.hist(i).roi.x1:img.hist(i).roi.x2,:)=250;
        end
    
        % Centroid
        x1 = -symbol_width+img.x_cent;
        x2 = symbol_width+img.x_cent;
        y1 = -symbol_width+img.y_cent;
        y2 = symbol_width+img.y_cent;

        if(x1 >= 1 && x2 <= img.w && y1 >= 1 && y2 <= img.h)
            hand_marked( x1:x2, y1:y2, : ) = 250;
        end  
    toc
    
    

    
    
    
    
    

    % PLOT
    disp('Plotting');
    tic
        subplot(2,3,1);    
        imshow(hand_marked); 
        title(strcat('Raw Image with Markings...',int2str(iter)));
%         imshow(hand_roi); 
%         title('Color Histogram Region of Interest');


        subplot(2,3,2);
        imshow(hand_mask);
        title('Isolated Colors from Region of Interest');        

        subplot(2,3,3);
        imshow(hand_canny); hold on;
        
        
        subplot(2,3,4);
        imshow(hand_g);
        
        
        
        subplot(2,3,5);
        imshow(hand_g - hand_g_prev);
    
        hand_g_prev = hand_g;


        subplot(2,3,6);
         


        

    toc
    
    
    
    
    iter = iter + 1;
end
    
    
    
    
    