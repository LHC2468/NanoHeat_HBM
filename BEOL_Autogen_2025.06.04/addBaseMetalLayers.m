%% make rear and front blocks
function geometry = addBaseMetalLayers(geometry, area_size, metal_thickness, via_height, num_layers)
    % Rear Cu block
    % FIX location
    z_pos = (metal_thickness + via_height)*(num_layers-1) + metal_thickness + 1;
    rear_Cu = struct('LayerName', 'Rear_Cu_Block', 'LayerType', 'Metal', ...
                 'Material', 'copper', 'XPosition', -area_size/2, 'YPosition', -area_size/2, ...
                 'ZPosition', z_pos, 'XSize', area_size, 'YSize', area_size, 'ZSize', 10, ...
                 'Top', area_size/2, 'Right', area_size/2);
    
    % Bond layer
    z_pos = (metal_thickness + via_height)*(num_layers-1) + metal_thickness;
    Bond = struct('LayerName', 'Bond_layer', 'LayerType', 'Dielectric', ...
                 'Material', 'Material_bond_layer', 'XPosition', -area_size/2, 'YPosition', -area_size/2, ...
        'ZPosition', z_pos, 'XSize', area_size, 'YSize', area_size, 'ZSize', 1, ...
        'Top', area_size/2, 'Right', area_size/2);

    % Dielectric layer
    Dielectric = struct('LayerName', 'Dielectric_layer', 'LayerType', 'Dielectric', ...
                 'Material', 'Material_Dielectric', 'XPosition', -area_size/2, 'YPosition', -area_size/2, ...
        'ZPosition', 0, 'XSize', area_size, 'YSize', area_size, 'ZSize', z_pos, ...
        'Top', area_size/2, 'Right', area_size/2);

    % Front Si
    front_Si = struct('LayerName', 'Front_Si', 'LayerType', 'Substrate', ...
                 'Material', 'silicon', 'XPosition', -area_size/2, 'YPosition', -area_size/2, ...
                  'ZPosition', 0, 'XSize', area_size, 'YSize', area_size, 'ZSize', -5, ...
                  'Top', area_size/2, 'Right', area_size/2);
    
    % front block
    front_Cu = struct('LayerName', 'Front_Cu_Block', 'LayerType', 'Metal', ...
                  'Material', 'copper', 'XPosition', -area_size/2, 'YPosition', -area_size/2, ...
                  'ZPosition', -5, 'XSize', area_size, 'YSize', area_size, 'ZSize', -10, ...
                  'Top', area_size/2, 'Right', area_size/2);
    
    geometry = [geometry; rear_Cu; Bond; Dielectric; front_Si; front_Cu];
end