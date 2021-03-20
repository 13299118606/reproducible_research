% Demo for erratic noise suppression using iterative SOSVMF with sparsity constraint
% Prepared By Guangtan Huang, Min Bai, and Yangkang Chen
% Dec, 2020
%
% References
% Zhao, Q., Q. Du, X. Gong, and Y. Chen, 2018, Signal-preserving erratic noise attenuation via iterative robust sparsity-promoting filter, IEEE Transactions on Geoscience and Remote Sensing, 56, 1558-0644.
% Huang, G., M. Bai, Q. Zhao, W. Chen, and Y. Chen, 2021, Erratic noise suppression using iterative structure-oriented space-varying median filtering with sparsity constraint, Geophysical Prospecting, 69, 101-121.
% Chen, Y., S. Zu, Y. Wang, and X. Chen, 2020, Deblending of simultaneous-source data using a structure-oriented space varying median filter, Geophysical Journal International, 222, 1805?1823.
%
% NOTE: this example is directly copied from erratic_sosvmf.m, and the
% performance may not be optimal

clc;clear;close all;

is_real=1;           % Type of the transform(0: complex-valued curvelets,1: real-valued curvelets)
finest=2;            % Chooses one of two possibilities for the coefficients at the finest level(1: curvelets,2: wavelets)
alpha=1.0;           % ������׼���alpha����ֵ��1.2���ҽ�Ϊ���룩

niter=10;

fid=fopen('real.bin','r');
ori=fread(fid,[800,220],'float');

dn=yc_scale(ori,2);
[n1,n2]=size(dn);
figure;imagesc([dn]);colormap(seis);caxis([-0.5,0.5]);


F=ones(n1,n2);                                  % ones(n)����n*n��1����Ƶ����
X=fftshift(ifft2(F))*sqrt(prod(size(F)));       % prod����size(F)�ĳ˻�,X��һ�������壬��׼��Ϊ1
C=fdct_wrapping(X,0,finest);                    % ���������任�õ��Ǹ�����,�����ΪС���任
% Compute norm of curvelets (exact)
E=cell(size(C));
for s=1:length(C)
    E{s}=cell(size(C{s}));
    for w=1:length(C{s})
        A=C{s}{w};
        E{s}{w}=sqrt(sum(sum(A.*conj(A)))/prod(size(A)));    %����A��ģ�������׼������򵥵����
    end
end

Cdn=fdct_wrapping(dn,is_real,finest);     %���������任�õ���ʵ����,�����ΪС���任
Smax=length(Cdn);
Sigma0=alpha*median(median(abs(Cdn{Smax}{1})))/0.58;     %��ȡ������׼�ѡȡ���߶�
Sigma=Sigma0;
% sigma=[Sigma,5*Sigma,2*Sigma, Sigma, 0.6*Sigma,Sigma/5];
% sigma=[Sigma,5*Sigma,2*Sigma, Sigma, 0.6*Sigma,Sigma*0.1];
sigma=[Sigma,linspace(2.5*Sigma,0.5*Sigma,niter)];
Sigma=sigma(1);

Ct=Cdn;
for s=2:length(Cdn)
    thresh=Sigma+Sigma*s;    %���������Ϊ4*sigma
    for w=1:length(Cdn{s})
        Ct{s}{w}=Cdn{s}{w}.*(abs(Cdn{s}{w})>thresh*E{s}{w});  %������ֵ�ı���
    end
end
d1=real(ifdct_wrapping(Ct,is_real,n1,n2));

d2=d1;

% figure;imagesc(dn);colormap(seis);caxis([-0.5,0.5]);colormap(seis);
figure;imagesc([dn,d1,dn-d1]);colormap(seis);caxis([-0.5,0.5]);colormap(seis);

