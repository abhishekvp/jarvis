#!/bin/bash
# 
# Thanks to the Speech Recognition Script using Google's Speech API from Amine SEHILI <https://github.com/amsehili/gspeech-rec> 
#
# Usage info
show_help() {
cat << EOF
  Usage: ${0##*/} [-h] [-i INFILE] [-d DURATION] [-r RATE] [-l LANGUAGE] [-k KEY]
  
  Record an utterance and send audio data to Google for speech recognition.
  
       -h|--help               display this help and exit
       -i|--input     INFILE   use INFILE instead of recording a stream with parecord.
       -d|--duration  FLOAT    recoding duration in seconds (Default: 3).
       -l|--language  STRING   set transcription language (Default: en_US).
                               Other languages: fr-FR, de-DE, es-ES, ...
       -r|--rate      INTEGER  Sampling rate of recorded data (Default: 16000).
                               If -i|--input is used, the sampling rate must be supplied by the user.
       -k|--key       STRING   Google Speech Recognition Key.
                  
EOF
}
 
DURATION=3
LANGUAGE=en-US

# PLEASE REPLACE THIS WITH YOUR OWN KEY <https://console.cloud.google.com> for the Google Cloud Speech API
KEY=AIzaSyBOti4mM-6x9WDnZIjIeyEU21OpBXqWBgw

record() {
    DURATION=$1
    SRATE=$2
    INFILE=$3
    
    if hash rec 2>/dev/null; then
    # try to record audio with sox 
        rec -q -c 1 -r $SRATE $INFILE trim 0 $DURATION
    else
    # fallback to parecord
        timeout $DURATION parecord $INFILE --file-format=flac --rate=$SRATE --channels=1
    fi
}
 
# parse parameters
while [[ $# -ge 1 ]]
do
   key="$1"
   case $key in
       -h|--help)
       show_help
       exit 0
       ;;
       -i|--input)
       INFILE="$2"
       shift
       ;;
       -d|--duration)
       DURATION="$2"
       shift
       ;;
       -r|--rate)
       SRATE=$2
       shift
       ;;
       -l|--language)
       LANGUAGE="$2"
       shift
       ;;
       -k|--key)
       KEY="$2"
       shift
       ;;
       *)
       echo "Unknown parameter '$key'. Type $0 -h for more information."
       exit 1
       ;;
   esac
   shift
done
 
if [[ ! "$DURATION" ]]
   then
     echo "ERROR: empty or invalid value for duration."
     exit 1
fi
 
if [[ ! "$LANGUAGE" ]]
   then
     echo "ERROR: empty value for language."
     exit 1
fi
 
if [[ ! "$INFILE" ]]
   then
      INFILE=record.flac
      if  [[ ! "$SRATE" ]]
         then
            SRATE=16000
      fi
      echo "Jarvis is up. Listening for commands..."
      record $DURATION $SRATE $INFILE
 
else
      if  [[ ! "$SRATE" ]]
      then
           >&2 echo "ERROR: no sampling rate specified for input file."
           exit 1
      fi
 
      echo "Try to recognize speech from file $INFILE"
      echo ""
fi
 
RESULT=`wget -q --post-file $INFILE --header="Content-Type: audio/x-flac; rate=$SRATE" -O - "http://www.google.com/speech-api/v2/recognize?client=chromium&lang=$LANGUAGE&key=$KEY"`
 
#echo "$RESULT";
FILTERED=`echo "$RESULT" | sed 's/,/\n/g;s/[{,},"]//g;s/\[//g;s/\]//g;s/:/: /g'| grep -o -i -e "transcript.*" | sed 's/transcript: //' | sed -e 'H;${x;s/\n/,/g;s/^,//;p;};d'`;
OUTPUT="${FILTERED%%,*}"

if [[ ! "$OUTPUT" ]]
  then
     >&2  "Sorry, I am unable to recognize any speech in audio data"
else
	if [[ $OUTPUT == *"morning"* ]]
	then
	  espeak "Good Morning Sir!";
	elif [[ $OUTPUT == *"evening"* ]]
	then
	  espeak "Good Evening Sir!";
	elif [[ $OUTPUT == *"how are you"* ]]
	then
	  espeak "I am doing great. Thank You Sir.";
	elif [[ $OUTPUT == *"wake up"* ]]
	then
	  espeak "Yes Sir. I am up and running Sir!";
	elif [[ $OUTPUT == *"you there"* || $OUTPUT == *"you up"* ]]
	then
	  espeak "Yes Sir. I am up and running!";
	elif [[ $OUTPUT == *"who are you"* || $OUTPUT == *"what are you"* || $OUTPUT == *"introduce"* ]]
	then
	  espeak "I am JARVIS, the voice enabled personal assistant!";
	elif [[ $OUTPUT == *"mail"* ]]
	then
	  espeak "Opening your mail Sir!"; 
	  chromium-browser http://www.gmail.com
	elif [[ $OUTPUT == *"song"* ]]
	then
	  espeak "Playing the song now Sir!"; 
	  chromium-browser https://www.youtube.com/watch?v=hdw1uKiTI5c
	elif [[ $OUTPUT == *"facebook"* ]]
	then
	  espeak "Opening your Facebook Sir!"; 
	  chromium-browser http://www.facebook.com
	elif [[ $OUTPUT == *"search"* || $OUTPUT == *"google"* ]]
	then
	  QUERY="${OUTPUT#*search }";
	  FINAL=`echo $QUERY | sed 's/ /+/g'`;
	  espeak "Searching your query online for $QUERY"; 
	  chromium-browser http://www.google.com/search?q=$FINAL
	elif [[ $OUTPUT == *"dismissed"* || $OUTPUT == *"sleep"* || $OUTPUT == *"rest"*}} ]]
	then
	  espeak "I am leaving the machine on for you. Have a Great Day! Good Bye Sir!";
	  kill -9 `ps --pid $$ -oppid=`; exit
	elif [[ $OUTPUT == *"log off"* || $OUTPUT == *"lock"*  ]]
	then
	  espeak "Logging Off Sir!";
	  gnome-screensaver-command -l
	elif [[ $OUTPUT == *"shutdown"* || $OUTPUT == *"power off"* || $OUTPUT == *"switch off"* ]]
	then
	  espeak "Shutting down system, Goodbye Sir!";
	  echo linux | sudo -S poweroff
	elif [[ $OUTPUT == *"restart"* || $OUTPUT == *"reboot"* || $OUTPUT == *"reset"* ]]
	then
	  espeak "Rebooting system. Now shutting down, Goodbye Sir!";
	  echo linux | sudo -S reboot
	else
	  echo "I am sorry, Sir. I still have lots to learn."
	fi
fi


 
exit 0
