# 1. Segmentation, Z-Projection, and Area Quantification of Z-Stack Images
This repository contains a Python script to perform Z-projection and segmentation of Z-stack images in ND2 format. It is optimized for fluorescence images of sprouting endothelial cells in the **Mimetas Organoplate**, and performs automated quantification of sprout area.

# Requirements
This script runs in a standard Python environment. You will need:
- Python ≥ 3.7
- Required libraries:
  - `nd2reader`
  - `numpy`
  - `matplotlib`
  - `pandas`
  - `scikit-image`

# Input
Set in the `input_directory` variable with Z-stack images in ND2 format.
- Input files must be in **ND2 format**
- Each file should be a **Z-stack** (multiple focal planes)
- Only grayscale or single-channel stacks are supported
  
### Example input structure:
```
input_directory/
├── WellA01.nd2
├── WellB01.nd2
```

# Output  
The script automatically creates a subfolder:  
`<input_directory>/zprojections_final/`, which contains:

- One binary mask image (`*_mask.png`) per input file
- A summary table `area_summary.csv` with segmented area in pixels

### Example output:
```
zprojections_final/
├── WellA01_mask.png
├── WellB01_mask.png
└── area_summary.csv
```









