function [ img ] = Centroid( img, I )
% CENTROID CALCULATION
    
    if(1)
        lower_i = 1;
        upper_i = img.h;
        lower_j = 1;
        upper_j = img.w;
        
        %img.first_cent = 0;
        
    else
        r = (img.circle(end).radius);        
        
        lower_i = int16(img.x_cent-r);
        upper_i = int16(img.x_cent+r);
        lower_j = int16(img.y_cent-r);
        upper_j = int16(img.y_cent+r);
    end
    
  
    

    img.n_cent = 0;
    img.x_cent = 0;
    img.y_cent = 0;      
    
    for i=lower_i:upper_i
        for j=lower_j:upper_j
            if(i>=1 && i<=img.h && j>=1 && j<=img.w)
                if(I(i,j)==1)
                    img.x_cent = img.x_cent + i;
                    img.y_cent = img.y_cent + j;
                    img.n_cent = img.n_cent + 1;
                end
            end
        end
    end

    img.x_cent = uint16(1.0 * img.x_cent / img.n_cent);
    img.y_cent = uint16(1.0 * img.y_cent / img.n_cent);
    
        %reys change
        %Jim's change
end

