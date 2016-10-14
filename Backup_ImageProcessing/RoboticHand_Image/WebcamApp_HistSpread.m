clear('cam');
clearvars;
close all;

% USER PARAMETERS
    symbol_width = 1;

    
    img.resize = 0.25;
    
    img.roi.x_n = 10; % Number of Horizontal Histogram Boxes
    img.roi.y_n = 1; % Number of Vertical Histogram Boxes
    
    img.hist_pad = 10; 
    img.hist_step = 1;
    
    img.avg_win = 20;               
    
    img.hist_bins = 256; % Number of Histogram Bins
    img.hist_thresh = 0.8; % Threshold Proportion of Maximum Value
    img.hist_width = 20; % 20 Intensity Value to Left and Right
    
    
    img_step = 10;

    
    img.hist_n = img.roi.x_n*img.roi.y_n; % Total Number of Different Histogram Samples
    img.hist_i = 1; % Histogram Iterator
    
    
% INITIAL (RUN ONCE)
    cam = webcam('WebCam');
    %preview(cam);

    % RESIZE IMAGE
    hand = imresize(snapshot(cam), img.resize);

    % CONVERT TO GREYSCALE
    hand_g = rgb2gray(hand);

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
    img.roi.x1 = round(img.w/2.0 - img.w/4.0);
    img.roi.y1 = round(img.h/2.0 - img.h/4.0);
    img.roi.x2 = round(img.w/2.0 + img.w/4.0);
    img.roi.y2 = round(img.h/2.0 + img.h/4.0);    
    
    img.x_cent = round(img.w/2.0);
    img.y_cent = round(img.h/2.0);
        
    for i = img.hist_n:-1:1
        img.hist(i).roi = img.roi;        
    end
    
    % PALM BLOB    
    palm_blob = true(size(hand_g));

    % BLOB BOUNDING BOX
    st = regionprops(palm_blob, 'BoundingBox');
    hand_rect = st.BoundingBox;
    
    % CROP EVERYTHING EXCEPT BOX AROUND HAND
    hand_crop = imcrop(hand,[hand_rect(1),hand_rect(2),hand_rect(3),hand_rect(4)]);
    
    [img.crop.h, img.crop.w, ~] = size(hand_crop);
    
    %closePreview(cam);
    
% LOOP
figure;
iter = 0;
while(1)    
    hand = imresize(snapshot(cam), img.resize);
    hand_g = rgb2gray(hand);
    hand_canny = edge(hand_g, 'Canny');

    % HISTOGRAM FOCUS
    disp('Histogram Profile Region');
    tic    
        % Calculate Centroid of Palm Blob
        [ img ] = Centroid( img, palm_blob );
    
        
        
        img.hist_i = 1;
        pad = 0;
        for i = pad:img.roi.x_n-1-pad
            for j = pad:img.roi.y_n-1-pad
                img.hist(img.hist_i).roi.rect = [ round( (i/img.roi.x_n)*img.crop.w + 1 ) ...
                                                  round( (j/img.roi.y_n)*img.crop.h + 1 ) ...
                                                  round( (1/img.roi.x_n)*img.crop.w - 1 ) ...
                                                  round( (1/img.roi.y_n)*img.crop.h - 1 ) ];                
                    
                                              
                
                img.hist_i = img.hist_i + 1;
            end
        end
        img.hist_n = img.hist_i - 1;
        
        
%     
%         img.roi.x1 = max( round(img.x_cent - img.crop.w/(2*img.roi.x_n)) , 1);
%         
%         img.roi.x2 = min( round(img.x_cent + img.crop.w/(2*img.roi.x_n)) , img.w);
% 
%         img.roi.y1 = max( round(img.y_cent - img.crop.h/(2*img.roi.y_n)) , 1);
% 
%         img.roi.y2 = min( round(img.y_cent + img.crop.h/(2*img.roi.y_n)) , img.h);
% 



