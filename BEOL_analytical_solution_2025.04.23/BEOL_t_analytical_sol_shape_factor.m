clear;

load("BEOL_data.mat");
%Metal W(width), P(pitch), T(thickness), shows M4~M10 (7x layers), in unit of [nm]
%Via P(pitch), T(thickness),shows V3~V9 (7x layers), in unit of [nm]

%Input the BEOL design parameters
size_unit_cell = 4000;  %in unit of [nm]
test_heat_flux = 100;   %in unit of [W/mm2]
T_base         = 0;

metal_line_density  = 0.5;
via_scaling         = 1;


%Thermal conductivity, in unit [W/mK]
k_ILD          = 0.2;
k_metal        = 400;


%Calculate the heat density (only in layer 7 (M10) in this case), in unit [W/m]
Via_P_T(:,1)      = size_unit_cell/via_scaling;
Metal_W_P_T(:,2)  = Metal_W_P_T(:,1)/metal_line_density;
Metal_d           = Metal_W_P_T(:,2) - Metal_W_P_T(:,1);      %Spacing between the two metal lines
q_M(7)            = (test_heat_flux*10^6 * (size_unit_cell*10^-9)^2);

%Calcualte the power density (in unit [W/m]) of each layer
heat_pwr(1:size(Metal_W_P_T,1))         = 0;
heat_pwr_L(1:size(Metal_W_P_T,1))       = 0;
heat_pwr_density(1:size(Metal_W_P_T,1)) = 0;
for i=1:size(Metal_W_P_T,1)
    for j=i:size(Metal_W_P_T,1)
        heat_pwr(i) = heat_pwr(i) + q_M(j);
    end
    heat_pwr_L(i)       = heat_pwr(i)/((size_unit_cell*10^-9)*(size_unit_cell/(Metal_W_P_T(i,1)/metal_line_density)));
    heat_pwr_density(i) = heat_pwr_L(i)/(Metal_W_P_T(i,1)*Metal_W_P_T(i,3)*10^-18);
end

%Calculate the healing length
for i=1:size(Metal_W_P_T,1)
    L_H(i)     = (Metal_W_P_T(i,3)*Via_P_T(i,2)*10^-18 * k_metal/k_ILD)^0.5;
    L(i)       = (Via_P_T(i,1)*10^-9)/via_scaling;
    L_ratio(i) = 2*L_H(i)/L(i);
    eta(i)     = 1 - (L_ratio(i)) * tanh((L_ratio(i))^-1);
end

%Summarize the J_coef of each layer
dT(1:size(Metal_W_P_T,1))     = 0;
S_top(1:size(Metal_W_P_T,1))  = 0;
S_bot(1:size(Metal_W_P_T,1))  = 0;
for i=1:size(Metal_W_P_T,1)
    
    %Calculate the shape factor
    S_top(i) = (Via_P_T(i,2)/Metal_W_P_T(i,1)) - 0.5*(Metal_d(i)/Metal_W_P_T(i,1));
    S_bot(i) = 1 + (Metal_d(i)/Metal_W_P_T(i,1));
    S(i)     = S_top(i) * S_bot(i);


    %Calculate the resistance (in unit [K-m/W])
    R(i)  = (Via_P_T(i,2)*10^-9)/(k_ILD*(Metal_W_P_T(i,1)*10^-9)*2);
    dT(i) = R(i)*eta(i)*heat_pwr_L(i);
    
    T(i) = sum(dT(1:i));

end
    
dT_HBM = sum(dT);
T = T';

