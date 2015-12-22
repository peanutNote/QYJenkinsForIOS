##关于Jenkins的一点小认识
Jenkins 是一个开源项目，提供了一种易于使用的持续集成系统，使开发者从繁杂的集成中解脱出来，专注于更为重要的业务逻辑实现上。同时 Jenkins 能实施监控集成中存在的错误，提供详细的日志文件和提醒功能，还能用图表的形式形象地展示项目构建的趋势和稳定性。

##Jenkins初探
换工作了，新公司想使用Jenkins实现自动化编译打包，安卓那边在之前公司有人弄过这次也是他负责，iOS这边就由我来负责了，起初想的是Jenkins应该是通过将服务器的代码下载下来再用xcode命令行的方式进行编译以及打包。有了这种想法我先去[Jenkins官网](http://jenkins-ci.org/)下载了最新的Jenkins安装到了我自己的电脑

* 新建了一个Item，勾选“构建一个自由风格的软件项目”
* 进入改Item，点击“配置”,在原代码管理处选在“Git”（这里需要填写git仓库地址以及你的git账号和密码）
* 如果需要更多有关git的功能如构建触发，构建环境等，可以去“系统管理”-“管理插件”-“可选插件”中下载安装
* 回到Item的配置，在“构建”-增加构建步骤中选在“Execute shell”,这里填写的就是在构建项目的时候会执行的shell命令（ 这里的shell命令其实就是用命令行来编译Xcode project，主要用到的命令有两个“xctool”以及“xcodebuild” ）
	* xcodebuild主要用法：
		* 清理项目							
		`xcodebuild clean -project ${PROJECT_NAME}.xcodeproj \
                 -configuration ${CONFIGURATION} \
                 -alltargets`
      * ARCHIVE
      `xcodebuild archive -project ${PROJECT_NAME}.xcodeproj \
                   -scheme ${SCHEME_NAME} \
                   -destination generic/platform=iOS \
                   -archivePath bin/${PROJECT_NAME}.xcarchive`
      * Export ipa
      `xcodebuild -exportArchive -archivePath ${PROJECT_NAME}.xcarchive \
                          -exportPath ${PROJECT_NAME} \
                          -exportFormat ipa \
                          -exportProvisioningProfile ${PROFILE_NAME}`
      * 具体参数说明可以参考该[博客](http://blog.reohou.com/how-to-export-ipa-from-archive-using-xcodebuild/)
	* xctool主要用法：
		* 安装xctool，可以使用[brew](http://brew.sh/)命令安装
		* 打包
		`xctool -workspace|-project YourWorkspace.xcworkspace|YourWorkspace.xcodeproj -scheme YourScheme archive`
		* 编译
		`xctool -workspace|-project YourWorkspace.xcworkspace|YourWorkspace.xcodeproj -scheme YourScheme build`
		* 测试（指的是单元测试）
		`xctool
  -workspace|-project YourWorkspace.xcworkspace|YourWorkspace.xcodeproj
  -scheme YourScheme`
* 点击“立即构建”，在此过程中可以点击“Build History”中的构建历史然后点击“Console Output”实时查看构建过程
* 一点说明：
	* 第一次直接构建的时候会报一个错“……xctool/xcodeblue: command not found……”，这事因为安装的Jenkins虽然是在我们本地，在构建的时候Jenkins没有加载本地环境变量PATH的能力，所以它不能识别xctool或者xcodebuild，解决办法：在Jenkins中“系统管理”-“系统设置”中找到“全局属性”勾选“Environment variables”添加键值对“PATH”：“xxx”（该路径可以使用echo $PATH）即可
	* 构建也会报错说找不到`-scheme YourScheme`中得`YourScheme`，这是因为Xcode没有设置将scheme设置为共享，Jenkins访问不到该scheme，解决办法：用Xcode打开该项目“Product”-“Scheme”-“Manager Schemes…”,将需要的scheme后面“share”打钩
	* 差不多这么样就可以使用了，这种主要用在本地搭建Jenkins的情况，但是这并不是我工作需要的，下面介绍另一种把Jenkins搭建在远程服务器的情况使用Jenkins打包iOS项目

##利用远程Jenkins实现本地打包上传
* 上面的情况是在本地搭建Jenkins在构建的时候其实就是利用本地安装的xctool或者xcodebuild命令对项目进行打包，但是如果Jenkins是搭建在远程服务器上呢，或许可以再远程服务器上安装xctool或者xcodebuild，但是如果改系统不支持这些工具（如windows，centos等）,这个时候我就需要利用Jenkins的Slave功能，将我们本地的一个已经安装了xctool或者xcodebuild的机器作为该Jenkins的一个代理，其原理就是当点击Jenkins中项目的构建时其实是Jenkins让他的一个slave去下载代码然后执行编译打包等工作（这些配置都是在远程服务器Jenkins中配置的），好了直接来说说如何做了。
* 在Jenkins中点击“系统管理”-“管理节点”-“新建节点”，这里的节点可以理解为代理模式中得协议，只有满足该节点才能成为Jenkins的代理去执行之后的操作
* 输入节点名，勾选“Dumb Slave”,完成后点击该节点，点击“配置从节点”

![image](https://github.com/peanutNote/QYJenkinsForIOS/blob/master/QYJenkinsForIOS/demo1.png)

![image](https://github.com/peanutNote/QYJenkinsForIOS/blob/master/QYJenkinsForIOS/demo2.png)

* 主要说明：
	* 远程工作目录：为你本地创建的一个用来存放代码以及生产打包产品的绝对目录（也可以是相对路劲具体看说明）
	* Environment variables：PATH为自己机器的PATH路径
	* Tool Locations：本地git路径，如果不填写如果使用git仓库无法下载代码
* 点击save，接下来就是用自己的电脑去服从（链接）该协议（节点），命令行执行`javaws YourJenkinsAddress/computer/iOS-Slave/slave-agent.jnlp`，知识后Jenkins上显示已经链接上
* 接着在Jenkins master下新建Item，在该item配置中勾选“Restrict where this project can be run”并在“Label Expression”后面填写前面创建的节点名称，这里要编译Xcode项目还需要下载一个插件“Xcode integration”，在“构建“”增加构建步骤中选择Xcode“，之后的配置可以参考[博客](https://blog.codecentric.de/en/2012/01/continuous-integration-for-ios-projects-with-jenkins-ci/)即可
* 最后就可以在制定的文件夹里生产想要的.ipa文件了，总得来说算是小成功了，但是还有很多配置都是云里雾里还有待继续研究