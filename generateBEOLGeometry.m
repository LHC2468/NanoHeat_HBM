clear;clc;close all;

[geometry, geoTable, area_size, metal_density, via_density...
    ,metal_thickness, via_height] = generateBEOLGeometry_main();

% MAIN
function [geometry, geoTable, area_size, metal_density, via_density...
    ,metal_thickness, via_height] = generateBEOLGeometry_main()
  
    % GUI inputs
    prompt = {'Metal density (0-1):','Via Density (0-1):', 'Metal Thickness (um):', 'Via Height (um):', 'Unit Cell Side Length (um):'};
    dlgtitle = 'BEOL Geometry Parameters';
    dims = [1 50];
    default_input = {'0.5','0.1','0.4','0.4','4'};
    user_input = inputdlg(prompt, dlgtitle, dims, default_input);
    
    % inputs to vars
    metal_density = str2double(user_input{1});
    via_density = str2double(user_input{2});
    metal_thickness = str2double(user_input{3});
    via_height = str2double(user_input{4});
    area_size = str2double(user_input{5});
    
    % geometry data structure for intake
    geometry = struct('LayerName',{},'LayerType',{},'Material',{},...
                     'XPosition',{},'YPosition',{},'ZPosition',{},...
                     'XSize',{},'YSize',{},'ZSize',{},...
                     'Top',{},'Right',{});
    
    % base layers (Rear_Cu_Block and Front_Cu_Block)
    geometry = addBaseMetalLayers(geometry, area_size);
    
    % metal layers with specified density
    geometry = createMetalLayers(geometry, metal_density, metal_thickness, area_size);
    
    % vias layers with specified density
    geometry = createVias(geometry, via_density, via_height, area_size);
    
    % struct2table to write to CSV
    geoTable = struct2table(geometry);
    csvwrite_with_headers('BEOL_geometry.csv', geoTable);
    
    fprintf('CSV file generated successfully: BEOL_geometry.csv\n');

    % plot vias in each layer ------------------------------------------ 
    via_layers = ["Via4", "Via5", "Via6", "Via7"];
    metal_layers = ["M5_metal", "M6_metal", "M7_metal", "M8_metal"];

    figure(1);
    for v = 1:length(via_layers)
        id_v = contains({geometry.LayerName}, via_layers(v)); % via index
        x = [geometry(id_v).XPosition];
        y = [geometry(id_v).YPosition];
        s = [geometry(id_v).XSize]; % rectangle side 边长

        id_m = contains({geometry.LayerName}, metal_layers(v)); % metal index
        mx = [geometry(id_m).XPosition];
        my = [geometry(id_m).YPosition];
        mw = [geometry(id_m).XSize]; % line width
        ml = [geometry(id_m).YSize]; % line length

        subplot(2,2,v)
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
            rectangle('Position', [x(j)-s(j)/2, y(j)-s(j)/2, s(j), s(j)], ...
                      'FaceColor', [0.2 0.7 1 0.7], 'EdgeColor', 'b')
        end

        axis equal
        xlim([-area_size/2, area_size/2])
        ylim([-area_size/2, area_size/2])
        title(['V', num2str(v+3),' and M',num2str(v+4),])
        xlabel('X (\mum)')
        ylabel('Y (\mum)')
        grid on
        hold off
    end
    sgtitle(sprintf('Via Viz (Via Density = %.2f, Metal Density = %.2f)'...
        , via_density, metal_density))
    
end
%% make rear and front blocks
function geometry = addBaseMetalLayers(geometry, area_size)
    % rear block
    % FIX location
    rear = struct('LayerName', 'Rear_Cu_Block', 'LayerType', 'Metal', ...
                 'Material', 'copper', 'XPosition', -area_size/2, 'YPosition', -area_size/2, ...
                 'ZPosition', 14.72, 'XSize', area_size, 'YSize', area_size, 'ZSize', 1, ...
                 'Top', area_size/2, 'Right', area_size/2);
    
    % front block
    front = struct('LayerName', 'Front_Cu_Block', 'LayerType', 'Metal', ...
                  'Material', 'copper', 'XPosition', -area_size/2, 'YPosition', -area_size/2, ...
                  'ZPosition', -5, 'XSize', area_size, 'YSize', area_size, 'ZSize', -10, ...
                  'Top', area_size/2, 'Right', area_size/2);
    
    geometry = [geometry; rear; front];
