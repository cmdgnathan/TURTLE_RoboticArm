function [ img, mask ] = MaskImageAvg( img, I )
% CENTROID CALCULATION
          
    mask = true(img.h,img.w);
    for c = 1:3

        mask = mask & ...
            (I(:,:,c) > img.color(c).x_avg_min) & ...
            (I(:,:,c) < img.color(c).x_avg_max);        
    end    

end

