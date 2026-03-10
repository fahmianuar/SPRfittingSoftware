%KRETSCHMANN%


for Theta_i = 30 : 0.5 : 60
    npris = 1.52;
    nref_r = 0.2425;
    nref_i = 3.7;
    n_analyte = 1.77861;
    %^^^^^ these need to be defined before

    %Parameters%
    K_nought=(2*pi)/(632.8*(10^(-9)));
    Omega = K_nought*299792458; %help (obj_Const.c) is speed of light?%
    Thickness = 51.6*(10^-9);

    %Complex Number Modifiers%
    Negative_num = complex(-1,0);
    Imaginary_num = complex(0,1);
    Real_num= complex(1,0);

    %Refractive index%
    Prism_index = complex(npris,0); %index1
    Ref_index = complex(nref_r,nref_i); %index2
    Analyte_index = complex(n_analyte,0); %index3

    %Propagation angles within each layer
    Theta_1 = Theta_i;
    Theta_2 = sqrt(Real_num-((Prism_index/Ref_index)^2)*((sind(Theta_1))^2));
    Theta_3 = sqrt(Real_num-((Prism_index/Analyte_index)^2)*((sind(Theta_1))^2));

    %Terms for reflection at boundaries
    q1 = complex (Prism_index*K_nought*cosd(Theta_1));
    q2 = complex (Ref_index*K_nought*Theta_2);
    q3 = complex (Analyte_index*K_nought*Theta_3);

    if (imag(q2)>0)
        q3 = q3*Negative_num;
    end

    %First layer terms
    Z1 = complex (q1/(Omega*(Prism_index^2)));

    %Second layer terms
    Z2 = complex (q2/(Omega*(Ref_index^2)));
    qProuct = complex (Thickness*q2);

    SA = complex (cosd(qProuct));
    SB = complex (sind(qProuct)*(Imaginary_num*Z2));
    SC = complex (((Imaginary_num*sind(qProuct))/Z2));
    SD = complex (cosd(qProuct));

    %Third layer terms
    Z3 = complex (q3/(Omega*(Analyte_index^2)));

    %Reflectance
    Reflectance_numer = complex (SA +(SB/Z3)-Z1*(SC+(SD/Z3)));
    Reflectance_denom = complex (SA +(SB/Z3)+Z1*(SC+(SD/Z3)));
    Reflectance_temp = complex (Reflectance_numer/Reflectance_denom);



    hold on
    plot(Theta_i, Reflectance_temp, 'o')

end

R = sqrt((real(Reflectance_temp)^2) + (imag(Reflectance_temp)^2));

R_squared = R^2;
