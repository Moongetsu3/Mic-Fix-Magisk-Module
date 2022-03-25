(

mount /data
mount -o rw,remount /data
MODPATH=${0%/*}

# run
FILE=$MODPATH/sepolicy.sh
if [ -f $FILE ]; then
  sh $FILE
fi

# etc
if [ -d /sbin/.magisk ]; then
  MAGISKTMP=/sbin/.magisk
else
  MAGISKTMP=`find /dev -mindepth 2 -maxdepth 2 -type d -name .magisk`
fi
ETC=$MAGISKTMP/mirror/system/etc
VETC=$MAGISKTMP/mirror/system/vendor/etc
VOETC=$MAGISKTMP/mirror/system/vendor/odm/etc
MODETC=$MODPATH/system/etc
MODVETC=$MODPATH/system/vendor/etc
MODVOETC=$MODPATH/system/vendor/odm/etc

# directory
SKU=`ls $VETC/audio | grep sku_`
if [ "$SKU" ]; then
  for SKUS in $SKU; do
    mkdir -p $MODVETC/audio/$SKUS
  done
fi
PROP=`getprop ro.build.product`
if [ -d $VETC/audio/"$PROP" ]; then
  mkdir -p $MODVETC/audio/"$PROP"
fi

# mixer paths
NAME=*mixer*paths*.xml
rm -f `find $MODPATH/system -type f -name $NAME`
MP=`find $ETC -maxdepth 1 -type f -name $NAME`
VMP=`find $VETC -maxdepth 1 -type f -name $NAME`
VAMP=`find $VETC/audio -maxdepth 1 -type f -name $NAME`
VOMP=`find $VOETC -maxdepth 1 -type f -name $NAME`
cp -f $MP $MODETC
cp -f $VMP $MODVETC
cp -f $VAMP $MODVETC/audio
cp -f $VOMP $MODVOETC
if [ "$SKU" ]; then
  for SKUS in $SKU; do
    VSMP=`find $VETC/audio/$SKUS -maxdepth 1 -type f -name $NAME`
    cp -f $VSMP $MODVETC/audio/$SKUS
  done
fi
if [ -d $VETC/audio/"$PROP" ]; then
  VBMP=`find $VETC/audio/"$PROP" -maxdepth 1 -type f -name $NAME`
  cp -f $VBMP $MODVETC/audio/"$PROP"
fi

# audio platform info
#NAME=*audio*platform*info*.xml
#rm -f `find $MODPATH/system -type f -name $NAME`
#API=`find $ETC -maxdepth 1 -type f -name $NAME`
#VAPI=`find $VETC -maxdepth 1 -type f -name $NAME`
#VAAPI=`find $VETC/audio -maxdepth 1 -type f -name $NAME`
#VOAPI=`find $VOETC -maxdepth 1 -type f -name $NAME`
#cp -f $API $MODETC
#cp -f $VAPI $MODVETC
#cp -f $VAAPI $MODVETC/audio
#cp -f $VOAPI $MODVOETC
#if [ "$SKU" ]; then
#  for SKUS in $SKU; do
#    VSAPI=`find $VETC/audio/$SKUS -maxdepth 1 -type f -name $NAME`
#    cp -f $VSAPI $MODVETC/audio/$SKUS
#  done
#fi
#if [ -d $VETC/audio/"$PROP" ]; then
#  VBAPI=`find $VETC/audio/"$PROP" -maxdepth 1 -type f -name $NAME`
#  cp -f $VBAPI $MODVETC/audio/"$PROP"
#fi

# aml fix
AML=/data/adb/modules/aml
DIR=$AML/system/vendor/odm/etc
if [ "$VOMP" ] || [ "$VOAPI" ]; then
  if [ -d $AML ] && [ ! -d $DIR ]; then
    mkdir -p $DIR
    cp -f $VOMP $DIR
    #cp -f $VOAPI $DIR
  fi
fi
PROP=`getprop ro.build.version.sdk`
if [ "$PROP" -ge 26 ]; then
  magiskpolicy "dontaudit vendor_configs_file labeledfs filesystem associate"
  magiskpolicy "allow     vendor_configs_file labeledfs filesystem associate"
  magiskpolicy "dontaudit init vendor_configs_file dir relabelfrom"
  magiskpolicy "allow     init vendor_configs_file dir relabelfrom"
  magiskpolicy "dontaudit init vendor_configs_file file relabelfrom"
  magiskpolicy "allow     init vendor_configs_file file relabelfrom"
  chcon -R u:object_r:vendor_configs_file:s0 $DIR
  magiskpolicy --live "type vendor_configs_file"
fi

# run
sh $MODPATH/.aml.sh

) 2>/dev/null


