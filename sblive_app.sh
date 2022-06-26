#!/bin/bash

source /opt/online/online.conf

SystemInit() {
  # System constants
  FFMPEG_BIN_PATH="$HOME_DIR/lib/ffmpeg"
  HLS_PATH_SYSTEM="$HOME_DIR/www/media/hls_$ID"
  LOG_DIR="$HOME_DIR/logs"
  LOG_DIR_JOBS="$LOG_DIR/jobs"
  LOG_DIR_JOBS_ERROR="$LOG_DIR_JOBS/error/"
  LOG_DIR_HTTP="$LOG_DIR/nginx/"
  LOG_FILE_SYSTEM="$LOG_DIR/system.log"
  UPDATE_DIR_LOCAL="$HOME_DIR/upd"
  UPDATE_FILE_NAME="latest_update"
  UPDATE_FILE_EXT=".tar.gz"
  UPDATE_FILE_LOCAL="$UPDATE_DIR_LOCAL/$UPDATE_FILE_NAME$UPDATE_FILE_EXT"
  UPDATE_VER_LOCAL="$HOME_DIR/online.ver"
  UPDATE_VER_REMOTE="$UPDATE_URL/version"
  ANALYZE_DURATION=5000000
  if ! [[ -d "$HLS_PATH_SYSTEM" ]]; then mkdir -p $HLS_PATH_SYSTEM; fi
  if ! [[ -d "$SCREEN_DIR" ]]; then mkdir -p $SCREEN_DIR; fi
  if ! [[ -d "$LOG_DIR_JOBS_ERROR" ]]; then mkdir -p $LOG_DIR_JOBS_ERROR; fi
  if ! [[ -d "$LOG_DIR_HTTP" ]]; then mkdir -p $LOG_DIR_HTTP; fi
}


SystemInit


# Screenshots generator
ScreenshotGen() {
  echo "`date '+%D %T'` [ScreenshotGen][INFO] Generating screenshots" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
  if [[ "$TOR" = 1 ]]
  then
    cp -f $SCREEN_DIR/"$ID"_IN_screen_$TARGET_IDX.jpg $SCREEN_DIR/"$ID"_OUT_screen_$TARGET_IDX.jpg &>/dev/null
  else
    timeout 30 $HOME_DIR/lib/ffmpeg -hide_banner -v fatal -y -analyzeduration $ANALYZE_DURATION -i $TARGET_MAIN -an -vcodec mjpeg -vframes 1 $SCREEN_DIR/"$ID"_OUT_screen_$TARGET_IDX.jpg 2>&1
  fi
}


FFProcFind() {
  echo "`date '+%D %T'` [FFProcFind][DEBUG] SOURCE: $SOURCE" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
  echo "`date '+%D %T'` [FFProcFind][DEBUG] TARGET_MAIN: $TARGET_MAIN" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
  if [[ $SOURCE && $TARGET_MAIN ]]
  then
    FF_MEMORY=`ps -o pid,cmd -C ffmpeg | grep "$SOURCE" | grep "$TARGET_MAIN"`
    #echo "`date '+%D %T'` [FFProcFind][DEBUG] FF_MEMORY: $FF_MEMORY" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    FF_PROC_COUNT=`ps -o pid,cmd -C ffmpeg | grep "$SOURCE" | grep "$TARGET_MAIN" | wc -l`
    JOB_PID=`echo $FF_MEMORY | head -n 1 | awk '{ print $1 }'`
  else
    FF_PROC_COUNT=0
    JOB_PID=""
  fi
  echo "`date '+%D %T'` [FFProcFind][DEBUG] FF_PROC_COUNT: $FF_PROC_COUNT" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
  echo "`date '+%D %T'` [FFProcFind][DEBUG] JOB_PID: $JOB_PID" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
}


FFProcKill() {
  FFProcFind
  echo "`date '+%D %T'` [FFProcKill][INFO] $FF_PROC_COUNT process(es) found" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
  while [[ "$JOB_PID" ]]
  do
    kill -9 $JOB_PID &>/dev/null &
    echo "`date '+%D %T'` [FFProcKill][INFO] Job PID $JOB_PID killed" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    if [[ $SOURCE && $TARGET_MAIN ]]
    then
      JOB_PID=`ps -o pid,cmd -C ffmpeg | grep "$SOURCE" | grep "$TARGET_MAIN" | head -n 1 | awk '{ print $1 }'`
    else
      JOB_PID=""
    fi
  done
}


