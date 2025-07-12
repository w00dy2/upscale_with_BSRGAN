#!/bin/bash

# chmod +x split_video.sh로 실행 권한을 부여합니다

# --- 사용자 설정 ---

# 작업 디렉토리 (프로젝트의 루트 폴더)
WORK_DIR="./"

# 분할할 원본 비디오 파일 경로
INPUT_VIDEO="${WORK_DIR}/video/[ 비디오 파일 명 수정하세요]"

# 추출된 프레임(이미지)을 저장할 디렉토리
OUTPUT_DIR="${WORK_DIR}/input_frames"

# 출력 이미지 형식 (png 또는 jpg)
IMAGE_FORMAT="png"

# --- 스크립트 시작 ---
set -e # 오류 발생 시 스크립트를 즉시 중단합니다.

echo "--- 비디오 프레임 분할 스크립트 (지정 폴더 저장 방식) ---"

# 1. FFmpeg 설치 여부 확인
if ! command -v ffmpeg &> /dev/null; then
    echo "오류: ffmpeg가 설치되어 있지 않습니다. ffmpeg를 먼저 설치해주세요."
    echo "  - Ubuntu/Debian: sudo apt update && sudo apt install ffmpeg"
    echo "  - macOS (Homebrew): brew install ffmpeg"
    exit 1
fi

# 2. 입력 비디오 파일 존재 여부 확인
if [ ! -f "$INPUT_VIDEO" ]; then
    echo "오류: 입력 비디오 파일이 존재하지 않습니다: $INPUT_VIDEO"
    exit 1
fi

# 3. 출력 디렉토리 생성 및 기존 파일 처리
mkdir -p "$OUTPUT_DIR"
# [ -n "$(ls -A "$OUTPUT_DIR")" ] : 디렉토리가 비어있지 않은지 확인
if [ -n "$(ls -A "$OUTPUT_DIR")" ]; then
    echo "경고: '$OUTPUT_DIR' 디렉토리에 파일이 이미 존재합니다."
    # 사용자에게 확인 받기
    read -p "기존 파일을 모두 삭제하고 계속하시겠습니까? (y/N) " -n 1 -r
    echo # 줄바꿈
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "기존 파일을 삭제합니다..."
        rm -f "${OUTPUT_DIR}"/*
    else
        echo "작업을 취소했습니다."
        exit 1
    fi
fi

echo "-------------------------------------"
echo "입력 비디오: $INPUT_VIDEO"
echo "프레임 저장 위치: $OUTPUT_DIR"
echo "이미지 형식: $IMAGE_FORMAT"
echo "-------------------------------------"


# 4. FFmpeg를 사용하여 비디오를 프레임으로 분할
echo "비디오 프레임 분할을 시작합니다... (비디오 길이에 따라 시간이 걸릴 수 있습니다)"

# %06d: 6자리 숫자로 프레임 번호를 매깁니다 (예: 000001, 000002). 30프레임 -> 분당 : 1800  -> 시간당 : 108000장 -> 일반적 비디오 길이 1~2시간 -> 6자리 충분
# -qscale:v 2: 이미지 품질을 설정합니다 (낮을수록 품질이 좋음, 2-5가 일반적).
ffmpeg -i "$INPUT_VIDEO" -qscale:v 1 "${OUTPUT_DIR}/frame_%06d.${IMAGE_FORMAT}"

# 5. 작업 완료 메시지
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 프레임 분할이 성공적으로 완료되었습니다."
    FRAME_COUNT=$(ls -1q "$OUTPUT_DIR" | wc -l | xargs) # xargs로 공백 제거
    echo "총 ${FRAME_COUNT}개의 프레임이 생성되었습니다. (저장 경로: ${OUTPUT_DIR})"
else
    echo "❌ 오류: 프레임 분할 중 문제가 발생했습니다."
    exit 1
fi