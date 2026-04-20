#!/usr/bin/env python3

import json
import re
import sys
import collections

def node_list_to_bracket_notation(nodes):
    """
    Convert a list of nodes like 'slurm-compute-node-001', 'slurm-compute-node-002', 
    'slurm-compute-node-003', 'slurm-compute-node-005'
    to a compact form like 'slurm-compute-node-[001-003,005]'

    This version is modified to correctly handle the zero-padding and
    bracket formatting seen in the user's example output.
    """
    if not nodes:
        return ""

    # Extract the prefix and node numbers
    prefix_pattern = re.compile(r'(.*?)(\d+)$')
    node_prefix = None
    node_numbers = []
    pad_width = 1  # Default padding if none is detected

    for node in nodes:
        match = prefix_pattern.match(node)
        if match:
            prefix, number_str = match.groups()
            number = int(number_str)
            
            if node_prefix is None:
                # This is the first node, establish prefix and padding
                node_prefix = prefix
                pad_width = len(number_str) # Capture padding from first node
            elif prefix != node_prefix:
                # If we have different prefixes, fall back to comma-separated list
                print(f"Warning: Mixed node prefixes ('{node_prefix}', '{prefix}'). Defaulting to comma list.", file=sys.stderr)
                return ','.join(sorted(nodes))
                
            node_numbers.append(number)
        else:
            # If any node doesn't match the pattern, fall back
            print(f"Warning: Node '{node}' did not match pattern. Defaulting to comma list.", file=sys.stderr)
            return ','.join(sorted(nodes))

    if not node_prefix:
         # This should only happen if list is not empty but no nodes matched
         return ','.join(sorted(nodes))

    # Sort node numbers
    node_numbers.sort()

    # Group consecutive numbers into ranges
    ranges = []
    if not node_numbers:
         return node_prefix # Should be unreachable if nodes list was valid
         
    start = node_numbers[0]
    prev = start

    for num in node_numbers[1:] + [None]:  # Add None as sentinel to handle the last range
        if num is None or num > prev + 1:
            # End of a range
            if prev == start:
                # Single number in range
                ranges.append(f"{start:0{pad_width}d}")
            else:
                # A proper range
                ranges.append(f"{start:0{pad_width}d}-{prev:0{pad_width}d}")
            
            if num is not None:
                start = num
        prev = num if num is not None else prev
        
    # Construct the final string, always using brackets as per the example
    return f"{node_prefix}[{','.join(ranges)}]"

def generate_topology(input_file, output_file):
    """
    Reads VM data from input_file, groups by pod_id, 
    and writes a Slurm topology file to output_file.
    """
    
    # 1. Read the provided JSON file
    print(f"Reading {input_file}...")
    try:
        with open(input_file, 'r') as f:
            vms_data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"Error: Failed to decode JSON from {input_file}.", file=sys.stderr)
        print(f"Details: {e}", file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print(f"Error: Input file not found: {input_file}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error reading file {input_file}: {e}", file=sys.stderr)
        sys.exit(1)

    # 2. Identify pod_id and group VMs
    pods = collections.defaultdict(list)
    
    # Ensure vms_data is a list
    if not isinstance(vms_data, list):
         print(f"Error: Expected JSON file to contain a list of VMs, but found {type(vms_data)}.", file=sys.stderr)
         sys.exit(1)

    for vm in vms_data:
        pod_id = vm.get('pod_id')
        vm_name = vm.get('name')
        
        if pod_id and vm_name:
            pods[pod_id].append(vm_name)
        else:
            print(f"Warning: Skipping VM entry with missing 'pod_id' or 'name': {vm}", file=sys.stderr)

    if not pods:
        print("Warning: No VMs with 'pod_id' and 'name' were found in the JSON file.", file=sys.stderr)

    # 3. Format and prepare output lines
    output_lines = []
    
    # Sort by pod_id to ensure a consistent output order (block01, block02, etc.)
    sorted_pod_ids = sorted(pods.keys())
    
    for i, pod_id in enumerate(sorted_pod_ids, 1):
        block_name = f"block{i:02d}"
        node_list = pods[pod_id]
        
        # Get the formatted node string (e.g., "slurm-compute-node-[001-017]")
        formatted_nodes = node_list_to_bracket_notation(node_list)
        
        output_lines.append(f"BlockName={block_name} Nodes={formatted_nodes}")

    # 4. Output the file
    header = [
        "##################################################################",
        "# Slurm's network topology configuration file for use with the",
        "# topology/block plugin",
        "##################################################################"
    ]
    
    try:
        with open(output_file, 'w') as f:
            for line in header:
                f.write(line + "\n")
            f.write("\n") # Add a blank line
            
            for line in output_lines:
                f.write(line + "\n")
            
            f.write("BlockSizes=18\n")
            
        print(f"Successfully generated {output_file}")
        
    except IOError as e:
        print(f"Error: Could not write to output file {output_file}.", file=sys.stderr)
        print(f"Details: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <input_json_file>")
        sys.exit(1)
        
    input_filename = sys.argv[1]
    output_filename = "topology.conf" # Output file as requested
    
    generate_topology(input_filename, output_filename)