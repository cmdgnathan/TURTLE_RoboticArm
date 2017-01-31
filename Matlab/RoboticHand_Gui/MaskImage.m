function [ img, mask ] = MaskImage( img, I )
% CENTROID CALCULATION
          
    mask = true(img.h,img.w);
    for c = 1:3
                
        img.hist(img.hist_i).color(c).xHist_min = ...
            img.hist(img.hist_i).color(c).xHist_avg - img.hist_width;

        img.hist(img.hist_i).color(c).xHist_max = ...
            img.hist(img.hist_i).color(c).xHist_avg + img.hist_width;
        
        
        mask = mask & ...
            (I(:,:,c) > img.hist(img.hist_i).color(c).xHist_min) & ...
            (I(:,:,c) < img.hist(img.hist_i).color(c).xHist_max);        
    end    

end

