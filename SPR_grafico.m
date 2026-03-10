% Matlab procedure that generates a Surface Plasmon Resonance profile
% to compare it with exp.tal data
% uses uicontrol for graphical input of relevant paramaters
% gigi Cristofolini jan 2007
% costanti iniziali
clear all

BASTA=0; %serve a fermare
c=299792458;
hbar=6.5822e-16;
pi=acos(-1);
lambda=632.8e-9;
omega=2*pi/lambda*c;
fukso=complex(0,1);

%setup del dialogo per i parametri:
figure(1)
clf
axes('position',[.05 .3  .9 .68])
%PRISMA
n_prisma=uicontrol('style','slider','min',0,'max',2,'value',1.505);
set(n_prisma,'units','normalized','position',[.10 .16 .25 .025]);
uicontrol('style','text','string','PRISM','units','normalized','position',[.0 .16 .07 .02]);
%ORO
n_oro=uicontrol('style','slider','min',0,'max',1,'value',.1726);
set(n_oro,'units','normalized','position',[.10 .12 .25 .025]);
k_oro=uicontrol('style','slider','min',0,'max',4,'value',3.4218);
set(k_oro,'units','normalized','position',[.40 .12 .25 .025]);
d_oro=uicontrol('style','slider','min',0,'max',100,'value',88);
set(d_oro,'units','normalized','position',[.70 .12 .25 .025]);
uicontrol('style','text','string','GOLD','units','normalized','position',[.0 .12 .07 .02]);
%LAYER
n_lyr=uicontrol('style','slider','min',0,'max',2,'value',1.7);
set(n_lyr,'units','normalized','position',[.10 .08 .25 .025]);
k_lyr=uicontrol('style','slider','min',0,'max',1,'value',0);
set(k_lyr,'units','normalized','position',[.40 .08 .25 .025]);
d_lyr=uicontrol('style','slider','min',0,'max',400,'value',20);
set(d_lyr,'units','normalized','position',[.70 .08 .25 .025]);
uicontrol('style','text','string','LAYER','units','normalized','position',[.0 .08 .07 .02]);
% SUBPHASE CHOICE
subfase=uicontrol('style','popup','string','air|water');
set(subfase,'units','normalized','position',[.13 .01 .1 .05])
uicontrol('style','text','string','SUBPHASE','units','normalized','position',[.0 .03 .1 .02]);

%FILE CHOICE
FL=dir('*.dat');
MS=' ';
for j=1:length(FL);
    MS=[MS,'|',FL(j).name];
end
fname=uicontrol('style','popup','string',MS);
set(fname,'units','normalized','position',[.5 .01 .2 .05])
uicontrol('style','text','string','EXPERIMENTAL DATA FILE','units','normalized','position',[.3 .03 .2 .02]);

%CAPTIONS
uicontrol('style','text','string','n','units','normalized','position',[.2 .22 .02 .02]);
uicontrol('style','text','string','k','units','normalized','position',[.5 .22 .02 .02]);
uicontrol('style','text','string','d','units','normalized','position',[.8 .22 .02 .02]);

%TERMINA CALCOLI
basta=uicontrol('style','pushbutton','string','STOP','callback','BASTA=1;');
set(basta,'units','normalized','position',[.9 .01 .1 .05]);


while BASTA==0
    clear expdata REF TRA %se passo ad un dataset più corto ...
    %% file di dati speriementali da fittare
    fnumber=get(fname,'value');
    if fnumber==1
        expdata(:,1)=(30:.1:70)';
        expdata(:,2)=1;
        FNAME='SIMULATION ONLY';
    else
        FNAME=FL(fnumber-1).name; 
        expdata=dlmread(FNAME,' ',15,1);
    end

    %strato 1: vetro del prisma
    en(1)=get(n_prisma,'value'); %parte reale indice rifrazione prisma (1.51 se vetro normale, 1.723 se SF10)
    ek(1)=0;
    %strato 2: layer di oro
    en(2)=get(n_oro,'value'); %parte reale indice rifr oro
    ek(2)=get(k_oro,'value'); %parte imag indice rifr oro
    d(2)=1e-9*get(d_oro,'value'); %spessore (nm)
    %strato 3: layer appiccicato
    en(3)=get(n_lyr,'value'); %parte reale indice rifrazione layer
    ek(3)=get(k_lyr,'value'); %parte imag indice rifrazione layer
    d(3)=1e-9*get(d_lyr,'value'); %spessore (nm)
    %strato 4: subfase sottostante
    if get(subfase,'value')==1
        %AIR
        en(4)=1.00;
        ek(4)=0;
    else
        %WATER
        en(4)=1.33;
        ek(4)=0;
    end
    %range angolare su cui fare il conto
    THETA_ext_deg=expdata(:,1);

    %calcolo costanti dielettriche
    er=en(1)^2-ek(1)^2;
    ei=2*en(1)*ek(1);
    e(1)=complex(er,ei);

    er=en(2)^2-ek(2)^2;
    ei=2*en(2)*ek(2);
    e(2)=complex(er,ei);

    er=en(3)^2-ek(3)^2;
    ei=2*en(3)*ek(3);
    e(3)=complex(er,ei);

    er=en(4)^2-ek(4)^2;
    ei=2*en(4)*ek(4);
    e(4)=complex(er,ei);

    %     --------- CALCOLI VERI ----------
    THETA_ext=THETA_ext_deg/180*pi;
    THETA=pi/4+asin(1/en(1)*sin(THETA_ext-pi/4));

    for jtheta=1:length(THETA);
        theta=THETA(jtheta);
        q1=sqrt(e(1)-en(1)^2*sin(theta)^2)/e(1);
        qn=sqrt(e(end)-en(1)^2*sin(theta)^2)/e(end);
        for j=2:(length(e)-1)
            beta=d(j)*2*pi/lambda*sqrt(e(j)-en(1)^2*sin(theta)^2);
            q=sqrt(e(j)-en(1)^2*sin(theta)^2)/e(j);
            em(j,1,1)=cos(beta);
            em(j,1,2)=-fukso*sin(beta)/q;
            em(j,2,1)=-fukso*sin(beta)*q;
            em(j,2,2)=cos(beta);
        end
        emtot=[1 0;
            0 1];
        for j=2:(length(e)-1)
            emtot1(:,:)=em(j,:,:);
            emtot=emtot*emtot1;
        end

        rp=((emtot(1,1)+emtot(1,2)*qn)*q1-(emtot(2,1)+emtot(2,2)*qn))/...
            ((emtot(1,1)+emtot(1,2)*qn)*q1+(emtot(2,1)+emtot(2,2)*qn));
        tp=2*q1/((emtot(1,1)+emtot(1,2)*qn)*q1+(emtot(2,1)+emtot(2,2)*qn));
        ref=rp*conj(rp);
        tra=tp*conj(tp)/cos(theta)*en(1)*qn;
        REF(jtheta)=ref;
        TRA(jtheta)=tra;
    end

    plot(THETA_ext_deg,REF,expdata(:,1),REF(1)/expdata(1,2)*expdata(:,2),'xk')
    ax=axis;
    text(ax(1)+(ax(2)-ax(1))*.1,ax(3)+(ax(4)-ax(3))*.2,['PRISM: n=',num2str(en(1)),...
        '\newline GOLD:   n=',num2str(en(2)),'+i',num2str(ek(2)),' d=',num2str(d(2)*1e9),'nm',...
        '\newline LAYER: n=',num2str(en(3)),'+i',num2str(ek(3)),' d=',num2str(d(3)*1e9),'nm']);
    title(FNAME)
    pause(.05)
end
