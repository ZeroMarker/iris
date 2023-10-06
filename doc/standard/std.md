# 命名

## 产品前缀
医生站Doc

## 命名规范
### CSP
/web/csp/
产品前缀
CSP名称后加.hui（所有的新建CSP），全小写字母
### CSS
/web/scripts/css
产品.功能.css

## HTML标签外
### 页面路径注释
```
<!--住院患者医嘱信息总览护士,csp.csp:ipdoc.patorderviewnurse-->
```
作用：页面CSP定位
### 登录验证
```
<csp:method name=OnPreHTTP arguments="" returntype=%Boolean>
	;1.2 是否登录或者登录超期
	i ##class(ext.websys.SessionEvents).SessionExpired() q 1
</csp:method> 
```
## Head
自定义csr
css
<Server>
// 动态生成HTML

## Body
<csp:if>
.show.csp
<csp:else>

## JS
最后

# 元素命名
弹窗：保存，关闭
非弹窗：确定，取消

编辑，修改=》修改
查询，查找=》查询
清屏，清空=》清屏

表单：新增
表格：增加

读身份证，读卡，读取信息

# JS
入口JS
*.main.js
产品文件夹，文件夹_hui
非产品文件夹，文件.hui

## 全局变量
公有    m_*
私有    _*

## 接口对接

scripts/dhcdoc/interface/template.js
scripts/dhcdoc/DHCDSS.js

