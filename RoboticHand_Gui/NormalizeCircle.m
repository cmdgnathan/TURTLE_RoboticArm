function [ img ] = NormalizeCircle( img )

    % Normalized Intersection Signal 
    img.intersection_norm_avg = zeros(img.norm_arc,1);
    for i=length(img.circle(:)):-1:1

        img.circle(i).iter_x_norm = zeros(img.norm_arc,1,'uint16');
        img.circle(i).iter_y_norm = zeros(img.norm_arc,1,'uint16');

        for j=1:img.norm_arc
            k = floor((j-1)*(img.circle(i).iter_n / img.norm_arc))+1;                
            img.circle(i).iter_x_norm(j) = img.circle(i).iter_x(k);
            img.circle(i).iter_y_norm(j) = img.circle(i).iter_y(k);                
        end                        
    end   

    
%     % SHOW ITERABLE MASK
%     mask = false(round(2*img.circle(1).radius+1), round(2*img.circle(1).radius+1));
%     for i = 1:img.norm_arc
% 
%         x = img.circle(5).iter_x_norm(i);
%         y = img.circle(5).iter_y_norm(i);
% 
%         mask(x,y) = 1;
% 
%     end
%     figure;
%     imshow(mask);    

        
end

