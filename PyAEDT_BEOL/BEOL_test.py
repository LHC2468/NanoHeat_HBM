# PyAEDT script to automate creation of BEOL geometry from CSV 
# May 2025
import os
import csv
from pyaedt import Hfss
from pyaedt.desktop import Desktop

def main():
    # working directory and csv path
    working_dir = os.getcwd()
    beol_csv = os.path.join(working_dir, "C:\\Users\\xx\\Desktop\\PyAEDT_BEOL\\BEOL_test_table.csv")
    
    # no need to call aedt version
    # desktop = Desktop("2024.2"), also doens't support Icepak classic...
    
    project_name = "PyAEDT_test_supervia_M10-8_2025.05"
    design_name = "PyAEDT_test_HBM_2025.04.0"
    
    # create project
    hfss = Hfss(project=project_name, design=design_name, solution_type="SBR+")
    
    # call import from csv function
    layers = import_beol_from_csv(beol_csv)
    
    # BEOL structure by calling functions below
    beol_objects = create_beol_structure(hfss, layers)
    thermal_objects = create_thermal_components(hfss)
    organize_project_structure(hfss, beol_objects, thermal_objects)

    hfss.save_project()
    print(f"Project {project_name} saved successfully")

# Functions ________________________________________________________

def import_beol_from_csv(file_path):
    """Import BEOL structure definition from a CSV file."""
    layers = []
    
    try:
        with open(file_path, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                if not row['LayerName']:  # Skip rows without LayerName??
                    continue
                layers.append(row)
        print(f"Successfully imported {len(layers)} layers from CSV")
    except Exception as e:
        print(f"Error importing layers from CSV: {str(e)}")
        
    return layers


def create_beol_structure(hfss, layers):
    """Create the BEOL structure based on the imported CSV data."""
    metal_layers = {}
    dielectric_layers = {}
    vias = {}
    Si = {}
    
    for layer in layers:
        try:
            name = layer['LayerName']
            layer_type = layer['LayerType']  
            material = layer['Material']
            x_pos = float(layer['XPosition'])
            y_pos = float(layer['YPosition'])
            z_pos = float(layer['ZPosition'])
            z_size = float(layer['ZSize'])
            x_size = float(layer['XSize'])
            y_size = float(layer['YSize'])
        except KeyError as e:
            print(f"Missing key in layer data: {e}")
            print(f"Available keys: {layer.keys()}")
            continue
        
        #if layer_type == "Metal" and "metal_interconnect" in name:
        if layer_type == "Metal":
            # assign metal geometries and property
            metal_obj = hfss.modeler.create_box(
                #origin=[-x_size/2, -y_size/2, z_pos], 
                origin=[x_pos, y_pos, z_pos],  
                sizes=[x_size, y_size, z_size],     
                name=name,
                material=material                      
            )
            metal_layers[name] = metal_obj
            print(f"Created {name}")
            
        elif layer_type == "Dielectric":

            diel_obj = hfss.modeler.create_box(
                origin=[-x_size/2, -y_size/2, z_pos],   
                sizes=[x_size, y_size, z_size],    
                name=name,
                material=material                   
            )
            dielectric_layers[name] = diel_obj
            print(f"Created {name}")
            
        elif layer_type == "Via":

            via_obj = hfss.modeler.create_box(
                origin=[x_pos, y_pos, z_pos],  
                sizes=[x_size, y_size, z_size],   
                name=name,
                material=material  
            )
            vias[name] = via_obj  
            print(f"Created via: {name}")

        elif layer_type == "Substrate":

            Si_obj = hfss.modeler.create_box(
                origin=[x_pos, y_pos, z_pos],  
                sizes=[x_size, y_size, z_size],   
                name=name,
                material=material  
            )
            Si[name] = Si_obj  
            print(f"Created via: {name}")    

    
    return {
        "metal_layers": metal_layers,
        "dielectric_layers": dielectric_layers,
        "vias": vias
    }


def create_thermal_components(hfss):
    
    # Front_Cu_block_minz component
    #cu_block = hfss.modeler.create_box(
    #    origin=[-30, -30, -5],  
    #    sizes=[60, 60, 5],      
    #    name="Front_Cu_block_minz",
    #    material="copper"       
    #)
    
    # Heat_source component
    heat_source = hfss.modeler.create_rectangle(
        position=[-2, -2, 24.72],  
        dimension_list=[4, 4],  
        name="heat_source",
        material="copper"
    )

    hfss.assign_source(
        assignment=heat_source.name,  
        thermal_condition="Surface Flux",  
        assignment_value="10 irrad_W_per_mm2",            
        boundary_name="Heat_Source_Boundary"
    )
		
    print("Created thermal components")
    #return {"Front_Cu_block_minz": cu_block, "Heat_source": heat_source}
    return {"Heat_source": heat_source}


def organize_project_structure(hfss, beol_objects, thermal_objects):
    
    try:
        # create_group organizes main project structure groups
        model_group = hfss.modeler.create_group("Model")
        
        # BEOL group
        beol_group = hfss.modeler.create_group("BEOL")
        
        for name, obj in beol_objects["metal_layers"].items():
            hfss.modeler.add_to_group(beol_group, obj)
        
        for name, obj in beol_objects["dielectric_layers"].items():
            hfss.modeler.add_to_group(beol_group, obj)

        for name, obj in beol_objects["vias"].items():
            hfss.modeler.add_to_group(beol_group, obj)

        hfss.modeler.add_to_group(model_group, beol_group)

        thermal_group = hfss.modeler.create_group("Thermal")
        
        for name, obj in thermal_objects.items():
            hfss.modeler.add_to_group(thermal_group, obj)
        
        hfss.modeler.add_to_group(model_group, thermal_group)
        
        print("BOEL structure creation complete")
    except Exception as e:
        print(f"Error organizing project structure: {str(e)}")

if __name__ == "__main__":
    main()
