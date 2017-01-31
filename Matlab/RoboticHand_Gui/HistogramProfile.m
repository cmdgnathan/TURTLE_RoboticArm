function [ img ] = HistogramProfile( img, roi )
% Isolate Specific Histogram Profile

    %Split into RGB Channels
    %Get histValues for each channel
    [img.color(3).yHist, img.color(3).x] = imhist(roi(:,:,3), img.hist_bins);
    [img.color(2).yHist, img.color(2).x] = imhist(roi(:,:,2), img.hist_bins);
    [img.color(1).yHist, img.color(1).x] = imhist(roi(:,:,1), img.hist_bins);            

    for c = 3:-1:1
        img.color(c).yHist_max = max(img.color(c).yHist(img.hist_pad:img.hist_step:end-img.hist_pad));
        thresh = img.hist_thresh*img.color(c).yHist_max;
        
%%%
% THRESHOLD
%         for i = img.hist_pad:img.hist_step:length(img.color(c).yHist)-img.hist_pad
%             if(img.color(c).yHist(i)>thresh)
%                 img.color(c).xHist_min = i;
%                 break;
%             end
%         end
% 
%         for i = length(img.color(c).yHist)-img.hist_pad:-img.hist_step:img.hist_pad
%             if(img.color(c).yHist(i)>thresh)
%                 img.color(c).xHist_max = i;
%                 break;
%             end
%         end

%%%
% AVERAGE
         img.color(c).xHist_avg = 0;
         img.color(c).xHist_n = 0;
         for i = img.hist_pad:img.hist_step:length(img.color(c).yHist)-img.hist_pad
             if(img.color(c).yHist(i)>thresh)
                 img.color(c).xHist_avg = img.color(c).xHist_avg + i;
                 img.color(c).xHist_n = img.color(c).xHist_n + 1;
             end
         end
         
        img.hist(img.hist_i).color(c).xHist_avg  = uint8(img.color(c).xHist_avg/img.color(c).xHist_n);
        img.hist(img.hist_i).color(c).xHist_min  = img.color(c).xHist_avg - 20;
        img.hist(img.hist_i).color(c).xHist_max  = img.color(c).xHist_avg + 20;


        
%%%
% MEDIAN
%         img.color(c).xHist_med = 0;
%         img.color(c).xHist_n = sum(img.color(c).yHist(2:end));
%         count = 0;
%         for i = 2:length(img.color(c).yHist)
%             count = count + img.color(c).yHist(i);
%             if(count > img.color(c).xHist_n/2)
%                 img.color(c).xHist_med = i;
%                 break;
%             end                
%         end
        
 %     % MAXIMUM
 %       [~,img.color(c).xHist_med] = max(img.color(c).yHist);
 %       
 %       img.color(c).xHist_min = max(1,                            img.color(c).xHist_med - img.hist_width);
 %       img.color(c).xHist_max = min(length(img.color(c).yHist)-1, img.color(c).xHist_med + img.hist_width);        
 %
 %
 %       img.hist(img.hist_i).color(c).xHist_med = img.color(c).xHist_med;
 %       img.hist(img.hist_i).color(c).xHist_min = img.color(c).xHist_min;
 %       img.hist(img.hist_i).color(c).xHist_max = img.color(c).xHist_max;
        
        
        % Transfer Histogram Contents
        img.hist(img.hist_i).color(c).yHist = img.color(c).yHist;
        img.hist(img.hist_i).color(c).x     = img.color(c).x;
    end


end

