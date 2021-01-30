% Demo for erratic noise suppression using iterative SOSVMF with sparsity constraint
% Prepared By Guangtan Huang, Min Bai, and Yangkang Chen
% Dec, 2020
%
% References
% Huang, G., M. Bai, Q. Zhao, W. Chen, and Y. Chen, 2021, Erratic noise suppression using iterative structure-oriented space-varying median filtering with sparsity constraint, Geophys- ical Prospecting, 69, 101-121.
% Chen, Y., S. Zu, Y. Wang, and X. Chen, 2019, Deblending of simultaneous-source data using a structure-oriented space varying median filter, Geophysical Journal International, 216, 1214?1232.


clc;clear;close all;

is_real=1;           % Type of the transform(0: complex-valued curvelets,1: real-valued curvelets)
finest=2;            % Chooses one of two possibilities for the coefficients at the finest level(1: curvelets,2: wavelets)
alpha=1.2;           % ������׼���alpha����ֵ��1.2���ҽ�Ϊ���룩
alpha=1.2;
niter=10;

dc=levents(200);dc=yc_scale(dc);

[n1,n2]=size(dc);

mask=rand(1,n2);
mask(logical(mask<0.9))=0;
mask(logical(mask>=0.9))=1;

err_n=zeros(size(dc));
for i=1:n1
    randn('state',123456+i);
    err_n(i,:)=0.2*randn(1,n2).*mask;
end

randn('state',201920);
ran_n=0.1*randn(n1,n2);

dn=dc+err_n+ran_n;

dt=0.004;
t=[0:n1-1]*dt;x=[1:n2];

figure;imagesc([dc,dn]);caxis([-0.5,0.5]);colormap(seis);


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

[-1,yc_snr(dc,dn)]
[0,yc_snr(dc,d1)]
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
    [i,yc_snr(dc,d1)]
    
    pause(1);figure(2);imagesc([dn,d1,dn-d1]);caxis([-0.5,0.5]);
end




%% SOSVMF
dipc=dip2d_shan(dc);
dipn=dip2d_shan(dn,5,20,2,0.01,[20,5,1]);
figure;imagesc([dipc,dipn]);colorbar;colormap(jet);caxis([-1,2]);

figure('units','normalized','Position',[0.0 0.0 0.6, 1.0],'color','w');
imagesc(x,t,dipc);
c = colorbar;c.Label.String = 'Local slope';c.Label.FontSize = 30;%c.Label.FontWeight = bold;
colormap(jet);caxis([-1,2]);
ylabel('Time (s)','Fontsize',30);
xlabel('Trace','Fontsize',30);
set(gca,'Linewidth',2,'Fontsize',30);
print(gcf,'-depsc','-r200','l_dip_dc.eps');

figure('units','normalized','Position',[0.0 0.0 0.6, 1.0],'color','w');
imagesc(x,t,dipn);
c = colorbar;c.Label.String = 'Local slope';c.Label.FontSize = 30;%c.Label.FontWeight = bold;
colormap(jet);caxis([-1,2]);
ylabel('Time (s)','Fontsize',30);
xlabel('Trace','Fontsize',30);
set(gca,'Linewidth',2,'Fontsize',30);
print(gcf,'-depsc','-r200','l_dip_dn.eps');



type_mf=1;ifsmooth=0;
ns=3;
[~,d3]=pwsmooth_lop_mf(0,0,dipn,[],n1,n2,ns,2,0.01,n1*n2,n1*n2,type_mf,ifsmooth,dn,[]);
d3=reshape(d3,n1,n2);


figure;imagesc([dn,d1,dn-d1]);colormap(seis);caxis([-0.5,0.5]);colormap(seis);%new
figure;imagesc([dn,d2,dn-d2]);colormap(seis);caxis([-0.5,0.5]);colormap(seis);%curvelet
figure;imagesc([dn,d3,dn-d3]);colormap(seis);caxis([-0.5,0.5]);colormap(seis);%curvelet


