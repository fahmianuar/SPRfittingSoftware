Reflectance;

Reflectance_4L;
Reflectance_WIM;

%Optical Fiber Transmission

Core_diameter = cdiam*10^-6;
Theta_i;
Core_radius = Core_diameter/2;
Fiber_length
Aux = (Fiber_length/Core_radius)*tan(Theta_i);

Transmission = R^Aux;

%Inputs
%all initialized is in their unit abbreviations
%small letters do not have their abbreviations calibrated
wavelength; 
d_silica; 
d_metal;
d_analyte;
n_prism;
eps_real;
eps_imaginary;

I_num = complex (0,1);
K_naught = (2*pi)/(wavelength*10^-9);
D_naught = d_silica*10^-6;
D_1 = d_metal*10^-9;
D_2 = d_a*10^-9; %analyte?? not sure %naughtsilica 1metal 2analyte

n_naught = complex (n_prism,0);
eps_1 = complex (eps_real,eps_imaginary);
n_analyte = complex (n_a,0);

%Phase factor (Delta)
Delta_0 = K_naught*D_naught*(complex (sqrt(n_naught^2))-(n_naught^2)*(sin(Theta_i)^2));
Delta_1 = K_naught*D_1*(complex (sqrt(n_naught^2))-(n_naught^2)*(sin(Theta_i)^2));
Delta_2 = K_naught*D_2*(complex(sqrt(n_analyte^2))-(n_naught^2)*(sin(Theta_i)^2));


%Optical Admittance (eta) as a function of the polarization states
%First Layer: Silica

etaS_Wave_Silica = complex (sqrt(n_naught^2)-(n_naught^2)*(sin(Theta_i)^2));
etaP_wave_Silica = complex ((n_naught^2)/etaS_Wave_Silica);

%Second Layer: Metal

etaS_Wave_Metal = complex (sqrt(eps_1-(n_naught^2)*(sin(Theta_i)^2)));
etaP_Wave_Metal = complex (eps_1/etaS_Wave_Metal);

%Third Layer: Analyte

etaS_Wave_Analyte = complex(sqrt((n_analyte^2)-(n_naught^2)*(sin(Theta_i)^2)));
etaP_Wave_Analyte = complex ((n_analyte^2)/etaS_Wave_Analyte);




%Characteristic Matrix of the layered system
%First Layer: Silica

Matrix11_Silica = complex (cos(Delta_0));
Matrix12_Silica = complex (-I_num*sin(Delta_0/etaP_wave_Silica));
Matrix21_Silica = complex (-I_num*sin(Delta_0)*etaP_wave_Silica);
Matrix22_Silica = complex (cos (delta_0));

%Second layer: Metal

Matrix11_Metal = complex (cos(Delta_1));
Matrix12_Metal = complex (-I_num*sin(Delta_1)/etaP_Wave_Metal);
Matrix21_Metal = complex (-I_num*sin(Delta_1)*etaP_Wave_Metal);
Matrix22_Metal = complex (cos(Delta_1));

%Total Characteristic Matrix

TotalCMatrix11 = complex (Matrix11_Silica*Matrix11_Metal + Matrix12_Silica*Matrix21_Metal);
TotalCMatrix12 = complex (Matrix11_Silica*Matrix12_Metal + Matrix12_Silica*Matrix22_Metal);
TotalCMatrix21 = complex (Matrix21_Silica*Matrix11_Metal + Matrix22_Silica*Matrix21_Metal);
TotalCMatrix22 = complex (Matrix21_Silica*Matrix12_Metal + Matrix22_Silica*Matrix22_Metal);

%Fresnel Reflection Coefficients

Fresnel_Numerator = complex ((TotalCMatrix11 + TotalCMatrix12*etaP_Wave_Analyte)*etaP_wave_Silica - (TotalCMatrix21 + TotalCMatrix22*etaP_Wave_Analyte));
Fresnel_Denominator = complex ((TotalCMatrix11 + TotalCMatrix12*etaP_Wave_Analyte)*etaP_wave_Silica + (TotalCMatrix21 + TotalCMatrix22*etaP_Wave_Analyte));

FresnelR1 = complex (Fresnel_Numerator/Fresnel_Denominator);

R = sqrt(real(FresnelR1)^2 + imaginary(FresnelR1)^2);
Rsquared = R^2;
