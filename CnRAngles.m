%Critical Angles%
Angle_index = (n_analyte/n_prism);
Crit_angle = asin(AngleIndexes)*(180/pi);

%Resonant Angles%

Temp_res = sqrt((e_analyte)*abs(e_3r))/(abs(e_3r))-(e_analyte)/(n_prism);
SPR_angle = asin(TempRes)*(180/pi);

