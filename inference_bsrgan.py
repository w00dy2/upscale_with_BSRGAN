import os
import argparse
import logging
import torch
import sys

# -- cv2 에러 
import importlib.util
# 1. cv2 모듈의 경로를 직접 지정
# __init__.py 파일의 전체 경로를 지정
cv2_path = '/opt/conda/lib/python3.8/site-packages/cv2/__init__.py'
spec = importlib.util.spec_from_file_location('cv2', cv2_path)
cv2 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cv2)

# 2. 로드된 cv2 모듈을 시스템 모듈 캐시에 등록, 다른 파일에서도 import cv2가 가능
sys.modules['cv2'] = cv2



from utils import utils_logger
from utils import utils_image as util
from models.network_rrdbnet import RRDBNet as net

def main():
    # -------------------------------------------------------------------------
    #                           Argument Parser
    # -------------------------------------------------------------------------
    parser = argparse.ArgumentParser(description='BSRGAN Inference')
    parser.add_argument('--input', type=str, required=True, help='Input folder path')
    parser.add_argument('--output', type=str, required=True, help='Output folder path')
    parser.add_argument('--model_path', type=str, required=True, help='Path to the BSRGAN model file')
    args = parser.parse_args()

    # -------------------------------------------------------------------------
    #                          Setup and Logging
    # -------------------------------------------------------------------------
    utils_logger.logger_info('blind_sr_log', log_path='blind_sr_log.log')
    logger = logging.getLogger('blind_sr_log')
    
    # -------------------------------------------------------------------------
    #                          Model Configuration
    # -------------------------------------------------------------------------
    
    
    # 스케일 팩터. 모델 이름에 'x2'가 포함되어 있으면 2로 설정.
    sf = 4 
    if 'x2' in os.path.basename(args.model_path):
        sf = 2
    
    # cuda 가능시 cuda로 설정 else cpu
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    logger.info(f'Using device: {device}')
    
    # -------------------------------------------------------------------------
    #                          Define and Load Model
    # -------------------------------------------------------------------------

    model = net(in_nc=3, out_nc=3, nf=64, nb=23, gc=32, sf=sf)
    model.load_state_dict(torch.load(args.model_path), strict=True)
    model.eval()
    for k, v in model.named_parameters():
        v.requires_grad = False
    model = model.to(device)
    logger.info(f'Model loaded from {args.model_path}')
    
    # -------------------------------------------------------------------------
    #                             Inference
    # -------------------------------------------------------------------------
    L_path = args.input
    E_path = args.output
    util.mkdir(E_path)
    
    image_paths = util.get_image_paths(L_path)
    logger.info(f'Found {len(image_paths)} images in {L_path}')
    
    for idx, img_path in enumerate(image_paths):
        img_name, ext = os.path.splitext(os.path.basename(img_path))
        logger.info(f'Processing {idx+1}/{len(image_paths)}: {img_name+ext}')
        
        # Read image
        img_L = util.imread_uint(img_path, n_channels=3)
        img_L = util.uint2tensor4(img_L)
        img_L = img_L.to(device)

        # Inference
        img_E = model(img_L)

        # Save image
        img_E = util.tensor2uint(img_E)
        
        # 출력 파일명을 원본과 동일하게 저장
        output_img_path = os.path.join(E_path, img_name + '.png')
        util.imsave(img_E, output_img_path)
        
    logger.info(f'All images processed and saved in {E_path}')


if __name__ == '__main__':
    main()