%% %����ȥ�룬����Ϊԭʼ�ź��Լ���ʼȥ����
d4=d3;
nfw=[3,3,3,3,3];
niter=10;
nfw=3*ones(niter,1);
% Sigma=0.2104*0.5;
Sigma=Sigma0;
% sigma=[Sigma,linspace(2.5*Sigma,0.25*Sigma,niter)];%max 10.02
sigma=[Sigma,linspace(Sigma,0.1*Sigma,niter)];%very good performance
% snrs4=zeros(niter+1,1);
snrs4=[];
snrs4(1)=yc_snr(dc,d4);
dipn=dip2d_shan(dn,5,20,2,0.01,[20,5,1]);
[0,yc_snr(dc,d4)]
for i=1:niter-2
    P=(dn-d4);
    inter=abs(P-median(P(:)));
    delta=median(inter(:))/0.675*1.345
    E_out=siga(P,delta);
    Z=d4+E_out;   %�õ���ѭ������������˥����Ľ��
    
    [~,Z]=pwsmooth_lop_mf(0,0,dipn,[],n1,n2,nfw(i),2,0.01,n1*n2,n1*n2,type_mf,ifsmooth,dn,[]);
    Z=reshape(Z,n1,n2);
    
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
    
    
    dipn=dip2d_shan(d4,5,20,2,0.01,[20,5,1]);
    d4=real(ifdct_wrapping(Ct,is_real,n1,n2));
    [i,yc_snr(dc,d4)]
    snrs4=[snrs4;yc_snr(dc,d4)];
    pause(1);figure(2);imagesc([dn,d4,dn-d4]);colormap(seis);caxis([-0.5,0.5]);

figure('units','normalized','Position',[0.0 0.0 0.6 1.0],'color','w');
imagesc(x,t,dipn);
c = colorbar;c.Label.String = 'Local slope';c.Label.FontSize = 30;%c.Label.FontWeight = bold;
colormap(jet);caxis([-1,2]);
ylabel('Time (s)','Fontsize',30);
xlabel('Trace','Fontsize',30);
set(gca,'Linewidth',2,'Fontsize',30);
tname=strcat(['l_dip_',num2str(i),'.eps']);
print(gcf,'-depsc','-r200',tname);

figure('units','normalized','Position',[0.2 0.4 0.4, 0.8],'color','w');
imagesc(x,t,d4);colormap(seis);caxis([-0.6,0.6]);
ylabel('Time (s)','Fontsize',30);
xlabel('Trace','Fontsize',30);
set(gca,'Linewidth',2,'Fontsize',30);
tname=strcat(['l_d_',num2str(i),'.eps']);
print(gcf,'-depsc','-r200',tname);

figure('units','normalized','Position',[0.2 0.4 0.4, 0.8],'color','w');
imagesc(x,t,dn-d4);colormap(seis);caxis([-0.6,0.6]);
ylabel('Time (s)','Fontsize',30);
xlabel('Trace','Fontsize',30);
set(gca,'Linewidth',2,'Fontsize',30);
tname=strcat(['l_n_',num2str(i),'.eps']);
print(gcf,'-depsc','-r200',tname);
end
figure;plot(snrs4);
yc_snr(dc,d3)

%% without sosvmf
d44=d3;
nfw=[3,3,3,3,3];
niter=10;
nfw=3*ones(niter,1);
% Sigma=0.2104*0.5;
Sigma=Sigma0;
% sigma=[Sigma,linspace(2.5*Sigma,0.25*Sigma,niter)];%max 10.02
sigma=[Sigma,linspace(0.5*Sigma,0.01*Sigma,niter)];%very good performance
% snrs4=zeros(niter+1,1);
snrs44=[];
snrs44(1)=yc_snr(dc,d44);
dipn=dip2d_shan(dn,5,20,2,0.01,[20,5,1]);
[0,yc_snr(dc,d44)]
for i=1:niter-2
    P=(dn-d44);
    inter=abs(P-median(P(:)));
    delta=median(inter(:))/0.675*1.345
    E_out=siga(P,delta);
    Z=d44+E_out;   %�õ���ѭ������������˥����Ľ��
    
