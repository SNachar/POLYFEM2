function out = BoundaryFunc_UBL_S24(xx,ang)
n = size(xx,1);
rang = 6.405689286260557e-02;
% wt = (1.016897363585255e-01)/2;
% val = dot(rang1(1),1);
if abs(rang - ang) < 1e-12
    out = ones(n,1);
else
    out = zeros(n,1);
end