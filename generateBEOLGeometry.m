clear;clc;close all;

[geometry, geoTable, area_size, metal_density, via_density...
    ,metal_thickness, via_height] = generateBEOLGeometry_main();

% MAIN
function [geometry, geoTable, area_size, metal_density, via_density...
    ,metal_thickness, via_height] = generateBEOLGeometry_main()
  
    % GUI inputs
    prompt = {'Number of Mx layers (<7):', 'Metal Line width (um):', 'Metal Thickness (um):', 'Metal line density (0-1):', 'Via Height (um):', 'Via population portion (0-1):', 'Unit Cell Side Length (um):'};
    dlgtitle = 'BEOL Geometry Parameters';
    dims = [1 50];
    default_input = {'5','0.4','0.4','0.5','0.4','0.5','4'};
    user_input = inputdlg(prompt, dlgtitle, dims, default_input);
    
    % inputs to vars
    num_layers       = str2double(user_input{1});
    metal_line_width = str2double(user_input{2});
    metal_thickness  = str2double(user_input{3});
    metal_density    = str2double(user_input{4});
    via_height       = str2double(user_input{5});
    via_density      = str2double(user_input{6});
    area_size        = str2double(user_input{7});
    
    % geometry data structure for intake
    geometry = struct('LayerName',{},'LayerType',{},'Material',{},...
                     'XPosition',{},'YPosition',{},'ZPosition',{},...
                     'XSize',{},'YSize',{},'ZSize',{},...
                     'Top',{},'Right',{});
    
    
    % metal layers with specified density
    geometry = createMetalLayers(geometry, metal_density, metal_line_width, metal_thickness, via_height, area_size, num_layers);
    
    % vias layers with specified density
    geometry = createVias(geometry, via_density, via_height, metal_line_width, metal_thickness, area_size, num_layers);
    
    % base layers (Rear_Cu_Block and Front_Cu_Block)
    geometry = addBaseMetalLayers(geometry, area_size, metal_thickness, via_height, num_layers);
    
    % struct2table to write to CSV
    geoTable = struct2table(geometry);
    csvwrite_with_headers('BEOL_geometry.csv', geoTable);
    
    fprintf('CSV file generated successfully: BEOL_geometry.csv\n');

    % plot vias in each layer ------------------------------------------ 
    via_layers = ["Via4", "Via5", "Via6", "Via7", "Via8", "Via9", "Via10"];
    metal_layers = ["M4_metal", "M5_metal", "M6_metal", "M7_metal", ...
                   "M8_metal", "M9_metal", "M10_metal"];

    figure(1);
    for lv = 1:num_layers    %[Yujui] Change from v to lv
        
        id_v = contains({geometry.LayerName}, via_layers(min(lv,length(via_layers)))); % via index
        x = [geometry(id_v).XPosition];
        y = [geometry(id_v).YPosition];
        s = [geometry(id_v).XSize]; % rectangle side 边长

        id_m = contains({geometry.LayerName}, metal_layers(min(lv,length(metal_layers)))); % metal index
        mx = [geometry(id_m).XPosition];
        my = [geometry(id_m).YPosition];
        mw = [geometry(id_m).XSize]; % line width
        ml = [geometry(id_m).YSize]; % line length

        subplot(2,4,lv)
        hold on
        % unit cell box
        rectangle('Position', [-area_size/2, -area_size/2, area_size, area_size], ...
                  'EdgeColor', 'r', 'LineWidth', 2)

        % metal line boxes
        for i = 1:numel(mx)
            rectangle('Position', [mx(i), my(i), mw(i), ml(i)], ...
                      'FaceColor', [1 0.8 0.3 0.5], 'EdgeColor', 'y')

        end

        % via boxes
        for j = 1:numel(x)
            % rectangle('Position', [x(j)-s(j)/2, y(j)-s(j)/2, s(j), s(j)], ...
            %           'FaceColor', [0.2 0.7 1 0.7], 'EdgeColor', 'b')
            rectangle('Position', [x(j), y(j), s(j), s(j)], ...
                      'FaceColor', [0.2 0.7 1 0.7], 'EdgeColor', 'b')
        end

        axis equal
        xlim([-area_size/2, area_size/2])
        ylim([-area_size/2, area_size/2])
        title(['M', num2str(lv+3),' and V',num2str(lv+3),])
        xlabel('X (\mum)')
        ylabel('Y (\mum)')
        grid on
        hold off
    end
    sgtitle(sprintf('Via Vizualization (Via Density = %.2f, Metal Density = %.2f)'...
        , via_density, metal_density))
    
