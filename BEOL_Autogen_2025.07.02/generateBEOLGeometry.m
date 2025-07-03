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
    default_input = {'7','0.14','0.28','0.5','0.29','1','3.92'};
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
                     'XSize',{},'YSize',{},'ZSize',{});
    
    
    % metal layers with specified density
    geometry = createMetalLayersCuts(geometry, metal_density, metal_line_width, metal_thickness, via_height, area_size, num_layers);
    
    % vias layers with specified density
    geometry = createVias_random(geometry, via_density, via_height, metal_line_width, metal_thickness, area_size, num_layers);
    
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