# Job config parse
JobDataParse() {
  # Create GUI status file
  if ! [[ -f "$HOME_DIR/online.www" ]]; then touch $HOME_DIR/online.www; fi
  lines_count=`wc -l < $HOME_DIR/online.www`
  # Add new status line(s) if they're not exist
  if (( "$lines_count" <= "$N" ))
  then
    for line in $(seq $lines_count $N)
    do
      echo -en "\n" >>$HOME_DIR/online.www
    done
  fi
  # Create sources info file
  if ! [[ -f "$HOME_DIR/online.src" ]]; then touch $HOME_DIR/online.src; fi
  lines_count=`wc -l < $HOME_DIR/online.src`
  # Add new status line(s) if they're not exist
  if (( "$lines_count" <= "$N" ))
  then
    for line in $(seq $lines_count $N)
    do
      echo -en "\n" >>$HOME_DIR/online.src
    done
  fi
  # Job constants get
  JOB_ID=$1
  SOURCE=$(eval echo \$SOURCE$JOB_ID)
  SOURCE_MAIN=$(eval echo \$SOURCE$JOB_ID)
  SOURCE_R=$(eval echo \$SOURCE_R$JOB_ID)
  SOURCE_BAK=$(eval echo \$SOURCE_R$JOB_ID)
  HTTP_UA=$(eval echo \$HTTP_UA$JOB_ID)
  UDP_OVERRUN=$(eval echo \$UDP_OVERRUN$JOB_ID)
  VDECODER=$(eval echo \$VDECODER$JOB_ID)
  VENCODER=$(eval echo \$VENCODER$JOB_ID)
  VPRESET=$(eval echo \$VPRESET$JOB_ID)
  GOP_SIZE=$(eval echo \$GOP_SIZE$JOB_ID)
  FPS=$(eval echo \$FPS$JOB_ID)
  KEYINT_MIN=$(eval echo \$KEYINT_MIN$JOB_ID)
  SCALE=$(eval echo \$SCALE$JOB_ID)
  DI=$(eval echo \$DI$JOB_ID)
  TOR=$(eval echo \$TOR$JOB_ID)
  VBITRATE=$(eval echo \$VBITRATE$JOB_ID)
  ABITRATE=$(eval echo \$ABITRATE$JOB_ID)
  ALANG=$(eval echo \$ALANG$JOB_ID)
  TARGETS_ALL=$(eval echo \$TARGET$JOB_ID)
  HLS_LIST_SIZE=$(eval echo \$HLS_LIST_SIZE$JOB_ID)
  HLS_CHUNK_TIME=$(eval echo \$HLS_CHUNK_TIME$JOB_ID)
  OVERLAY_TEXT=$(eval echo \$OVERLAY_TEXT$JOB_ID)
  VP_USER_X264="$VP_X264"
  VP_USER_NVENC="$VP_NVENC"

  # Set active source
  SOURCE_ACTIVE=`head -n $JOB_ID $HOME_DIR/online.www | tail -n 1 | awk '{ print $4 }'`
  if [[ "$SOURCE_ACTIVE" = 2 && "$SOURCE_R" ]]
  then
    SOURCE="$SOURCE_R"
  else
    SOURCE_ACTIVE=1
  fi

  # GOP settings
  if [[ "$GOP_SIZE" ]]
  then
    GOP="-g $GOP_SIZE"
    VP_USER_NVENC="$VP_USER_NVENC -strict_gop 1"
  fi
  # Keyframe interval, force IDR inject
  if [[ "$KEYINT_MIN" ]]
  then
    KEYINT="-keyint_min $KEYINT_MIN -force_key_frames 'expr:gte(t,n_forced*2)'";
    VP_USER_NVENC="$VP_USER_NVENC -forced-idr 1"
  fi
  # Frame rate (FPS) options
  if [[ "$FPS" ]]; then FPS="-r $FPS"; fi
  # Deinterlace options
  if [[ "$DI" ]]
  then
    # Frame -> Frame (original fps)
    if [[ "$DI" = "yadif_frame_frame" ]]; then FILTER_DI="yadif=0"; fi
    # Field -> Frame (double fps)
    if [[ "$DI" = "yadif_field_frame" ]]; then FILTER_DI="yadif=1"; fi
    # CUVID decoder, "bob" deinterlace
    if [[ "$DI" = "cuvid_bob" ]]; then VDECODER_OPT="-deint adaptive -drop_second_field 1"; fi
    # CUVID decoder, "adaptive" deinterlace
    if [[ "$DI" = "cuvid_adaptive" ]]; then VDECODER_OPT="-deint adaptive -drop_second_field 1"; fi
  else
    # No deinterlace
    FILTER_DI="null"
  fi
  # Audio tracks mapping
  if [[ "$ALANG" ]]
  then
    # Map by: Language code (metadata)
    AUDIO_MAP="-map 0:m:language:$ALANG"
    # Map by: Track number
    if [[ ${ALANG:0:1} = "!" ]]
      then
        AUDIO_MAP="-map 0:${ALANG:1:2}"
      fi
    # Map by: PID
    if [[ ${ALANG:0:1} = "#" ]]
      then
        AUDIO_MAP="-map 0:$ALANG"
      fi
    # No audio
    if [[ $ALANG = "none" ]]
      then
        AUDIO_MAP="-an"
      fi
  else
    # Map by: First available audio track with highest bitrate
    AUDIO_MAP="-map 0:a"
  fi
  ABR=`echo "$VBITRATE" | awk 'BEGIN { FS=";" } { print NF }'`
  # Targets parse
  if [[ `echo "$TARGETS_ALL" | grep ".m3u8"` ]]
  then
    if [[ `echo "$TARGETS_ALL" | grep "udp:"` ]]
    then
      TARGET_TYPE="UDP_HLS"
      # N are UDP targets, N+1 is HLS target (last element)
      TARGET_HLS=`echo "$TARGETS_ALL" | awk -v ABR=$ABR 'BEGIN { FS=";" } { print $(ABR+1) }'`
    else
      TARGET_TYPE="HLS"
      TARGET_HLS="$TARGETS_ALL"
    fi
    HLS_PATH_BASE=`echo "$TARGET_HLS" | awk 'BEGIN { FS="/" } { print $(NF-1) }'`
    HLS_PATH_ABS="$HLS_PATH_SYSTEM/$HLS_PATH_BASE"
    HLS_MANIFEST_NAME=`echo "$TARGET_HLS" | awk 'BEGIN { FS="/" } { print $NF }'`
    HLS_MANIFEST_MASTER="$HLS_PATH_ABS/$HLS_MANIFEST_NAME"
    # HLS master manifest create
    VB1=`echo "$VBITRATE" | awk 'BEGIN { FS=";" } { print $1 }'`
    TARGET_MAIN=`echo $HLS_PATH_ABS/$HLS_PATH_BASE"_"$VB1"_.m3u8"`
    TARGET_IDX="$TARGET_HLS"
  else
    TARGET_TYPE="UDP"
    TARGET_MAIN=`echo "$TARGETS_ALL" | awk 'BEGIN { FS=";" } { print $1 }'`
    TARGET_IDX="$TARGET_MAIN"
  fi
  TARGET_IDX=`echo "$TARGET_IDX" | sed -e 's/\/\///; s/\//_/g; s/:/_/g; s/\./_/g'`

#  HTTP_UA_Setup
  if [[ `echo "$SOURCE" | grep -P "http://|https://"` && $HTTP_UA ]]
  then
    # Set HTTP User-Agent
    HTTP_UA_VALUE=$(echo -user_agent \"$HTTP_UA\")
  else
    HTTP_UA_VALUE=""
  fi

}


# Set HTTP User-Agent
HTTP_UA_Setup() {
  if [[ `echo "$SOURCE" | grep -P "http://|https://"` && $HTTP_UA ]]
  then
    # Set HTTP User-Agent
    HTTP_UA="-user_agent \"$HTTP_UA\""
  else
    HTTP_UA=""
  fi
}


TargetIDXGet() {
  if [[ "$1" ]]
  then
    JobDataParse $1
    echo "$TARGET_IDX"
  fi
}


# Source options apply
SourceOptions() {
  THREADS_OPTIONS="-threads 2"
  if [[ `echo "$SOURCE" | grep "udp://"` ]]
  then
    echo "`date '+%D %T'` [FFEncoderStart][INFO] Source is UDP" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    if (( $STREAM_HEIGHT > 700 ))
    then
#      if [[ "$DI" = "yadif_field_frame" && "$VENCODER" = "libx264" ]]
      if [[ "$DI" = "yadif_field_frame" ]]
      then
        SOURCE_OPTIONS="\"$SOURCE?fifo_size=5711392&buffer_size=33554432"
        echo "`date '+%D %T'` [FFEncoderStart][INFO] UDP fifo_size set to 1 Gb" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
        echo "`date '+%D %T'` [FFEncoderStart][INFO] UDP buffer_size set to 32 Mb" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
        if ! [[ "$STREAM_FIELD_ORDER" = "progressive" ]]
        then
          THREADS_OPTIONS="-threads 8"
        fi
      else
        SOURCE_OPTIONS="\"$SOURCE?fifo_size=2855696&buffer_size=16777216"
        echo "`date '+%D %T'` [FFEncoderStart][INFO] UDP fifo_size set to 512 Mb" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
        echo "`date '+%D %T'` [FFEncoderStart][INFO] UDP buffer_size set to 16 Mb" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
        if ! [[ "$STREAM_FIELD_ORDER" = "progressive" ]]
        then
          THREADS_OPTIONS="-threads 4"
        fi
      fi
    else
      SOURCE_OPTIONS="\"$SOURCE?fifo_size=1427848&buffer_size=8388608"
      echo "`date '+%D %T'` [FFEncoderStart][INFO] UDP fifo_size set to 256 Mb" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
      echo "`date '+%D %T'` [FFEncoderStart][INFO] UDP buffer_size set to 8 Mb" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    fi
    if [[ "$UDP_OVERRUN" = "" ]] || [[ "$UDP_OVERRUN" = 1 ]]
    then
      SOURCE_OPTIONS="$SOURCE_OPTIONS&overrun_nonfatal=1\""
      echo "`date '+%D %T'` [FFEncoderStart][INFO] UDP overrun protection enabled" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    else
      SOURCE_OPTIONS="$SOURCE_OPTIONS\""
    fi
  else
    SOURCE_OPTIONS="\"$SOURCE\""
    if (( $STREAM_HEIGHT > 700 ))
    then
#      if [[ "$DI" = "yadif_field_frame" && "$VENCODER" = "libx264" ]]
      if [[ "$DI" = "yadif_field_frame" ]]
      then
        if ! [[ "$STREAM_FIELD_ORDER" = "progressive" ]]
        then
          THREADS_OPTIONS="-threads 8"
        fi
      else
        if ! [[ "$STREAM_FIELD_ORDER" = "progressive" ]]
        then
          THREADS_OPTIONS="-threads 2"
        fi
      fi
    fi
  fi

  echo "`date '+%D %T'` [FFEncoderStart][INFO] Threads global: $THREADS_OPTIONS" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log

  #-vsync parameter
  #0, passthrough Each frame is passed with its timestamp from the demuxer to the muxer.
  #1, cfr Frames will be duplicated and dropped to achieve exactly the requested constant frame rate.
  #2, vfr Frames are passed through with their timestamp or dropped so as to prevent 2 frames from having the same timestamp.
  #-merge_pmt_versions 1

  DEMUX_OPTIONS=""

  if [[ `echo "$SOURCE" | grep -P "http://|https://"` ]]
  then
    echo "`date '+%D %T'` [FFEncoderStart][INFO] Source is HTTP(s)" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    echo "`date '+%D %T'` [JobDataParse][INFO] Setting HTTP User-Agent=\"$HTTP_UA\"" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    DEMUX_OPTIONS="$DEMUX_OPTIONS -re -reconnect 1 -reconnect_streamed 1 -reconnect_delay_max 10"
    if [[ `echo "$SOURCE" | grep ".m3u8"` ]]
    then
      echo "`date '+%D %T'` [FFEncoderStart][INFO] Source is HLS" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
      DEMUX_OPTIONS="$DEMUX_OPTIONS -http_persistent 1 -http_multiple 1 -fflags +igndts"
    fi
  fi
  if [[ `echo "$SOURCE" | grep -P ".png|.jpg|.jpeg|.bmp|.gif"` ]]
  then
    echo "`date '+%D %T'` [FFEncoderStart][INFO] Source is an image file" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    DEMUX_OPTIONS="$DEMUX_OPTIONS -loop 1 -r 25"
  fi
  echo "`date '+%D %T'` [FFEncoderStart][INFO] Using source: $SOURCE ($SOURCE_ACTIVE)" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
  echo "`date '+%D %T'` [FFEncoderStart][INFO] Source options: $SOURCE_OPTIONS" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
  if [[ "$DEMUX_OPTIONS" ]]
  then
    echo "`date '+%D %T'` [FFEncoderStart][INFO] Demux options: $DEMUX_OPTIONS" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
  fi
  SOURCE_OPTIONS="$HTTP_UA_VALUE $DEMUX_OPTIONS $THREADS_OPTIONS -i $SOURCE_OPTIONS"
}


# Decoder options apply
DecoderOptions() {
  if [[ "$VDECODER" = "cuvid" ]]
  then
    FFMPEG_DECODERS=`timeout 30 $HOME_DIR/lib/ffmpeg -hide_banner -analyzeduration $ANALYZE_DURATION -decoders 2>&1`
    if [[ "$STREAM_VCODEC" = "mpeg2video" && `echo "$FFMPEG_DECODERS" | grep mpeg2_cuvid` ]]
    then
      VDECODER="-c:v mpeg2_cuvid $VDECODER_OPT"
      #FILTER_PIXEL_FORMAT=",format=pix_fmts=nv12"
      echo "`date '+%D %T'` [FFEncoderStart][INFO] Video decoder: mpeg2_cuvid" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    fi
    if [[ "$STREAM_VCODEC" = "h264" && `echo "$FFMPEG_DECODERS" | grep h264_cuvid` ]]
    then
      VDECODER="-c:v h264_cuvid $VDECODER_OPT"
      #FILTER_PIXEL_FORMAT=",format=pix_fmts=nv12"
      echo "`date '+%D %T'` [FFEncoderStart][INFO] Video decoder: h264_cuvid" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    fi
    if [[ "$VDECODER" = "cuvid" ]]
    then
      VDECODER=""
      echo "`date '+%D %T'` [FFEncoderStart][INFO] Video decoder: CUVID init failed, using FFMPEG" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    fi
  else
    VDECODER=""
    echo "`date '+%D %T'` [FFEncoderStart][INFO] Video decoder: FFMPEG" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
  fi
}


# Encoder options apply
EncoderOptions() {
  echo "`date '+%D %T'` [FFEncoderStart][INFO] Video encoder: $VENCODER ($VPRESET)" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
  if [[ "$VENCODER" = "libx264" ]]; then VPRESET="-preset:v $VPRESET $VP_USER_X264"; fi
  if [[ "$VENCODER" = "h264_nvenc" ]]
  then
    VPRESET_DEFAULT="-preset:v llhq -rc:v vbr_hq -coder:v cabac $VP_USER_NVENC"
    if [[ "$VPRESET" = "HQ" ]]
    then
      # unstable options: -weighted_pred:v 1
      # ?: -b_ref_mode middle
      VPRESET="$VPRESET_DEFAULT -rc-lookahead:v 16 -temporal-aq:v 1 -spatial-aq:v 1"
    else
      VPRESET="$VPRESET_DEFAULT"
    fi
  fi
  echo "`date '+%D %T'` [FFEncoderStart][INFO] Video encoder preset: $VPRESET" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
}


# HLS manifest generator
HLSManifestCreate() {
  if ! [[ -d $HLS_PATH_ABS ]]; then mkdir -p $HLS_PATH_ABS; fi
  if ! [[ -f $HLS_MANIFEST_MASTER ]]; then echo "#EXTM3U" >$HLS_MANIFEST_MASTER; fi
  echo "#EXT-X-STREAM-INF:PROGRAM-ID=1, BANDWIDTH="$VB"000" >>$HLS_MANIFEST_MASTER
  echo "$HLS_MANIFEST" >>$HLS_MANIFEST_MASTER
  echo "`date '+%D %T'` [HLSManifestCreate][INFO] HLS master manifest update: $HLS_MANIFEST" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
}


ABRTargetUDP() {
  TARGET_UDP=`echo "$TARGETS_ALL" | awk -v IDX=$idx 'BEGIN { FS=";" } { print $IDX }'`
  echo "`date '+%D %T'` [JobABRParse][INFO]  Target UDP: $TARGET_UDP" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
  TEE_UDP="[f=mpegts]$TARGET_UDP?pkt_size=1316"
}


ABRTargetHLS() {
  HLS_MANIFEST=`echo $HLS_PATH_BASE"_"$VB"_.m3u8"`
  HLS_MANIFEST_ABS=`echo $HLS_PATH_ABS/$HLS_PATH_BASE"_"$VB"_.m3u8"`
  echo "`date '+%D %T'` [JobABRParse][INFO]  Target HLS: $HLS_MANIFEST" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
  HLS_CHUNKS=`echo $HLS_PATH_ABS/$HLS_PATH_BASE"_"$VB"_%s_%%02d.ts"`
  HLSManifestCreate
  TEE_HLS="[f=hls:hls_list_size=$HLS_LIST_SIZE:hls_time=$HLS_CHUNK_TIME:hls_segment_filename=$HLS_CHUNKS:ignore_io_errors=1:use_localtime=1:hls_flags=delete_segments+program_date_time+second_level_segment_index]$HLS_MANIFEST_ABS"
}


# Parse ABR assets
JobABRParse() {
  FILTER_SPLIT=",split=$ABR"
  for idx in `seq 1 $ABR`
  do
    echo "`date '+%D %T'` [JobABRParse][INFO] --- Profile $idx parse ---" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    VB=`echo "$VBITRATE" | awk -v IDX=$idx 'BEGIN { FS=";" } { print $IDX }'`
    echo "`date '+%D %T'` [JobABRParse][INFO]  Video bitrate: $VB" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    AB=`echo "$ABITRATE" | awk -v IDX=$idx 'BEGIN { FS=";" } { print $IDX }'`
    echo "`date '+%D %T'` [JobABRParse][INFO]  Audio bitrate: $AB" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    FILTER_LOG="None"
    if [[ "$SCALE" ]]
    then
      SCALE_QX=`echo "$SCALE" | awk -v IDX=$idx 'BEGIN { FS=";" } { print $IDX }'`
      if [[ "$SCALE_QX" ]]
      then
        if [[ "$SCALE_QX" = "copy" ]]
        then
          #SCALE_QX="fifo"
          SCALE_QX="null"
        else
          FILTER_LOG="Scale $SCALE_QX"
          #SCALE_QX="fifo,scale=$SCALE_QX"
          SCALE_QX="null,scale=$SCALE_QX"
        fi
      fi
    else
      #SCALE_QX="fifo"
      SCALE_QX="null"
    fi
    # Parse variable to overlay text filter
    if [[ "$OVERLAY_TEXT" ]]
    then
      if [[ ${OVERLAY_TEXT:0:1} = "@" ]]
      then
        TEXT_QX=$(eval echo "$"${OVERLAY_TEXT:1:2})
      fi
      DRAWTEXT_QX=",drawtext='fontfile=$HOME_DIR/font/arial.ttf:fontsize=36:fontcolor=yellow:text=$TEXT_QX:x=100:y=100'"
      if ! [[ "$FILTER_LOG" = "None" ]]
      then
        FILTER_LOG="$FILTER_LOG, Drawtext: $TEXT_QX"
      else
        FILTER_LOG="Drawtext: $TEXT_QX"
      fi
    fi
    echo "`date '+%D %T'` [JobABRParse][INFO]  Filter: $FILTER_LOG" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    # Profle filters
    FILTER_SPLIT="$FILTER_SPLIT[split$idx]"
    FILTER_QX="$FILTER_QX;[split$idx]$SCALE_QX$DRAWTEXT_QX[profile$idx]"
    PROFILE_AV_MAP="-map '[profile$idx]' $AUDIO_MAP"
    echo "`date '+%D %T'` [JobABRParse][INFO]  AV mapping: $PROFILE_AV_MAP" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    # Profiles constructor
    case "$TARGET_TYPE" in
      UDP) ABRTargetUDP;;
      HLS) ABRTargetHLS;;
      UDP_HLS) ABRTargetUDP; ABRTargetHLS; TEE_JOIN="|";;
    esac
    PROFILE_AENCODER="-c:a aac -b:a "$AB"k -ac 2 -strict -2"
    PROFILE_VENCODER="-c:v $VENCODER $VPRESET -b:v "$VB"k -minrate "$VB"k -maxrate "$VB"k -bufsize "$((2*$VB))"k $GOP $FPS $KEYINT"
    PROFILE_TEE="-f tee '$TEE_UDP$TEE_JOIN$TEE_HLS'"