end


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
                 'Material', 'silicon_dioxide', 'XPosition', -area_size/2, 'YPosition', -area_size/2, ...
        'ZPosition', z_pos, 'XSize', area_size, 'YSize', area_size, 'ZSize', 1, ...
        'Top', area_size/2, 'Right', area_size/2);

    % Dielectric layer
    Dielectric = struct('LayerName', 'Bond_layer', 'LayerType', 'Dielectric', ...
                 'Material', 'silicon_dioxide', 'XPosition', -area_size/2, 'YPosition', -area_size/2, ...
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


%% make metal lines
function geometry = createMetalLayers(geometry, metal_density, metal_line_width, metal_thickness, via_height, area_size, num_layers)
    
    metal_widths(1:num_layers) = metal_line_width;                                                         % line width, matching via length  
    
    for layer = 1:num_layers
        layer_name_base = sprintf('M%d_metal', layer+3);
        z_pos = (via_height+metal_thickness)*(layer-1);
        
                
        % number of metal lines based on density
        num_lines = round(metal_density * area_size/metal_widths(layer)); 
        
        % Generate vertical (in Y-direction) lines for the layer (#=even)
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
                    'YSize', y_size, 'ZSize', metal_thickness, ...
                    'Top', y_pos + area_size, 'Right', x_pos + metal_widths(layer));

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
                    'YSize', y_size, 'ZSize', metal_thickness, ...
                    'Top', y_pos + area_size, 'Right', x_pos + metal_widths(layer));

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


%% makes random vias in each layer
function geometry = createVias(geometry, via_density, via_height, metal_line_width, metal_thickness, area_size, num_layers)
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




        % Place the Vias at the intersections based on the assigned density
        via_number = length(intersect_x);
        for i=1:via_number
            if rand() <= via_density
                x_pos  = intersect_x(i);
                y_pos  = intersect_y(i);

                via = struct('LayerName', sprintf('%s_%d', via_name_base, i), ...
                    'LayerType', 'Via', 'Material', 'copper', ...
                    'XPosition', x_pos, 'YPosition', y_pos, ...
                    'ZPosition', z_pos, 'XSize', via_size, ...
                    'YSize', via_size, 'ZSize', via_height, ...
                    'Top', y_pos + via_size, 'Right', x_pos + via_size);

                geometry = [geometry; via];

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


%%
function csvwrite_with_headers(filename, table_data)
    % write table data with headers to CSV
    fid = fopen(filename, 'w');
    
    % headers
    headers = table_data.Properties.VariableNames;
    fprintf(fid, '%s', headers{1});
    for i = 2:length(headers)
        fprintf(fid, ',%s', headers{i});
    end
    fprintf(fid, '\n');
    
    % write
    for i = 1:height(table_data)
        % first column (string)
        if iscell(table_data{i,1})
            fprintf(fid, '%s', table_data{i,1}{1});
        else
            fprintf(fid, '%g', table_data{i,1});
        end
        
        % remaining columns (num)
        for j = 2:width(table_data)
            if iscell(table_data{i,j})
                fprintf(fid, ',%s', table_data{i,j}{1});
            else
                fprintf(fid, ',%g', table_data{i,j});
            end
        end
        fprintf(fid, '\n');
    end
    
    fclose(fid);
end

