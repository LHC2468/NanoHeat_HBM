load("/Users/LHC/Desktop/BEOL_analytical_solution_2025.04.23/BEOL_data.mat");

%%
clear
% or could manually input for changing in script 
% Metal W(width), P(pitch), T(thickness), shows M4~M10 (7x layers), in unit of [nm]
% Via P(pitch), T(thickness),shows V3~V9 (7x layers), in unit of [nm]
              % W   P   T    M#
Metal_W_P_T = [140 280  280  4;    % M4 [nm]
               140 282  280  5;    % M5
               140 282  280  6;    % M6
               400 800  800  7;    % M7
               400 800  800  8;    % M8
               800 1600 2000 9;    % M9
               800 1600 2000 10];  % M10
           % P    T   V#
Via_P_T = [11200 120  3;           % V3 [nm]
           11200 290  4;           % V4
           11200 290  5;           % V5
           11200 290  6;           % V6
           11200 820  7;           % V7
           11200 820  8;           % V8
           11200 2000 9];          % V9

%% 
clc; clf; close all

% Parameters 
% Input the BEOL design dimensions
size_unit_cell = 11200; %in unit of [nm]
test_heat_flux = 10;    %in unit of [W/mm2]
T_base         = 300;   % could start from room temp? not used, put in T(i=0) later

metal_scaling  = 1;
via_scaling    = 1 * metal_scaling;
%s_j            = [145,148,152,160,165,175,180]; % shape factor 

% Thermal conductivity, in unit [W/mK]
k_ILD          = 0.2;
k_metal        = 400;

% Preallocate 
n_layers = size(Metal_W_P_T,1);
L_H      = zeros(n_layers,1);
L_ratio  = zeros(n_layers,1);
eta      = zeros(n_layers,1);
heat_pwr = zeros(n_layers,1);
R        = zeros(n_layers,1);
dT       = zeros(n_layers,1);
T        = zeros(n_layers,1);
s_j      = zeros(n_layers,1); % shape factor
N_lines      = zeros(n_layers,1);
%% Calculate
% the heat density (only in layer 7 (M10) in this case), in unit [W/m]
heat_layer_num     = 7;
Via_P_T(:,1)       = size_unit_cell/via_scaling;
% number of metal lines each layer
for i=1:heat_layer_num
    N_lines(i) = (size_unit_cell/Metal_W_P_T(i,2))*metal_scaling;
end 

%N_M10_lines        = (size_unit_cell/Metal_W_P_T(7,2))*metal_scaling;
q_M(heat_layer_num)= ((test_heat_flux*10^6) * (size_unit_cell^2 * 10^-18))...
                    /(N_lines(7)*(size_unit_cell*10^-9));

% Calculate the healing length
for i=1:size(Metal_W_P_T,1) % each metal layer
    L_H(i)     = (Metal_W_P_T(i,3)*Via_P_T(i,2)*10^-18 * k_metal/k_ILD)^0.5;
    L_ratio(i) = 2*L_H(i)/(Via_P_T(i,1)*10^-9);
    eta(i)     = 1 - (L_ratio(i)) * tanh((L_ratio(i))^-1);
end

% shape factor s
for k=1:heat_layer_num
    s_j(k) = 4*L_H(k)*10e9/log(8.*Metal_W_P_T(k,3)/(pi.*Metal_W_P_T(k,1)));
end 

% Summarize the J_coef of each layer
heat_pwr(i) = 0;
%T(i) = 0;
%T = T_base * ones(n_layers,1);  % enable T_base BC

for i = 1:n_layers
    % heating
    for j=i:size(Metal_W_P_T,1)
        heat_pwr(i) = heat_pwr(i) + q_M(j);
    end
    % Thermal resistance 
    R(i) = (Via_P_T(i,2)*1e-9) / (k_ILD*(Metal_W_P_T(i,1)*1e-9)*(s_j(i)*sqrt(via_scaling)));
    dT(i) = R(i) * heat_pwr(i);
    
    % Cumulative temperature with base BC
    if i == 1
        T(i) = T_base + dT(i);  % BC at base layer (M4)
    else
        T(i) = T(i-1) + dT(i);  % accumulate temp from previous layers
    end
end

    
dT_HBM = sum(dT); % total temp rise as sum of dT from each layer
T = T';
disp(['Total temp rise is ', num2str(dT_HBM), 'K']);

%% visualization
figure (1);
plot(Metal_W_P_T(:,4), T, 'r-o','LineWidth', 2, 'MarkerFaceColor','w');
xlabel('Metal Layer Number (M#)');
ylabel('Temperature [K]');
title('Temperature from Base vs. Metal Layer Number');
grid on
set(gca, 'FontSize', 12);

for i = 1:n_layers
    text(Metal_W_P_T(i,4), T(i), sprintf('%.1fK', T(i)), ...
        'VerticalAlignment','bottom', 'HorizontalAlignment','right', 'FontSize',10);
end


%% change notes 2025/04/25-26

% edit input array within script 
% sections for preallocation and parameters input
% enable uniform BC setting (currently at 300K)
% attempt to add s_j for each layer
    % need more literature review and potentially experimenta values
% draft data visualization within script
% next, add joule heating? 


% 04/28 notes
% passivation?
% rearrange 16-13 slide eq for different thermal resistance
% scaling for s by w/d 
% ILD layer temp difference? 
% use eq 10 in #2 paper for shape factor 

% study:
% stack metalization? 
% why ohmic heating renders thermal resistance unreliable?
% power grid? could have uniform via density
% thermal impedence sensitive to via path, grounded or no?
    % what percentage of via actually go full length bottom up
% geometry chanages, random via location and line breaks