#    PROFILE_OPT="-max_muxing_queue_size 4096 -flags +global_header+cgop"
    PROFILE_OPT="-max_muxing_queue_size 8192"
    PROFILES="$PROFILES $PROFILE_VENCODER $PROFILE_AENCODER $PROFILE_AV_MAP $PROFILE_OPT $PROFILE_TEE"
  done
  FILTER_PROFILES="$FILTER_SPLIT$FILTER_QX"
}


# FFMPEG CLI constructor
FFEncoderStart() {
  echo "`date '+%D %T'` [FFEncoderStart][INFO] Encoder init" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
#  HTTP_UA_Setup
  # MediaInfo source analyze
  STREAM_INFO=`eval timeout 30 $HOME_DIR/lib/ffprobe -hide_banner $HTTP_UA_VALUE -analyzeduration $ANALYZE_DURATION $SOURCE -show_streams -select_streams v 2>&1`
  STREAM_INFO_LINE=$(echo "$STREAM_INFO" | grep "Stream #" | awk '{ORS=" |"} { gsub("   Stream", "Stream"); print }' | rev | cut -c 2- | rev)
  sed -i -e "`echo $i`c $STREAM_INFO_LINE" $HOME_DIR/online.src
  SOURCE_UP=`echo "$STREAM_INFO" | grep "STREAM"`
  if [[ "$SOURCE_UP" ]]
  then
    STREAM_HEIGHT=`echo "$STREAM_INFO" | grep height | awk 'BEGIN { FS="=" } NR==1 { print $2 }'`
    STREAM_WIDTH=`echo "$STREAM_INFO" | grep width | awk 'BEGIN { FS="=" } NR==1 { print $2 }'`
    STREAM_VCODEC=`echo "$STREAM_INFO" | grep codec_name | awk 'BEGIN { FS="=" } NR==1 { print $2 }'`
    STREAM_FIELD_ORDER=`echo "$STREAM_INFO" | grep field_order | awk 'BEGIN { FS="=" } NR==1 { print $2 }'`
    echo "`date '+%D %T'` [FFEncoderStart][INFO] MediaInfo: Frame size ($STREAM_WIDTH"x"$STREAM_HEIGHT), Video codec: $STREAM_VCODEC, Field order: $STREAM_FIELD_ORDER" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    SourceOptions
    DecoderOptions
    EncoderOptions
    # Job parameters info
    echo "`date '+%D %T'` [FFEncoderStart][INFO] Deinterlace: $DI" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    if [[ $ALANG ]]
    then
      echo "`date '+%D %T'` [FFEncoderStart][INFO] Audio language: $ALANG" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    fi
    echo "`date '+%D %T'` [FFEncoderStart][INFO] Target type: $TARGET_TYPE" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    echo "`date '+%D %T'` [FFEncoderStart][INFO] Target main: $TARGET_MAIN" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    echo "`date '+%D %T'` [FFEncoderStart][INFO] $ABR profiles found" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    JobABRParse
    # Screenshot filter
    FILTER_SS="fps=1,select='not(mod(t,5))'"
    # Text overlay filter
    FILTER_TEXT="drawtext='fontfile=$HOME_DIR/font/arial.ttf:fontsize=24:fontcolor=yellow:textfile=/opt/online/www/pwd/msg_cast:reload=1:x=(w-mod(2*n\,w+tw)):y=h-50'"
    if [[ "$STREAM_FIELD_ORDER" = "progressive" ]]
    then
      FILTER_DI="null"
    fi
#    FILTER_GLOBAL="$FILTER_TEXT$FILTER_DI"
    FILTER_GLOBAL="$FILTER_DI"
    #FILTER_COMPLEX="-filter_complex \"[0:v]fifo$FILTER_PIXEL_FORMAT$FILTER_SS[ss];[0:v]fifo$FILTER_PIXEL_FORMAT$FILTER_GLOBAL$FILTER_PROFILES\""
    FILTER_COMPLEX="-filter_complex \"[0:v]$FILTER_SS[ss];[0:v]$FILTER_GLOBAL$FILTER_PROFILES\""
#    SS_OPT="-an -map '[ss]' -q:v 12 -vsync vfr -update 1 $SCREEN_DIR/"$ID"_IN_screen_$TARGET_IDX.jpg"
    SS_OPT="-an -map '[ss]' -threads 1 -q:v 12 -vsync vfr -update 1 $SCREEN_DIR/"$ID"_IN_screen_$TARGET_IDX.jpg"
    echo "`date '+%D %T'` [FFEncoderStart][INFO] Source screenshots generation enabled" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    LOG_ENCODER="-loglevel warning"
#    LOG_ENCODER="FFREPORT=file=$LOG_DIR_JOBS/"$TARGET_IDX"_encoder.log:level=24"
    LOG_PROGRESS="-progress udp://127.0.0.1:99$i"
#    LOG_PROGRESS="-progress $LOG_DIR_JOBS/"$TARGET_IDX"_progress.log"
    GENERIC="$LOG_ENCODER $LOG_PROGRESS -y -analyzeduration $ANALYZE_DURATION"
#    QC="-max_error_rate 0.75"
    QC="-abort_on empty_output -max_error_rate 0.75 -ignore_unknown"
    STD_OUT="2>>$LOG_DIR_JOBS/"$TARGET_IDX"_encoder.log"
#    STD_OUT="2>&1"
    # FFMPEG main pipeline
    FFMPEG_START="$FFMPEG_BIN_PATH $GENERIC $QC $VDECODER $SOURCE_OPTIONS $FILTER_COMPLEX $SS_OPT $PROFILES $STD_OUT"
    echo "`date '+%D %T'` [FFEncoderStart][DEBUG] FFMPEG Pipe: $FFMPEG_START" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    exec `eval $FFMPEG_START` &
    #echo -en "\rJob $i start: Encoder core init"
    sed -i -e "`echo $i`c STOP UPDATING NA $SOURCE_ACTIVE NA NA NA NA" $HOME_DIR/online.www
    sleep 15
    #echo -en "\rJob $i start: Generating screenshots"
    ScreenshotGen
  else
    echo "`date '+%D %T'` [FFEncoderStart][INFO] MediaInfo: Source error" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
  fi
  JOB_STATE=`head -n $i $HOME_DIR/online.www | tail -n 1 | awk '{ print $1 }'`
  echo "`date '+%D %T'` [FFEncoderStart][INFO] Job state: $JOB_STATE" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
  if [[ "$SOURCE_UP" ]]
  then
    if [[ "$1" ]]
    then
      sed -i -e "`echo $i`c START $1 NA $SOURCE_ACTIVE NA NA NA NA" $HOME_DIR/online.www
      echo "`date '+%D %T'` [FFEncoderStart][INFO] Job status: $1" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    else
      sed -i -e "`echo $i`c START UPDATING NA $SOURCE_ACTIVE NA NA NA NA" $HOME_DIR/online.www
      echo "`date '+%D %T'` [FFEncoderStart][INFO] Job status: UPDATING" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    fi
  else
    sed -i -e "`echo $i`c START ERR_SRC NA $SOURCE_ACTIVE NA NA NA NA" $HOME_DIR/online.www
    echo "`date '+%D %T'` [FFEncoderStart][INFO] Job status: ERR_SRC" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
  fi
  FFProcFind
  if [[ "$JOB_PID" ]]
  then
    echo "`date '+%D %T'` [FFEncoderStart][INFO] Encoder started, PID: $JOB_PID" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
  else
    echo "`date '+%D %T'` [FFEncoderStart][INFO] Encoder start failed" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
  fi
}


