#!/bin/sh
# 该脚本用于简单的调用android 和 ios 打包脚本
# ************************* 需要配置 Start ********************************
# 打包平台名称 从config 配置中获取
__APP__TAG=''
projectPath=$(dirname $(pwd))
echo $projectPath
ApiFile=$projectPath"/Rn-newModel/app/utils/Config.js"

# ==================== 公共部分 =====================
# ######### 脚本样式 #############
__TITLE_LEFT_COLOR="\033[36;1m==== "
__TITLE_RIGHT_COLOR=" ====\033[0m"

__OPTION_LEFT_COLOR="\033[33;1m"
__OPTION_RIGHT_COLOR="\033[0m"

__LINE_BREAK_LEFT="\033[32;1m"
__LINE_BREAK_RIGHT="\033[0m"

# 红底白字
__ERROR_MESSAGE_LEFT="\033[41m ! ! ! "
__ERROR_MESSAGE_RIGHT=" ! ! ! \033[0m"

# 等待用户输入时间
__WAIT_ELECT_TIME=0.2

# 选择项输入方法 接收3个参数：1、选项标题 2、选项数组 3、选项数组的长度(0~256)
function READ_USER_INPUT() {
  title=$1
  options=$2
  maxValue=$3
  echo "${__TITLE_LEFT_COLOR}${title}${__TITLE_RIGHT_COLOR}"
  for option in ${options[*]}; do
    echo "${__OPTION_LEFT_COLOR}${option}${__OPTION_RIGHT_COLOR}"
  done
  read
  __INPUT=$REPLY
  expr $__INPUT "+" 10 &> /dev/null
  if [[ $? -eq 0 ]]; then
    if [[ $__INPUT -gt 0 && $__INPUT -le $maxValue ]]; then
      return $__INPUT
    else
      echo "${__ERROR_MESSAGE_LEFT}输入越界了，请重新输入${__ERROR_MESSAGE_RIGHT}"
      READ_USER_INPUT $title "${options[*]}" $maxValue
    fi
  else
    echo "${__ERROR_MESSAGE_LEFT}输入有误，请输入0~256之间的数字序号${__ERROR_MESSAGE_RIGHT}"
    READ_USER_INPUT $title "${options[*]}" $maxValue
  fi
}

# 打印信息
function printMessage() {
  pMessage=$1
  echo "${__LINE_BREAK_LEFT}${pMessage}${__LINE_BREAK_RIGHT}"
}

