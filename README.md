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
# 2. Preprocessing of angiogenic sprouts signal

## Preprocessing in NIS Elements (GA3 Batch Processing)

To prepare your 3D angiogenic sprout images for analysis, preprocessing is performed using a GA3 script in **NIS Elements (Laboratory Imaging)**.

## Required Software 

> **Software Requirement**  
> - **NIS Elements** version: 6.10.01 (64-bit)  
> - **Note**: NIS Elements is a licensed software. Ensure you have the appropriate license and modules (e.g., GA3) installed.

### Steps to Batch Process GA3 Files

1. **Prepare the GA3 Script**
   - Download the .ga3 script file (`Quantificiation-3D-angiogenic-sprouts/scripts/preprocessing_script_nis_version_6_10_01.ga3`)
   - Ensure your `.ga3` file is configured for the desired preprocessing steps.
   - The script used in this project includes:
     - Denoising
     - Rolling ball background subtraction (radius: 20 px)
     - Z-intensity equalization using histogram stretching (bottom: 0, top: 80th quantile per frame)

2. **Launch NIS Elements**
   - Open the NIS Elements software.

3. **Import the GA3 Script**
   - Use the “Import” option to load your `.ga3` file within the GA3 editor.

4. **Access Batch Processing**
   - Navigate to the batch processing interface `Image/Batch GA3...`.

5. **Configure Batch Job**
   - Assign the loaded GA3 script to the batch job.
   - Adjust any parameters if needed.
   - Set output directories and file naming conventions.
     
6. **Select Script and Input Files**
   - Select the `preprocessing_script_nis_version_6_10_01.ga3` script
   - Add the images or folders you want to process.
   - Ensure all files are compatible with the GA3 routine.
  
7. **Run the Batch Process**
   - Start the batch job.
   - Monitor progress through the batch processing window.

After preprocessing, the output images can be used as input for the ImageJ macro described in the next section.


# 3. Segmentation and filling up of angiogenic sprouts

## Overview

The macro performs the following steps:

- Batch processing of 3D image stacks from a specified input directory
- Pixel classification using a pre-trained model from ilastik
- 3D morphological operations: dilation, erosion, hole filling
- Size filtering of segmented objects
- Export of processed binary masks

## Required Software and Plugins

To run this macro successfully, ensure the following software and plugin versions are installed in your Fiji/ImageJ environment:

### ImageJ Environment

- **ImageJ**: 1.54f  
- **Java**: 1.8.0_322 (64-bit)

### Plugins

- **CLIJ2**: `clij2_-2.5.3.5`  
  GPU-accelerated image processing for 3D morphological operations and filtering.

- **MorphoLibJ**: `MorphoLibJ_-1.6.4`  
  Used for connected component labeling and morphological analysis.

- **3D ImageJ Suite**: `mcib3d_plugins-4.1.7b`  
  Provides 3D operations such as distance transforms and 3D filtering.

- **ilastik4ij**: `ilastik4ij-2.0.3`  
  Enables integration of ilastik pixel classification models into Fiji workflows.

Ensure all plugins are correctly installed and accessible via the Fiji plugin menu. You can install them via the Fiji update sites or manually from their respective repositories.

---

## Parameters

- `filt_size`: Minimum object size to retain (default: 3000 voxels)
- `closing_gap`: Distance for morphological closing (default: 12)
- `auto_threshold`: Thresholding method (e.g., Otsu, Default, Huang)
- `max_holefilling`: Maximum size of holes to fill (default: 700000 voxels)
- `gpu`: GPU device name (e.g., "NVIDIA GeForce RTX 3070")

## Usage

1. Open Fiji and drag and drop the macro file (Quantificiation-3D-angiogenic-sprouts/scripts/fillingtubes_script.ijm)
2. Select:
   - Input directory containing `.nd2` files
   - Output directory for saving results
   - Pixel classifier file (e.g., `.ilp` or `.model`)
   - File suffix (default: `.nd2`)
3. The macro will:
   - Import each image using Bio-Formats
   - Apply pixel classification
   - Convert to binary mask
   - Perform 3D morphological operations
   - Save the final binary mask as `.tif`

## Output

- Binary `.tif` images of segmented sprouts saved in the output directory
- Console log of processed files

## Customization

You can modify the macro to:
- Adjust filtering thresholds
- Change morphological parameters
- Add measurements or export statistics

## Notes

- Ensure your GPU is compatible and properly configured for CLIJ2.
- The macro uses `setBatchMode(true)` for performance; disable it for debugging.
- The macro assumes single channel 16-bit image stacks.