end
%% make metal lines
function geometry = createMetalLayers(geometry, metal_density, thickness, area_size)
    
    num_layers = 5; 
    metal_widths = [0.4, 0.4, 0.4, 0.4, 0.4]; % line width, matching via length  
    z_positions = [0, 0.8, 1.6, 2.4, 3.2];
    min_segment_length = 1; % arbitrary min metal line segment length 
    
    for layer = 1:num_layers
        layer_name_base = sprintf('M%d_metal', layer+3);
        z_pos = z_positions(layer);
        
        % number of metal lines based on density
        num_lines = round(metal_density * area_size/metal_widths(layer)); 
        
        for i = 0:num_lines-1
            % randomize metal line cuts -----------------------------------
            x_pos = -area_size/2 + i * (area_size/num_lines);
            % y_pos = -area_size/2; % flip for horizontal lines
            y_min = -area_size/2;
            y_max = area_size/2 - min_segment_length;
            y_start = (y_max - y_min) * rand() + y_min;
            max_length = area_size/2 - y_start;
            length = min_segment_length + (max_length - min_segment_length) * rand();

            % list the metal structure ------------------------------------
            metal_line = struct('LayerName', sprintf('%s_%d', layer_name_base, i), ...
                              'LayerType', 'Metal', 'Material', 'copper', ...
                              'XPosition', x_pos, 'YPosition', y_start, ...
                              'ZPosition', z_pos, 'XSize', metal_widths(layer), ...
                              'YSize', length, 'ZSize', thickness, ...
                              'Top', y_start + area_size, 'Right', x_pos + metal_widths(layer));
            
            geometry = [geometry; metal_line];
        end
    end
end

%% makes random vias in each layer
function geometry = createVias(geometry, via_density, via_height, area_size)
    via_size = 0.4; % side length of the via (边长，not height)
    num_vias = round(via_density * area_size^2 / (via_size^2)); % number of vias per layer
    via_z_positions = [0.4, 1.2, 2.0, 2.8]; % Z positions for each BEOL via layer
    metal_layer_names = ["M5_metal", "M6_metal", "M7_metal", "M8_metal"];
    % NEED implementation as a user defined array

    % bound via within unit cell
    min_coord = -area_size/2 + via_size/2;
    max_coord =  area_size/2 - via_size/2;
    % CHECK via placement logic, center or corner??

    for v_layer = 1:length(via_z_positions)
        via_name_base = sprintf('Via%d', v_layer+3);
        z_pos = via_z_positions(v_layer);

        % via snapping check --------------------------------------------
        current_metal_name = metal_layer_names(v_layer);
        metal_idxs = contains({geometry.LayerName}, current_metal_name);
        metal_lines = geometry(metal_idxs);

        % metal line centers for via snapping
        % (matching/overlapping whatever you call it)
        metal_centers_x = [metal_lines.XPosition] + [metal_lines.XSize]/2;
        metal_centers_y = [metal_lines.YPosition] + [metal_lines.YSize]/2;

        % positions for overlap checking
        placed_x = [];
        placed_y = [];

        for i = 1:num_vias %---------------------------------------------
            is_overlapping = true;
            attempt = 0;
            max_attempts = 100;

            while is_overlapping && attempt < max_attempts % when could place new
                % core randomization algorithm, in min-max range
                x_pos = (max_coord - min_coord) * rand() + min_coord;
                y_pos = (max_coord - min_coord) * rand() + min_coord;

                % via snapping 
                dists = sqrt((metal_centers_x - x_pos).^2 + (metal_centers_y - y_pos).^2);
                [~, idx_min] = min(dists);
                x_pos = metal_centers_x(idx_min); %(x_pos for x snapping for vertical lines , vise versa)
                %y_pos = metal_centers_y(idx_min);

                % check overlap with previous vias:
                if isempty(placed_x)
                    is_overlapping = false;
                else
                    % distances to all existing vias
                    dists = sqrt((placed_x - x_pos).^2 + (placed_y - y_pos).^2);
                    if all(dists >= via_size)
                        is_overlapping = false;
                    end
                end
                attempt = attempt + 1;
            end

            if attempt == max_attempts
                warning('Could not place all vias without overlap. Placed %d out of %d.', i-1, num_vias);
                break;
            end

            placed_x(end+1) = x_pos;
            placed_y(end+1) = y_pos;

            via = struct('LayerName', sprintf('%s_%d', via_name_base, i), ...
                         'LayerType', 'Via', 'Material', 'copper', ...
                         'XPosition', x_pos, 'YPosition', y_pos, ...
                         'ZPosition', z_pos, 'XSize', via_size, ...
                         'YSize', via_size, 'ZSize', via_height, ...
                         'Top', y_pos + via_size/2, 'Right', x_pos + via_size/2);

            geometry = [geometry; via];
        end
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
