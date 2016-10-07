#!/bin/bash

function find_stick_device {
# Find / enter source usb stick device
echo "Insert the ${1} stick, then press <enter>!"
read forgetme
FOUNDSTICK=`dmesg | tail -10 | grep "Attached SCSI" | tail -1 | awk '{print $4,$5}'`
echo "Enter your ${1} stick device - you must type /dev/sdx, where sdx is probably: ${FOUNDSTICK}?:"
read STICKDEVICE
}

function unmount_stick {
# Try to umount everything that is mounted on that device
for n in ${1}* ; do
        umount -f ${n} 2>/dev/null;
done
}

function read_save_partition_table {
# Read partition table from stick and save to file
sfdisk --dump ${1} > ${2} 
PARTITIONS=`awk '{print $1}' ${2} | grep ^\/dev`
}

function read_save_images {
# Save partition data with dd
for partition in `echo ${PARTITIONS}`; do
        shortpartition=`echo ${partition} | sed 's/\/dev\///'`
        dd if=${partition} of=${WORKFOLDER}/${shortpartition}.img bs=512
done
}

function wipe_partitions {
# Delete all partitions on device
echo "Are you really sure you want to wipe ${1}? Type YES to wipe:"
read wipe_reply
if [ ${wipe_reply} = "YES" ]; then
	dd if=/dev/zero of=${1} bs=512 count=1 conv=notrunc
else
	exit 1;
fi
}

function create_new_partition_table_file {
# Calculate minimum required size (blocks) for target stick
PARTITION_START=`tail -1 ${SOURCE_PARTITION_FILE} | awk '{print $4}' | sed 's/\,//'`
PARTITION_LENGTH=`tail -1 ${SOURCE_PARTITION_FILE} | awk '{print $6}' | sed 's/\,//'`
LAST_LBA=`expr ${PARTITION_START} + ${PARTITION_LENGTH}`
# Create lba-modded partition file
sed "s/^last\-lba\:\ [1-9].*/last\-lba\:\ "${LAST_LBA}"/" ${SOURCE_PARTITION_FILE} > ${MODDED_PARTITION_FILE}
# Adjust device to target device
STICKDEVSHORT=`echo ${STICKDEVICE} | cut -c 6-8`
sed "s/\/dev\/sd[a-z]/\/dev\/"${STICKDEVSHORT}"/g" ${MODDED_PARTITION_FILE} >  ${TARGET_PARTITION_FILE}

}

function write_new_partition_table {
sfdisk --force ${STICKDEVICE} < ${TARGET_PARTITION_FILE}
}

function write_partition_images {
sfdisk --dump ${STICKDEVICE} > ${ACTUAL_PARTITION_FILE} 
TARGETPARTITIONS=`awk '{print $1}' ${ACTUAL_PARTITION_FILE} | grep ^\/dev`
echo "Partitions are: `echo ${TARGETPARTITIONS}`"
for partition in `echo ${TARGETPARTITIONS}`; do
	shortpartition=`echo ${partition} | sed 's/\/dev\///'`
	STARTSECTOR=`grep "${partition}" ${TARGET_PARTITION_FILE} | awk '{print $4}' | sed 's/\,//'`
	echo "Shortpartition is: ${shortpartition}"
	dd if="${WORKFOLDER}/${shortpartition}.img" of="${STICKDEVICE}" seek="${STARTSECTOR}" bs=512
	sync;
done
}

# Main
WORKFOLDER=/tmp
SOURCE_PARTITION_FILE=${WORKFOLDER}/source.partition.txt
MODDED_PARTITION_FILE=${WORKFOLDER}/modded.partition.txt
TARGET_PARTITION_FILE=${WORKFOLDER}/target.partition.txt
ACTUAL_PARTITION_FILE=${WORKFOLDER}/actual.partition.txt

find_stick_device source;
unmount_stick ${STICKDEVICE};
read_save_partition_table ${STICKDEVICE} ${SOURCE_PARTITION_FILE}
read_save_images;
# Above reading works fine ...
echo "Finished reading, remove SOURCE stick and press a key to continue."; read forgetme;
find_stick_device target;
unmount_stick ${STICKDEVICE};
wipe_partitions ${STICKDEVICE};
create_new_partition_table_file;
write_new_partition_table ${STICKDEVICE};
write_partition_images;
echo "Finished writing target stick!"

