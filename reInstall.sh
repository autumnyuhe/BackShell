# !/bin/bash

# 检查RN Config 配置文件
function checkConfiguration {
    #检查 config.js 配置文件中 RN_RELEASE 配置，如果 是 production 版本 配置为 false 则 发出 警报
    # 如果 配置的 是 false 就 发出 异常警报

    projectPath=$(dirname $(pwd))

    ApiFile=$projectPath"/Rn-newModel/app/utils/Config.js"
    echo $ApiFile

    echo -e "\033[42;37m==============开始检查config配置文件==============\033[0m"

    while read line
    do
        if [[ $line == //* ]]
        then
            continue
        fi

        if [[ $line == *WEBNUM* ]]
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

checkConfiguration

time=$(date "+%Y-%m-%d %H:%M:%S")
echo -e "\033[44;37m 初始化脚本执行时间： ${time} \033[0m"

npm install
source copyNodeModules.sh
npm start -- --reset-cache
