# !/bin/bash

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
                echo -e "\033[41;33m================检查config配置异常================\033[0m"
                exit
            else
                echo -e "\033[42;37m================检查config配置正常================\033[0m"
            fi
        fi

    done < ${ApiFile}
}

# 打包IOS函数 Production 环境
function doIOSProductionPackaging {
    echo -e "\033[44;37m IOS 正式包 开始打包\033[0m"
    react-native bundle --entry-file index.js --bundle-output ./bundle/ios/main.jsbundle --platform ios --assets-dest ./bundle/ios --dev false
    echo -e "\033[44;37m IOS 正式包 开始上传打包\033[0m"
    code-push release-react TXTB-Ios ios --t 1.0.0 --dev false --d Production --des "$package_des" --m true

}

# 打包Android函数  Production 环境
function doAndroidProductionPackaging {
    echo -e "\033[44;37m Android 正式包 开始打包\033[0m"
    react-native bundle --entry-file index.js --bundle-output ./bundle/android/main.jsbundle --platform android --assets-dest ./bundle/android --dev false
    echo -e "\033[44;37m Android 正式包 开始上传打包\033[0m"
    code-push release-react TXTB-Android android --t 1.0.0 --dev false --d Production --des "$package_des" --m true
}

# 打包IOS函数 Debug 环境
function doIOSDebugPackaging {
    echo -e "\033[44;37m IOS 测试包 开始打包\033[0m"
    react-native bundle --entry-file index.js --bundle-output ./bundle/ios/main.jsbundle --platform ios --assets-dest ./bundle/ios --dev false
    echo -e "\033[44;37m IOS 测试包 开始上传打包\033[0m"
    code-push release-react TXTB-Ios ios --t 1.0.0 --dev false --d Staging --des "$package_des" --m true

}

# 打包Android函数  Debug 环境
function doAndroidDebugPackaging {
    echo -e "\033[44;37m Android 测试包 开始打包\033[0m"
    react-native bundle --entry-file index.js --bundle-output ./bundle/android/main.jsbundle --platform android --assets-dest ./bundle/android --dev false
    echo -e "\033[44;37m Android 测试包 开始上传打包\033[0m"
    code-push release-react TXTB-Android android --t 1.0.0 --dev false --d Staging --des "$package_des" --m true
}

#选择打包环境
echo -e "请选择需要推送热更包的\033[32;1m环境\033[0m(输入序号,按回车即可)："
echo "1. 正式包"
echo "2. 测试包"
# 读取用户输入并存到变量里
read parameter
sleep 0.5
environment="$parameter"
# 判读用户是否有输入
if [ "$environment" = "1" ];then
    #正式包热更需要检车 config 配置文件
    #检测本地硬编码
    echo -e "请选择是否检测本地\033[32;1m config环境配置 \033[0m(输入序号,按回车即可)"
    echo "检测输入：    1"
    echo "不检测请输入：16896086"

    while true
    do
        read parameter
        sleep 0.5
        if [ $parameter == "1" ]
        then
            #检查config配置是否正确
            checkConfiguration
            break
        elif [ $parameter == "16896086" ]
        then
            break
        else
            echo "输入的参数无效，请重新输入！"
        fi
    done

fi


#选择打包方式
echo -e "请选择需要推送热更的\033[32;1m平台\033[0m(输入序号,按回车即可)："
echo "1. IOS包"
echo "2. Android包"
echo "3. IOS & Android 全部包"
# 读取用户输入并存到变量里
read parameter
sleep 0.5
package_number="$parameter"

# 更新日志自动增加更新日期
time=$(date "+%Y-%m-%d")

# 判读用户是否有输入
if [ -n "$environment" ]
then
    if [ "$environment" = "1" ] ; then
        #正式环境文案输入直接写死为 ‘优化用户游戏体验；’
        package_des="优化用户游戏体验！\\n\\n更新日期：$time"
        echo "$package_des"
        if [[ "$package_number" = "1" ]];
            then
                doIOSProductionPackaging
        elif [[ $package_number == "2" ]]
            then
                doAndroidProductionPackaging
        elif [[ $package_number == "3" ]]
            then
                doIOSProductionPackaging
                doAndroidProductionPackaging
        fi
    elif [ "$environment" = "2" ] ; then
        #测试环境 可以输入修改内容
        echo "请选择输入修改内容"
        # 读取用户输入并存到变量里
        read parameter
        sleep 0.5
        package_des="$parameter\\n\\n更新日期：$time"
        echo "$package_des"

        if [[ "$package_number" = "1" ]]
            then
                doIOSDebugPackaging
        elif [[ $package_number == "2" ]]
            then
                doAndroidDebugPackaging
        elif [[ $package_number == "3" ]]
            then
                doIOSDebugPackaging
                doAndroidDebugPackaging
        fi
    fi
fi

#最后重置 bundle 文件夹

echo "删除打包文件!!!"
rm -rf bundle/
echo "重置打包目录!!!"
mkdir bundle bundle/ios bundle/android
