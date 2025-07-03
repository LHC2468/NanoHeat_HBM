%% makes random vias in each layer
function geometry = createVias_con_stagger_cascade(geometry, via_density, via_height, metal_line_width, metal_thickness, area_size, num_layers)
    via_size       = metal_line_width; % side length of the via (边长，not height)
    num_layers_via = num_layers - 1;


    % %Assign the z position of the via (Note: "# of via layer" is equal to "# of Mx layer - 1")
    % via_z_positions(1:num_layers_via)  = linspace(0,(num_layers_via-1)*via_height, num_layers_via);      % Assume same height for each meteal layer
    % via_z_positions                    = via_z_positions + metal_thickness;

    metal_layer_names = ["M4_metal", "M5_metal", "M6_metal", "M7_metal", "M8_metal", "M9_metal", "M10_metal"];
    % NEED implementation as a user defined array

    % % bound via within unit cell
    % min_coord = -area_size/2 + via_size/2;
    % max_coord =  area_size/2 - via_size/2;
    % % CHECK via placement logic, center or corner??
    % num_vias       = round(via_density * area_size^2 / (via_size^2)); % number of vias per layer


    for v_layer = 1:num_layers_via
        via_name_base = sprintf('Via%d', v_layer+3);          
        z_pos = (via_height+metal_thickness)*v_layer - via_height;


        % Extract the locations of the metal lines
        current_metal_name    = metal_layer_names(v_layer);
        metal_idxs_v          = contains({geometry.LayerName}, current_metal_name);
        metal_lines_v         = geometry(metal_idxs_v);
        num_lines_v           = sum(metal_idxs_v);

        current_metal_name    = metal_layer_names(v_layer+1);
        metal_idxs_v_1        = contains({geometry.LayerName}, current_metal_name);
        metal_lines_v_1       = geometry(metal_idxs_v_1);
        num_lines_v_1         = sum(metal_idxs_v_1);


        % Extract the intersect coordinate (origin) of the Mx and Mx_1
        metal_v_origin_x   = [metal_lines_v.XPosition];
        metal_v_origin_y   = [metal_lines_v.YPosition];

        metal_v_1_origin_x = [metal_lines_v_1.XPosition];
        metal_v_1_origin_y = [metal_lines_v_1.YPosition];


        if rem(v_layer+3,2) == 0  %Even number
            for i=1:num_lines_v
                for j=1:num_lines_v_1
                    intersect_x(j+num_lines_v*(i-1)) = metal_v_origin_y(i);
                    intersect_y(j+num_lines_v*(i-1)) = metal_v_1_origin_x(j);
                end
            end
        end

        if rem(v_layer+3,2) == 1  %Odd number
            for i=1:num_lines_v
                for j=1:num_lines_v_1
                    intersect_x(j+num_lines_v*(i-1)) = metal_v_origin_x(i);
                    intersect_y(j+num_lines_v*(i-1)) = metal_v_1_origin_y(j);
                end
            end
        end




        % Place the Vias at the intersections every num_line_v_1 + 1
        via_number = length(intersect_x);

        % Assign the vias periodically [This is for CASCADE]
        % One cycle is completed when the via touches the top-most location
        % Initialize the cycle number
        cycle_num = 1;
        for i=1:via_number
            % Via location is based on the number of cycle          
            if rem(i-((v_layer-1))-(cycle_num-1),round((1/via_density)*(num_lines_v_1+1))) == 1

                x_pos  = intersect_x(i);
                y_pos  = intersect_y(i);

                via = struct('LayerName', sprintf('%s_%d', via_name_base, i), ...
                    'LayerType', 'Via', 'Material', 'copper', ...
                    'XPosition', x_pos, 'YPosition', y_pos, ...
                    'ZPosition', z_pos, 'XSize', via_size, ...
                    'YSize', via_size, 'ZSize', via_height);

                geometry = [geometry; via];

                % When complete one cycle (via touches the top-most line
                if rem(i, num_lines_v_1*(num_lines_v-(v_layer-1))) == 0
                    cycle_num = cycle_num + 1;
                end
            end               
        end



        % positions for overlap checking
        placed_x = [];
        placed_y = [];

        % for i = 1:num_vias %---------------------------------------------
        %     is_overlapping = true;
        %     attempt = 0;
        %     max_attempts = 100;
        % 
        %     while is_overlapping && attempt < max_attempts % when could place new
        %         % core randomization algorithm, in min-max range
        %         x_pos = (max_coord - min_coord) * rand() + min_coord;
        %         y_pos = (max_coord - min_coord) * rand() + min_coord;
        % 
        %         % via snapping
        %         dists = sqrt((metal_v_origin_x - x_pos).^2 + (metal_v_origin_y - y_pos).^2);
        %         [~, idx_min] = min(dists);
        %         x_pos = metal_v_origin_x(idx_min); %(x_pos for x snapping for vertical lines , vise versa)
        %         %y_pos = metal_centers_y(idx_min);
        % 
        %         % check overlap with previous vias:
        %         if isempty(placed_x)
        %             is_overlapping = false;
        %         else
        %             % distances to all existing vias
        %             dists = sqrt((placed_x - x_pos).^2 + (placed_y - y_pos).^2);
        %             if all(dists >= via_size)
        %                 is_overlapping = false;
        %             end
        %         end
        %         attempt = attempt + 1;
        %     end
        % 
        %     if attempt == max_attempts
        %         warning('Could not place all vias without overlap. Placed %d out of %d.', i-1, num_vias);
        %         break;
        %     end
        % 
        %     placed_x(end+1) = x_pos;
        %     placed_y(end+1) = y_pos;
        % 
        %     via = struct('LayerName', sprintf('%s_%d', via_name_base, i), ...
        %         'LayerType', 'Via', 'Material', 'copper', ...
        %         'XPosition', x_pos-via_size/2, 'YPosition', y_pos-via_size/2, ...
        %         'ZPosition', z_pos, 'XSize', via_size, ...
        %         'YSize', via_size, 'ZSize', via_height, ...
        %         'Top', y_pos + via_size/2, 'Right', x_pos + via_size/2);
        % 
        %     geometry = [geometry; via];
        % end


    end
end