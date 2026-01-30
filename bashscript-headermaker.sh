#!/usr/bin/env bash

## name: bashscript-headermaker.sh
## description: Makes bashscript header.
## usage: bash bashscript-header-maker.sh

# Prompt user for script details
read -p "Filename: " filename
read -p "Description: " description
read -p "Usage: " usage

# Check if file already exists
if [[ -f "$filename" ]]; then
    echo "Error: File '$filename' already exists."
    exit 1
fi

# Create the file with the header format
cat <<EOF > "$filename"
#!/usr/bin/env bash

## name: $filename
## description: $description
## usage: $usage

# Your code starts here...
EOF

# Make the script executable
chmod +x "$filename"

echo -e "\n[✔] $filename has been created successfully!"