%     [~,Z]=pwsmooth_lop_mf(0,0,dipn,[],n1,n2,nfw(i),2,0.01,n1*n2,n1*n2,type_mf,ifsmooth,dn,[]);
%     Z=reshape(Z,n1,n2);
    
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
    
    
%     dipn=dip2d_shan(d4,5,20,2,0.01,[20,5,1]);
    d44=real(ifdct_wrapping(Ct,is_real,n1,n2));
    [i,yc_snr(dc,d44)]
    snrs44=[snrs44;yc_snr(dc,d44)];
    pause(1);figure(2);imagesc([dn,d44,dn-d44]);colormap(seis);caxis([-0.5,0.5]);

figure('units','normalized','Position',[0.2 0.4 0.4, 0.8],'color','w');
imagesc(x,t,d44);colormap(seis);caxis([-0.6,0.6]);
ylabel('Time (s)','Fontsize',30);
xlabel('Trace','Fontsize',30);
set(gca,'Linewidth',2,'Fontsize',30);
tname=strcat(['l_dd_',num2str(i),'.eps']);
print(gcf,'-depsc','-r200',tname);

figure('units','normalized','Position',[0.2 0.4 0.4, 0.8],'color','w');
imagesc(x,t,dn-d44);colormap(seis);caxis([-0.6,0.6]);
ylabel('Time (s)','Fontsize',30);
xlabel('Trace','Fontsize',30);
set(gca,'Linewidth',2,'Fontsize',30);
tname=strcat(['l_nn_',num2str(i),'.eps']);
print(gcf,'-depsc','-r200',tname);
end
figure;plot(snrs44);





%% another test
d5=d3;
nfw=[3,3,3,3,3];
niter=10;
nfw=3*ones(niter,1);

nfw=[3*ones(niter/2,1),1*ones(niter/2,1)];%failed (Nice!)
% Sigma=0.2104*0.5;
Sigma=Sigma0;
% sigma=[Sigma,linspace(2.5*Sigma,0.25*Sigma,niter)];%max 10.02
sigma=[Sigma,linspace(Sigma,0.1*Sigma,niter)];%very good performance
% snrs4=zeros(niter+1,1);
snrs5(1)=yc_snr(dc,d5);
[0,yc_snr(dc,d5)]
for i=1:niter-2
    P=(dn-d5);
    inter=abs(P-median(P(:)));
    delta=median(inter(:))/0.675*1.345
    E_out=siga(P,delta);
    Z=d5+E_out;   %�õ���ѭ������������˥����Ľ��
    
    [~,Z]=pwsmooth_lop_mf(0,0,dipn,[],n1,n2,nfw(i),2,0.01,n1*n2,n1*n2,type_mf,ifsmooth,dn,[]);
    Z=reshape(Z,n1,n2);
    
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
    
    
    dipn=dip2d_shan(d5,5,20,2,0.01,[20,5,1]);
    d5=real(ifdct_wrapping(Ct,is_real,n1,n2));
    [i,yc_snr(dc,d5)]
    snrs5=[snrs5;yc_snr(dc,d5)];
    pause(1);figure(2);imagesc([dn,d5,dn-d5]);colormap(seis);caxis([-0.5,0.5]);
end


figure;plot(snrs5);




%another few iterations

d6=d3;
nfw=[3,3,3,3,3];
niter=5;
nfw=3*ones(niter,1);