%% %����ȥ�룬����Ϊԭʼ�ź��Լ���ʼȥ����
Sigma=Sigma0;
% sigma=[Sigma,5*Sigma,2*Sigma, Sigma, 0.6*Sigma,Sigma/5];
% sigma=[Sigma,5*Sigma,2*Sigma, Sigma, 0.6*Sigma,Sigma*0.1];
sigma=[Sigma,linspace(2.5*Sigma,0.5*Sigma,niter)];

for i=1:niter
    P=(dn-d1);
    inter=abs(P-median(P(:)));
    delta=median(inter(:))/0.675*1.345
    E_out=siga(P,delta);
    Z=d1+E_out;   %�õ���ѭ������������˥����Ľ��
    
    Cdn=fdct_wrapping(Z,is_real,finest);     %���������任�õ���ʵ����,�����ΪС���任
    
    Smax=length(Cdn);
    Sigma=sigma(i+1);     %��ȡ������׼�ѡȡ���߶�
    
    Ct=Cdn;
    for s=2:length(Cdn)
        thresh=Sigma+Sigma*s;
        for w=1:length(Cdn{s})
            Ct{s}{w}=Cdn{s}{w}.*(abs(Cdn{s}{w})>thresh*E{s}{w});
        end
    end
    d1=real(ifdct_wrapping(Ct,is_real,n1,n2));
    
    pause(1);figure(2);imagesc([dn,d1,dn-d1]);colormap(seis);caxis([-0.5,0.5]);
end

figure;imagesc([dn,d1,dn-d1]);colormap(seis);caxis([-0.5,0.5]);colormap(seis);%new
figure;imagesc([dn,d2,dn-d2]);colormap(seis);caxis([-0.5,0.5]);colormap(seis);%curvelet

%% plot

dt=0.004;
t=[0:n1-1]*dt;x=[1:n2];

figure('units','normalized','Position',[0.2 0.4 0.4, 0.8],'color','w');
imagesc(x,t,dn);colormap(seis);caxis([-0.6,0.6]);
ylabel('Time (s)','Fontsize',30);
xlabel('Trace','Fontsize',30);
% title('Noise','Fontsize',30);
set(gca,'Linewidth',2,'Fontsize',30);
print(gcf,'-depsc','-r200','f_dn.eps');


figure('units','normalized','Position',[0.2 0.4 0.4, 0.8],'color','w');
imagesc(x,t,d2);colormap(seis);caxis([-0.6,0.6]);
ylabel('Time (s)','Fontsize',30);
xlabel('Trace','Fontsize',30);
% title('Noise','Fontsize',30);
set(gca,'Linewidth',2,'Fontsize',30);
print(gcf,'-depsc','-r200','f_curv.eps');


figure('units','normalized','Position',[0.2 0.4 0.4, 0.8],'color','w');
imagesc(x,t,d1);colormap(seis);caxis([-0.6,0.6]);
ylabel('Time (s)','Fontsize',30);
xlabel('Trace','Fontsize',30);
% title('Noise','Fontsize',30);
set(gca,'Linewidth',2,'Fontsize',30);
print(gcf,'-depsc','-r200','f_curvi.eps');


figure('units','normalized','Position',[0.2 0.4 0.4, 0.8],'color','w');
imagesc(x,t,dn-d2);colormap(seis);caxis([-0.6,0.6]);
ylabel('Time (s)','Fontsize',30);
xlabel('Trace','Fontsize',30);
% title('Noise','Fontsize',30);
set(gca,'Linewidth',2,'Fontsize',30);
print(gcf,'-depsc','-r200','f_curv_n.eps');


figure('units','normalized','Position',[0.2 0.4 0.4, 0.8],'color','w');
imagesc(x,t,dn-d1);colormap(seis);caxis([-0.6,0.6]);
ylabel('Time (s)','Fontsize',30);
xlabel('Trace','Fontsize',30);
% title('Noise','Fontsize',30);
set(gca,'Linewidth',2,'Fontsize',30);
print(gcf,'-depsc','-r200','f_curvi_n.eps');