FFEncoderStop() {
  JobDataParse $i
  echo "`date '+%D %T'` [FFEncoderStop][INFO] Encoder stop processing" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
  FFProcKill
  SOURCE_ACTIVE=`head -n $i $HOME_DIR/online.www | tail -n 1 | awk '{ print $4 }'`
  if ! [[ "$SOURCE_ACTIVE" ]]; then SOURCE_ACTIVE=1; fi
  if [[ "$1" ]]; then JOB_STATUS=$1; else JOB_STATUS="OFFLINE"; fi
  sed -i -e "`echo $i`c STOP $JOB_STATUS NA $SOURCE_ACTIVE NA NA NA NA" $HOME_DIR/online.www
  echo "`date '+%D %T'` [FFEncoderStop][DEBUG] online.www inject: STOP $JOB_STATUS NA $SOURCE_ACTIVE NA NA NA NA" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
  echo "`date '+%D %T'` [FFEncoderStop][INFO] Removing assets" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
  rm -f $SCREEN_DIR/"$ID"_OUT_screen_$TARGET_IDX.jpg &>/dev/null &
  rm -f $SCREEN_DIR/"$ID"_IN_screen_$TARGET_IDX.jpg &>/dev/null &
  if [[ "$TARGET_TYPE" = "HLS" ]] || [[ "$TARGET_TYPE" = "UDP_HLS" ]]
  then
    rm -rf $HLS_PATH_ABS/ &>/dev/null &
  fi
  echo "`date '+%D %T'` [FFEncoderStop][INFO] Encoder stopped" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
}


