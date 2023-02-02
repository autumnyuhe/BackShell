#!/bin/sh
# 该脚本用于检查项目中未使用的图片并提供一键删除功能
# ************************* 需要配置 Start ********************************

projectPath=$(dirname $(pwd))
echo $projectPath

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

# 1.竖版 或者 横版 选项
__PACK_ENV_OPTIONS=("1.竖版" "2.横版")
READ_USER_INPUT "请选择检查模板: " "${__PACK_ENV_OPTIONS[*]}" ${#__PACK_ENV_OPTIONS[*]}

__PACK_ENV_OPTION=$?


projectPath=$(dirname $(pwd))
#图片目录名称 横版 image 竖版 img
imgPathName=""
# 判读用户是否有输入
if [ "$__PACK_ENV_OPTION" = "1" ]
then
    #竖版
    imgPathName=img
    ImgFile=$projectPath"/Rn-newModel/app/static/${imgPathName}"
    workfile=$projectPath"/Rn-newModel/app/components"
    workfile2=$projectPath"/Rn-newModel/app/customizeview"
    workfile3=$projectPath"/Rn-newModel/app/tools"
    workfile4=$projectPath"/Rn-newModel/app/utils"
   
elif [ "$__PACK_ENV_OPTION" = "2" ]
then
    #横版
    imgPathName=image
    ImgFile=$projectPath"/HprojectModel/app/static/${imgPathName}"
    workfile=$projectPath"/HprojectModel/app/components"
    workfile2=$projectPath"/HprojectModel/app/customizeview"
    workfile3=$projectPath"/HprojectModel/app/tools"
    workfile4=$projectPath"/HprojectModel/app/utils"
else
    echo -e "\033[41;33m================输入错误，请重检查您的输入================\033[0m"
    exit
fi

echo "图片定义的文件路径为:"$ImgFile

echo "检查项目文件路径为:"$workfile

#图片数组
Img_array=()
#相对路径图片数组
Img_Relative_array=()
#未使用图片列表
diff_list=()

#项目中用到图片数组
imgsList=()

#读取getAllImgs 项目图片目录所有png图片 并存储
getAllImgs(){
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
                echo "目录需要循环下一级"$1"/"$file
                getAllImgs $1"/"$file
            fi
        else
            # checkFile $1"/"$file
            filename=$1"/"$file
            if [[ $hasFinish == "true" ]]
            then
                echo '循环结束'
                break
            elif [ "${filename##*.}"x = "png"x ] && [[ $hasFinish == "false" ]]
            then
                # hasFinish="true"
                # echo $filename
                #判断调用的所有颜色变量是否有定义
                #删除图片路径中的@2x @3x
                filename=${filename/@2x/}
                filename=${filename/@3x/}
                Img_array[${#Img_array[@]}]=$filename
                #记录相对路径图片
                #读取 ${imgPathName} 后面字符
                path=${filename#*${imgPathName}/}
                Img_Relative_array[${#Img_Relative_array[@]}]=$path
            fi
        fi
    done

    #去重复
    Img_array=($(awk -v RS=' ' '!a[$1]++' <<< ${Img_array[@]}))
    Img_Relative_array=($(awk -v RS=' ' '!a[$1]++' <<< ${Img_Relative_array[@]}))
}

checkFileContent(){
    file=$1
    while read line
    do
        if [[ $line == //* ]]
        then
            continue
        fi

        if [[ $line == *static/${imgPathName}/* ]]
        then
            # echo $line
            a=$line
            a=${a//static/${imgPathName}//@} 
            #要将$a分割开，先存储旧的分隔符
            OLD_IFS="$IFS"

            #设置分隔符
            IFS="@" 

            #如下会自动分隔
            arr=($a)

            #恢复原来的分隔符
            IFS="$OLD_IFS"

            #遍历数组
            for s in ${arr[@]}
            do
                if [[ $s == *png* ]]
                then
                    #截取 png 前面的内容
                    name=${s%png*}
                    #把末尾的png 加上
                    name=$name"png"

                    if [[ $name == *,* ]] && ! [[ $name == *, ]]
                    then
                        #如果 切割后的字符串还包含逗号 并且以 逗号结尾 则需要二次分割
                        # echo -e "\033[41;33m================$name 需要二次分割================\033[0m"
                        #替换空格
                        name=`echo $name | xargs`
                        #截取png分号前面的变量名称
                        name=${name%png,*}
                        #把末尾的Color 加上
                        name=$name"png"
                        # echo -e "\033[41;33m================$name 分割后的值================\033[0m"
                    fi
                    #读取${imgPathName} 路径后面的内容
                    name=${name/\/${imgPathName}\//}
                    imgsList[${#imgsList[@]}]=$name
                fi
            done
        fi

    done < ${file}
}

#读取指定路径下面的全部js文件
read_dir(){
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
                read_dir $1"/"$file
            fi
        else
            # checkFile $1"/"$file
            filename=$1"/"$file
            if [[ $hasFinish == "true" ]]
            then
                echo '循环结束'
                break
            elif [ "${filename##*.}"x = "js"x ] && [[ $hasFinish == "false" ]]
            then
                # hasFinish="true"
                # echo $filename
                #判断调用的所有颜色变量是否有定义
                checkFileContent $filename
            fi
        fi
    done
}

#未使用到的图片列表
getDiffImgList() {
    # declare -a diff_list
    t=0
    flag=0
    # echo Img_Relative_array=${Img_Relative_array[@]}
    # echo imgsList=${imgsList[@]}
    
    for list1_num in "${Img_Relative_array[@]}"
    do
        # echo list1_num is ${list1_num}
        for list2_num in "${imgsList[@]}"
        do
            # echo list2_num is ${list2_num}
            if [[ "${list1_num}" == "${list2_num}" ]]; then
                flag=1
                break
            fi
        done
        if [[ $flag -eq 0 ]]; then
            diff_list[t]=$list1_num
            t=$((t+1))
        else
            flag=0
        fi
    done
    # echo diff_list=${diff_list[@]}

    printMessage "项目中需要删除的图片元素为:"
    for((i=0;i<${#diff_list[@]};i++));
    do
        echo $ImgFile/${diff_list[$i]}
    done
    printMessage "项目中需要删除的图片元素个数为:${#diff_list[*]}"
}

#获取本地全部图片路径
getAllImgs $ImgFile

#打印获取的图片数列表
# echo "图片数组的元素为: ${Img_array[*]}"
# echo -e "\033[44;37m 工程中图片数组的元素为\033[0m"
# for((i=0;i<${#Img_Relative_array[@]};i++));
# do
# echo ${Img_Relative_array[$i]}
# done
# echo -e "\033[44;37m 工程中图片数组的元素为个数为:${#Img_Relative_array[*]}\033[0m"

#遍历所有js文件
read_dir $workfile
read_dir $workfile2
read_dir $workfile3
read_dir $workfile4

#去重复
imgsList=($(awk -v RS=' ' '!a[$1]++' <<< ${imgsList[@]}))
#代码中用到的图片列表
# echo -e "\033[44;37m 项目中用到图片的元素为\033[0m"
# for((i=0;i<${#imgsList[@]};i++));
# do
# echo ${imgsList[$i]}
# done
# echo -e "\033[44;37m 项目中用到图片的元素为个数为:${#imgsList[*]}\033[0m"

#排查项目将中未用到的图片列表
getDiffImgList

# 2.是否一键删除未使用图片 选项
__PACK_DEL_OPTIONS=("1.放弃删除" "2.删除")
READ_USER_INPUT "请选择是否删除未使用图片: " "${__PACK_DEL_OPTIONS[*]}" ${#__PACK_DEL_OPTIONS[*]}

__PACK_DEL_OPTION=$?

if [ "$__PACK_DEL_OPTION" = "1" ]
then
    #不删除
    printMessage "选择放弃删除！"
    exit
elif [ "$__PACK_DEL_OPTION" = "2" ]
then
    #删除
    printMessage "开始删除..."
    for((i=0;i<${#diff_list[@]};i++));
    do
        filePath=$ImgFile/${diff_list[$i]}
        echo "文件"$filePath
        rm -rf $filePath
        #删除@2x
        filePath2=${filePath/.png/@2x.png}
        echo "文件"$filePath2
        rm -rf $filePath2
        #删除@3x
        filePath3=${filePath/.png/@3x.png}
        echo "文件"$filePath3
        rm -rf $filePath3
    done
    printMessage "删除完成!"
    exit
else
    echo -e "\033[41;33m================输入错误，请重检查您的输入================\033[0m"
    exit
fi
