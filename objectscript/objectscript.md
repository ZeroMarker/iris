M语言学习笔记
2023-07-24
常见命令
$Order, $O
$get get var value, null return null.

' not
$data, $d judge var exist.

$quit,  $q

Set x=1
S time=$Piece($Horolog,","2)
write time

$Piece(string, delimiter, [from], [to])
Set定义变量值
Write 输出变量
Do 执行
Kill清除变量
Zwrite 变量和子节点值
Znspace切换命名空间
Break 断点调试
Get获取变量值，变量不存在时返回空值，用于出错保护
Piece截取字段值, $p(^PAPER(2,”ALL”),”^”,6), 取出以输入字符串^为分隔符的第六个元素
Quit退出，返回函数值
Comment // /**/
代码规范
命名
变量 大驼峰，单词分隔首字母大写
函数 动宾
类 DHC+产品+功能
注释
使用中文
类注释：
///名称
///描述
///编写者
///编写日期
函数注释
/// Function:获取rowId为3的病人（PA_Person）的生日（PAPER_Dob） (YYYY-MM-DD)
/// CreateDate:2023-07-24
/// Creator:chenhongliang
/// Table:PA_Person
/// Input:rowId
/// Output:PAPER_Dob (YYYY-MM-DD)
/// Others: d ##class(Demo.Person).GetPatientBirthday(3)
代码注释
//
四种变量类型
-	普通变量, a
-	进程Global, ^||a
-	Global, ^a
-	特殊变量
查看Global
使用Portal
 
使用Terminal
 
查找表结构和相应字段
使用基础数据平台的开发工具查询
 
Piece:$Piece对应位置
PList:Query对应位置
 
2023-07-25
Studio
类对应表结构
 
RowId表达式
 
表关联
 
多表查询
 
Class File
Persistent
Serial
Registered
Abstract
Date Type
CSP
Extend
Property Type
single value
collection
contain elelments
relationship
index
required
indexed
unique
calculated
创建持久类
 
持久类对应Global查询
 
建立索引
 
查询索引
 
SQL查询数据插入
 
使用Studio建立SQLStroage
 