# 2.IOS 或者 Android 选项
__PACK_ENV_OPTIONS=("1.IOS" "2.Android" "3.IOS&&Android")
READ_USER_INPUT "请选择打包平台: " "${__PACK_ENV_OPTIONS[*]}" ${#__PACK_ENV_OPTIONS[*]}

__PACK_ENV_OPTION=$?

# 3.Staging 或者 Release 选项
__PACK_ENV_OPTIONS2=("1.正式包" "2.测试包")
READ_USER_INPUT "请选择打包类型: " "${__PACK_ENV_OPTIONS2[*]}" ${#__PACK_ENV_OPTIONS2[*]}

__PACK_ENV_OPTION2=$?

if [[ $__PACK_ENV_OPTION -eq 1 ]]; then
    cd ios/AutoPacking && ./autopacking.sh ${__PACK_ENV_OPTION2} 
    cd ../..
elif [[ $__PACK_ENV_OPTION -eq 2 ]]; then
    cd android && ./autopacking.sh ${__PACK_ENV_OPTION2} 
    cd ..
elif [[ $__PACK_ENV_OPTION -eq 3 ]]; then
    cd ios/AutoPacking && ./autopacking.sh ${__PACK_ENV_OPTION2}
    #回到主目录
    cd ../..
    cd android && ./autopacking.sh ${__PACK_ENV_OPTION2} 
    cd ..
fi

# 4.svn 是否上传
__PACK_SVN_OPTIONS=("1.不上传" "2.上传")
READ_USER_INPUT "请选择是否上传svn: " "${__PACK_SVN_OPTIONS[*]}" ${#__PACK_SVN_OPTIONS[*]}

__PACK_SVN_OPTION=$?
if [[ $__PACK_SVN_OPTION -eq 1 ]]; then
   #不上传
    echo -e "\033[42;37m==============不上传svn==============\033[0m"
   exit
fi

# 检查RN Config 配置文件
function checkConfiguration {
    #检查 config.js 配置文件中 RN_RELEASE 配置，如果 是 production 版本 配置为 false 则 发出 警报
    # 如果 配置的 是 false 就 发出 异常警报
    
    echo $ApiFile

    echo -e "\033[42;37m==============开始检查config配置文件==============\033[0m"

    while read line
    do
        if [[ $line == //* ]]
        then
            continue
        fi

        if [[ $line == *RN_REALEASE* ]]
        then
            echo $line
            #读取=后面内容
            kRN_REALEASE="${line#*=}"
            #替换空格
            kRN_REALEASE=`echo "${kRN_REALEASE#*=}" | sed 's/ //g'`
            #替换分号
            kRN_REALEASE=`echo "${kRN_REALEASE#*=}" | sed 's/;//g'`
            #打印结果
            echo "find RN_RELEASE = $kRN_REALEASE"
            #输出是否异常
            if [ "$kRN_REALEASE" == "false" ]
            then
                if [[ ${__BUILD_CONFIGURATION} == "Release" ]]; then
                    echo -e "\033[41;33m================检查config配置异常================\033[0m"  
                    exit
                else
                    echo -e "\033[42;37m================检查config配置正常================\033[0m"
                fi
                
            else
                echo -e "\033[42;37m================检查config配置正常================\033[0m"
            fi
        elif [[ $line == *WEBNUM* ]]
        then
            echo $line
            #读取=后面内容
            kWEBNUM="${line#*=}"
            #替换空格
            kWEBNUM=`echo "${kWEBNUM#*=}" | sed 's/ //g'`
            #替换分号
            kWEBNUM=`echo "${kWEBNUM#*=}" | sed 's/;//g'`
            #打印结果
            echo "find WEBNUM = $kWEBNUM"
            # 赋值给 平台名称变量
            __APP__TAG=$kWEBNUM
            #输出平台编号
            echo -e "\033[42;37m================打包平台为{$kWEBNUM}================\033[0m"
        fi

    done < ${ApiFile}
}



# 4. 上传svn
echo -e "\033[42;37m==============SVN 上传开始==============\033[0m"
#检查 配置文件
checkConfiguration
#删除 平台 名称中的双引号
__APP__TAG=`echo $__APP__TAG | sed 's/\"//g'`
#删除 平台 名称中的单引号
__APP__TAG=`echo $__APP__TAG | sed $'s/\'//g'`

myFile="Rn-newModel/svn"        #被提交的目录名
mkdir svn                       # 创建 svn 目录

cd ./svn && touch svn_log.txt
cd ..
date > $projectPath/$myFile/svn_log.txt #输出打印日志到log文件
echo "====================== Start ======================" >> $projectPath/$myFile/svn_log.txt
svnname=binson        #svn用户名
svnpwd=123456        #svn用户名对应的密码
commit_dir=$projectPath        #服务器本地路径

# svn 路径
if [[ $__PACK_ENV_OPTION2 -eq 1 ]]; then
    #测试路径
    target_svn_dir=http://192.168.110.61/svn/Txv1.0-test/app/RN/%E6%AD%A3%E5%BC%8F%E5%8C%85/${__APP__TAG}       #svn路径
elif [[ $__PACK_ENV_OPTION2 -eq 2 ]]; then
    #测试路径
    target_svn_dir=http://192.168.110.61/svn/Txv1.0-test/app/RN/%E6%B5%8B%E8%AF%95%E5%8C%85/${__APP__TAG}       #svn路径
else
    echo '环境选择异常'
    exit
fi


ipaFolder=$projectPath/Rn-newModel/ios/build    # IOS 需要上传的文件目录
apkFolder=$projectPath/Rn-newModel/android/apk  # Android 需要上传的文件目录
targetFolder=$commit_dir/$myFile/$__APP__TAG/

echo '目标地址:'${targetFolder}

function copyFileToSVN {
    
    hasFinish="false"
    for file in `ls -a $1`
    do
        if [[ $hasFinish == "true" ]]
            then
                echo '循环结束'
                break
        elif [ -d $1"/"$file ]
        then
            if [[ $file != '.' && $file != '..' ]]
            then
                copyFileToSVN $1"/"$file
            fi
        else
            # checkFile $1"/"$file
            filename=$1"/"$file
            if [[ $hasFinish == "true" ]]
            then
                echo '循环结束'
                break
            elif [ "${filename##*.}"x = "$2"x ] && [[ $hasFinish == "false" ]]
            then
                echo $filename
                # copy 文件到目录
                cp -R $filename ${targetFolder}$file
                
            fi
        fi
    done

}

# 进入svn 目录
cd $commit_dir/$myFile

#检出文件夹，如果存在进入该目录
if [ ! -d "$myFile" ]; then
    svn checkout $target_svn_dir --username $svnname --password $svnpwd >> $projectPath/$myFile/svn_log.txt
else
    cd $commit_dir/$myFile
fi
# #更新项目
svn update -username $svnname --password $svnpwd >> $projectPath/$myFile/svn_log.txt
#复制文件到提交目录
if [[ $__PACK_ENV_OPTION -eq 1 ]]; then
    # copy ipa 到 svn 目录
    copyFileToSVN ${ipaFolder} 'ipa'
elif [[ $__PACK_ENV_OPTION -eq 2 ]]; then
    # copy apk 到 svn 目录
    copyFileToSVN ${apkFolder} 'apk'
elif [[ $__PACK_ENV_OPTION -eq 3 ]]; then
     # copy ipa & apk 到 svn 目录
    copyFileToSVN ${ipaFolder} 'ipa'
    copyFileToSVN ${apkFolder} 'apk'
fi

cd $commit_dir/$myFile/$__APP__TAG/
echo -e "\033[42;37m==============SVN 目录文件列表!!!==============\033[0m"
ls
#增加项目
svn st | grep '^\?' | tr '^\?' ' ' | sed 's/[ ]*//' | sed 's/[ ]/\\ /g' | xargs svn add >> $projectPath/$myFile/svn_log.txt
#上传项目
svn commit -m "cormit file $myFile" $commit_dir/$myFile/$__APP__TAG/* --username $svnname --password $svnpwd >> $projectPath/$myFile/svn_log.txt
echo "====================== End ======================" >> $projectPath/$myFile/svn_log.txt

# 回到根目录
cd ../../

echo "删除SVN文件!!!"
rm -rf svn/
