#!/bin/bash

# Script de conversion/compression MKV vers MP4
# Usage: ./mkv_to_gif.sh [options] fichier.mkv [fichier2.mkv ...]

# Valeurs par défaut
WIDTH=720
FPS=30
START_TIME=""
DURATION=""
QUALITY="medium"  # low, medium, high
KEEP_AUDIO=true

# Fonction d'aide
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] fichier.mkv [fichier2.mkv ...]

Convertit/compresse des fichiers MKV en MP4 (avec son).

OPTIONS:
    -w, --width WIDTH       Largeur de la vidéo (défaut: 720, -1 pour garder l'originale)
    -f, --fps FPS          Images par seconde (défaut: 30)
    -s, --start TIME       Temps de départ (format: HH:MM:SS ou secondes)
    -d, --duration TIME    Durée de l'extrait (format: HH:MM:SS ou secondes)
    -q, --quality QUALITY  Qualité: low, medium, high (défaut: medium)
    -n, --no-audio         Supprimer le son
    -a, --all              Convertir tous les .mkv du répertoire courant
    -h, --help             Afficher cette aide

EXEMPLES:
    # Convertir un fichier avec les paramètres par défaut (720p, son inclus)
    $(basename "$0") video.mkv

    # Convertir en 1080p avec haute qualité
    $(basename "$0") -w 1920 -q high video.mkv

    # Extraire de 10s à 15s et convertir
    $(basename "$0") -s 10 -d 5 video.mkv

    # Convertir tous les MKV du dossier
    $(basename "$0") --all

    # Basse qualité pour des fichiers très légers
    $(basename "$0") -q low video.mkv

    # Sans audio
    $(basename "$0") --no-audio video.mkv

    # Garder la résolution originale
    $(basename "$0") -w -1 video.mkv

EOF
    exit 0
}

# Parser les arguments
FILES=()
CONVERT_ALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -w|--width)
            WIDTH="$2"
            shift 2
            ;;
        -f|--fps)
            FPS="$2"
            shift 2
            ;;
        -s|--start)
            START_TIME="$2"
            shift 2
            ;;
        -d|--duration)
            DURATION="$2"
            shift 2
            ;;
        -q|--quality)
            QUALITY="$2"
            shift 2
            ;;
        -n|--no-audio)
            KEEP_AUDIO=false
            shift
            ;;
        -a|--all)
            CONVERT_ALL=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            FILES+=("$1")
            shift
            ;;
    esac
done

# Si --all est activé, récupérer tous les .mkv
if [ "$CONVERT_ALL" = true ]; then
    FILES=(*.mkv)
fi

# Vérifier qu'on a des fichiers à traiter
if [ ${#FILES[@]} -eq 0 ]; then
    echo "Erreur: Aucun fichier à convertir"
    echo "Utilisez -h pour l'aide"
    exit 1
fi

# Vérifier que ffmpeg est installé
if ! command -v ffmpeg &> /dev/null; then
    echo "Erreur: ffmpeg n'est pas installé"
    exit 1
fi

# Définir les paramètres de qualité (CRF pour H.264)
# CRF: 0=lossless, 23=défaut, 51=pire qualité
# Plus bas = meilleure qualité mais fichier plus gros
case $QUALITY in
    low)
        CRF=28
        PRESET="fast"
        AUDIO_BITRATE="96k"
        ;;
    medium)
        CRF=23
        PRESET="medium"
        AUDIO_BITRATE="128k"
        ;;
    high)
        CRF=18
        PRESET="slow"
        AUDIO_BITRATE="192k"
        ;;
    *)
        echo "Qualité invalide: $QUALITY (utilisez: low, medium, high)"
        exit 1
        ;;
esac

# Fonction de conversion
convert_mkv_to_mp4() {
    local input="$1"
    local output="${input%.mkv}.mp4"
    
    # Vérifier que le fichier existe
    if [ ! -f "$input" ]; then
        echo "Erreur: Le fichier '$input' n'existe pas"
        return 1
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Conversion: $input → $output"
    echo "Paramètres: ${WIDTH}px, ${FPS}fps, qualité: $QUALITY (CRF=$CRF)"
    
    # Construire les options ffmpeg
    local ffmpeg_input_opts=""
    local video_filters="fps=$FPS"
    
    if [ -n "$START_TIME" ]; then
        ffmpeg_input_opts="$ffmpeg_input_opts -ss $START_TIME"
        echo "Départ: ${START_TIME}s"
    fi
    
    if [ -n "$DURATION" ]; then
        ffmpeg_input_opts="$ffmpeg_input_opts -t $DURATION"
        echo "Durée: ${DURATION}s"
    fi
    
    # Ajouter le scaling si nécessaire
    if [ "$WIDTH" != "-1" ]; then
        video_filters="$video_filters,scale=$WIDTH:-2"
    fi
    
    # Options audio
    local audio_opts=""
    if [ "$KEEP_AUDIO" = true ]; then
        audio_opts="-c:a aac -b:a $AUDIO_BITRATE"
        echo "Audio: inclus ($AUDIO_BITRATE)"
    else
        audio_opts="-an"
        echo "Audio: supprimé"
    fi
    
    # Conversion
    echo "Conversion en cours..."
    ffmpeg -v warning $ffmpeg_input_opts -i "$input" \
        -c:v libx264 -preset $PRESET -crf $CRF \
        -vf "$video_filters" \
        $audio_opts \
        -movflags +faststart \
        -y "$output" 2>&1 | grep -v "^$"
    
    if [ -f "$output" ]; then
        local input_size=$(du -h "$input" | cut -f1)
        local output_size=$(du -h "$output" | cut -f1)
        local reduction=$(awk "BEGIN {printf \"%.1f\", (1 - $(stat -f%z "$output" 2>/dev/null || stat -c%s "$output") / $(stat -f%z "$input" 2>/dev/null || stat -c%s "$input")) * 100}")
        echo "✓ Terminé: $output_size (original: $input_size, réduction: ${reduction}%)"
        return 0
    else
        echo "✗ Erreur lors de la conversion"
        return 1
    fi
}

# Convertir tous les fichiers
success_count=0
fail_count=0

for file in "${FILES[@]}"; do
    if convert_mkv_to_mp4 "$file"; then
        ((success_count++))
    else
        ((fail_count++))
    fi
    echo
done

# Résumé
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Résumé: $success_count réussi(s), $fail_count échec(s)"
