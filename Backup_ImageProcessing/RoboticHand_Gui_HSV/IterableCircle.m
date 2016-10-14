function [ img ] = IterableCircle( img )
% Create a Linearly Iterable Circle (Angular Coordinates)

    arc_n = img.arc_n;
    height = img.h;
    width = img.w;

    % ITERABLE CIRCLE
    for i = arc_n:-1:1
        r = double(i)/arc_n*img.arc_max+img.arc_min;
        img.circle(i).radius = r;

        % LOOK UP TABLE FOR CIRCLE ARCS   
        img.circle(i).mask = CircleLUT( r, img.thick );

        % Count Iterable Elements
        img.circle(i).iter_n = 0;

        % Top Half of Circle
        for x = 1:int16(2*img.circle(i).radius)
            for y = 1:int16(img.circle(i).radius)        
                if(img.circle(i).mask(x,y)==1)
                    img.circle(i).iter_n = img.circle(i).iter_n + 1;
                end
            end
        end 

        % Bottom Half of Circle
        for x = int16(2*img.circle(i).radius):-1:1
            for y = int16(img.circle(i).radius)+1:2*int16(img.circle(i).radius)
                if(img.circle(i).mask(x,y)==1)
                    img.circle(i).iter_n = img.circle(i).iter_n + 1;
                end
            end
        end                 

         % Create Iterable Sequence 
        img.circle(i).iter_x = zeros(img.circle(i).iter_n, 1, 'uint16');
        img.circle(i).iter_y = zeros(img.circle(i).iter_n, 1, 'uint16'); 

        

        j = 1;

        % Top Half of Circle
        for x = 1:int16(2*img.circle(i).radius)
            for y = 1:int16(img.circle(i).radius)
                if(img.circle(i).mask(x,y)==1)
                    img.circle(i).iter_x(j) = y;
                    img.circle(i).iter_y(j) = x;
                    j = j + 1;
                end
            end
        end  

        % Bottom Half of Circle
        for x = int16(2*img.circle(i).radius):-1:1
            for y = int16(img.circle(i).radius)+1:2*int16(img.circle(i).radius)
                if(img.circle(i).mask(x,y)==1)
                    img.circle(i).iter_x(j) = y;
                    img.circle(i).iter_y(j) = x;
                    j = j + 1;
                end
            end
        end   



    end

%     % SHOW ITERABLE MASK
%     mask = false(2*img.circle(1).radius+1, 2*img.circle(1).radius+1);
%     for i = 1:img.circle(1).iter_n
% 
%         x = img.circle(1).iter_x(i);
%         y = img.circle(1).iter_y(i);
% 
%         mask(x,y) = 1;
% 
%     end
%     imshow(mask);

end