% nfw=[3*ones(niter/2,1),1*ones(niter/2,1)];
% Sigma=0.2104*0.5;
Sigma=Sigma0;
% sigma=[Sigma,linspace(2.5*Sigma,0.25*Sigma,niter)];%max 10.02
sigma=[Sigma,linspace(Sigma,0.2*Sigma,niter)];%very good performance
% snrs4=zeros(niter+1,1);
snrs6(1)=yc_snr(dc,d6);
[0,yc_snr(dc,d6)]
for i=1:niter
    P=(dn-d6);
    inter=abs(P-median(P(:)));
    delta=median(inter(:))/0.675*1.345
    E_out=siga(P,delta);
    Z=d6+E_out;   %�õ���ѭ������������˥����Ľ��
    
    [~,Z]=pwsmooth_lop_mf(0,0,dipn,[],n1,n2,nfw(i),2,0.01,n1*n2,n1*n2,type_mf,ifsmooth,dn,[]);
    Z=reshape(Z,n1,n2);
    
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
    
    
    dipn=dip2d_shan(d6,5,20,2,0.01,[20,5,1]);
    d6=real(ifdct_wrapping(Ct,is_real,n1,n2));
    [i,yc_snr(dc,d6)]
    snrs6=[snrs6;yc_snr(dc,d6)];
    pause(1);figure(2);imagesc([dn,d6,dn-d6]);colormap(seis);caxis([-0.5,0.5]);
end


figure;plot(snrs6);



figure;imagesc([[dc,d2,d1,d3,d4];[dn,dn-d2,dn-d1,dn-d3,dn-d4]]);colormap(seis);caxis([-1,1]);

