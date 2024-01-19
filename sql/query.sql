-- @Block
SELECT description,*
From information_schema.columns
where table_name like "PA_adm";
-- 表字段

-- @Block
SELECT description,*
From information_schema.columns
where	
		table_schema = "SQLUser"
	-- and column_name like "%json%"
 	and table_name like "%SS_group%";
-- 表字段

-- @Block
SELECT OE_OrdItem->OE_OrdExec->OEORE_XDate
FROM OE_Order;
-- 父表子表引用

-- @Block
select OEORI_ItemStat_DR->ostat_desc As 状态 ,*
from OE_OrdItem
WHERE OEORI_RowId in (
	SELECT DISTINCT  ES_OrdItemID
	FROM SqlUser.Ens_Statuslog
	where ES_ExamID like "%EKG104%"
)
order by OEORI_ItemStat_DR->ostat_desc;

-- @Block
SELECT * 
FROM SQLUser.CT_Sex;
--性别

-- @Block
INSERT INTO SQLUser.Student 
VALUES ('1', '2023-01-01', '张', '1');

-- @Block
SELECT TARAC_TARTAC_DR->TARTAC_Desc,* 
FROM SQLUser.DHC_TarAcctCate;
-- 账单费用类别

-- @Block
SELECT * 
FROM SQLUser.PA_PatMas;
--病人信息

-- @Block
SELECT AA_Arcim_DR -> ARCIM_Desc AS apply_count, count(*) 
FROM SQLUser.DHC_Doc_AntibioticApply 
group by AA_Arcim_DR;
-- 特抗药申请

-- @Block
Select * 
FROM SQLUser.CT_Address;
--地址

-- @Block
SELECT * 
from SQLUser.CT_Hospital;
--医院

-- @Block
SELECT * 
FROM SQLUser.ARC_ItmMast 
-- 医嘱项明细

-- @Block
select * from SQLUser.DHC_CardRef;
-- 卡表

-- @Block
SELECT *
FROM SQLUser.OE_OrdItem;
--医嘱明细

-- @Block
SELECT  AA_OEORI_DR->OEORI_OEORD_ParRef->OEORD_Adm_DR->PAADM_PAPMI_DR->PAPMI_No 
        AS PA 
FROM SQLUser.DHC_Doc_AntibioticApply
WHERE AA_OEORI_DR like "%||%";
-- 特抗药申请

-- @Block
SELECT OEORI_RowId 
FROM SQLUser.OE_OrdItem 
WHERE OEORI_RowId like "266%";

-- @Block
SELECT OEORI_RowId 
FROM SQLUser.OE_OrdItem 
WHERE OEORI_RowId IN (
    SELECT  AA_OEORI_DR->OEORI_RowId 
    FROM SQLUser.DHC_Doc_AntibioticApply
);
-- 医嘱 特抗药

-- @Block
SELECT * 
FROM SQLUser.PA_Adm 
WHERE PAADM_ADMNo = "0000000001";
-- 就诊

-- @Block
SELECT  AA_OEORI_DR->OEORI_InsertDate 
        AS PA 
FROM SQLUser.DHC_Doc_AntibioticApply;
-- 特抗药

-- @Block
select * 
from SQLUser.ARC_BillGrp;
-- 医嘱账单组

-- @Block
select AA_Arcim_DR -> ARCIM_Desc 
        AS apply_count, count(*) 
FROM SQLUser.DHC_Doc_AntibioticApply 
group by AA_Arcim_DR;
-- 特抗药

-- @Block
select AA_Arcim_DR -> ARCIM_Desc,* 
FROM SQLUser.DHC_Doc_AntibioticApply 
group by AA_Arcim_DR
-- 特抗药

-- @Block
select PAPMI_ConcessionCardNo ,* 
from SQLUser.PA_PatMas;
-- 病人信息


-- @Block
SELECT OEORI_RowId 
FROM SQLUser.OE_OrdItem 
WHERE OEORI_RowId like "266%"
-- 医嘱明细

-- @Block
SELECT OEORI_RowId 
FROM SQLUser.OE_OrdItem 
WHERE OEORI_RowId IN (
    SELECT  AA_OEORI_DR->OEORI_RowId 
    FROM SQLUser.DHC_Doc_AntibioticApply
);
-- 医嘱明细 特抗药申请

-- @Block
SElECT * 
FROM SQLUser.CT_CareProv

