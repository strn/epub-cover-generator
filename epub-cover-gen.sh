#!/usr/bin/env bash

###################################################
#
# This program generates images that should serve
# as EPUB covers
#
# Author: strngit@github.com
#
###################################################

### Variables ###

### General variables ###
TEMPLATE_LIST=("kentaur" "polaris")
DEF_TITLE_FONT="Times-New-Roman"
DEF_AUTHOR_FONT="Arial"
DEF_PUBLISHER_FONT="Arial"
# Colours for book title
DEF_BOOK_TITLE_FG="yellow"
DEF_BOOK_TITLE_BG="black"
# Colours for author's name
DEF_AUTHOR_NAME_FG="white"
DEF_AUTHOR_NAME_BG="black"
# Colours for publisher
DEF_PUBLISHER_NAME_FG="white"
DEF_PUBLISHER_NAME_BG="black"
#
### Kentaur template default variables ###
#
# Part of original image height that
# certain parts occupy
#
# What part of original image (1/...) will
# title height be
DEF_PART_TITLE=3
# What part of original image (1/...) will
# author's name height be
DEF_PART_AUTHOR=13
# What part of original image (1/...) will
# publisher's name height be
DEF_PART_PUBLISHER=21
#
### Polaris template default variables ###
#
#
# What percent of image's width
# will be taken for margin space
DEF_MARGIN_PERCENT_WIDTH=1
# What percent of image's height
# will be taken for margin space
DEF_MARGIN_PERCENT_HEIGHT=1
# Number of vertical areas into
# front cover image will be divided
DEF_NUM_VERT_PARTS=3

### Functions ###

function log_info() {
    echo "$(date +'%Y-%y-%d %H:%M:%S')  [INFO] $@"
}

function log_warn() {
    echo "$(date +'%Y-%y-%d %H:%M:%S')  [WARN] $@"
}

function log_fatal() {
    echo "$(date +'%Y-%y-%d %H:%M:%S') [FATAL] $@"
    exit 1
}

# Check if all required utilities are available
function check_environment() {
    log_info "Checking environment..."
    which identify >/dev/null 2>&1
    [ $? -ne 0 ] && log_fatal "Imagemagick's 'identify' utility was not found"
    which convert >/dev/null 2>&1
    [ $? -ne 0 ] && log_fatal "Imagemagick's 'convert' utility was not found"
    which bc >/dev/null 2>&1
    [ $? -ne 0 ] && log_fatal "Calculator 'bc' utility was not found"
}

# Check program parameter<PATH_TO_CONFIG_FILE>s
function check_general_parameters() {
    log_info "Checking parameters..."

    [ -z "$TEMPLATE" ] && log_fatal "Template name (TEMPLATE=...) is not specified"
    [[ ! "${TEMPLATE_LIST[@]}" =~ "${TEMPLATE,,}" ]] && log_fatal \
    "Unknown template '$TEMPLATE'. Allowed values are: [${TEMPLATE_LIST[@]}]"
    # Set temporary directory

}

function usage() {
    cat <<EOF

$(basename $0) <PATH_TO_CONFIG_FILE>

<PATH_TO_CONFIG_FILE> is a simple text file which consists
of consecutive lines in format NAME=VALUE. NAMEs are:

TEMPLATE    describes cover layout. Allowed values are: ['kentaur', 'polaris']

EOF
    exit
}

function check_kentaur_params() {
    [ -z "$FRONT_IMG" ] && log_fatal "Front cover image (FRONT_IMG=...) is not specified"
    [ ! -f "$FRONT_IMG" ] && log_fatal "Front cover image file '$FRONT_IMG' does not exist"
    if [ -z "$BOOK_TITLE_FONT" ]; then
        log_warn "Font for book's title was not specified. Using '$DEF_TITLE_FONT'"
        BOOK_TITLE_FONT="$DEF_TITLE_FONT"
    fi
    if [ -z "$BOOK_AUTHOR_FONT" ]; then
        log_warn "Font for author's name was not specified. Using '$DEF_AUTHOR_FONT'"
        BOOK_AUTHOR_FONT="$DEF_AUTHOR_FONT"
    fi
    [ -z "$BOOK_TITLE" ] && log_fatal "Book title (BOOK_TITLE=...) was not specified"
    [ -z "$AUTHOR_NAME" ] && log_fatal "Book author (AUTHOR_NAME=...) was not specified"
    if [ -z "$BOOK_TITLE_FG" ]; then
        log_warn "Book's title foreground colour not set, using '$DEF_BOOK_TITLE_FG'"
        BOOK_TITLE_FG="$DEF_BOOK_TITLE_FG"
    fi
    if [ -z "$BOOK_TITLE_BG" ]; then
        log_warn "Book's title background colour not set, using '$DEF_BOOK_TITLE_BG'"
        BOOK_TITLE_BG="$DEF_BOOK_TITLE_BG"
    fi
    if [ -z "$AUTHOR_NAME_FG" ]; then
        log_warn "Author's title foreground colour not set, using '$DEF_AUTHOR_NAME_FG'"
        AUTHOR_NAME_FG="$DEF_AUTHOR_NAME_FG" 
    fi
    if [ -z "$AUTHOR_NAME_BG" ]; then
        log_warn "Author's title background colour not set, using '$DEF_AUTHOR_NAME_BG'"
        AUTHOR_NAME_BG="$DEF_AUTHOR_NAME_BG"  
    fi
    if [ -n "$PUBLISHER_NAME" ]; then
        if [ -z "$PUBLISHER_NAME_FG" ]; then
            log_warn "Publisher's name foreground colour was not specified. Using '$DEF_PUBLISHER_NAME_FG'"
            PUBLISHER_NAME_FG="$DEF_PUBLISHER_NAME_FG"
        fi
        if [ -z "$PUBLISHER_NAME_BG" ]; then
            log_warn "Publisher's name background colour was not specified. Using '$DEF_PUBLISHER_NAME_BG'"
            PUBLISHER_NAME_BG="$DEF_PUBLISHER_NAME_BG"
        fi
        if [ -z "$PUBLISHER_FONT" ]; then
            log_warn "Font for publisher's name was not specified. Using '$DEF_PUBLISHER_FONT'"
            PUBLISHER_FONT="$DEF_PUBLISHER_FONT"
        fi
    fi
    # Assign default values for parts
    [ -z "$PART_TITLE" ] && PART_TITLE=$DEF_PART_TITLE
    [ -z "$PART_AUTHOR" ] && PART_AUTHOR=$DEF_PART_AUTHOR
    [ -z "$PART_PUBLISHER" ] && PART_PUBLISHER=$DEF_PART_PUBLISHER
}

