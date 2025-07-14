#!/bin/bash
set -e # 오류 발생 시 즉시 중단

# --- 사용자 설정 ---
INPUT_VIDEO="./video/[비디오 명 입력하세요]"
BSRGAN_PATH="./"
MODEL_PATH="${BSRGAN_PATH}model/BSRGANx2.pth"
FRAMERATE=30 # 프레임 설정
VIDEO_BASENAME=$(basename "$INPUT_VIDEO")
FINAL_VIDEO="output_resumed_${VIDEO_BASENAME}" # 최종 파일 이름

# --- 폴더 설정 ---
WORK_DIR=$(pwd)
INPUT_FRAMES_DIR="${WORK_DIR}/input_frames"
OUTPUT_FRAMES_DIR="${WORK_DIR}/output_frames"
TEMP_INPUT_DIR="${WORK_DIR}/temp_input_for_resume"
TEMP_OUTPUT_DIR="${WORK_DIR}/temp_output_for_resume"


# ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
#               【 작업 중단 시 에러 처리를 위함 】 이전 작업 자동 복구 단계 tempfolder에 있는 데이터를 output폴더로 이동
# ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
echo "========================================================"
echo "0/6: 이전 실행에서 중단된 작업이 있는지 확인하고 복구합니다..."
echo "========================================================"
# 최종 출력 폴더가 없다면 미리 생성
mkdir -p "$OUTPUT_FRAMES_DIR"

# 임시 출력 폴더가 존재하고, 비어있지 않다면
if [ -d "$TEMP_OUTPUT_DIR" ] && [ -n "$(ls -A "$TEMP_OUTPUT_DIR")" ]; then
    echo "이전에 처리된 임시 파일들을 ${OUTPUT_FRAMES_DIR}로 이동합니다."
    mv "${TEMP_OUTPUT_DIR}"/* "$OUTPUT_FRAMES_DIR/"
    echo "복구 완료."
else
    echo "복구할 이전 작업이 없습니다."
fi
echo ""


# --- 1. 누락된 프레임 자동 탐색 및 준비 ---
echo "========================================================"
echo "1/6: BSRGAN 이어하기 준비 (누락된 프레임 자동 탐색)"
echo "========================================================"

rm -rf $TEMP_INPUT_DIR $TEMP_OUTPUT_DIR
mkdir -p $TEMP_INPUT_DIR $TEMP_OUTPUT_DIR
# input 데이터와 output 데이터를 비교하여 차이가 나지 않으면 변환 완료된 상태
unprocessed_files=$(comm -23 <(ls -1 "$INPUT_FRAMES_DIR" | sort) <(ls -1 "$OUTPUT_FRAMES_DIR" | sort))

if [ -z "$unprocessed_files" ]; then
    echo "모든 프레임이 이미 처리되었습니다. BSRGAN 단계를 건너뜁니다."
else
    echo "누락된 프레임을 임시 폴더로 복사합니다..."
    echo "$unprocessed_files" | xargs -I {} cp "${INPUT_FRAMES_DIR}/{}" "${TEMP_INPUT_DIR}/"
    
    file_count=$(echo "$unprocessed_files" | wc -l)
    echo "총 ${file_count}개의 프레임을 추가로 처리합니다."
    echo ""

    # --- 2. BSRGAN으로 "누락된" 프레임만 처리 ---
    echo "========================================================"
    echo "2/6: BSRGAN으로 누락된 프레임 처리 시작"
    echo "========================================================"
    python "${BSRGAN_PATH}inference_bsrgan.py" \
        --input $TEMP_INPUT_DIR \
        --output $TEMP_OUTPUT_DIR \
        --model_path $MODEL_PATH
    echo "BSRGAN 처리 완료."
    echo ""

    # --- 3. 처리된 결과물을 최종 출력 폴더로 이동 ---
    echo "========================================================"
    echo "3/6: 처리된 결과물을 최종 폴더로 이동"
    echo "========================================================"
    mv "${TEMP_OUTPUT_DIR}"/* "$OUTPUT_FRAMES_DIR/"
    echo "파일 이동 완료."
    echo ""

    # --- 4. 임시 폴더 삭제 ---
    echo "========================================================"
    echo "4/6: 임시 작업 폴더 삭제"
    echo "========================================================"
    rm -rf $TEMP_INPUT_DIR $TEMP_OUTPUT_DIR
    echo "임시 폴더 삭제 완료."
    echo ""
fi

# --- 5. 모든 프레임을 동영상으로 재조합 ---
echo "========================================================"
echo "5/6: 모든 프레임을 동영상으로 재조합 (원본 음원 추가)"
echo "========================================================"

# 1. 비디오에서 음원 추출
TEMP_AUDIO="temp_audio.aac"
./ffmpeg -i "$INPUT_VIDEO" -vn -acodec aac -b:a 128k "$TEMP_AUDIO"

# 2. 이미지 프레임으로 비디오 생성 (원본 음원 포함)
./ffmpeg -framerate "$FRAMERATE" -i "${OUTPUT_FRAMES_DIR}/frame_%08d.png" -i "$TEMP_AUDIO" -c:v libx264 -pix_fmt yuv420p -crf 18 -map 0:v -map 1:a -shortest "$FINAL_VIDEO"

# 3. 임시 오디오 파일 삭제
rm "$TEMP_AUDIO"

echo ""

# --- 6. 최종 완료 메시지 ---
echo "========================================================"
echo "6/6: 🎉 모든 작업이 완료되었습니다! 최종 파일: ${FINAL_VIDEO}"
echo "========================================================"