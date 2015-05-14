function [F] = attrForce3D(binaryImg,gamma)
%ATTRFORCE Compute the attraction force in TuFF in 3D

num_masters = 2;
Dirac = @(x,e) ((1/2/e)*(1+cos(pi*x/e)).*((x<=e) & (x>=-e)));
border_width = 4;

CC = bwconncomp(binaryImg);
% num_cc = CC.NumObjects;
F = zeros(size(binaryImg));

regions = regionprops(CC, 'Area', 'PixelIdxList');
[~,sortList] = sort([regions.Area],'descend');  %-- Sort the components according to size

% rad = max(round(6*border_width),1);
% Ker = TuFF.AM_VFK(3,rad,'power',gamma);   % Gaussian kernel of radii = rad
% vfkX = Ker(:,:,:,1);
% vfkY = Ker(:,:,:,2);
% vfkZ = Ker(:,:,:,3);


for ii = 1 : num_masters
    rp = regions(sortList(ii));
    master_img = false(size(binaryImg));
    master_img(rp(1).PixelIdxList)  = true;  %-- binary image only with master
    
    phi_master = double(bwdist(~master_img) - bwdist(master_img)); %-- LSF for master 
    master_contour = Dirac(phi_master,border_width);
    master_kappa = TuFF.compute_divergence3D(phi_master);
    master_kappa = abs(master_kappa).*(master_kappa<0);          %-- only convex portions can attract
    
    %-- Attraction force field computation
%     Fx = convn(master_contour.*master_kappa,vfkX,'same').*(~master_img);
%     Fy = convn(master_contour.*master_kappa,vfkY,'same').*(~master_img);
%     Fz = convn(master_contour.*master_kappa,vfkZ,'same').*(~master_img);
    
    [Fx,Fy,Fz] = gradient(master_contour);
    Fx = Fx.*master_kappa.*(~master_img);
    Fy = Fy.*master_kappa.*(~master_img);
    Fz = Fz.*master_kappa.*(~master_img);
    
    %-- Compute the outward normal for slaves
    slave_img = binaryImg - master_img;
    phi_slave = double(bwdist(~slave_img) - bwdist(slave_img)); %-- LSF for slave
    slave_contour = Dirac(phi_slave,border_width);
    [nx,ny,nz] = gradient(phi_slave);
    nx = -nx.*(~slave_img).*slave_contour;
    ny = -ny.*(~slave_img).*slave_contour;
    nz = -nz.*(~slave_img).*slave_contour;
    
    F = Fx.*nx + Fy.*ny + Fz.*nz;
    if max(F(:) > eps)
        F = (F-min(F(:)))/(max(F(:))-min(F(:)));
    end
end

F = F/num_masters;

end

