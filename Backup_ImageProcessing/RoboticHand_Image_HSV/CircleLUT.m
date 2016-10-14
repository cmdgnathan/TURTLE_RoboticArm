function [ mask ] = CircleLUT( r, thick )
% Circle Look Up Table
    [xx yy] = meshgrid(-r:r);
    C = sqrt(xx.^2+yy.^2);
    mask = (C<=r) & (C>=r-thick);
end