JobStart() {
  if [[ "$1" ]]
  then
    M=$1; N=$1
  else
    sv stop online &>/dev/null
    M=1
    echo "Start ALL jobs processing ($N)"
    echo "`date '+%D %T'` [JobStart][INFO] Start ALL jobs processing ($N)" >>$LOG_FILE_SYSTEM
  fi
  for i in `seq $M $N`
  do
    echo -en "\rJob $i start: "
    JobDataParse $i
    echo "`date '+%D %T'` [JobStart][INFO] Job start processing" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    FFProcFind
    if [[ "$FF_PROC_COUNT" = 0 ]]
    then
      FFEncoderStart $2&
      echo "`date '+%D %T'` [JobStart][INFO] Job started" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
      echo -e "\rJob $i start: OK"
    else
      echo "`date '+%D %T'` [JobStart][INFO] Job has already started (JOB_PID: $JOB_PID)" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
      echo -e "\rJob $i start: Already started (JOB_PID: $JOB_PID)"
    fi
  done
  if ! [[ "$1" ]]; then sv start online &>/dev/null & fi
}


JobStop() {
  if [[ "$1" ]]
  then
    JobDataParse $1
    M=$1; N=$1
    echo "`date '+%D %T'` [JobStop][INFO] Job stop processing" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
  else
    sv stop online &>/dev/null
    M=1
    echo "`date '+%D %T'` [JobStop][INFO] Stop ALL jobs processing ($N)" >>$LOG_FILE_SYSTEM
  fi
  for i in `seq $M $N`
  do
    echo -en "\rJob $i stop: "
    FFEncoderStop $2
    echo -e "\rJob $i stop: OK"
  done
  if ! [[ "$1" ]]; then sv start online &>/dev/null & fi
}


