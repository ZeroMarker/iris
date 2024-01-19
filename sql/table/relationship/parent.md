## intro
Relationship
1-n,父子
```objectscript
/// 子表建立关系
Relationship DHCScParRef As DHCStudentGXA [ Cardinality = parent, Inverse = ChildScCourse, SqlFieldName = DHC_ScParRef ];

/// 创建childsub
Property DHCScChildSub As %Numeric [ InitialExpression = {$i(^DHCCOURSEGX(+$s($d(initvalue):initvalue,1:%d(0)),"Course",0))}, Required, SqlColumnNumber = 2, SqlFieldName = DHC_ScChildSub ];


/// 定义父表的关系
Relationship ChildScCourse As DHCStudentCourse [ Cardinality = children, Inverse = DHCScParRef ];
```

## Cache Storage
// 父表
Relationship ChildCourse As StudentCourse [ Cardinality = children, Inverse = ParRef ];
^User.StudentCourseD

// 子表
Relationship ParRef As Student [ Cardinality = parent, Inverse = ChildCourse, sqlFieldName = "Student_ParRef"];
Property CourseDR
Property Score

// Course
Property CourseDR

INSERT INTO StudentCourse (Student_ParRef, Course_DR, Score)
VALUES (1, 2, 90)
VALUES (1, 4, 100)

建立关系后编译产生Storage

## SQLStorage

父子表间的RelationShip定义
子表中ChildSub的定义
子表中ChildSub的Index定义
子表SQLStorage的DataMaster的定义


Relationship  copy  改：父表 和子表
子表 ChildSub copy  改：sub名称 + InitialExpression (storage 未确定 可以先不修改)
子表对 ChildSub 加 index  [ IdKey, PrimaryKey, Unique ]
新建一个storage , SQLStoage  去定义主索引
DataMap 里 subscripts 去定义Global节点  第一级节点：
      {父表.RowId }  {DHC_BStudent.St_RowId}///  最后一级节点是 {ChildSub}
DataMap 里 RowId  父表.RowId {L1}     ChildSub {Lx}
定义 SqlRowIdName 属性值 注意: SqlIdExpression 不用去定义
storage 已经确定，对 ChildSub 修改 InitialExpression:Global 名称 附加节点 


父表： 
Relationship ChildStudentCourse As User.DHCStudentCourse [ Cardinality = children, Inverse = DHCSCStParRef ]
子表：
Index RowIDBasedIDKeyIndex On DHCSCChildsub [ IdKey, PrimaryKey, Unique ];
Relationship DHCSCStParRef As User.DHCStudent [ Cardinality = parent, Inverse = ChildStudentCourse, Required, SqlFieldName = DHCSC_St_ParRef ];

Property DHCSCChildsub As %Numeric(SCALE = 0) [ InitialExpression = {$i(^DHCSTUDENT(+$s($d(initvalue):initvalue,1:%d(0)),"C",0))}, Required, SqlColumnNumber = 2, SqlFieldName = DHCSC_Childsub ];

DataMaster
global
父表global
subscript
{Student.St_RowId}
"Course"
{ChildSub}
rowid
Student.St_RowId    {L1}
ChildSub            {L3}

sqlRowIdName
Sc_RowID
{Student.St_RowId}||{ChildSub}

IndexCourse
^DHCSTUDENT
subscript
{Student.St_RowId}
"Course"
0
"Course"
{Course_DR}
{ChildSub}
rowid
Student.St_RowId    {L1}
ChildSub            {L6}


## Child Table CRUD
new
```objectscript
s obj = ##class(StudentCourse).%New(ParRef)
// 新建对象需要传递父表RowId

if(obj) {
    d obj.ParRefSetObjectId(ParRef)
    d obj.CourseDRSetObjectId(CourseDR)
    tcommit
    s sc=obj.%Save()
    if($$$ISOK(sc)) {
        s id = obj.%Id()
        s result
    }
    else {
        s error = $System.Status.GetErrorText(sc)
        s result
    }
    d obj.%Close()
}
q result


```
Query
```objectscript
s id = "3||6"
s obj=##class(Student).OpenId(id)

if (ParRef'="") {
    s ChildSub = 0
    for {
        s ChildSub = $o(^DHCSTUDNET(ParRef,"C",ChildSub))
        q:ChildSub=""
        s StScRowId=ParRef_"||"_ChildSub
        s dataStr = $g(^DHCSTUDNET(ParRef,"C",ChildSub))
    }
}
else {
    s ParRef=0
    for {
        s ParRef=$o(^DHCSTUDENT(ParRef))
        q:ParRef=""
        s ChildSub=0
        for {
            s ChildSub=$o(^DHCSTUDNET(ParRef,"C",ChildSub))
            q:ChildSub=""
            s StScRowId=ParRef_"||"_ChildSub
            s dataStr = $g(^DHCSTUDNET(ParRef,"C",ChildSub))
        }
    }
}
```
save
```objectscript
tstart
s sc=obj.%Save()
if ($$$ISOK(sc)) {
    tcommit
    s ParRef = obj.%Id()
    if (ParRef'="") {
        s crsObj = ##class(StudentCourse).%New(ParRef)
        // Cache Storage
        s scObj = ##class(User.StudentCourse).%New()
		d scObj.StParRefSetObjectId(id)
        
        if (crsObj) {
            tstart
            s coursesc = crsObj.%Save()
            if ($$$ISOK(coursesc)) {
                tcommit
            }
            else {
                trollback
            }
            d crsObj.%Close()
        }
    }
}
else {
    trollback
}
d obj.%Close()
```