-- @Block
SELECT * 
FROM SQLUser.CT_Loc
-- 科室

-- @Block
SELECT PAADM_PAPMI_DR -> PAPMI_Name,PAADM_AdmDocCodeDR->CTPCP_Desc,PAADM_DepCode_DR->CTLOC_Desc,* 
FROM SQLUser.PA_Adm 
WHERE PAADM_ADMNo = "0000000001";
-- 就诊

-- @Block
SELECT * 
FROM SQLUser.DHC_DocCureAppCureItem;
-- 治疗申请单中治疗项目

-- @Block
SELECT * 
FROM SQLUser.DHC_DocCureRecode;
-- Arrive_DR DCR_ChildSub
-- 治疗记录表(预约记录表子表)

-- @Block
SELECT * 
FROM SQLUser.DHC_DocCureApp;
-- DCA_RowId
-- 治疗记录申请表

-- @Block
SELECT DCA_Adm_DR->PAADM_PAPMI_DR->PAPMI_Name,* 
FROM SQLUser.DHC_DocCureApp;
-- 治疗记录申请表

-- @Block
SELECT PAPMI_No, PAPMI_Name, PAPMI_DOB, PAPMI_Sex_DR->CTSEX_Desc, PAPMI_DVAnumber 
FROM PA_PatMas 
WHERE PAPMI_Name LIKE "陈洪亮%";
-- 病人信息

-- @Block
SELECT * 
FROM PA_Adm
WHERE PAADM_PAPMI_DR = 676;
-- 就诊

-- @Block
SELECT * 
FROM OE_Order
WHERE OEORD_Adm_DR = 1774;
-- 就诊 医嘱

-- @Block
SELECT TOP 40 * 
FROM OE_OrdItem
WHERE OEORI_OEORD_ParRef = 1636;
-- 医嘱明细

-- @Block
SELECT TOP 20 * 
FROM DHC_InvPrt
WHERE PRT_Acount = 1243.29;
-- 发票

-- @Block
SELECT * 
FROM OE_OrdItem
WHERE OEORI_OEORD_ParRef IN
(
	SELECT OEORD_RowId1 FROM OE_Order
	WHERE OEORD_Adm_DR IN
	(
		SELECT PAADM_RowID FROM PA_Adm
		WHERE PAADM_PAPMI_DR = 676
	)
);
--  就诊 医嘱 医嘱明细

-- @Block
SELECT TOP 20 * 
FROM DHC_InvPrt
WHERE PRT_inv = "0001000202";
-- 发票打印

-- @Block
SELECT * 
FROM dhc_patbilldetails
WHERE PBD_PBO_ParRef IN
(
	SELECT PBO_RowId 
	FROM dhc_patbillorder
	WHERE PBO_PB_ParRef IN
	(
		SELECT PB_Rowid 
		FROM dhc_patientbill
		WHERE PB_Adm_DR IN
		(
			SELECT PAADM_Rowid 
			FROM PA_adm
			WHERE PAADM_PAPMI_DR = 846 & PAADM_Type = "I"
		)
	)
);
-- 就诊 账单 账单医嘱 账单明细

-- @Block
SELECT TOP 20 * 
FROM PHC_DrgMast
WHERE PHCD_Code = 4567897654;
-- 药品

-- @Block
SELECT TOP 20 * 
FROM ARC_ItmMast
WHERE ARCIM_Code = 4567897654;
-- 医嘱项

-- @Block
SELECT TOP 20 * 
FROM INC_Itm 
WHERE INCI_Code = 4567897654;
-- Inventory
-- 库存项

-- @Block
SELECT TOP 20 * 
FROM DHC_InIsTrf 
WHERE INIT_No = "TRXYK1282023090802";
-- 库存转移申请单

-- @Block
SELECT TOP 20 * 
FROM DHC_InIsTrfItm
WHERE INITI_INIT_ParRef = 146;
-- 库存转移申请单

-- @Block
SELECT TOP 200 * 
FROM DHC_INTRANS
WHERE INTR_INCI_DR IN
(
	SELECT INCI_RowId FROM INC_Itm 
	WHERE INCI_Code = 4567897654
);
-- 转移记录

