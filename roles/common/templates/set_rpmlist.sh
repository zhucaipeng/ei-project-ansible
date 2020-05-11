#!/bin/bash

[[ -n $2 && -d $2 ]] && find ${2} -type f -exec mv {} /tmp \; || mkdir -p $2

echo '[packages]' >> $2/custom.fact

if [[ $(ls $1/redhat7/*.rpm 2> /dev/null |wc -l) -gt 0 ]];then
    rpm7_list=$(ls $1/redhat7/*.rpm |awk -F "/" '{print $NF}' |awk -F"-[0-9]" '{print $1}' |tr '\n' ',' |xargs |tr " " ",")
    echo "redhat7_packages = ${rpm7_list}" >> $2/custom.fact
fi

if [[ $(ls $1/redhat6/*.rpm 2> /dev/null |wc -l) -gt 0 ]];then
    rpm6_list=$(ls $1/redhat6/*.rpm |awk -F "/" '{print $NF}' |awk -F"-[0-9]" '{print $1}' |tr '\n' ',' |xargs |tr " " ",")
    echo "redhat6_packages = ${rpm6_list}" >> $2/custom.fact
fi

if [[ $(ls $1/sles/x86_64/*.rpm 2> /dev/null |wc -l) -gt 0 ]];then
    sles_x86_list=$(ls $1/sles/x86_64/*.rpm |awk -F "/" '{print $NF}' |awk -F"x86_64|noarch" '{print $1}' |sed 's/.$//g' |xargs |tr " " ",")
    echo "sles_x86_packages = ${sles_x86_list}" >> $2/custom.fact
fi

if [[ $(ls $1/sles/ppc64/*.rpm 2> /dev/null |wc -l) -gt 0 ]];then
    sles_ppc64_list=$(ls $1/sles/ppc64/*.rpm |awk -F "/" '{print $NF}' |awk -F"ppc64|noarch" '{print $1}' |sed 's/.$//g' |xargs |tr " " ",")
    echo "sles_ppc64_packages = ${sles_ppc64_list}" >> $2/custom.fact
fi

exit 0