# Generate cover according to 'kentaur' layout
function generate_kentaur_cover() {
    # Determine cover image size. All elements will be calculated
    # based on that
    read -r FRONT_IMG_W FRONT_IMG_H < <(identify -format "%w %h" "$FRONT_IMG")
    # Allow title to be max 1/$PART_TITLE height of cover image
    TITLE_H=$(echo "$FRONT_IMG_H / $PART_TITLE" | bc)
    magick -background "$BOOK_TITLE_BG" -fill "$BOOK_TITLE_FG" \
        -size "$FRONT_IMG_W"x"$TITLE_H" -gravity center \
        -font "$BOOK_TITLE_FONT" label:"$BOOK_TITLE" "$TEMPDIR/kn-title.jpg"
    AUTHOR_H=$(echo "$FRONT_IMG_H / $PART_AUTHOR" | bc)
    magick -background "$AUTHOR_NAME_BG" -fill "$AUTHOR_NAME_FG" \
        -size "$FRONT_IMG_W"x"$AUTHOR_H" -gravity south \
        -font "$BOOK_AUTHOR_FONT" label:"$AUTHOR_NAME" "$TEMPDIR/kn-author.jpg"
    if [ -n "$PUBLISHER_NAME" ]; then
        PUBL_H=$(echo "$FRONT_IMG_H / $PART_PUBLISHER" | bc)
        PUBLISHER_IMG="$TEMPDIR/kn-publ.jpg"
        magick -background "$PUBLISHER_NAME_BG" -fill "$PUBLISHER_NAME_FG" \
            -size "$FRONT_IMG_W"x"$PUBL_H" -gravity center \
            -font "$PUBLISHER_FONT" label:"$PUBLISHER_NAME" "$PUBLISHER_IMG"
    fi
    if [ -n "$PUBLISHER_NAME" ]; then
        convert -append "$TEMPDIR/kn-author.jpg" "$TEMPDIR/kn-title.jpg" \
            "$FRONT_IMG" "$PUBLISHER_IMG" kentaur-cover.jpg
    else
        convert -append "$TEMPDIR/kn-author.jpg" "$TEMPDIR/kn-title.jpg" \
            "$FRONT_IMG" kentaur-cover.jpg
    fi
}

