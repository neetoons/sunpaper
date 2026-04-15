#!/bin/bash

#################################################
# BASIC CONFIGURATION
#################################################
latitude="10.4806N"  # Actualizado a Caracas para ti, bella
longitude="66.9036W"
wallpaperPath="$HOME/sunpaper/images/Corporate-Synergy"
cachePath="$HOME/.cache"
awww_enable="true"
awww_transition_type="wipe" # "wipe", "fade", "crossfade"
awww_transition_duration=2

# Otros modos (puedes activarlos si tienes los assets)
moonphase_enable="false"
weather_enable="false"
weather_api_key=""
weather_city_id="3646738" # Caracas ID

# --- Variables Internas ---
version="2.1-awww"
cacheFileWall="$cachePath/sunpaper_cache.wallpaper"
cacheFileDay="$cachePath/sunpaper_cache.day"
cacheFileNight="$cachePath/sunpaper_cache.night"
cacheFileWeather="$cachePath/sunpaper_cache.weather"

#################################################
# FUNCTIONS (The logic)
#################################################

set_cache(){
    if [ ! -d "$cachePath" ]; then mkdir -p "$cachePath"; fi
    if [ -f "$cacheFileWall" ]; then
        currentpaper=$( cat < "$cacheFileWall" )
    else
        touch "$cacheFileWall"
        echo "0" > "$cacheFileWall"
        currentpaper=0
        awww_first="true"
    fi
}

clear_cache(){
    rm "$cacheFileWall" "$cacheFileDay" "$cacheFileNight" "$cacheFileWeather" 2>/dev/null
    echo "Cache despejado, ¡como tu cutis después de un skin care! ✨"
}

get_currenttime(){
    if [ "$time" ]; then
        currenttime=$(date -d "$time" +%s)
    else
        currenttime=$(date +%s)
    fi
}

get_suntimes(){
    # Requiere 'sunwait' instalado en tu NixOS
    get_sunrise=$(sunwait list civil rise $latitude $longitude)
    get_sunset=$(sunwait list civil set $latitude $longitude)

    sunrise=$(date -d "$get_sunrise" +"%s")
    sunriseMid=$(date -d "$get_sunrise 15 minutes" +"%s")
    sunriseLate=$(date -d "$get_sunrise 30 minutes" +"%s")
    dayLight=$(date -d "$get_sunrise 90 minutes" +"%s")
    twilightEarly=$(date -d "$get_sunset 90 minutes ago" +"%s")
    twilightMid=$(date -d "$get_sunset 30 minutes ago" +"%s")
    twilightLate=$(date -d "$get_sunset 15 minutes ago" +"%s")
    sunset=$(date -d "$get_sunset" +"%s")
}

get_sunpoll(){
    if [ "$currenttime" -ge "$sunrise" ] && [ "$currenttime" -lt "$sunset" ]; then
        sun_poll="DAY"
    else
        sun_poll="NIGHT"
    fi
}

exec_awww(){
    if ! pgrep -x "awww" > /dev/null ; then
        nohup awww > /dev/null 2>&1 &
        sleep 1
    fi
}

setpaper_construct(){
    # Lógica de Clima
    if [[ "$weather_enable" == "true" ]] && [[ -f "$wallpaperPath/rain/1.jpg" ]]; then
        if [[ ! -z "$currentWeather" ]] && [[ "$currentWeather" != "cloud" ]]; then
            wallpaperPath="$wallpaperPath/$currentWeather"
        fi
    fi

    # Lógica de awww (A Wayland Wallpaper Wallower `[A Wayland Wallpaper Wallower]` )
    if [ "$awww_enable" == "true" ]; then
        exec_awww
        if [ "$awww_first" == "true" ]; then
            awww -i "$wallpaperPath"/"$image".jpg --transition-duration 0
        else
            awww -i "$wallpaperPath"/"$image".jpg --transition-type "$awww_transition_type" --transition-duration "$awww_transition_duration"
        fi
    fi
}

set_paper(){
    if [ "$currenttime" -ge "$sunrise" ] && [ "$currenttime" -lt "$sunriseMid" ]; then image=2
    elif [ "$currenttime" -ge "$sunriseMid" ] && [ "$currenttime" -lt "$sunriseLate" ]; then image=3
    elif [ "$currenttime" -ge "$sunriseLate" ] && [ "$currenttime" -lt "$dayLight" ]; then image=4
    elif [ "$currenttime" -ge "$dayLight" ] && [ "$currenttime" -lt "$twilightEarly" ]; then image=5
    elif [ "$currenttime" -ge "$twilightEarly" ] && [ "$currenttime" -lt "$twilightMid" ]; then image=6
    elif [ "$currenttime" -ge "$twilightMid" ] && [ "$currenttime" -lt "$twilightLate" ]; then image=7
    elif [ "$currenttime" -ge "$twilightLate" ] && [ "$currenttime" -lt "$sunset" ]; then image=8
    else image=1; fi

    if [[ "$currentpaper" != "$image" ]]; then
        echo "$image" > "$cacheFileWall"
        setpaper_construct
    fi
}

main(){
    get_currenttime
    get_suntimes
    set_cache
    set_paper
}

#################################################
# CLI ARGUMENTS
#################################################

while :; do
    case $1 in
        -h|--help) echo "Usa -d para daemon, -c para limpiar cache, -r para reporte."; exit ;;
        -c|--clear) clear_cache; exit ;;
        -r|--report) main; echo "Current image: $image"; exit ;;
        -d|--daemon) daemon_enable="true" ;;
        -k|--kill) pkill -f sunpaper.sh; exit ;;
        *) break ;;
    esac
    shift
done

if [ "$daemon_enable" == "true" ]; then
    main
    while :; do
        main
        sleep 60
    done
else
    main
fi
