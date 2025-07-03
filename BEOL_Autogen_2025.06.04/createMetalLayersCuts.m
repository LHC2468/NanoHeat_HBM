%% make metal lines
function geometry = createMetalLayersCuts(geometry, metal_density, metal_line_width, metal_thickness, via_height, area_size, num_layers)
    
    metal_widths(1:num_layers) = metal_line_width;                                                         % line width, matching via length  
    min_segment_length = area_size * 0.1; 
    max_segments_per_line = 5; 

    for layer = 1:num_layers
        layer_name_base = sprintf('M%d_metal', layer+3);
        z_pos = (via_height+metal_thickness)*(layer-1);
             
        % number of metal lines based on density
        num_lines = round(metal_density * area_size/metal_widths(layer)); 
      
        % Generate horizontal (in X-direction) lines for the layer (#=even)
        if rem(layer,2) == 0  %Even number
            for i = 0:num_lines-1
            y_pos = -area_size/2 + i * (area_size/num_lines);
            x_min = -area_size/2;
            x_max = area_size/2;
            num_segments = randi([1, max_segments_per_line]);
                for seg = 1:num_segments
                    seg_length = min_segment_length + (area_size-min_segment_length)*rand();
                    x_start = x_min + (x_max - x_min - seg_length)*rand();
                    x_size = seg_length;
                    y_size = metal_widths(layer);
                    metal_line = struct('LayerName', sprintf('%s_%d_%d', layer_name_base, i, seg), ...
                        'LayerType', 'Metal', 'Material', 'copper', ...
                        'XPosition', x_start, 'YPosition', y_pos, ...
                        'ZPosition', z_pos, 'XSize', x_size, ...
                        'YSize', y_size, 'ZSize', metal_thickness);
                    geometry = [geometry; metal_line];
                end
            end
        end

        % Generate vertical (in Y-direction) lines for the layer (#=odd)
        if rem(layer,2) == 1  %Odd number
            for i = 0:num_lines-1
            x_pos = -area_size/2 + i * (area_size/num_lines);
            y_min = -area_size/2;
            y_max = area_size/2;
            num_segments = randi([1, max_segments_per_line]);
                for seg = 1:num_segments
                    seg_length = min_segment_length + (area_size-min_segment_length)*rand();
                    x_start = y_min + (y_max - y_min - seg_length)*rand();
                    x_size = seg_length;
                    y_size = metal_widths(layer);
                    metal_line = struct('LayerName', sprintf('%s_%d_%d', layer_name_base, i, seg), ...
                        'LayerType', 'Metal', 'Material', 'copper', ...
                        'XPosition', x_start, 'YPosition', x_pos, ...
                        'ZPosition', z_pos, 'XSize', x_size, ...
                        'YSize', y_size, 'ZSize', metal_thickness);
                    geometry = [geometry; metal_line];
                end
            end
        end
    end
% loops end, then function end, too many ends...      
end