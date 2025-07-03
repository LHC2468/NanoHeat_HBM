%% make metal lines
function geometry = createMetalLayersCuts(geometry, metal_density, metal_line_width, metal_thickness, via_height, area_size, num_layers)
    
    metal_widths(1:num_layers) = metal_line_width;                                                         % line width, matching via length  
    min_segment_length = area_size * 0.05; 
    max_segments_per_line = 6; 

    for layer = 1:num_layers
        layer_name_base = sprintf('M%d_metal', layer+3);
        z_pos = (via_height+metal_thickness)*(layer-1);
             
        % number of metal lines based on density
        num_lines = round(metal_density * area_size/metal_widths(layer)); 
      
        % Generate vertical (in Y-direction) lines for the layer (#=odd)
        if rem(layer,2) == 1  %Odd number
            for i = 0:num_lines-1
                y_pos = -area_size/2 + i * (area_size/num_lines);
                x_min = -area_size/2;
                x_max = area_size/2;
                num_segments = randi([1, max_segments_per_line]);
                intervals = zeros(max_segments_per_line,2); % gap b/t segments 
            
                seg_count = 0;
                attempts = 0;
                max_attempts = 100; % cap total loops 
                while seg_count < num_segments && attempts < max_attempts
                    seg_length = min_segment_length + (area_size-min_segment_length)*rand();
                    x_start = x_min + (x_max - x_min - seg_length)*rand();
                    x_end = x_start + seg_length;
            
                    if ~check_overlap(x_start, x_end, intervals)
                        seg_count = seg_count + 1;
                        intervals = [intervals; x_start, x_end];
                        x_size = seg_length;
                        y_size = metal_widths(layer);
                        metal_line = struct('LayerName', sprintf('%s_%d_%d', layer_name_base, i, seg_count), ...
                            'LayerType', 'Metal', 'Material', 'copper', ...
                            'XPosition', x_start, 'YPosition', y_pos, ...
                            'ZPosition', z_pos, 'XSize', x_size, ...
                            'YSize', y_size, 'ZSize', metal_thickness);
                        geometry = [geometry; metal_line];
                    end
                    attempts = attempts + 1;
                end
            end
        end

        % Generate horizontal (in X-direction) lines for the layer (#=even)
        if rem(layer,2) == 0  %Even number
            for i = 0:num_lines-1
                x_pos = -area_size/2 + i * (area_size/num_lines);
                y_min = -area_size/2;
                y_max = area_size/2;
                num_segments = randi([1, max_segments_per_line]);
                intervals = zeros(max_segments_per_line,2); % gap b/t segments 
            
                seg_count = 0;
                attempts = 0;
                max_attempts = 100; % cap total loops 
                while seg_count < num_segments && attempts < max_attempts
                    seg_length = min_segment_length + (area_size-min_segment_length)*rand();
                    y_start = y_min + (y_max - y_min - seg_length)*rand();
                    y_end = y_start + seg_length;
            
                    if ~check_overlap(y_start, y_end, intervals)
                        seg_count = seg_count + 1;
                        intervals = [intervals; y_start, y_end];
                        y_size = seg_length;
                        x_size = metal_widths(layer);
                        metal_line = struct('LayerName', sprintf('%s_%d_%d', layer_name_base, i, seg_count), ...
                            'LayerType', 'Metal', 'Material', 'copper', ...
                            'XPosition', x_pos, 'YPosition', y_start, ...
                            'ZPosition', z_pos, 'XSize', x_size, ...
                            'YSize', y_size, 'ZSize', metal_thickness);
                        geometry = [geometry; metal_line];
                    end
                    attempts = attempts + 1;
                end
            end
            
        end
    end
% loops end, then function end, too many ends...      
end

%% check for line segment overlap

function is_overlap = check_overlap(new_start, new_end, existing_intervals)
    is_overlap = false;
    for k = 1:size(existing_intervals, 1)
        ex_start = existing_intervals(k, 1);
        ex_end   = existing_intervals(k, 2);
        % Overlap if intervals intersect
        if new_start < ex_end && new_end > ex_start
            is_overlap = true;
            return;
        end
    end
end