-- @Block
select Regfeetemp1
from SQLUser.DHCRegistrationFee
where RegfeeAdmDr in (
	select PAADM_RowID
	from SQLUser.PA_Adm
	where PAADM_PAPMI_DR = 46
		and PAADM_VisitStatus = "A"
) 
	-- and RegfeeDepDr = RegfeeDepDr
	-- and RegfeeDate + 3 >= RegfeeDate   
	and RegfeeArcPrice > 0;
-- 挂号 发票 价格

-- @Block
select RegfeeTimeRangeDr
from SQLUser.DHCRegistrationFee
where RegfeeAdmDr = AdmId;
-- 挂号 时段

-- @Block
SELECT TR_RowId
FROM DHC_TimeRange
WHERE TR_ValidEndDate IS NULL
	AND TR_Desc = "Desc";
-- 时段

-- @Block
SELECT OEORI_LabEpisodeNo,* 
FROM OE_OrdItem
WHERE OEORI_OEORD_ParRef IN
(
	SELECT OEORD_RowId1 
	FROM OE_Order
	WHERE OEORD_Adm_DR IN
	(
		SELECT PAADM_RowID 
		FROM PA_Adm
		WHERE PAADM_PAPMI_DR = 46
	)
);
-- 就诊 医嘱 检验

-- @Block
SELECT AS_TimeRange_DR ,* 
FROM DHC_RBApptSchedule;
-- 排班 时段

-- @Block
SELECT * 
FROM SqlUser.OEC_Priority;
-- 医嘱类型 自备药长期

-- @Block
select PAADM_DepCode_DR -> ctloc_desc ,count(*) As 总数
From PA_Adm
group by PAADM_DepCode_DR;
select * FROM Ct_loc;
-- 患者 科室 统计

-- @Block
select PAADM_DepCode_DR -> ctloc_desc ,count(*) As 总数
from PA_Adm  
where PAADM_VisitStatus = "A" 
	and PAADM_AdmDate ='2023-11-11' 
	and PAADM_Type  in ('O','E') 
group by PAADM_DepCode_DR;

-- @Block
select *
from SS_Group
where SS_Group.SSGRP_Desc like "%收费%";
-- 安全组

-- @Block
select * 
from RB_Resource 
where res_desc like "%便民号%";

-- @Block
SELECT *
FROM RBC_SessionType;
-- 挂号职称

-- @Block
SELECT *
from ARC_ItmMast
where ARCIM_RowId = "15963||1";
-- 医嘱项

-- @Block
SELECT *
FROM ARC_ItemCat;
-- 医嘱项子类

-- @Block
SELECT arcc.ARCIC_Desc,sum(pbo.PBO_ToTalAmount) As 费用 --,pbo.PBO_ToTalAmount,arc.arcim_desc,*
FROM dhc_patbillorder pbo
join ARC_ItmMast arc
on pbo.PBO_ARCIM_DR = arc.ARCIM_RowId
join ARC_ItemCat arcc on arc.ARCIM_ItemCat_DR = arcc.ARCIC_RowId
where 
		arcc.ARCIC_OrderType = "R"
	and	arcc.ARCIC_Desc != "其他"
group by ARCIC_Desc;
-- 医嘱 费用 子类

-- @Block
SELECT arc.ARCIM_Desc ,* 
FROM OE_OrdItem ord
join ARC_ItmMast arc 
on ord.OEORI_ItmMast_DR = arc.ARCIM_RowId;
-- 医嘱 子类

-- @Block
select OEORI_ItemStat_DR->OSTAT_Desc,OEORI_ResultUpdateUser_DR,* 
from OE_OrdItem 
where OEORI_RowId in ("402||77", "402||78", "402||79");
-- 医嘱 状态 

-- @Block
SELECT *
from OEC_OrderStatus;
-- 医嘱状态

SELECT *
FROM websys.menu
--where ID = 57618;
where caption like "挂号";

select *
from websys.WorkFlowItemDefinition
--where Url like "%&%";
WHERE ID = 50001;

select OEORI_ItemStat_DR->ostat_desc,*
from OE_OrdItem
WHERE OEORI_RowId = "1238||7";

SELECT *
FROM Ens_InterfaceMethod
WHERE method_code like "%UpdateSystemStatus%";
SELECT ES_PreStatusCode, ES_StatusCode,*
FROM SqlUser.Ens_Statuslog
where ES_ExamID like "%EKG1041%";

SELECT *
from Ens_StatusCode;

SELECT *
FROM Ens_Status
WHERE ES_ExamID like "EKG1041%";

