clear;
load('../results/havard_stahlhut_tip.mat');
dT = OpRot(1,1).ElPerf.dT;
dQ = OpRot(1,1).ElPerf.dT;
figure(1)
plot(dQ);

% Root cutout is not included in simulation, need to 
% prepend for vizualization
num_cutout_elems = OpRot(1,1).Rot.cutout/OpRot(1,1).Rot.Bl.dy;
dT = [zeros(1, round(num_cutout_elems)) dT];
dQ = [zeros(1, round(num_cutout_elems)) dQ];
%plot(dT);

% 3D plot of Thrust
%cylinder(dT)
n = 50;
theta = linspace(0,pi,n).';

x0 = linspace(1,length(dT), length(dT));
y0 = dT(x0);
y = x0.*cos(theta);
x = x0.*sin(theta);
z = repmat(y0,[n,1]);

figure(2)
h = surf(x,y,z);
hold on
set(h, 'EdgeAlpha',0.0);
set(h, 'FaceAlpha',1);
theta = linspace(pi,2*pi,n).';

x0 = linspace(1,length(dT), length(dT));
y0 = dT(x0);
y = x0.*cos(theta);
x = x0.*sin(theta);
z = repmat(y0,[n,1]);
h = surf(x,y,z);
hold on
set(h, 'EdgeAlpha',0.0);
set(h, 'FaceAlpha',0.2);
axHand = h.Parent;
axHand.ZLim = [-0.5, 0.5];
axHand.XLim = [-length(dT), length(dT)];
axHand.YLim = [-length(dT), length(dT)];
% Draw 2d plot
y = linspace(-length(dT),length(dT), 2*length(dT));
x = zeros(1,2*length(dT));
z = zeros(1,2*length(dT));
z(1:length(dT)) = flip(dT);
z(1+length(dT):2*length(dT)) = dT;

plot3(x,y,z,'linewidth',2, 'color','red');

set(gca,'XTick',[]);
set(gca,'YTick',[]);
set(gca,'ZTick',[]);
zlabel('dT');
title('Radial thrust distrubution')
%set(h,'zscale','log')
view(-50,50)
