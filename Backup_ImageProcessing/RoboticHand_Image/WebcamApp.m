clear('cam');
clearvars;
close all;

% USER PARAMETERS
    symbol_width = 1;

    
    img.resize = 0.25;
    
    img.roi.x_w = 32.0;
    img.roi.y_h = 32.0;
    
    img.hist_pad = 10;
    img.hist_step = 1;
    
    img.avg_win = 20;               
    
    img.hist_bins = 256; % Number of Histogram Bins
    img.hist_thresh = 0.8; % Threshold Proportion of Maximum Value
    
    img_step = 10;

    img.first_hist = 1;
    img.first_cent = 1;
    img.first_roi = 1;
    
    img.hist_n = 4; % Total Number of Different Histogram Samples
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
    %closePreview(cam);
    
% LOOP
figure;
iter = 0;
while(1)    
    hand = imresize(snapshot(cam), img.resize);
    hand_g = rgb2gray(hand);

    % HISTOGRAM FOCUS
    disp('Histogram Profile Region');
    tic
        if(img.first_roi)
            img.roi.x1 = uint16(img.w/2.0 - img.w/img.roi.x_w);
            img.roi.y1 = uint16(img.h/2.0 - img.h/img.roi.y_h);
            img.roi.x2 = uint16(img.w/2.0 + img.w/img.roi.x_w);
            img.roi.y2 = uint16(img.h/2.0 + img.h/img.roi.y_h);

            img.first_roi = 0;        
        else
            cond = ((img.x_cent - img.w/img.roi.x_w) > 0);
            img.roi.x1 = uint16(double(img.x_cent - img.w/img.roi.x_w)*(cond) + 1*(~cond));

            cond = (img.x_cent + img.w/img.roi.x_w) < img.w;
            img.roi.x2 = uint16(double(img.x_cent + img.w/img.roi.x_w)*(cond) + img.w*(~cond));        

            cond = (img.y_cent - img.h/img.roi.y_h) > 0;
            img.roi.y1 = uint16(double(img.y_cent - img.h/img.roi.y_h)*(cond) + 1*(~cond));

            cond = (img.y_cent + img.h/img.roi.y_h) < img.h;
            img.roi.y2 = uint16(double(img.y_cent + img.h/img.roi.y_h)*(cond) + img.h*(~cond));        
        end


        for i = img.hist_n:-1:1
            img.hist(i).roi = img.roi;        
        end

        img.hist_i = 1;
        for i = [-1,1]
            for j = [-1,1]
                img.hist(img.hist_i).roi.x1 = img.roi.x1 + i*img.w/img.roi.x_w;
                img.hist(img.hist_i).roi.x2 = img.roi.x2 + i*img.w/img.roi.x_w;
                img.hist(img.hist_i).roi.y1 = img.roi.y1 + j*img.w/img.roi.y_h;
                img.hist(img.hist_i).roi.y2 = img.roi.y2 + j*img.w/img.roi.y_h;

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
        hand_mask = true(img.h,img.w);    
        for i=1:img.hist_n
            img.hist_i = i;            
            [ img, hand_mask_bw ] = MaskImage( img, hand );
            hand_mask = hand_mask & hand_mask_bw;
        end
    toc
    
    % CALCULATE CENTROID
    disp('Calculate Centroid');
    tic
        [ img ] = Centroid( img, hand_mask );
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
    
    

    
    
    
    
    


    % Iterable Circles on Marked Hand
    disp('Iterable Circles on Marked Hand');
    tic
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
    toc
    
    % Normalized Intersection Signal 
    img.intersection_norm_avg = zeros(img.norm_arc,1);
    for i=1:length(img.circle(:))
        temp = resample(img.circle(i).intersection, img.norm_arc, img.circle(i).iter_n);
        img.circle(i).intersection_norm = temp(1:img.norm_arc);
        img.intersection_norm_avg = img.intersection_norm_avg + img.circle(i).intersection_norm;
        
    end   
    
    % Average Across Normalized
    
    
%     % AVERAGE ARCS
%     img.circle(end).intersection_avg = zeros(img.circle(i).iter_n, 1);        
%     for i=1:length(img.circle(:))
%         for j=img.avg_win/2+1:img.circle(i).iter_n-img.avg_win/2
%             img.circle(i).intersection_avg(j) = ...
%                 mean(img.circle(i).intersection((j-img.avg_win/2):(j+img.avg_win/2)));                        
%         end
%     end
%     
%     % DIFFERENTIAL ARCS
%     img.circle(end).intersection_diff = zeros(img.circle(i).iter_n, 1);    
%     for i=1:length(img.circle(:))
%         for j=2:img.circle(i).iter_n
%             img.circle(i).intersection_diff(j) = ...
%                 img.circle(i).intersection(j) - img.circle(i).intersection(j-1);
%         end
%     end   

    % PLOT
    disp('Plotting');
    tic
        subplot(2,4,1);    
        imshow(hand_marked); 
        title(strcat('Raw Image with Markings...',int2str(iter)));
%         imshow(hand_roi); 
%         title('Color Histogram Region of Interest');

        subplot(2,4,2);
        imshow(hand_mask);
        title('Isolated Colors from Region of Interest');        
%        plot(img.color(1).x, img.color(1).yHist, 'Red'); hold on;
%        plot(img.color(2).x, img.color(2).yHist, 'Green'); hold on; 
%        plot(img.color(3).x, img.color(3).yHist, 'Blue'); 
                        

        subplot(2,4,3);
        imshow(mask);
        title('Arc Crossings');
        
        for i=1:4
            subplot(2,4,i+4);
            plot(1:100, img.circle(2*i).intersection_norm, ...
                1:100, img.circle(2*i-1).intersection_norm)
            title('Angular Plot of Arc Intersections');
        end

%         subplot(2,4,6);
%         plot(img.intersection_norm_avg);
%         %plot(img.circle(2).intersection_avg);
%         title('Angular Plot of Arc Intersections');




        

    toc
    
    
    
    
    iter = iter + 1;
end
    
    
    
    
    