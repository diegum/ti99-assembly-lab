#!/bin/sh

SOURCE_STEM=$1
if [ -z $SOURCE_STEM ]; then
    echo "ERROR: missing file stem argument."
    exit 1
fi

# Are there more arguments?
OTHER_SOURCES=$([[ $# -gt 1 ]] && echo $(echo $@ | cut -d' ' -f2-))

XDT99_VERSION=3.0.0
XDT99_PATH="/opt/xdt99/xdt99-${XDT99_VERSION}"
XAS99="xas99.py"
XDM99="xdm99.py"

MAME_VERSION=0224
MAME="/opt/ti99/mame${MAME_VERSION}/mame64"
MAME_TI99="${MAME} -cfg_directory ${PCLOUD_DRIVE}/ti99_4a/cfg -inipath ${PCLOUD_DRIVE}/ti99_4a/ini -nvram_directory ${PCLOUD_DRIVE}/ti99_4a/nvram -rompath ${PCLOUD_DRIVE}/ti99_4a/roms -video soft ti99_4a"
TI99_OPTIONS="-cart ${PCLOUD_DRIVE}/ti99_4a/cart/editor_assembler.rpk -ioport peb -ioport:peb:slot2 32kmem -ioport:peb:slot8 hfdc -ioport:peb:slot8:hfdc:f1 525dd -flop2 ${PCLOUD_DRIVE}/v9t9/DISKS/Ed-Assm.Dsk"

DISK_NAME=diegum

# Build the .obj
XAS99_COMMAND="${XAS99} -R -C -i -L ${SOURCE_STEM}.lst ${SOURCE_STEM}.asm ${OTHER_SOURCES}"
echo "Assembling: ${XAS99_COMMAND}"
python3 ${XDT99_PATH}/${XAS99_COMMAND}
STATUS_CODE=$?
if [ ${STATUS_CODE} -ne 0 ]; then
    exit ${STATUS_CODE}
fi

# Put .img on disk
XDM99_COMMAND="${XDM99} ${DISK_NAME}.dsk -a ${SOURCE_STEM}.img -n $(echo ${SOURCE_STEM} | tr '[:lower:]' '[:upper:]')"
echo "Copying: ${XDM99_COMMAND}"
python3 ${XDT99_PATH}/${XDM99_COMMAND}
STATUS_CODE=$?
if [ ${STATUS_CODE} -ne 0 ]; then
    exit ${STATUS_CODE}
fi

echo "Launching: ${MAME_TI99} ${TI99_OPTIONS} -flop1 ./${SOURCE_STEM}.dsk"
/opt/ti99/mame0224/mame64 -cfg_directory "/Users/entertainment/pCloud Drive/ti99_4a/cfg" -inipath "/Users/entertainment/pCloud Drive/ti99_4a/ini" -nvram_directory "/Users/entertainment/pCloud Drive/ti99_4a/nvram" -rompath "/Users/entertainment/pCloud Drive/ti99_4a/roms" -video soft ti99_4a -cart "/Users/entertainment/pCloud Drive/ti99_4a/cart/editor_assembler.rpk" -ioport peb -ioport:peb:slot2 32kmem -ioport:peb:slot8 hfdc -ioport:peb:slot8:hfdc:f1 525dd -ioport:peb:slot8:hfdc:f2 525dd -flop2 "/Users/entertainment/pCloud Drive/v9t9/DISKS/Ed-Assm.Dsk" -flop1 ./${DISK_NAME}.dsk
