clearvars;
close all;

% USER PARAMETERS
hist_pad = 10;
hist_step = 10;
img_step = 10;

% LOAD IMAGE
Image = imread('hand.jpg');
%Image = imread('hand_races.jpg');

% RESIZE IMAGE
hand = imresize(Image, 1.0);

% CONVERT TO GREYSCALE
hand_g = rgb2gray(hand);

% SIZE PARAMETERS
[img.h, img.w] = size(hand_g); % Height and Width of Image
img.arc_n = 8;                 % Number of Arcs for Finger Detection


%%
% ITERABLE CIRCLE LUT SERIES
[ img ] = IterableCircle( img );


%%

        
        
        
% REGION OF INTEREST
x1 = 700;
y1 = 1200;
x2 = 1200;
y2 = 1700;
% x1 = 180;
% y1 = 170;
% x2 = 230;
% y2 = 220;

hand_marked = hand;
hand_marked(y1:y2,(-10:10)+x1,:)=250;
hand_marked(y1:y2,(-10:10)+x2,:)=250;
hand_marked((-10:10)+y1,x1:x2,:)=250;
hand_marked((-10:10)+y2,x1:x2,:)=250;









% SUB IMAGE
hand_sub = hand(y1:y2,x1:x2,:);
hand_g_sub = hand_g(y1:y2,x1:x2);



% MAIN IMAGE
    %Split into RGB Channels
    %Get histValues for each channel
    [yRed, x] = imhist(hand(:,:,1));
    [yGreen, x] = imhist(hand(:,:,2));
    [yBlue, x] = imhist(hand(:,:,3));
    [yGrey, x] = imhist(hand_g);
    
    %Split into RGB Channels
    %Get histValues for each channel
    [img.color(3).yHist, x] = imhist(hand_sub(:,:,3));
    [img.color(2).yHist, x] = imhist(hand_sub(:,:,2));
    [img.color(1).yHist, x] = imhist(hand_sub(:,:,1));
    
    
    [yGrey_sub, x] = imhist(hand_g_sub);    
    
    %Plot them together in one plot
    figure;
    subplot(2,4,1);
    imshow(hand_marked);
    subplot(2,4,5);
    plot(x/256, yRed, 'Red'); hold on;
    plot(x/256, yGreen, 'Green'); hold on;
    plot(x/256, yBlue, 'Blue'); 
    
    subplot(2,4,2);
    imshow(hand_g);
    subplot(2,4,6);
    plot(x/256, yGrey, 'Black');
    
    subplot(2,4,3);
    imshow(hand_sub);
    subplot(2,4,7);
    plot(x/256, img.color(1).yHist, 'Red'); hold on;
    plot(x/256, img.color(2).yHist, 'Green'); hold on;
    plot(x/256, img.color(3).yHist, 'Blue'); hold on;
    
    
    subplot(2,4,4);
    imshow(hand_g_sub);
    subplot(2,4,8);
    plot(x/256, yGrey_sub, 'Black');
   
%%    
    
    
for c = 1:3
    img.color(c).yHist_max = max(img.color(c).yHist(hist_pad:hist_step:end-hist_pad));
    thresh = 0.3*img.color(c).yHist_max;
    for i = hist_pad:hist_step:length(img.color(c).yHist)-hist_pad
        if(img.color(c).yHist(i)>thresh)
            img.color(c).xHist_min = i;
            break;
        end
    end
    
    for i = length(img.color(c).yHist)-hist_pad:-hist_step:hist_pad
        if(img.color(c).yHist(i)>thresh)
            img.color(c).xHist_max = i;
            break;
        end
    end
end
    
    
hand_g1 = zeros(img.h, img.w, 'uint8');
  
I = hand;

%%
% CENTROID CALCULATION
n_cent = 0;
x_cent = 0;
y_cent = 0;

for i=1:img.h
    for j=1:img.w
        if(I(i,j,1)>=img.color(1).xHist_min && I(i,j,1)<=img.color(1).xHist_max && ...
                I(i,j,2)>=img.color(2).xHist_min && I(i,j,2)<=img.color(2).xHist_max && ...
                I(i,j,3)>=img.color(3).xHist_min && I(i,j,3)<=img.color(3).xHist_max)

            hand_g1(i,j) = hand_g(i,j);
                        
            n_cent = n_cent + 1;
            x_cent = x_cent + (i);
            y_cent = y_cent + (j);
        end
    end
end

x_cent = uint16(1.0 * x_cent / n_cent);
y_cent = uint16(1.0 * y_cent / n_cent);

hand_marked((-50+x_cent:50+x_cent),(-50+y_cent:50+y_cent),:) = 250;
imshow(hand_marked);


%%
% Iterable Circles on Marked Hand
mask = false(2*img.circle(end).radius+1, 2*img.circle(1).radius+1);
for i=1:length(img.circle(:))
    for j=1:img.circle(i).iter_n
        
        x = x_cent - img.circle(i).radius + uint16(img.circle(i).iter_x(j));
        y = y_cent - img.circle(i).radius + uint16(img.circle(i).iter_y(j));
        
        if(x>0 && x<=img.w && y>0 && y<=img.h)
            hand_marked(x-10:x+10,y-10:y+10,:) = 250;
            img.circle(i).intersection(j) = hand_g1(x,y);
        end
        mask(img.circle(i).iter_x(j),img.circle(i).iter_y(j)) = 1;
    end
end
 

% Plots 
figure;
subplot(1,2,1);
imshow(hand_marked);
subplot(1,2,2);
imshow(hand_g1);
%subplot(4,1,3);
%imshow(mask);
%subplot(4,1,4);
%plot(img.circle(1).intersection);

figure;
j=1;
for i=length(img.circle(:)):-1:1
    subplot(length(img.circle(:)),1,j);
    plot(img.circle(i).intersection);
    j=j+1;
end


