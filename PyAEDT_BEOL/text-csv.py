import csv
import os

# Define the directory and filenames
base_path = r'C:\Users\xx\Desktop\PyAEDT_BEOL'
input_file = os.path.join(base_path, 'BEOL_test_table.txt')
output_file = os.path.join(base_path, 'BEOL_test_table.csv')

# Read from the input text file
with open(input_file, newline='', encoding='utf-8') as infile:
    reader = csv.reader(infile, delimiter=',')
    rows = list(reader)

# Write to the output CSV file
with open(output_file, 'w', newline='', encoding='utf-8') as outfile:
    writer = csv.writer(outfile, delimiter=',')
    writer.writerows(rows)
