figure;
hold on;

%adding the original points
plot(0,0,'.m','MarkerSize',6)
plot(norm(X,normtype),0,'.m','MarkerSize',6)
plot(-norm(Y,normtype)*cos(theta),-norm(Y,normtype)*sin(theta),'.m','MarkerSize',6)

%adding the text associated to them
text(0+xoffs,0+yoffs,'B','color','m','BackgroundColor','w')
text(norm(X,normtype)+xoffs,0+yoffs,'B0','color','m','BackgroundColor','w')
text(-norm(Y,normtype)*cos(theta)+xoffs,-norm(Y,normtype)*sin(theta)+yoffs,'A','color','m','BackgroundColor','w')

%keeping the distances of the stable points only
val  = objvalD(sub2ind(size(objvalD),I,J));

%creating the uniform grid
ax = linspace(xlim(1),xlim(2),npta);
ay = linspace(ylim(1),ylim(2),nptb);
[ax,ay]= meshgrid(ax,ay);

%interpolating the values of the stable distances on a uniform grid
Z = griddata(x,y,val,ax,ay,'cubic');
mpo = (min(o)+max(o))/2;
mpp = (min(p)+max(p))/2;
border = round(griddata([o],[p],[ones(length(o),1)],ax,ay,'cubic'));
border(isnan(border))=0;
Border = border;
for i =1 : npta
    for j = 1 : nptb
        if border(i,j)== 1
            Border(i,j)=1;
            if (i == npta || i ==1) ||...
                    (j==nptb || j==1)
                Border(i,j) = 2;
            else
                if(border(i-1,j) == 0 || border(i+1,j) == 0 )||...
                    (border(i,j-1) == 0 || border(i,j+1) == 0)
                Border(i,j)=2;
                end
                if (border(i-1,j) == 2 || border(i+1,j) == 2 )||...
                    (border(i,j-1) == 2 || border(i,j+1) == 2)
            end
        end
    end
end

%---computing and adding the contour---
%noticable level that we want to have vmin,B,B0 and vmax
vmin = min(val);
vmax = max(val);
vb0 = norm(A-B0,normtype);
vb  = norm(A-B,normtype);
vl = min(vb,vb0);
vu = max(vb,vb0);

%a ratio is computed so that the number of curves is spread evenly outside
%of the 4 noticable points.
rap1 = ceil(((vl-vmin)/(vmax-vmin))*10);
rap2 = ceil(((vu-vl)/(vmax-vmin))*10);
rap3 = ceil(((vmax-vu)/(vmax-vmin))*10);

%tracing the contours
v = [[vmin:(vl-vmin)/rap1:vl],[vl+(vu-vl)/rap2:(vu-vl)/rap2:vu-(vu-vl)/rap2],[vu:(vmax-vu)/rap3:vmax]];
[C,h]=contour(ax,ay,Z,v);

