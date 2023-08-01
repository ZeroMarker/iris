父子表
Relationship
1-n,父子
/// 子表建立关系
Relationship DHCScParRef As DHCStudentGXA [ Cardinality = parent, Inverse = ChildScCourse, SqlFieldName = DHC_ScParRef ];

/// 创建childsub
Property DHCScChildSub As %Numeric [ InitialExpression = {$i(^DHCCOURSEGX(+$s($d(initvalue):initvalue,1:%d(0)),"Course",0))}, Required, SqlColumnNumber = 2, SqlFieldName = DHC_ScChildSub ];

/// 定义父表的关系
Relationship ChildScCourse As DHCStudentCourse [ Cardinality = children, Inverse = DHCScParRef ];