JobRestart() {
  if [[ "$1" ]]
  then
    JobDataParse $1
    echo "`date '+%D %T'` [JobRestart][INFO] Job restart processing" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    online stop $1 $2
    online start $1 $2
  else
    echo "`date '+%D %T'` [JobRestart][INFO] Restart ALL jobs processing ($N)" >>$LOG_FILE_SYSTEM
    online stop
    online start
  fi
}


# Set source for ALL jobs
JobSourceAll() {
  sv stop online &>/dev/null
  echo "Switch source processing ($N jobs)"
  echo "`date '+%D %T'` [JobSourceAll][INFO] Setting $1 source for ALL jobs ($N)" >>$LOG_FILE_SYSTEM
  for job in `seq 1 $N`
  do
    if [[ "$1" = "backup" ]]
    then
      S_IDX=2
      NEW_IDX=1
    else
      S_IDX=1
      NEW_IDX=2
    fi
    JobDataParse $job
    if [[ "$SOURCE_ACTIVE" = "$S_IDX" ]]
    then
      echo "`date '+%D %T'` [JobSourceAll][INFO] Job source is $1 already, skipping" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
      echo "Job $job: Source is $1 already, skipping"
    else
      WWW_INJECT=`head -n $job $HOME_DIR/online.www | tail -n 1 | awk -v NEW_IDX=$NEW_IDX '{ $4=NEW_IDX } { print }'`
      sed -i -e "`echo $job`c $WWW_INJECT" $HOME_DIR/online.www
      JobSource $job &>/dev/null
      echo "Job $job: New source is $SOURCE ($NEW_IDX)"
    fi
  done
  echo "Switch source complete"
  sv start online &>/dev/null &
}


JobSource() {
  if [[ "$1" ]]
  then
    i=$1
    JobDataParse $1
    echo "`date '+%D %T'` [JobSource][INFO] Job source switch processing" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    if [[ "$SOURCE_ACTIVE" = 1 ]]
    then
      if [[ "$SOURCE_BAK" ]]
      then
        echo "`date '+%D %T'` [JobSource][INFO] Job source switch: $SOURCE_MAIN -> $SOURCE_BAK" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
        echo "Job $1 source switch: $SOURCE_MAIN -> $SOURCE_BAK"
        SOURCE_ACTIVE=2
        JOB_RESTART=1
      else
        echo "`date '+%D %T'` [JobSource][INFO] No backup source defined, keeping current: $SOURCE_MAIN" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
        echo "Job $1 source switch: No backup source defined, keeping current: $SOURCE_MAIN"
      fi
    else
      if [[ "$SOURCE_MAIN" ]]
      then
        echo "`date '+%D %T'` [JobSource][INFO] Job source switch: $SOURCE_BAK -> $SOURCE_MAIN" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
        echo "Job $1 source switch: $SOURCE_BAK -> $SOURCE_MAIN"
        SOURCE_ACTIVE=1
        JOB_RESTART=1
      else
        echo "`date '+%D %T'` [JobSource][INFO] No main source defined, keeping current: $SOURCE_BAK" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
        echo "Job $1 source switch: No main source defined, keeping current: $SOURCE_BAK"
      fi
    fi
    JOB_STATUS=`head -n $1 $HOME_DIR/online.www | tail -n 1 | awk '{ print $2 }'`
    if [[ "$JOB_STATUS" = "ERR_SRC" || "$JOB_STATUS" = "ERR_ENC" ]]; then JOB_RESTART=1; fi
    if [[ "$JOB_RESTART" ]]
    then
      echo "`date '+%D %T'` [JobSource][INFO] Job restart required" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
      JOB_STATE=`head -n $1 $HOME_DIR/online.www | tail -n 1 | awk '{ print $1 }'`
      online stop $1 $2
      WWW_INJECT=`head -n $1 $HOME_DIR/online.www | tail -n 1 | awk -v SA=$SOURCE_ACTIVE '{ $4=SA } { print }'`
      sed -i -e "`echo $1`c $WWW_INJECT" $HOME_DIR/online.www
      echo "`date '+%D %T'` [JobSource][DEBUG] online.www inject: $WWW_INJECT" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
      JobDataParse $1
      if [[ "$JOB_STATE" = "START" ]]
      then
        FFEncoderStart &
      fi
      echo "`date '+%D %T'` [JobSource][INFO] Job source switch complete, new active source: $SOURCE ($SOURCE_ACTIVE)" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    fi
  else
    echo "Error: Job ID required"
    echo "Usage: online source <job_id>"
    echo "`date '+%D %T'` [JobSource][ERROR] Job ID required" >>$LOG_FILE_SYSTEM
  fi
}


JobDelete() {
  if [[ "$1" ]]
  then
    sv stop online &>/dev/null
    echo -en "\rJob $1 delete: "
    i=$1
    FFEncoderStop
    echo "`date '+%D %T'` [JobDelete][INFO] Job $1: Encoder stopped" >>$LOG_FILE_SYSTEM
    sed -i -e "`echo $1`d" $HOME_DIR/online.www
    sed -i -e "`echo $1`d" $HOME_DIR/online.src
    rm $LOG_DIR_JOBS/"$TARGET_IDX"_job.log &>/dev/null &
    rm $LOG_DIR_JOBS/"$TARGET_IDX"_encoder.log &>/dev/null &
    echo "`date '+%D %T'` [JobDelete][INFO] Job $1: Removing assets ("$ID"_IN_screen_$TARGET_IDX.jpg, "$ID"_OUT_screen_$TARGET_IDX.jpg, "$TARGET_IDX"_job.log, "$TARGET_IDX"_encoder.log)" >>$LOG_FILE_SYSTEM
    echo "`date '+%D %T'` [JobDelete][INFO] Job $1 deleted" >>$LOG_FILE_SYSTEM
    echo -e "\rJob $1 delete: OK"
  else
    echo "`date '+%D %T'` [JobDelete][ERROR] Job ID required" >>$LOG_FILE_SYSTEM
    echo "Error: Job ID required"
    echo "Usage: online delete <job_id>"
  fi
}


JobRestartErrorSource() {
  JOB_STATUS_FULL="START ERR_SRC NA $SOURCE_ACTIVE NA NA NA NA"
  sed -i -e "`echo $i`c $JOB_STATUS_FULL" $HOME_DIR/online.www
  mv -f $LOG_DIR_JOBS/"$TARGET_IDX"_encoder.log $LOG_DIR_JOBS_ERROR &>/dev/null &
  online source $i ERR_SRC
}


JobRestartErrorTarget() {
  JOB_STATUS_FULL="START ERR_ENC NA $SOURCE_ACTIVE NA NA NA NA"
  sed -i -e "`echo $i`c $JOB_STATUS_FULL" $HOME_DIR/online.www
  mv -f $LOG_DIR_JOBS/"$TARGET_IDX"_encoder.log $LOG_DIR_JOBS_ERROR &>/dev/null &
  online restart $i ERR_ENC
}