SELECT * 
FROM OE_OrdExec
where OEORE_OEORI_ParRef = "1238||7";

select * 
from OEC_OrderCategory;

select * from arc_billgrp;
select * from arc_billsub;

select * from DHC_TarCate;
select * from DHC_TarSubCate;

select CTCF_FrUOM_DR -> CTUOM_Desc, CTCF_Factor, CTCF_ToUOM_DR ->CTUOM_Desc, * 
from ct_confac;

select * from CT_CareProv;

SELECT * from SS_User;

SELECT * from DHC_PAC_BedFeeItem;
SELECT * from PAC_Bed;
SELECT * from PAC_BedAdm ;
SELECT * from DHC_PACBed_FeeType;
SELECT * from ARC_ItmMast;
SELECT * from PAC_BedType;

SELECT description,*
From information_schema.columns
where	
		table_schema = "SQLUser"
	-- and column_name like "%json%"
 	and table_name like "DHC_oedispensing";
-- 打包

SELECT * FROM 
MR_Diagnos;
SELECT *
from MR_DiagType;
SELECT *
from MRC_DiagnosType;
-- 诊断类型 诊断

select * from INSU_AdmInfo;

select inadm_xstring7,* from INSU_AdmInfo;
SELECT * from INSU_DicData;
-- 医保类型 医保字典 
/*
SELECT * from ARC_InsuranceType;
select * from INSU_TarContrast;

select description,* from information_schema.columns
where table_name like "%INSU%"
and description like "%类型%";
*/

-- :;B:Billed;TB:To Bill;I:Ignore;R:Refunded;P:Paid;
select OEORI_ItemStat_DR->ostat_desc,OE_OrdItem->arcim_desc,* from OE_OrdItem 
where OEORI_RowId in ("2||198","2||199","2||200","2||202");
SELECT OEORE_billed,OEORE_Order_Status_DR,* FROM oe_ordexec 
WHERE OEORE_OEORI_ParRef in ("2||198","2||199","2||200","2||202");
SELECT * from ARC_ItmMast;
SELECT * from SQLUser.OEC_OrderStatus;
-- 医嘱状态
select * from SQLUser.OEC_Order_AdminStatus;
-- 执行记录状态


SELECT * FROM DHCDoc_ErrCodeRegister;
-- 医生站错误代码

select PAPMI_ID, PAPMI_DVAnumber from PA_PatMas;
-- 身份证 && 证件号
-- $p($g(^PAPER(papmi,"PAT",3)),"^",6) PAPMI_DVAnumber
-- $p($g(^PAPER(papmi,"ALL")),"^",9) PAPMI_ID

SELECT 	OEORI_SeeDate,OEORI_SeeTime from SQLUser.OE_OrdItemExt;
-- 处理时间

SELECT * from Doc_InterfaceMethod;
-- 医生站接口

select SSUSR_DefaultDept_DR,* from SS_User;
SELECT * from SS_UserOtherLogonLoc;
-- 默认登录科室 登录科室

SELECT 
	res.RES_CTLOC_DR->CTLOC_Desc,
	rbas.AS_Date, AS_Load, 
	AS_NoApptSession,
	AS_SessStartTime,
	AS_SessEndTime,
	AS_TimeRange_DR->TR_Desc,
	ext.AS_SessionType_DR->SESS_Desc,
	AS_TimeCreate
FROM SQLUser.RB_ApptSchedule rbas
JOIN SQLUser.DHC_RBApptSchedule ext 
	ON rbas.AS_Rowid = ext.AS_Rowid
JOIN SQLUser.RB_Resource res 
	ON rbas.AS_RES_ParRef = res.RES_RowId1 
WHERE rbas.AS_Date BETWEEN '2012-10-01' AND '2012-10-31'
AND rbas.AS_RowId NOT IN (
	SELECT APPT_AS_ParRef
	FROM RB_Appointment
)
ORDER BY res.RES_CTLOC_DR;

SELECT * FROM dbo.bt_specimen;
-- 标本类型

SELECT PAADM_AdmReason_DR,* from PA_Adm ;
SELECT * FROM SQLUser.PAC_AdmReason;
-- 收费费别
SELECT PAPER_SocialStatus_DR,* from PA_Person;
select * from SQLUser.CT_SocialStatus
-- 病人类型
SELECT PT_BillType,* FROM SQLUser.DHC_PrescriptType;
-- 处方类型 收费费别

