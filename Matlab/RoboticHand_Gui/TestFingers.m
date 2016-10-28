clear vars;
clear all;
close all;

img.arc_n = 8;
img.norm_arc = 100; 
img.node_n = 50;

img.finger_n = 10;

for a=img.arc_n:-1:1
    img.circle(a).intersection_norm = false(img.norm_arc,1);
end

for n=img.node_n:-1:1
    img.node(n).arc = 0;
    img.node(n).left = 0;
    img.node(n).right = 0;
    img.node(n).parent = 0;
    img.node(n).base = false;
    img.node(n).id = 0;
end

for f=img.finger_n:-1:1
    img.finger(f).left = 0;
    img.finger(f).right = 0;
    img.finger(f).arc = 0;
end

% img.circle(8).intersection_norm(20:30) = true;
% img.circle(7).intersection_norm(25:35) = true;
% img.circle(6).intersection_norm(30:40) = true;
% img.circle(5).intersection_norm(35:45) = true;
% img.circle(4).intersection_norm(40:50) = true;
% img.circle(3).intersection_norm(45:55) = true;
img.circle(2).intersection_norm(50:60) = true;
img.circle(1).intersection_norm(10:35) = true;
% 
% % Floating Segment
img.circle(8).intersection_norm(50:55) = true;
% 
% 
% img.circle(8).intersection_norm(70:80) = true;
% img.circle(7).intersection_norm(70:80) = true;
% img.circle(6).intersection_norm(70:80) = true;
% img.circle(5).intersection_norm(70:80) = true;
% img.circle(4).intersection_norm(70:80) = true;
% img.circle(3).intersection_norm(70:80) = true;
img.circle(2).intersection_norm(45:90) = true;
img.circle(1).intersection_norm(45:90) = true;
% 
% 
% img.circle(3).intersection_norm(20:30) = true;
% img.circle(2).intersection_norm(20:30) = true;

figure;
subplot(2,1,1);
for a=img.arc_n:-1:1
    plot(1:img.norm_arc, 1.0*img.circle(a).intersection_norm+a); hold on;  
end
hold off;

tic
img.node_n = 0;

% Start from Base and Work Outwards
for r=1:img.arc_n

    % Edge Detection
    img.circle(r).intersection_norm(1) = 0;
    img.circle(r).intersection_norm(end) = 0;
    
    a1 = img.circle(r).intersection_norm(1:end-1);
    a2 = img.circle(r).intersection_norm(2:end);      
    
    posedge = (~a1 & a2) & a2;
    negedge = (a1 & ~a2) & a1;
    
    posedge_i = find(posedge);
    negedge_i = find(negedge);
        
    for n=1:length(posedge_i)
        img.node_n = img.node_n + 1;
        img.node(img.node_n).arc = r;
        img.node(img.node_n).left = posedge_i(n);
        img.node(img.node_n).right = negedge_i(n);
        
        if(r>1)
            for i = img.node_n:-1:1
                prev_arc(i) = img.node(i).arc;
            end
            for nn=find(prev_arc==r-1)
                if( (img.node(img.node_n).left >= img.node(nn).left &&...
                     img.node(img.node_n).left <= img.node(nn).right) ...
                     || ...
                     (img.node(img.node_n).right >= img.node(nn).left &&...
                     img.node(img.node_n).right <= img.node(nn).right) )
                    img.node(img.node_n).parent = nn;
                    
                    img.node(img.node_n).base = img.node(nn).base;
                    
                end
            end
        else
            img.node(img.node_n).base = true;
        end                
    end   
end


% Start from Tip and Work Inwards
img.node_id = 1;
for n=img.node_n:-1:1    
    if(img.node(n).id == 0 && img.node(n).parent ~= 0)
        img.finger(img.node_id).left = img.node(n).left;
        img.finger(img.node_id).right = img.node(n).right;      
        img.finger(img.node_id).arc = img.node(n).arc;
        % Trickle Down Fingers
        new_n = n;
        while(img.node(new_n).id == 0 && img.node(new_n).parent ~= 0)
            img.node(new_n).id = img.node_id;
            new_n = img.node(new_n).parent;
        end        
        img.node_id = img.node_id + 1;
    end                
end
toc


% Reset Fingers




subplot(2,1,2);
plot(posedge); hold on;
plot(negedge);
% for a=img.arc_n:-1:1
%     plot(1:img.norm_arc, 1.0*img.circle(a).intersection_norm+a); hold on;  
% end
% hold off;





