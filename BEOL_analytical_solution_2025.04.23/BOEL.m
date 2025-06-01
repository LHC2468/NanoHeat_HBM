clc
clear 
close all

% parameters 
k_Cu = 387; % W/m*K
k_dielec = 0.1; 
k_oxide = 0.2; 
k_Si = 130; 


% get dT for each layer, per layer and total temp drop, which gives
% analytical k 
% no joule heating, use per unit length heat flux instead

% w is width of metal line, s as shape factor P236 Lavine book 
% 160 kinda works but should vary for each layer 
