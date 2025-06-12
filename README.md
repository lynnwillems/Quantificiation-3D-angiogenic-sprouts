# 1. Segmentation Z-projection and quantification area of Z-stack images
This repository contains a Python script for quantifying the segmented area from Z-stack images in ND2 format, fluorescent images of sprouting endothelial cells in the Mimetas Organoplate.

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

# Output  
Output is saved in input directory as `zprojections_final/`, containing:
  - One binary mask image (`_mask.png`) per input file
  - A `area_summary.csv` file summarizing areas in pixels

