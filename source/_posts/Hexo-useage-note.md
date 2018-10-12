---
title: Hexo使用笔记
type: categories
comments: true
date: 2017-04-07 21:20:19
categories: Hexo
tags: [hexo使用]
---

{% cq %} 

博主使用过博客站点有简书、CSDN、博客园、都不同程度的遇到了各种不顺心，MarkDown使用起来也不是特别方便，决定使用GitPages+Hexo来实现编写博客，在完成完成Hexo配置的过程中，踩了不少坑，决定记录下来供大家参考。

个人博客站点:[KobeLuo的博客](https://kobeluo.github.io/TECH/)

{% endcq %}


<!--more-->

### 有关[Github](https://github.com/)仓库

---


#### 创建一个Github账号，添加一个Repository

{% note danger %} 
**注意： 如果想要使用username.github.io这种方式访问你的博客站点，
Repository的名字一定要与用户名username相同**(username/username.github.io)
仓库名创建之后一定像这样:KobeLuo/KobeLuo.github.io      
{% endnote %}
博主曾经在这里踩过坑，导致博客站点报404，一直无法访问

#### [git分支与关系](https://help.github.com/articles/configuring-a-publishing-source-for-github-pages/)

首先理解一个原理:
{% note info %}
github仓库下至少需要两个分支,这里我们假设为branch1和branch2，
如果branch1作为最后静态页面的发布分支，那么branch2就可以作为平时创作的源代码托管分支.
branch1不需要你通过git命令push代码，需要通过使用`hexo d`命令发布到该分支上，前提是本地_config.yml文件已经配置正确，关于本地配置后面会提到
branch2是平时写博客过程中，需要使用git命令push源代码的分支,当然你也可以创建更多的源代码托管分支。
{% endnote%}

通常情况下建的博客站点都是在username.github.io这一层，GitPages会默认master作为hexo的发布分支(上面提到的branch1)，此时settings->Gitpages->Source下的branch是不可选择的，在这种情况下，开发分支就必须要使用其它的分支(比如develop分支或其他分支)来存储Hexo主题下的源代码。

如果你的博客站点不是以username.github.io，那么需要按照[**git发布配置规范**](https://help.github.com/articles/configuring-a-publishing-source-for-github-pages/)配置站点，此时settings->GitPages->Source可以选择，通常情况下会有master、gh-pages和/docs供你选择，选择好静态页面的发布分支后,再考虑源代码托管到哪个分支上面。

#### 关于SSHKey    
首先进入用户目录下的.ssh目录
{% codeblock lang:objc %}
cd ~/.ssh
{% endcodeblock %}使用ssh keygen生成一个SSHKey,需要提供一个邮箱
{% codeblock lang:objc %}
ssh-keygen -t rsa -C "your@email.address"
{% endcodeblock %}

Enter file in which to save the key (/Users/name/.ssh/id_rsa):**`在此输入id_rsa的名字:id_rsa_name`**
例如:id_rsa_person or id_rsa_company,如果只需要管理一个SSHKey,直接回车会默认生成id_rsa为名的SSHKey
配置了名字，后面一路回车
结束后，.ssh文件夹里边会包括id_rsa_name、id_rsa_name.pub两个文件，复制id_rsa_pub的内容拷贝到github设置的SSHKey选项中即可完成配置。

#### 多账号管理:
如果你有多个Github账号，由于Github账号SSHKey的唯一性，就必须生成多个SSHKey，多个SSHKey只要生成的时候指定的名字不一样即可，假设你生成了两个rsa名为id_rsa_name1和id_rsa_name2,
那么你需要在.ssh目录里边创建一个名为`config`的文件，里边的配置信息如下:

{% codeblock lang:objc %}
Host kobe_old //所有使用id_rsa_kobe_old.pub作为公钥的github链接中的github.com需要换成kobe_old
HostName 			github.com					
User				git
IdentityFile		~/.ssh/id_rsa_kobe_old

Host kobe_new //所有使用id_rsa_kobe_new.pub作为公钥的github链接中的github.com需要换成kobe_new
HostName 			github.com				
User				git
IdentityFile		~/.ssh/id_rsa_kobe_new 
{% endcodeblock %}
{% note info %}
从远程clone一个仓库时，例如https://github.com:KobeLuo/Kobeluo.github.io/
当有多个SSHKey时，``需要将github.io改成kobe_new``如果该账号使用kobe_new对应的SSHKey
更改后的远程地址是https://kobe_new:KobeLuo/Kobeluo.github.io/
{% endnote %}


#### 绑定你的独立域名
Github提供gitpages服务可以生成独立二级域名，如非必要，你大可不必自己购买独立域名，如果你购买了自己的域名，就按照以下步骤做:
- 在静态页面托管分支创建一个CNAME文件，里边放你的独立域名，我的域名是kobeluo.com,因此CNAME中存放的就是kobeluo.com,如果你使用的是hexo模板，每次执行hexo g之后CNAME文件都将被清理掉，**解决办法是把CNAME文件存放在本地hexo根目录下的source文件目录中，这样每次hexo d都会生成到发布静态网页分支**

- 配置DNS,在你的DNS配置域名解析页面中配置三组记录他们分别是:
我这里使用的是[**DNSPod**](https://www.dnspod.cn),关于如何使用DNSPod请自行查阅。

{% codeblock lang:objc %}
主机记录	记录类型	记录值
@	A	192.30.252.153
@	A	192.30.252.154
www	CNAME	your.blog.address(我这里是:KobeLuo.github.io)
{% endcodeblock %}

配置完成之后，等待10分钟，等待域名生效。

### 关于[Hexo主题](https://github.com/iissnan/hexo-theme-next)模板
---

#### hexo安装
请自行查阅[**hexo官方安装教程](https://hexo.io/zh-cn/docs/)

#### hexo命令
hexo有自己独立的一套命令

{% codeblock lang:objc %}
hexo new "article"
//创建一篇新文章
hexo new page "foldername"
//创建一个新页面
hexo g  (hexo generate)
//生成静态页面
hexo s  (hexo server) ,如果报错就执行代码 
//链接本地服务器
hexo d  (hexo deploy)
//发布到指定服务器
hexo clean //清理静态页面站点，博主使用过一次，会把git配置和hexo搞乱，慎用。

{% endcodeblock %}

执行hexo s可能会报错，如果报错则执行以下命令：
{% codeblock lang:objc %}
npm install hexo-server --save
{% endcodeblock %}

#### hexo站点配置
hexo根目录下的`_config.yml`就是站点配置文件，使用编辑软件打开,搜索`deploy:`,
{% codeblock lang:objc %}
deploy:
	type: git
	repo: your.blog.site(like:xxx.github.io)
	branch: gh-pages or master or docs
{% endcodeblock %}

{% note info %}
填写_config.yml配置文件里边的值前都需要添加一个空格，
例如 `type: git` 注意中间有一个空格
{% endnote %}
配置好这一项后，使用`Hexo d`就可以把代码deploy到远程仓库了
{% note warnning %}
如果你的Github站点不是以github.io结束的，需要配置`root:`字段，例如，我的技术博客地址是kobeluo.github.io/TECH/ , 那么root:配置就是 **`/TECH/`**,否则github无法连接CSS和JS
{% endnote %}

### <center> 2018.10.12日更新</center >
--- 
由于自己懒惰，博客已经停更一年多了，近日再次捡起博客，发现Hexo已经有一些变化，记载于此。
首先hexo不再像以前一样安装之后就可以直接使用, [hexo是怎么工作的](http://coderunthings.com/2017/08/20/howhexoworks/),这篇文章说得非常清楚了。
#### 关于hexo
hexo分为三个分支：
* HEXO
    1. hexo-cli
    2. hexo (hexo-core)
    3. hexo plugins

使用命令`npm install -g hexo-cli` 后可以使用命令
`hexo generate (hexo g) 和 hexo new`但是无法使用`hexo s 和hexo d`,
此时需要使用npm安装启动本地服务和发布的插件,命令是
{% codeblock lang:objc %}
npm install hexo-server --save
npm install hexo-deployer-git --save
{% endcodeblock %}
安装好插件后,应该就可以使用`hexo s`了，此时启动本地服务,网页可能弹出Can not GET /XX/XX目录,此时你需要执行
{% codeblock lang:objc %}
npm install
{% endcodeblock %}
再次执行hexo s,本地网页应该就可以正常显示了.

假设你已经安装好了[npm](https://treehouse.github.io/installation-guides/mac/node-mac.html),这里针对已有的博客,需要再次编辑博客的一个完整流程:
{% codeblock lang:objc %}
git clone git@github.com:xxxxxxx /A/B/C  将仓库clone到你本地/A/B/C的位置
npm install -g hexo-cli 安装hexo
npm install  
npm install hexo-server --save 安装hexo s
npm install hexo-deployer-git --save 安装 hexo d

{% endcodeblock %}
如果你本地有多个github账号，因此而产生的权限问题，请左转[ssh key](#多账号管理)
hexo d实质是将你本地public文件夹的内容push到博客`_config.yml`所指定的分支上去,如果`hexo d`报权限错误，
请一定检查
```ruby
deploy:
type: git
repo: git@github.com:KobeLuo/TECH.git
branch: gh-pages
```  

### 友情链接

---

下面是一些记录的hexo站点:

- http://www.jianshu.com/p/ab21abc31153


- http://www.jianshu.com/p/35e197cb1273


- https://hexo.io/docs/

- https://www.jianshu.com/p/35e197cb1273

{% note info %}
**特别鸣谢:**
建站过程中，[**Andrew Liu**](http://liuhongjiang.github.io/hexotech/)提供了非常多的帮助，再次感谢！.
{% endnote %}
