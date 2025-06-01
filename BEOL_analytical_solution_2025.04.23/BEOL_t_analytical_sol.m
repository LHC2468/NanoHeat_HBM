clear
clc

load("/Users/LHC/Desktop/BEOL_analytical_solution_2025.04.23/BEOL_data.mat");
%Metal W(width), P(pitch), T(thickness), shows M4~M10 (7x layers), in unit of [nm]
%Via P(pitch), T(thickness),shows V3~V9 (7x layers), in unit of [nm]

%Input the BEOL design parameters
size_unit_cell = 11200; %in unit of [nm]
test_heat_flux = 10;   %in unit of [W/mm2]
T_base         = 0;

metal_scaling  = 1;
via_scaling    = 1 * metal_scaling;


%Thermal conductivity, in unit [W/mK]
k_ILD          = 0.2;
k_metal        = 400;


%Calculate the heat density (only in layer 7 (M10) in this case), in unit [W/m]
Via_P_T(:,1)      = size_unit_cell/via_scaling;
N_M10_lines       = (size_unit_cell/Metal_W_P_T(7,2))*metal_scaling;
q_M(7)            = ((test_heat_flux*10^6) * (size_unit_cell^2 * 10^-18))/(N_M10_lines*(size_unit_cell*10^-9));


%Calculate the healing length
for i=1:size(Metal_W_P_T,1)
    L_H(i)     = (Metal_W_P_T(i,3)^2*Via_P_T(i,2)*10^-27 * k_metal/k_ILD)^0.5;
    L_ratio(i) = 2*L_H(i)/(Via_P_T(i,1)*10^-9);
    eta(i)     = 1 - (L_ratio(i)) * tanh((L_ratio(i))^-1);
end

%Summarize the J_coef of each layer
heat_pwr(i) = 0;
T(i) = 0;
for i=1:size(Metal_W_P_T,1)
    for j=i:size(Metal_W_P_T,1)
        heat_pwr(i) = heat_pwr(i) + q_M(j);
    end

    %Calculate the resistance (in unit [K-m/W])
    R(i)  = (Via_P_T(i,2)*10^-9)/(k_ILD*(Metal_W_P_T(i,1)*10^-9) * (160 * via_scaling^0.5) );
    dT(i) = R(i)*heat_pwr(i);
    
    T(i) = sum(dT(1:i));
end
    
dT_HBM = sum(dT);
T = T';