% 
% %% plot
% [nt,nx]=size(dc);
% dt=0.004;
% t=[0:nt-1]*dt;x=[1:nx];
% figure('units','normalized','Position',[0.2 0.4 0.4, 0.8],'color','w');
% imagesc(x,t,dc);colormap(seis);caxis([-0.6,0.6]);
% ylabel('Time (s)','Fontsize',30);
% xlabel('Trace','Fontsize',30);
% % title('Noise','Fontsize',30);
% set(gca,'Linewidth',2,'Fontsize',30);
% print(gcf,'-depsc','-r200','l_dc.eps');
% 
% figure('units','normalized','Position',[0.2 0.4 0.4, 0.8],'color','w');
% imagesc(x,t,dn);colormap(seis);caxis([-0.6,0.6]);
% ylabel('Time (s)','Fontsize',30);
% xlabel('Trace','Fontsize',30);
% % title('Noise','Fontsize',30);
% set(gca,'Linewidth',2,'Fontsize',30);
% print(gcf,'-depsc','-r200','l_dn.eps');
% 
% 
% figure('units','normalized','Position',[0.2 0.4 0.4, 0.8],'color','w');
% imagesc(x,t,d2);colormap(seis);caxis([-0.6,0.6]);
% ylabel('Time (s)','Fontsize',30);
% xlabel('Trace','Fontsize',30);
% % title('Noise','Fontsize',30);
% set(gca,'Linewidth',2,'Fontsize',30);
% print(gcf,'-depsc','-r200','l_curv.eps');
% 
% 
% figure('units','normalized','Position',[0.2 0.4 0.4, 0.8],'color','w');
% imagesc(x,t,d1);colormap(seis);caxis([-0.6,0.6]);
% ylabel('Time (s)','Fontsize',30);
% xlabel('Trace','Fontsize',30);
% % title('Noise','Fontsize',30);
% set(gca,'Linewidth',2,'Fontsize',30);
% print(gcf,'-depsc','-r200','l_curvi.eps');
% 
% 
% figure('units','normalized','Position',[0.2 0.4 0.4, 0.8],'color','w');
% imagesc(x,t,d3);colormap(seis);caxis([-0.6,0.6]);
% ylabel('Time (s)','Fontsize',30);
% xlabel('Trace','Fontsize',30);
% % title('Noise','Fontsize',30);
% set(gca,'Linewidth',2,'Fontsize',30);
% print(gcf,'-depsc','-r200','l_sosvmf.eps');
% 
% figure('units','normalized','Position',[0.2 0.4 0.4, 0.8],'color','w');
% imagesc(x,t,d4);colormap(seis);caxis([-0.6,0.6]);
% ylabel('Time (s)','Fontsize',30);
% xlabel('Trace','Fontsize',30);
% % title('Noise','Fontsize',30);
% set(gca,'Linewidth',2,'Fontsize',30);
% print(gcf,'-depsc','-r200','l_sosvmfi.eps');
% 
% 
% figure('units','normalized','Position',[0.2 0.4 0.4, 0.8],'color','w');
% imagesc(x,t,dn-d2);colormap(seis);caxis([-0.6,0.6]);
% ylabel('Time (s)','Fontsize',30);
% xlabel('Trace','Fontsize',30);
% % title('Noise','Fontsize',30);
% set(gca,'Linewidth',2,'Fontsize',30);
% print(gcf,'-depsc','-r200','l_curv_n.eps');
% 
% 
% figure('units','normalized','Position',[0.2 0.4 0.4, 0.8],'color','w');
% imagesc(x,t,dn-d1);colormap(seis);caxis([-0.6,0.6]);
% ylabel('Time (s)','Fontsize',30);
% xlabel('Trace','Fontsize',30);
% % title('Noise','Fontsize',30);
% set(gca,'Linewidth',2,'Fontsize',30);
% print(gcf,'-depsc','-r200','l_curvi_n.eps');
% 
% 
% figure('units','normalized','Position',[0.2 0.4 0.4, 0.8],'color','w');
% imagesc(x,t,dn-d3);colormap(seis);caxis([-0.6,0.6]);
% ylabel('Time (s)','Fontsize',30);
% xlabel('Trace','Fontsize',30);
% % title('Noise','Fontsize',30);
% set(gca,'Linewidth',2,'Fontsize',30);
% print(gcf,'-depsc','-r200','l_sosvmf_n.eps');
% 
% figure('units','normalized','Position',[0.2 0.4 0.4, 0.8],'color','w');
% imagesc(x,t,dn-d4);colormap(seis);caxis([-0.6,0.6]);
% ylabel('Time (s)','Fontsize',30);
% xlabel('Trace','Fontsize',30);
% % title('Noise','Fontsize',30);
% set(gca,'Linewidth',2,'Fontsize',30);
% print(gcf,'-depsc','-r200','l_sosvmfi_n.eps');
% 
% 
% figure('units','normalized','Position',[0.2 0.4 0.4, 0.4],'color','w');
% plot([0:8],snrs4,'-g*','linewidth',2);
% ylabel('SNR (dB)','Fontsize',30);
% xlabel('Iteration NO','Fontsize',30);
% % title('Noise','Fontsize',30);
% set(gca,'Linewidth',2,'Fontsize',30);
% print(gcf,'-depsc','-r200','l_snrs4.eps');
% 
% %% local similarity
% rect=[10,5,1];niter=20;eps=0;verb=0;
% [simi1]=localsimi(dc,d1,rect,niter,eps,verb);
% [simi2]=localsimi(dc,d2,rect,niter,eps,verb);
% [simi3]=localsimi(dc,d3,rect,niter,eps,verb);
% [simi4]=localsimi(dc,d4,rect,niter,eps,verb);
% 
% [simi11]=localsimi(dn-d1,d1,rect,niter,eps,verb);
% [simi22]=localsimi(dn-d2,d2,rect,niter,eps,verb);
% [simi33]=localsimi(dn-d3,d3,rect,niter,eps,verb);
% [simi44]=localsimi(dn-d4,d4,rect,niter,eps,verb);
% 
% 
% figure('units','normalized','Position',[0.0 0.0 0.6, 1],'color','w');
% imagesc(x,t,simi1);colormap(jet);colormap(jet);
% c = colorbar;c.Label.String = 'Local similarity';c.Label.FontSize = 30;%c.Label.FontWeight = bold;
% caxis([0,1]);
% ylabel('Time (s)','Fontsize',30);
% xlabel('Trace','Fontsize',30);
% % title('Noise','Fontsize',30);
% set(gca,'Linewidth',2,'Fontsize',30);
% print(gcf,'-depsc','-r200','l_simi_curvi.eps');
% 
% 
% figure('units','normalized','Position',[0.0 0.0 0.6, 1],'color','w');
% imagesc(x,t,simi2);colormap(jet);colormap(jet);
% c = colorbar;c.Label.String = 'Local similarity';c.Label.FontSize = 30;%c.Label.FontWeight = bold;
% caxis([0,1]);
% ylabel('Time (s)','Fontsize',30);
% xlabel('Trace','Fontsize',30);
% % title('Noise','Fontsize',30);
% set(gca,'Linewidth',2,'Fontsize',30);
% print(gcf,'-depsc','-r200','l_simi_curv.eps');
% 
% 
% figure('units','normalized','Position',[0.0 0.0 0.6, 1],'color','w');
% imagesc(x,t,simi3);colormap(jet);colormap(jet);
% c = colorbar;c.Label.String = 'Local similarity';c.Label.FontSize = 30;%c.Label.FontWeight = bold;
% caxis([0,1]);
% ylabel('Time (s)','Fontsize',30);
% xlabel('Trace','Fontsize',30);
% % title('Noise','Fontsize',30);
% set(gca,'Linewidth',2,'Fontsize',30);
% print(gcf,'-depsc','-r200','l_simi_sosvmf.eps');
% 
% 
% figure('units','normalized','Position',[0.0 0.0 0.6, 1],'color','w');
% imagesc(x,t,simi4);colormap(jet);colormap(jet);
% c = colorbar;c.Label.String = 'Local similarity';c.Label.FontSize = 30;%c.Label.FontWeight = bold;
% caxis([0,1]);
% ylabel('Time (s)','Fontsize',30);
% xlabel('Trace','Fontsize',30);
% % title('Noise','Fontsize',30);
% set(gca,'Linewidth',2,'Fontsize',30);
% print(gcf,'-depsc','-r200','l_simi_sosvmfi.eps');
% 
% 
% figure('units','normalized','Position',[0.0 0.0 0.6, 1],'color','w');
% imagesc(x,t,simi11);colormap(jet);colormap(jet);
% c = colorbar;c.Label.String = 'Local similarity';c.Label.FontSize = 30;%c.Label.FontWeight = bold;
% caxis([0,0.5]);
% ylabel('Time (s)','Fontsize',30);
% xlabel('Trace','Fontsize',30);
% % title('Noise','Fontsize',30);
% set(gca,'Linewidth',2,'Fontsize',30);
% print(gcf,'-depsc','-r200','l_simi2_curvi.eps');
% 
% 
% figure('units','normalized','Position',[0.0 0.0 0.6, 1],'color','w');
% imagesc(x,t,simi22);colormap(jet);colormap(jet);
% c = colorbar;c.Label.String = 'Local similarity';c.Label.FontSize = 30;%c.Label.FontWeight = bold;
% caxis([0,0.5]);
% ylabel('Time (s)','Fontsize',30);
% xlabel('Trace','Fontsize',30);
% % title('Noise','Fontsize',30);
% set(gca,'Linewidth',2,'Fontsize',30);
% print(gcf,'-depsc','-r200','l_simi2_curv.eps');
% 
% 
% figure('units','normalized','Position',[0.0 0.0 0.6, 1],'color','w');
% imagesc(x,t,simi33);colormap(jet);colormap(jet);
% c = colorbar;c.Label.String = 'Local similarity';c.Label.FontSize = 30;%c.Label.FontWeight = bold;
% caxis([0,0.5]);
% ylabel('Time (s)','Fontsize',30);
% xlabel('Trace','Fontsize',30);
% % title('Noise','Fontsize',30);
% set(gca,'Linewidth',2,'Fontsize',30);
% print(gcf,'-depsc','-r200','l_simi2_sosvmf.eps');
% 
% 
% figure('units','normalized','Position',[0.0 0.0 0.6, 1],'color','w');
% imagesc(x,t,simi44);colormap(jet);colormap(jet);
% c = colorbar;c.Label.String = 'Local similarity';c.Label.FontSize = 30;%c.Label.FontWeight = bold;
% caxis([0,0.5]);
% ylabel('Time (s)','Fontsize',30);
% xlabel('Trace','Fontsize',30);
% % title('Noise','Fontsize',30);
% set(gca,'Linewidth',2,'Fontsize',30);
% print(gcf,'-depsc','-r200','l_simi2_sosvmfi.eps');
% 
% 









