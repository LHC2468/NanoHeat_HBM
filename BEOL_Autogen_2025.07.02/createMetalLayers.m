%% make metal lines
function geometry = createMetalLayers(geometry, metal_density, metal_line_width, metal_thickness, via_height, area_size, num_layers)
    
    metal_widths(1:num_layers) = metal_line_width;                                                         % line width, matching via length  
    
    for layer = 1:num_layers
        layer_name_base = sprintf('M%d_metal', layer+3);
        z_pos = (via_height+metal_thickness)*(layer-1);
        
                
        % number of metal lines based on density
        num_lines = round(metal_density * area_size/metal_widths(layer)); 
        
        % Generate horizontal (in X-direction) lines for the layer (#=even)
        if rem(layer,2) == 0  %Even number
            for i = 0:num_lines-1
                x_pos = -area_size/2 + i * (area_size/num_lines);
                y_pos = -area_size/2;

                x_size = metal_widths(layer);
                y_size = area_size;

                metal_line = struct('LayerName', sprintf('%s_%d', layer_name_base, i), ...
                    'LayerType', 'Metal', 'Material', 'copper', ...
                    'XPosition', x_pos, 'YPosition', y_pos, ...
                    'ZPosition', z_pos, 'XSize', x_size, ...
                    'YSize', y_size, 'ZSize', metal_thickness);

                % list the metal structure ------------------------------------
                % y_pos change to y_start and area_size change to length
                geometry = [geometry; metal_line];

            end
        end

        % Generate vertical (in Y-direction) lines for the layer (#=odd)
        if rem(layer,2) == 1  %Odd number
            for i = 0:num_lines-1
                x_pos = -area_size/2;
                y_pos = -area_size/2 + i * (area_size/num_lines);       %Flip for horizontal lines

                x_size = area_size;
                y_size = metal_widths(layer);

                metal_line = struct('LayerName', sprintf('%s_%d', layer_name_base, i), ...
                    'LayerType', 'Metal', 'Material', 'copper', ...
                    'XPosition', x_pos, 'YPosition', y_pos, ...
                    'ZPosition', z_pos, 'XSize', x_size, ...
                    'YSize', y_size, 'ZSize', metal_thickness);

                % list the metal structure ------------------------------------
                % y_pos change to y_start and area_size change to length
                geometry = [geometry; metal_line];

            end
        end
      

        % (Not used at this time) randomize metal line cuts -----------------------------------
        % y_min = -area_size/2;
        % y_max = area_size/2 - min_segment_length;
        % y_start = (y_max - y_min) * rand() + y_min;
        % max_length = area_size/2 - y_start;
        % length = min_segment_length + (max_length - min_segment_length) * rand();
        
    end
end