%         img.hist_i = 1;
%         for i = [-2,0,2]
%             for j = [-2,0,2]
%                 img.hist(img.hist_i).roi.x1 = round(img.roi.x1 + i*img.crop.w/img.roi.x_n);
%                 img.hist(img.hist_i).roi.x2 = round(img.roi.x2 + i*img.crop.w/img.roi.x_n);
%                 img.hist(img.hist_i).roi.y1 = round(img.roi.y1 + j*img.crop.w/img.roi.y_n);
%                 img.hist(img.hist_i).roi.y2 = round(img.roi.y2 + j*img.crop.w/img.roi.y_n);
% 
%                 img.hist_i = img.hist_i + 1;
%             end
%         end
%         img.hist_n = img.hist_i - 1;
    toc

    % PROFILE HISTOGRAM IN REGION
    disp('Profile Histogram Regions');        
    tic
        for i=1:img.hist_n
            img.hist_i = i;
            %hand_roi = hand(img.roi.y1:img.roi.y2,img.roi.x1:img.roi.x2,:);
            %[ img ] = HistogramProfile( img, hand_roi );                    
            hist_crop = imcrop(hand_crop, img.hist(img.hist_i).roi.rect);
            [ img ] = HistogramProfile( img, hist_crop );                    
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
    
    % BLOB BOUNDING BOX
    st = regionprops(palm_blob, 'BoundingBox');
    hand_rect = st.BoundingBox;

    % CROP EVERYTHING EXCEPT BOX AROUND HAND
    hand_crop = imcrop(hand,[hand_rect(1),hand_rect(2),hand_rect(3),hand_rect(4)]);

    img.crop.rect = hand_rect;
    [img.crop.h, img.crop.w, ~] = size(hand_crop);
    
    
    
    
    % CALCULATE CENTROID (FOR RECENTERING HISTOGRAM)
    disp('Calculate Centroid');
    tic
        [ img ] = Centroid( img, palm_blob );
    toc
    
    
    % MARK IMAGE 
    disp('Mark Image');
    tic
        hand_marked = hand;
    
%         % Histogram Profile Region
%         for i = 1:img.hist_n        
%             hand_marked(img.hist(i).roi.y1:img.hist(i).roi.y2,uint16(img.hist(i).roi.x1-symbol_width):uint16(img.hist(i).roi.x1+symbol_width),:)=250;
%             hand_marked(img.hist(i).roi.y1:img.hist(i).roi.y2,uint16(img.hist(i).roi.x2-symbol_width):uint16(img.hist(i).roi.x2+symbol_width),:)=250;
%             hand_marked(uint16(img.hist(i).roi.y1-symbol_width):uint16(img.hist(i).roi.y1+symbol_width),img.hist(i).roi.x1:img.hist(i).roi.x2,:)=250;
%             hand_marked(uint16(img.hist(i).roi.y2-symbol_width):uint16(img.hist(i).roi.y2+symbol_width),img.hist(i).roi.x1:img.hist(i).roi.x2,:)=250;
%         end
    
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
        imshow(hand_marked); hold on;

        
        title(strcat('Raw Image with Markings...',int2str(iter)));

        subplot(2,3,2);
        imshow(hand_mask);
        title('Isolated Colors from Region of Interest'); 
        
        subplot(2,3,3);
        imshow(palm_blob); hold on;
        rectangle('Position',[hand_rect(1),hand_rect(2),hand_rect(3),hand_rect(4)], ...
            'EdgeColor','r','LineWidth',2 )
                        
        subplot(2,3,4);
        imshow(hand_crop);
        
        %subplot(2,3,5);
        %H = fspecial('laplacian');
        %dd = imfilter(x,H);
        %imshow(dd);

        subplot(2,3,6);
        imshow(palm_blob); hold on;
        for i=1:img.hist_n
            rectangle('Position',img.hist(i).roi.rect + [img.crop.rect(1) img.crop.rect(2) 0 0], ...
                'EdgeColor','r','LineWidth',2); hold on;
        end
        


         


        

    toc
    
    
    
    
    iter = iter + 1;
end
    
    
    
    
    