function check_polaris_params() {
    [ -z "$FRONT_IMG" ] && log_fatal "Front cover image (FRONT_IMG=...) is not specified"
    [ ! -f "$FRONT_IMG" ] && log_fatal "Front cover image file '$FRONT_IMG' does not exist"
    if [ -z "$BOOK_TITLE_FONT" ]; then
        log_warn "Font for book's title was not specified. Using '$DEF_TITLE_FONT'"
        BOOK_TITLE_FONT="$DEF_TITLE_FONT"
    fi
    if [ -z "$BOOK_AUTHOR_FONT" ]; then
        log_warn "Font for author's name was not specified. Using '$DEF_AUTHOR_FONT'"
        BOOK_AUTHOR_FONT="$DEF_AUTHOR_FONT"
    fi
    [ -z "$BOOK_TITLE" ] && log_fatal "Book title (BOOK_TITLE=...) was not specified"
    [ -z "$AUTHOR_NAME" ] && log_fatal "Book author (AUTHOR_NAME=...) was not specified"
    if [ -z "$BOOK_TITLE_FG" ]; then
        log_warn "Book's title foreground colour not set, using '$DEF_BOOK_TITLE_FG'"
        BOOK_TITLE_FG="$DEF_BOOK_TITLE_FG"
    fi
    if [ -z "$AUTHOR_NAME_FG" ]; then
        log_warn "Author's title foreground colour not set, using '$DEF_AUTHOR_NAME_FG'"
        AUTHOR_NAME_FG="$DEF_AUTHOR_NAME_FG" 
    fi
    # Check additional parameters if publishe's name is defined
    if [ -n "$PUBLISHER_NAME" ]; then
        if [ -z "$PUBLISHER_NAME_FG" ]; then
            log_warn "Publisher's name foreground colour was not specified. Using '$DEF_PUBLISHER_NAME_FG'"
            PUBLISHER_NAME_FG="$DEF_PUBLISHER_NAME_FG"
        fi
        if [ -z "$PUBLISHER_FONT" ]; then
            log_warn "Font for publisher's name was not specified. Using '$DEF_PUBLISHER_FONT'"
            PUBLISHER_FONT="$DEF_PUBLISHER_FONT"
        fi
    fi
    # Assign default parameters for percent
    [ -z "$MARGIN_PERCENT_WIDTH" ] && MARGIN_PERCENT_WIDTH=$DEF_MARGIN_PERCENT_WIDTH
    [ -z "$MARGIN_PERCENT_HEIGHT" ] && MARGIN_PERCENT_HEIGHT=$DEF_MARGIN_PERCENT_HEIGHT
    [ -z "$NUM_VERT_PARTS" ] && NUM_VERT_PARTS=$DEF_NUM_VERT_PARTS
}

function generate_polaris_cover() {
    # Determine cover image size. All elements will be calculated
    # based on that
    read -r FRONT_IMG_W FRONT_IMG_H < <(identify -format "%w %h" "$FRONT_IMG")
    LR_MARGIN=$(echo "$FRONT_IMG_W / 100 * $MARGIN_PERCENT_WIDTH" | bc)
    TB_MARGIN=$(echo "$FRONT_IMG_H / 100 * $MARGIN_PERCENT_HEIGHT" | bc)
    # Height of segment for writing book title and author's name
    SEGMENT_H=$(echo "($FRONT_IMG_H - 2 * $TB_MARGIN) / $NUM_VERT_SEGMENTS" | bc)
    # Width of segment for writing both book title and author's name
    SEGMENT_W=$(echo "$FRONT_IMG_W - 2 * $LR_MARGIN" | bc)
    # Calculate book title height
    TITLE_H=$(echo "$BOOK_TITLE_SEGMENTS * $SEGMENT_H" | bc)
    # Calculate Y offset for book title
    TITLE_Y_OFFSET=$(echo "($BOOK_TITLE_INDEX - 1) * $SEGMENT_H + $TB_MARGIN" | bc)
    # Generate book title image
    magick -background none -fill "$BOOK_TITLE_FG" \
        -size "$SEGMENT_W"x"$TITLE_H" -gravity center \
        -font "$BOOK_TITLE_FONT" label:"$BOOK_TITLE" "$TEMPDIR/po-title.png"
    # Calculate author's name height
    AUTHOR_H=$(echo "$AUTHOR_NAME_SEGMENTS * $SEGMENT_H" | bc)
    # Calculate Y offset for author's name
    AUTHOR_Y_OFFSET=$(echo "($AUTHOR_NAME_INDEX - 1) * $SEGMENT_H + $TB_MARGIN" | bc)
    # Generate book author image
    magick -background none -fill "$AUTHOR_NAME_FG" \
        -size "$SEGMENT_W"x"$AUTHOR_H" -gravity center \
        -font "$BOOK_AUTHOR_FONT" label:"$AUTHOR_NAME" "$TEMPDIR/po-author.png"
    # Convert background image to PNG format
    log_info "Converting '$FRONT_IMG' to '$TEMPDIR/bg.png'"
    convert "$FRONT_IMG" "$TEMPDIR/bg.png"
    log_info "done"
    # Compose elements
    magick "$TEMPDIR/bg.png" \
        "$TEMPDIR/po-title.png" -geometry +$LR_MARGIN+$TITLE_Y_OFFSET -composite +repage \
        "$TEMPDIR/po-author.png" -geometry +$LR_MARGIN+$AUTHOR_Y_OFFSET -composite \
        polaris-cover.jpg
}

### Main program ###

# First argument should be configuration file containing
# all other parameters

CFG_FILE="$1"
[ -z "$@" ] && usage
[ ! -f "${CFG_FILE}" ] && log_fatal "Configuration file '${CFG_FILE}' does not exist"
source "$PWD/${CFG_FILE}"

check_general_parameters

# Make temporary directory
TEMPDIR=$(mktemp -d)
trap "/bin/rm -rf $TEMPDIR" EXIT SIGINT

if [ "${TEMPLATE,,}" == "kentaur" ]; then
    check_kentaur_params
    generate_kentaur_cover
elif [ "${TEMPLATE,,}" == "polaris" ]; then
    check_polaris_params
    generate_polaris_cover
else
    log_fatal "Unknown template '${TEMPLATE}'"
fi
