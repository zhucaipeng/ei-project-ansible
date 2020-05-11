#!/bin/bash

URL6="https://ftp3.linux.ibm.com/dl.php?file=/redhat/yum/server/6/6Server/x86_64/os/Packages"
URL7="https://ftp3.linux.ibm.com/dl.php?file=/redhat/yum/server/7/7Server/x86_64/os/Packages"
SLES_X86_URL="https://ftp3.linux.ibm.com/dl.php?file=/suse/catalogs/SLES11-SP4-LTSS-Updates/sle-11-x86_64/rpm/x86_64"
SLES_PPC64_URL="https://ftp3.linux.ibm.com/dl.php?file=/suse/catalogs/SLES11-SP4-LTSS-Updates/sle-11-ppc64/rpm/ppc64"

[[ ! -e ${3} ]] && echo "${3} do NOT exsit!" && exit
mkdir -p ${5}/{redhat6,redhat7,sles/{x86_64,ppc64}} &> /dev/null

##Find the minimum number of packages to download
cat /dev/null > ${4}
case $(hostname) in
    z10000)
	SITE="z1"
  ;;
    v10000)
	SITE="p1"
  ;;
    v30000)
  SITE="p3"
  ;;
    v50000)
  SITE="p5"
  ;;
      *) 
  echo "Please run $0 on CWS node" && exit
  ;;
esac

