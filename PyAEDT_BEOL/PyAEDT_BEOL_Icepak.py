# PyAEDT script to automate creation of BEOL geometry from CSV 
# May 2025
import os
import csv
from pyaedt import Icepak
from pyaedt.desktop import Desktop

def main():
    # working directory and csv path
    working_dir = os.getcwd()
    beol_csv = os.path.join(working_dir, "C:\\Users\\xx\\Desktop\\PyAEDT_BEOL\\BEOL_test_table.csv")
    
    project_name = "PyAEDT_gen_test_2025.06"
    design_name = "PyAEDT_gen_test"
    
    # create Icepak project
    icepak = Icepak(project=project_name, design=design_name)
    
    # call import from csv function
    layers = import_beol_from_csv(beol_csv)
    
    # BEOL structure by calling functions below
    beol_objects = create_beol_structure(icepak, layers)
    thermal_objects = create_thermal_components(icepak)
    organize_project_structure(icepak, beol_objects, thermal_objects)
    
    icepak.save_project()
    print(f"Project {project_name} saved successfully")

# Functions ________________________________________________________

def import_beol_from_csv(file_path):
    """Import BEOL structure definition from a CSV file."""
    layers = []
    
    try:
        with open(file_path, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                if not row['LayerName']:  # Skip rows without LayerName
                    continue
                layers.append(row)
        print(f"Successfully imported {len(layers)} layers from CSV")
    except Exception as e:
        print(f"Error importing layers from CSV: {str(e)}")
        
    return layers


def create_beol_structure(icepak, layers):
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
        
        if layer_type == "Metal":
            # assign metal geometries and property
            metal_obj = icepak.modeler.create_box(
                origin=[x_pos, y_pos, z_pos],  
                sizes=[x_size, y_size, z_size],     
                name=name,
                material=material                      
            )
            metal_layers[name] = metal_obj
            print(f"Created {name}")
            
        elif layer_type == "Dielectric":

            diel_obj = icepak.modeler.create_box(
                origin=[-x_size/2, -y_size/2, z_pos],   
                sizes=[x_size, y_size, z_size],    
                name=name,
                material=material                   
            )
            dielectric_layers[name] = diel_obj
            print(f"Created {name}")
            
        elif layer_type == "Via":

            via_obj = icepak.modeler.create_box(
                origin=[x_pos, y_pos, z_pos],  
                sizes=[x_size, y_size, z_size],   
                name=name,
                material=material  
            )
            vias[name] = via_obj  
            print(f"Created via: {name}")

        elif layer_type == "Substrate":

            Si_obj = icepak.modeler.create_box(
                origin=[x_pos, y_pos, z_pos],  
                sizes=[x_size, y_size, z_size],   
                name=name,
                material=material  
            )
            Si[name] = Si_obj  
            print(f"Created substrate: {name}")    
    
    return {
        "metal_layers": metal_layers,
        "dielectric_layers": dielectric_layers,
        "vias": vias
    }


def create_thermal_components(icepak):
    # Example: create a heat source rectangle
    heat_source = icepak.modeler.create_rectangle(
        position=[-2, -2, 24.72],  
        dimension_list=[4, 4],  
        name="heat_source",
        material="copper"
    )

    # Assign a thermal condition (Surface Flux for example)
    icepak.assign_surface_flux(
        assignment=heat_source.name,  
        value="10",   # units W/m^2, adjust as needed
        boundary_name="Heat_Source_Boundary"
    )
    
    print("Created thermal components")
    return {"Heat_source": heat_source}


def organize_project_structure(icepak, beol_objects, thermal_objects):
    try:
        # create_group organizes main project structure groups
        model_group = icepak.modeler.create_group("Model")
        
        # BEOL group
        beol_group = icepak.modeler.create_group("BEOL")
        
        for name, obj in beol_objects["metal_layers"].items():
            icepak.modeler.add_to_group(beol_group, obj)
        
        for name, obj in beol_objects["dielectric_layers"].items():
            icepak.modeler.add_to_group(beol_group, obj)

        for name, obj in beol_objects["vias"].items():
            icepak.modeler.add_to_group(beol_group, obj)

        icepak.modeler.add_to_group(model_group, beol_group)

        thermal_group = icepak.modeler.create_group("Thermal")
        
        for name, obj in thermal_objects.items():
            icepak.modeler.add_to_group(thermal_group, obj)
        
        icepak.modeler.add_to_group(model_group, thermal_group)
        
        print("BEOL structure creation complete")
    except Exception as e:
        print(f"Error organizing project structure: {str(e)}")

if __name__ == "__main__":
    main()