JobCheck() {
  if [[ "$1" ]]
  then
    M=$1; N=$1
  else
    M=1
    echo "ALL jobs check processing ($M-$N)"
    echo "`date '+%D %T'` [JobCheck][DEBUG] Job check heartbeat: $N jobs" >>$LOG_FILE_SYSTEM
  fi
  for i in `seq $M $N`
  do
    echo -en "\rJob $i check: "
    JOB_STATUS_FULL=`head -n $i $HOME_DIR/online.www | tail -n 1`
    JOB_STATE=`echo "$JOB_STATUS_FULL" | awk '{ print $1 }'`
    if [[ "$JOB_STATE" = "START" ]]
    then
      JobDataParse $i
      echo "`date '+%D %T'` [JobCheck][DEBUG] Job check processing" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
      FFProcFind
      ScreenshotGen
      SOURCE_ACTIVE=`head -n $i $HOME_DIR/online.www | tail -n 1 | awk '{ print $4 }'`
      if ! [[ "$SOURCE_ACTIVE" ]]; then SOURCE_ACTIVE=1; fi
      if [[ "$FF_PROC_COUNT" = 1 ]]
      then
        SS_EXIST=`echo "$SCREEN_DIR/"$ID"_IN_screen_$TARGET_IDX.jpg"`
        SS_EXPIRED=$(find $SCREEN_DIR/ -name "$ID"_IN_screen_$TARGET_IDX.jpg -mmin +4)
        if [[ -f "$SS_EXIST" && -z "$SS_EXPIRED" ]]
        then
          SS_EXIST=`echo "$SCREEN_DIR/"$ID"_OUT_screen_$TARGET_IDX.jpg"`
          SS_EXPIRED=$(find $SCREEN_DIR/ -name "$ID"_OUT_screen_$TARGET_IDX.jpg -mmin +4)
          if [[ -f "$SS_EXIST" && -z "$SS_EXPIRED" ]]
          then
            UPTIME=`ps -o etime,pid,cmd -C ffmpeg | grep "$SOURCE" | grep "$TARGET_MAIN" | head -n 1 | awk '{ print $1 }'`
            ENCODE_RATIO=$(timeout 2 nc -ul 99$i | grep speed | awk 'BEGIN { FS="=" } NR==1 { print $2 }' | tr -d " \t\n\r")
            ENCODE_RATIO=${ENCODE_RATIO:-NA}

            UTC_TIME_NOW=$(date +%s)
            UTC_TIME_INIT=$(head -n $i $HOME_DIR/online.www | tail -n 1 | awk '{ print $8 }')
            UTC_TIME_INIT=${UTC_TIME_INIT:-$UTC_TIME_NOW}
            if [[ "$UTC_TIME_INIT" = "NA" ]]; then UTC_TIME_INIT=$UTC_TIME_NOW; fi
            UTC_TIME_DIFF=$(($UTC_TIME_NOW - $UTC_TIME_INIT))
            echo "`date '+%D %T'` [JobCheck][DEBUG] UTC_TIME_NOW=$UTC_TIME_NOW, UTC_TIME_INIT=$UTC_TIME_INIT, UTC_TIME_DIFF=$UTC_TIME_DIFF" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log

            ERROR_LOG_NOW=`timeout 2 wc -l $LOG_DIR_JOBS/"$TARGET_IDX"_encoder.log | awk '{print $1}'`
            ERROR_LOG_LAST=$(head -n $i $HOME_DIR/online.www | tail -n 1 | awk '{ print $7 }')
            if [[ "$ERROR_LOG_LAST" = "NA" ]]; then ERROR_LOG_LAST=$ERROR_LOG_NOW; fi
            if (( $ERROR_LOG_LAST > $ERROR_LOG_NOW )); then ERROR_LOG_LAST=$ERROR_LOG_NOW; fi
            ERROR_LOG_LAST=${ERROR_LOG_LAST:-$ERROR_LOG_NOW}
            ERROR_LOG_DIFF=$(($ERROR_LOG_NOW - $ERROR_LOG_LAST))
            echo "`date '+%D %T'` [JobCheck][DEBUG] ERROR_LOG_NOW=$ERROR_LOG_NOW, ERROR_LOG_LAST=$ERROR_LOG_LAST, ERROR_LOG_DIFF=$ERROR_LOG_DIFF, ERROR_THRESHOLD=$ERROR_THRESHOLD, ERROR_WINDOW=$ERROR_WINDOW" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log

            JOB_STATUS_ONLINE=0
            if (( $ERROR_LOG_DIFF >= $ERROR_THRESHOLD ))
            then
              echo "`date '+%D %T'` [JobCheck][ERROR] Log errors threshold exeeded: $ERROR_LOG_DIFF / $ERROR_THRESHOLD" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log

              if (( $UTC_TIME_DIFF >= $ERROR_WINDOW ))
              then
                echo "`date '+%D %T'` [JobCheck][DEBUG] Log errors check interval exeeded: $UTC_TIME_DIFF / $ERROR_WINDOW" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
                JobRestartErrorTarget
              else
                JOB_STATUS_ONLINE=1
              fi

            else
              UTC_TIME_INIT="NA"
              ERROR_LOG_DIFF=0
              JOB_STATUS_ONLINE=1
            fi

            if [[ "$JOB_STATUS_ONLINE" = 1 ]]
            then
              JOB_STATUS_FULL="START ONLINE $UPTIME $SOURCE_ACTIVE $ENCODE_RATIO $ERROR_LOG_DIFF $ERROR_LOG_NOW $UTC_TIME_INIT"
              sed -i -e "`echo $i`c $JOB_STATUS_FULL" $HOME_DIR/online.www
            fi

          else
            echo "`date '+%D %T'` [JobCheck][ERROR] Target screenshot is absent or expired" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
            rm "$SS_EXPIRED" &>/dev/null &
            JobRestartErrorTarget
          fi
        else
          if [ -f $SS_EXIST ]; then SS_EXIST="True"; else SS_EXIST="False"; fi
          echo "`date '+%D %T'` [JobCheck][DEBUG] SS_EXIST: $SS_EXIST, SS_EXPIRED: $SS_EXPIRED" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
          echo "`date '+%D %T'` [JobCheck][ERROR] Source screenshot is absent or expired" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
          rm "$SS_EXPIRED" &>/dev/null &
          JobRestartErrorSource
        fi
      else
        if [[ "$FF_PROC_COUNT" = 0 ]]
        then
          echo "`date '+%D %T'` [JobCheck][INFO] No FFMPEG process(es) found" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
#          HTTP_UA_Setup
          SOURCE_UP=`eval timeout 30 $HOME_DIR/lib/ffprobe -hide_banner $HTTP_UA_VALUE -analyzeduration $ANALYZE_DURATION $SOURCE -show_streams -select_streams v 2>&1 | grep "STREAM"`
          if [[ "$SOURCE_UP" ]]
          then
            echo "`date '+%D %T'` [JobCheck][ERROR] Target error detected" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
            JobRestartErrorTarget
          else
            echo "`date '+%D %T'` [JobCheck][ERROR] Source error detected" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
            JobRestartErrorSource
          fi
        else
          echo "`date '+%D %T'` [JobCheck][ERROR] More that one FFMPEG instance detected (killed)" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
          JobRestartErrorTarget
        fi
      fi
      echo "`date '+%D %T'` [JobCheck][INFO] Job status: $JOB_STATUS_FULL" >>$LOG_DIR_JOBS/"$TARGET_IDX"_job.log
    fi
    echo -e "\rJob $i check: $JOB_STATUS_FULL"
  done
  if [ "$JOB_SWITCH_TIME" ] && [ "$JOB_SWITCH_SOURCE" ]
  then
    TIME_NOW=$(date +%k%M)
    JOB_SWITCH_TIME=$(date -d $JOB_SWITCH_TIME +%k%M)
    if (( $TIME_NOW >= $JOB_SWITCH_TIME )) && (( $TIME_NOW <= $(($JOB_SWITCH_TIME + 5)) ))
    then
      echo "`date '+%D %T'` [JobCheck][INFO] Scheduled source switch for all jobs: $JOB_SWITCH_SOURCE" >>$LOG_FILE_SYSTEM
      online source_all $JOB_SWITCH_SOURCE
    fi
  fi
  if ! [[ "$1" ]]; then sleep 15; fi
}


