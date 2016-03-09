function out = ExactSol_IncidentLeftFace_2D_45degDown_LS4_sigt100(xx,~)
x = xx(:,1); y = xx(:,2);
val = cos(pi/4); valdenom = 3.500211745815407e-01;
sigt = 100;
out = (1/val)*exp(-sigt*x./valdenom);
out(y>1-x) = 0.;