添加RowID和ID表达式
 
 
2023-07-26
无索引遍历和有索引遍历
```objectscript
ClassMethod GetAddressByCode(Code As %String) As %String
{
    /*
    s count = 0
    s CTADDRowID = 0
    for
    {
        s CTADDRowID = $Order(^CT("ADD",CTADDRowID))
        q:CTADDRowID=""
        s CTADDCode = $Piece($Get(^CT("ADD",CTADDRowID)),"^",1)
        s count=count+1
        if (CTADDCode=Code)
        {
            s CTADDDesc = $Piece($Get(^CT("ADD",CTADDRowID)),"^",2)
            w "代码"_Code_"对应的地址为"_CTADDDesc
            w !
        }
    }
    */
    s CTADDRowID = $Order(^CT("ADD",0,"Code",Code,0))
    if (CTADDRowID'="")
    {
        s CTADDDesc = $Piece($Get(^CT("ADD",CTADDRowID)),"^",2)
        w "代码"_Code_"对应的地址为"_CTADDDesc
        w !
    }
}
```
特殊变量
$HOROLOG, $H
$JOB, $J
运算符
算数运算符：+, -, *, /
算数比较运算符：>, <
字符串比较：=, “[“被包含
连接符：_, &, ||, ‘
常用命令
Merge拷贝
程序流控制
If, else, for, quit, do, goto, continue, 
Try-catch, break, write, read
Tstart, TRollback, TCommit
命令
$Get
$Data, 变量存在,0->undefined,1->has data,10->has node, no data,11->has data and node
$Order，上一个或下一个索引
$Extract $E(“AABB”,2,3)
$Replace $R(str,”a”,”d”)
$Translate $tr(str,”a”,”b”)
$Length
$Zconvert $zcvt(str,”U”), Upper
$Zdate
$ZdateH
$Ztime
$ZtimeH
数据增删改查
SQL增加
```objectscript
/// Table:DHC_Student_SFA
/// Others:##class(Demo.Person).InsertData(1,"name",1,"2023-01-01")
ClassMethod InsertData(StCode As %String, StName As %String, StSexDR As %String, StDob As %String) As %String
{
    if (StDob'="")
    {
        s StDob = $zdh(StDob,3)
    }
    &SQL(
        INSERT INTO SQLUser.DHC_Student_SFA
        Values (:StCode, :StName, :StSexDR, :StDob)
    )
    if (SQLCODE=0)
    {
        s result="新增成功"_%ROWID
    }
    else
    {
        s result="新增失败"_%msg
    }
    q result
}
```
PLIST增加
```objectscript
/// Table:DHC_Student_SFA
/// Others:##class(Demo.Person).InsertDataByPLIST(1,"name",1,"2023-01-01")
ClassMethod InsertDataByPLIST(StCode As %String, StName As %String, StSexDR As %String, StDob As %String) As %String
{
    if (StDob'="")
    {
        s StDob = $zdh(StDob,3)
    }
	K PLIST
	S PLIST(1)=1
	S PLIST(2)=”name”
	S PLIST(3)=1
S PLIST(4)=”2023-01-01”
    &SQL(
        INSERT INTO SQLUser.DHC_Student_SFA
        Values :PLIST()
    )
    if (SQLCODE=0)
    {
        s result="新增成功"_%ROWID
    }
    else
    {
        s result="新增失败"_%msg
    }
    q result
}
```
 
2023-07-27
面向对象
继承, 多继承，左继承，右继承
封装
多态

## OREF
set obj = ##class(web.Student).%New()
## ID
set obj = ##class(web.Student).%OpenId()
##class(web.Student).%ExistsId()
.%DeleteId()
.%Id()
.%Save()

OREF
Class.%New()
ID
Class.%OpenId()
Obj.%Save()
Obj.%Close()
Obj.%Id()
Obj.%DeleteId()
类的类型、基本属性、方法
ClassType
Transient
Persistent
Serial
Data Type
Property
Single value
Collection
Containing elements
Relationship
Method, ClassMethod
Obj.Method()
Obj.ClassMethod(), Class.ClassMethod()
事务Transaction
变量和进程Global不支持
Tstart
Tcommit
Trollback
多层事务，一次提交，单层回滚
面向对象新增数据
```objectscript
ClassMethod ObjectAddData(StCode As %String, StName As %String, StSexDR As %String, StDob As %String) As %String
{
    q:StCode="" "学号不能为空"
    q:StName="" "姓名不能为空"
    q:$Data(^DHCSTUDENTSFA("Code",StCode)) "学号已存在"
    if (StDob'="")
    {
        s StDob = ##class(websys.Conversions).DateHtmlToLogical(StDob)
    }
    s oref=##class(User.DHCStudentSFA).%New()
    if (oref)
    {
        s oref.StCode = StCode
        s oref.StName = StName
        d oref.StSexDRSetObjectId(StSexDR)  // 指向性字段，使用SetObjectId()
        s oref.StDob = StDob
        Tstart
        d oref.%Save()
        if ($$$ISOK(sc))    // (sc)=1
        {
            Tcommit
            s StRowId = oref.%Id()
            s result = "新增成功"_StRowId
        }
        else
        {
            Trollback
            s result = "新增失败"_$system.OBJ.DisplayError(sc)
        }
    }
    d oref.%Close()
    q result
}    
```
WebService
```objectscript
/// web.Service
Class web.Service Extends %SOAP.WebService [ ProcedureBlock ]
{

/// Name of the WebService.
Parameter SERVICENAME = "Service";

/// TODO: change this to actual SOAP namespace.
/// SOAP Namespace for the WebService
Parameter NAMESPACE = "http://tempuri.org";

/// Namespaces of referenced classes will be used in the WSDL.
Parameter USECLASSNAMESPACES = 1;

/// TODO: add arguments and implementation.
/// Test
Method Test() As %String [ WebMethod ]
{
	Quit "Test"
}

Method GetPatientBirthday(RowId As %String) As %String [ WebMethod ]
{
    quit:RowId="" ""
    // ^PAPER(2,"ALL")="zfmcs0707^ZFMCS0707^^^^53879^2^^^^^^^^^^^^^^^^^^20"
    set PatientStr = $Get(^["DHC-APP"]PAPER(RowId,"ALL"))  // 获取数据串
    set PaperDob = $Piece(PatientStr,"^",6)     // 截取所需字段
    s:PaperDob'="" PaperDob=$ZDATE(PaperDob, 3)
    quit "RowId为"_RowId_"的病人（PA_Person）的生日"_PaperDob
}

Method Forecast(StockName As %String) As %Integer [ WebMethod ]
{
    // apply patented, nonlinear, heuristic to find new price
    Set price = $Random(1000)
    Quit price
}

}
```
 
2023-07-28
Query
```objectscript
/// Others:d ##class(%ResultSet).RunQuery("Demo.Person","GetList")
/// Query GetList() As %Query(ROWSPEC = "StRowId:%String,StCode,%String,StName:%String,StSexDR,%String,StDob:%String")
Query GetList() As websys.Query(ROWSPEC = "StRowID:%String,StCode,%String,StName:%String,StSexDR,%String,StDob:%String")
{
}

ClassMethod GetListExecute(ByRef qHandle As %Binary) As %Status
{
    s repid = $i(^CacheTemp)
    s ind = 1

    s StRowID = 0
    for
    {
        s StRowID = $O(^DHCSTUDENTSFA(StRowID))
        q:StRowID'=""
        s StCode = $p($g(^DHCSTUDENTSFA,StRowID),"^",1)
        s StName = $p($g(^DHCSTUDENTSFA,StRowID),"^",2)
        s StSexDR = $p($g(^DHCSTUDENTSFA,StRowID),"^",3)
        s:StSexDR'="" StSexDR = $p($g(^CT("SEX",StSexDR)),"^",2)
        s StDob = $p($g(^DHCSTUDENTSFA,StRowID),"^",4)
        s:StDob'="" StDob = $zd(StDob, 3)
        s Data = $lb(StRowID,StCode,StName,StSexDR,StDob)
        s ^CacheTemp(repid,ind)=Data
        s ind = ind + 1        
    }
    s qHandle = $lb(0,repid,0)
    q $$$OK
}
```
父子表
```objectscript
/// 子表建立关系
Relationship DHCScParRef As DHCStudentGXA [ Cardinality = parent, Inverse = ChildScCourse, SqlFieldName = DHC_ScParRef ];

/// 创建childsub
Property DHCScChildSub As %Numeric [ InitialExpression = {$i(^DHCCOURSEGX(+$s($d(initvalue):initvalue,1:%d(0)),"Course",0))}, Required, SqlColumnNumber = 2, SqlFieldName = DHC_ScChildSub ];

/// 定义父表的关系
Relationship ChildScCourse As DHCStudentCourse [ Cardinality = children, Inverse = DHCScParRef ];
```
WebService
```objectscript
Class WeatherWebService.WeatherWebServiceSoap Extends %SOAP.WebClient [ ProcedureBlock ]
{

/// This is the URL used to access the web service.
Parameter LOCATION = "http://www.webxml.com.cn/WebServices/WeatherWebService.asmx";

/// This is the namespace used by the Service
Parameter NAMESPACE = "http://WebXml.com.cn/";

/// Use xsi:type attribute for literal types.
Parameter OUTPUTTYPEATTRIBUTE = 1;

/// Determines handling of Security header.
Parameter SECURITYIN = "ALLOW";

/// This is the name of the Service
Parameter SERVICENAME = "WeatherWebService";

/// This service supports both SOAP 1.1 and SOAP 1.2.
Parameter SOAPVERSION;

/// w ##class(WeatherWebService.WeatherWebServiceSoap).%New().getSupportCity()
ClassMethod TestWebService(byProvinceName As %String) As %String
{
	s obj = ##class(WeatherWebService.WeatherWebServiceSoap).%New()
	if (obj)
	{
		s result = obj.getSupportCity(byProvinceName)
		q result
	}
}
}
```
HISUI
```html
<html>
<head>

<!-- Put your page Title here -->
<title>	Cache Server Page </title>

<HISUI/>
</head>

<body>
		<a href="#" class="hisui-linkbutton hover-dark" data-options="iconCls:'icon-w-find'">时间线查看</a>
<a href="#" class="hisui-linkbutton hover-dark">确诊</a>
<a href="#" class="hisui-linkbutton" id="searchbtn" data-options="iconCls:'icon-search'">查询</a>    
		<!-- Put your page code here -->
		<script language="javascript">
		$(function(){
			$("#searchbtn").click(function(){
				alert(1)
				})
			}
		)
		</script>
</body>
</html>
```
 