CPUInfo() {
  PREV_TOTAL=0
  PREV_IDLE=0
  # Get the total CPU statistics
  CPU=(`cat /proc/stat | grep '^cpu '`)
  # Discard the "cpu" prefix
  unset CPU[0]
  # Get the idle CPU time
  IDLE=${CPU[4]}
  # Calculate the total CPU time.
  TOTAL=0
  for VALUE in "${CPU[@]:0:4}"
  do
    let "TOTAL=$TOTAL+$VALUE"
  done
  # Calculate the CPU usage since we last checked
  let "DIFF_IDLE=$IDLE-$PREV_IDLE"
  let "DIFF_TOTAL=$TOTAL-$PREV_TOTAL"
  let "DIFF_USAGE=(1000*($DIFF_TOTAL-$DIFF_IDLE)/$DIFF_TOTAL+5)/10"
  echo "$DIFF_USAGE%"
}


SystemUpdate() {
  source $UPDATE_VER_LOCAL
  echo "App update processing..."
  echo "Local version: $APP_VER_LOCAL"
  echo "`date '+%D %T'` [SystemUpdate][INFO] Local version: $APP_VER_LOCAL" >>$LOG_FILE_SYSTEM
  APP_VER_REMOTE=$(curl -sf $UPDATE_VER_REMOTE)
  APP_VER_REMOTE=${APP_VER_REMOTE:-Error}
  echo "Remote version: $APP_VER_REMOTE"
  echo "`date '+%D %T'` [SystemUpdate][INFO] Remote version: $APP_VER_REMOTE" >>$LOG_FILE_SYSTEM
  if [ "$APP_VER_REMOTE" != "Error" ] && [ "$APP_VER_LOCAL" != "$APP_VER_REMOTE" ]
  then
    if ! [[ -d "$UPDATE_DIR_LOCAL" ]]; then mkdir -p $UPDATE_DIR_LOCAL; fi
    cd $UPDATE_DIR_LOCAL &>/dev/null
    echo "`date '+%D %T'` [SystemUpdate][INFO] Set work dir: $UPDATE_DIR_LOCAL/$UPDATE_FILE_NAME" >>$LOG_FILE_SYSTEM
#    sv stop online &>/dev/null
    UPDATE_FILE_REMOTE="$UPDATE_URL/$UPDATE_FILE_NAME$UPDATE_FILE_EXT"
    echo "`date '+%D %T'` [SystemUpdate][INFO] Downloading update ($UPDATE_FILE_REMOTE)" >>$LOG_FILE_SYSTEM
    curl $UPDATE_FILE_REMOTE -o $UPDATE_FILE_LOCAL &>/dev/null
    echo "`date '+%D %T'` [SystemUpdate][INFO] Extracting update ($UPDATE_FILE_LOCAL)" >>$LOG_FILE_SYSTEM
    tar fxz $UPDATE_FILE_LOCAL && rm -f $UPDATE_FILE_LOCAL >/dev/null
    if [[ -f update_run.sh ]]
    then
      echo "`date '+%D %T'` [SystemUpdate][INFO] Update actions required, running update_run.sh" >>$LOG_FILE_SYSTEM
      chmod +x update_run.sh &>/dev/null
      ./update_run.sh $HOME_DIR $LOG_FILE_SYSTEM &>/dev/null
    else
      echo "`date '+%D %T'` [SystemUpdate][INFO] Update actions are not required, skipping" >>$LOG_FILE_SYSTEM
    fi
    \cp -fR . $HOME_DIR &>>$LOG_FILE_SYSTEM
    if [[ -d "$UPDATE_DIR_LOCAL/sys" ]]
    then
      chown -R root:root sys/etc/sudoers.d &>/dev/null
      chmod 755 sys/etc/sudoers.d &>/dev/null
      chmod 440 sys/etc/sudoers.d/* &>/dev/null
      \cp -fR sys/* / &>>$LOG_FILE_SYSTEM
    fi
    echo "`date '+%D %T'` [SystemUpdate][INFO] Update content extracted" >>$LOG_FILE_SYSTEM
    rm -rf $UPDATE_DIR_LOCAL/ &>/dev/null
    cd $HOME_DIR/lib
    sudo ./build.sh &>/dev/null
#    sudo service php7.0-fpm restart &>/dev/null
#    sudo service nginx restart &>/dev/null
    sudo sv restart online &>/dev/null
    echo "System update complete, new version: $APP_VER_REMOTE"
    echo "`date '+%D %T'` [SystemUpdate][INFO] System update complete, new version: $APP_VER_REMOTE" >>$LOG_FILE_SYSTEM
  else
    echo "Software has latest version"
  fi
}


JobIDCheck() {
  if [[ "$2" ]]
  then
    if [[ "$2" =~ ^[0-9]+$ ]] && [ "$2" -ge 1 -a "$2" -le $N ]
    then
      $1 $2 $3
    else
      echo "Job ID is not found"
    fi
  else
    $1 $2 $3
  fi
}


if [[ "$1" = "init" ]]; then echo "System init: OK";
elif [[ "$1" = "start" ]]; then JobIDCheck JobStart $2 $3;
elif [[ "$1" = "stop" ]]; then JobIDCheck JobStop $2 $3;
elif [[ "$1" = "restart" ]]; then JobIDCheck JobRestart $2 $3;
elif [[ "$1" = "source" ]]; then JobIDCheck JobSource $2 $3;
elif [[ "$1" = "source_all" ]]; then JobSourceAll $2;
elif [[ "$1" = "delete" ]]; then JobIDCheck JobDelete $2;
elif [[ "$1" = "check" ]]; then JobIDCheck JobCheck $2;
elif [[ "$1" = "target_idx" ]]; then JobIDCheck TargetIDXGet $2;
elif [[ "$1" = "cpu_info" ]]; then CPUInfo;
elif [[ "$1" = "update" ]]; then SystemUpdate;
else echo -e "Error: command is not defined\nUsage: online <command> [job_id]"; fi

