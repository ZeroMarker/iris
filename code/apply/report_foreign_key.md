## 报告外键
```objectscript
/// 标本报告关联表
Class User.EnsLISSpecimenReport Extends %Persistent [ ClassType = persistent, DdlAllowed, Owner = {UnknownUser}, ProcedureBlock, SqlTableName = Ens_LISSpecimenReport ]
{

ForeignKey FKSPECIDREFERENCESPECREPORT(LISSRReportID) References User.EnsLISReportResult(LISREPORTRESULTPKey) [ SqlName = FK_SPECID_REFERENCE_SPECREPORT ];

/// DDL Primary Key Specification
Index LISSPECIMENREPORTPKey On (LISSRReportID, LISSRSpecimenID, LISSROrderItemID);

Index RELORDERSPECIMENHOSCODE On LISSRSpecimenID;

/// 报告ID 
Property LISSRReportID As %Library.String [ SqlColumnNumber = 2, SqlFieldName = LISSR_ReportID ];

/// 标本号 
Property LISSRSpecimenID As %Library.String [ SqlColumnNumber = 3, SqlFieldName = LISSR_SpecimenID ];

/// 医嘱号
Property LISSROrderItemID As User.OEOrdItem [ SqlColumnNumber = 4, SqlFieldName = LISSR_OrderItemID ];

/// 患者ID
Property LISSRPatientID As User.PAPatMas [ SqlColumnNumber = 5, SqlFieldName = LISSR_PatientID ];

/// 就诊号
Property LISSRVisitNumber As User.PAAdm [ SqlColumnNumber = 6, SqlFieldName = LISSR_VisitNumber ];

/// 时间戳 
Property LISSRUpdateDate As %Library.Date [ InitialExpression = {$P($H,",")}, Required, SqlColumnNumber = 7, SqlFieldName = LISSR_UpdateDate ];

/// 时间戳
Property LISSRUpdateTime As %Library.Time [ InitialExpression = {$P($H,",",2)}, Required, SqlColumnNumber = 8, SqlFieldName = LISSR_UpdateTime ];

/// 报告状态 
Property LISSRStatus As %Library.String [ InitialExpression = "1", SqlColumnNumber = 9, SqlFieldName = LISSR_Status ];

}
```