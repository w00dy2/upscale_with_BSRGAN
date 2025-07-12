# upscale_with_BSRGAN
for upscale video with BSRGAN

This project is based on the BSRGAN repository. For more details, please refer to the original repository:
Original BSRGAN Repository: https://github.com/cszn/BSRGAN

1. input video at video folder
2. split_video.sh
3. upscale_video.sh

## Usage
1. `sudo apt update && sudo apt install ffmpeg` / `brew install ffmpeg`


2.  **Make the script executable:**
    Before running the script, you need to grant it execution permissions.

    ```bash
    chmod +x split_video.sh
    chmod +x upscale_video.sh
    ```

3.  **Set your video path:**
    Open the shell script (`split_video.sh`) and modify the `INPUT_VIDEO` variable to point to your video file.
    Open the shell script (`upscale_video.sh`) and modify the `INPUT_VIDEO` variable to point to your video file.

    ```sh
    # Inside your_script_name.sh
    INPUT_VIDEO="./video/your_video.mp4" # <-- Change this line
    ```
## results
### Server spec
- ubuntu20.04.6 LTS
- CPU
    Core(s) per socket:              10
    Socket(s):                       2
    NUMA node(s):                    2
    Vendor ID:                       GenuineIntel
    CPU family:                      6
    Model:                           79
    Model name:                      Intel(R) Xeon(R) CPU E5-2640 v4 @ 2.40GHz
- GPU
    tesla M40 (cuda)
- Memorry
    126GB

### processing time
- 3~4 seconds for process 1 png