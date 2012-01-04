#!/bin/bash
CONFIG="~/.test_configs/simple_record.yml"
CONFIG_DIR=`dirname $CONFIG`
CONFIG_EXP=`eval "echo $CONFIG"`
if [ ! -d $CONFIG_DIR ]; then
  mkdir -p `eval "echo $CONFIG_DIR"`
fi
echo "amazon:" > $CONFIG_EXP
echo -n "  access_key: " >> $CONFIG_EXP
echo $AMAZON_ACCESS_KEY_ID >> $CONFIG_EXP
echo -n "  secret_key: " >> $CONFIG_EXP
echo $AMAZON_SECRET_ACCESS_KEY >> $CONFIG_EXP
chmod og-rwx $CONFIG_EXP