echo -e "\nScanning and matching..."
for K in $(cat ${SN} |grep -v ^# |grep -v ^$ |sed 's/\t//g' |sed 's/ //g'|uniq)
do

	Q=$(echo ${K} |sed "s/\(.*\)-.*/\1/g"  |sed 's/\(.*\)-.*/\1/g')

	echo ${K} |egrep el6 &> /dev/null && OS="*el6*"
	echo ${K} |egrep el7 &> /dev/null && OS="*el7*"
	echo ${K} |egrep -v "el6|el7" |grep x86_64 &> /dev/null && OS="*sles*x86_64*"
	echo ${K} |egrep -v "el6|el7" |grep ppc64 &> /dev/null && OS="*sles*ppc64*"
	echo ${K} |egrep -v "el6|el7" |grep noarch &> /dev/null && OS="*sles*"	

	if echo ${K} |grep ".el[7|6]" |grep x86_64 &> /dev/null;then

		COUNT=0;TMP_COUNT=0;for I in $(lssys -qe oslevel==${OS} nodestatus!=BAD realm==*.${SITE} |xargs -n50 |tr " " ",");do echo $I;TMP_COUNT=$(dssh -kn ${I} 'rpm -qa |egrep "^'${Q}'-[0-9].*x86_64"' |grep -v TodaroPromptBuster 2> /dev/null |wc -l);let COUNT+=${TMP_COUNT};done

		if [[ $COUNT -eq 0 && ${SITE} == "p1" && ${OS} == "*el7" ]];then
			S_COUNT=0;TMP_S_COUNT=0;for I in $(lssys -qe oslevel==${OS} nodestatus!=BAD eihostname==softlayer |xargs -n50 |tr " " ",");do echo $I;TMP_S_COUNT=$(dssh -kn ${I} 'rpm -qa |egrep "^'${Q}'-[0-9].*x86_64"' |grep -v TodaroPromptBuster 2> /dev/null |wc -l);let S_COUNT+=${TMP_S_COUNT};done

		fi

	elif echo ${K} |grep ".el[7|6]" |grep i686 &> /dev/null;then

		COUNT=0;TMP_COUNT=0;for I in $(lssys -qe oslevel==${OS} nodestatus!=BAD realm==*.${SITE} |xargs -n50 |tr " " ",");do echo $I;TMP_COUNT=$(dssh -kn ${I} 'rpm -qa |egrep "^'${Q}'-[0-9].*i686"' |grep -v TodaroPromptBuster 2> /dev/null |wc -l);let COUNT+=${TMP_COUNT};done

		if [[ $COUNT -eq 0 && ${SITE} == "p1" && ${OS} == "*el7" ]];then
			S_COUNT=0;TMP_S_COUNT=0;for I in $(lssys -qe oslevel==${OS} nodestatus!=BAD eihostname==softlayer |xargs -n50 |tr " " ",");do echo $I;TMP_S_COUNT=$(dssh -kn ${I} 'rpm -qa |egrep "^'${Q}'-[0-9].*i686"' |grep -v TodaroPromptBuster 2> /dev/null |wc -l);let S_COUNT+=${TMP_S_COUNT};done
		fi

	elif echo ${K} |grep ".el[7|6]" |grep noarch &> /dev/null;then
		
		COUNT=0;TMP_COUNT=0;for I in $(lssys -qe oslevel==${OS} nodestatus!=BAD realm==*.${SITE} |xargs -n50 |tr " " ",");do echo $I;TMP_COUNT=$(dssh -kn ${I} 'rpm -qa |egrep "^'${Q}'-[0-9].*noarch"' |grep -v TodaroPromptBuster 2> /dev/null |wc -l);let COUNT+=${TMP_COUNT};done

	else

		COUNT=0;TMP_COUNT=0;for I in $(lssys -qe oslevel==${OS} nodestatus!=BAD realm==*.${SITE} |xargs -n50 |tr " " ",");do echo $I;TMP_COUNT=$(dssh -kn ${I} 'rpm -qa |egrep "^'${Q}'-[0-9]"' |grep -v TodaroPromptBuster 2> /dev/null |wc -l);let COUNT+=${TMP_COUNT};done
	fi

	[[ ${COUNT} -gt 0 || ${S_COUNT} -gt 0 ]] && echo ${K} >> ${4}

done

if [[ ! -s ${4} ]];then
	echo -e "\033[34m \nNot suitable for ${SITE}.\n\033[0m"
	exit
fi

##Download the packages
DL_LIST=$(cat ${4} |sort -n |uniq)
P_LIST=$(find ${5} -type f |awk -F"/" '{print $NF}' |sort -n |uniq)

if [[ ${DL_LIST} != ${P_LIST} ]];then

	find ${5} -type f -name *.rpm -exec mv {} /tmp \;
	for I in `cat ${4} |grep el7`
	do
  	LABEL=${I:0:1}
  	wget --user=${1} --password=${2} --no-check-certificate ${URL7}/${LABEL}/${I} -O ${5}/redhat7/${I}
	done

	for I in `cat ${4} |grep el6`
	do
  	LABEL=${I:0:1}
  	wget --user=${1} --password=${2} --no-check-certificate ${URL6}/${LABEL}/${I} -O ${5}/redhat6/${I}
	done

	for I in `cat ${4} |egrep -v "el6|el7" |grep x86_64`
	do
  	wget --user=${1} --password=${2} --no-check-certificate ${SLES_X86_URL}/${I} -O ${5}/sles/x86_64/${I}
	done

	for I in `cat ${4} |egrep -v "el6|el7" |grep ppc64`
	do
  	wget --user=${1} --password=${2} --no-check-certificate ${SLES_PPC64_URL}/${I} -O ${5}/sles/ppc64/${I}
	done

	for I in `cat ${4} |egrep -v "el6|el7" |grep noarch`
  do
    echo -e "\033[31m noarch packages can NOT download automatically at present,please download ${I} by manually,and put both in sles x86 and ppc64 path! \033[0m"
  done
fi

tsum=0
for I in $(find ${5} -type f)
do
	TYPE=$(file ${I} |awk -F":" '{print $2}' |sed 's/^ //g' |awk '{print $1}')
	if [[ ${TYPE} != "RPM" ]];then
		echo -e "\033[31m ${I##*/} is suitable for ${SITE},but can't download from ftp3,please download by manually!\n \033[0m"
		tsum+=1 && mv ${I} /tmp
	fi
done
if [[ ${tsum} -gt 0 ]];then
  exit 1
fi

DL_LIST=$(cat ${4} |sort -n |uniq)
P_LIST=$(find ${5} -type f |awk -F"/" '{print $NF}' |sort -n |uniq)
if [[ ${DL_LIST} != ${P_LIST} ]];then
	echo -e "\033[31m The download rpms is not equal than actually required,please check first! \033[0m"
	exit 2
else
	for I in $(cat ${4});do
  	echo -e "\033[34m \n${I} is suitable for ${SITE}.and prepared well in ${5} \033[0m"
	done
fi
echo

chown -R root:root ${5}
chmod -R 0775 ${5}

exit 0
