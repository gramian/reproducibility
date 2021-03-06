
isdiscrete = 1;

runstable = zeros(nexp,nc-1);
rstable = zeros(nexp,nc-1);

load 50_original_unstable_polynomials_and_their_roots


[nl,nc] = size(unstable);
nite = nl;
n = nc;

startingpoints = zeros(nl,nc);
for i = 1 : nite
    p = unstable(i,1:n); % we deal with monic polynomials the first coefficient does add information
    
    b  = PolySPMirrored(p,0,isdiscrete);
    
    startingpoints(i,:) = [1 fliplr(b.')];
end

rstartingpoints = zeros(nl,nc-1);
figure;
hold on;
for i = 1 : nexp
    rstartingpoints(i,:) = roots(startingpoints(i,:));
    h(i) = plot(real(rstartingpoints(i,:)),imag(rstartingpoints(i,:)),'o');
    set(h(i),'markersize',5,'markeredgecolor','black','linewidth',1.5);
end
%mise en page
box on;
set(gca,'fontsize',14)
xlabel('Re(z)')
ylabel('Im(z)')
set(gca,'xlim',[0.5 0.85],'ylim',[0.5 0.85]);
set(gca,'xtick',[0.5 0.85],'ytick',[0.5 0.85]);
x = [0:0.1:360];
h1 = plot(cosd(x),sind(x));
set(h1,'Color','black','Linewidth',3)
set_plot(5,5,1)