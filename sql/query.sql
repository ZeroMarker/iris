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


-- @Block
INSERT INTO SQLUser.Student 
VALUES ('1', '2023-01-01', '张', '1');

-- @Block
SELECT TARAC_TARTAC_DR->TARTAC_Desc,* 
FROM SQLUser.DHC_TarAcctCate;
-- 账单费用类别



-- @Block
SELECT AA_Arcim_DR -> ARCIM_Desc AS apply_count, count(*) 
FROM SQLUser.DHC_Doc_AntibioticApply 
group by AA_Arcim_DR;
-- 特抗药申请


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
-- 医嘱明细

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
SELECT TOP 20 * 
FROM DHC_InvPrt
WHERE PRT_inv = "0001000202";
-- 发票打印



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
SELECT AS_TimeRange_DR ,* 
FROM DHC_RBApptSchedule;
-- 排班 时段

-- @Block
SELECT * 
FROM SqlUser.OEC_Priority;
-- 医嘱类型 自备药长期

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
-- where ID = 57618;
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
WHERE method_code like "%UpdateSystemStatus%"
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
SELECT * FROM MR_Adm;
SELECT * FROM MRC_ICDDx 
-- 诊断类型 诊断 ICD

select * from INSU_AdmInfo;

select inadm_xstring7,* from INSU_AdmInfo;
SELECT * from INSU_DicData;
-- ^DHCINDID
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

select * from SQLUser.PHC_Instruc 
-- 用法

SELECT  * from 	INSU_DicData where INDID_DicCode like "%Auto%"
-- 医保字典

SELECT * FROM DocCFTreatStatusInfo
-- 菜单按钮

SELECT * from DHC_AppPart
-- 部位
SELECT * from DHC_AppTreeLink
-- 检查树部位

SELECT ARCIC_OrderType,* from arc_itemCat WHERE  ARCIC_Desc like "%会诊%"
-- r l m n p x
-- 药品 检验 材料 其他 自定义 检查

select * from RBC_SessionType
SELECT * from DHC_RBCSessionTypeService
-- 出诊级别

SELECT * from PHC_Poison 
PHC_DrgMast->PHCD_PHCPO_DR
-- 管制药品

SELECT * from DHC_RegConDisCount
-- 挂号优惠

SELECT * from DHCQueue
SELECT * from DHCPerState
-- 队列

select * FROM DHC_DocOrderListSet
-- 诊断录入表格列

select * from SQLUser.DHC_DocDiagnosCertificate;

select * from DHC_RegConDisCount;

SELECT * from RBC_SessionType;

-- 诊室
SELECT * from DHCExaBorough;

SELECT  * from SQLUser.CT_LOC WHERE CTLOC_desc like "%诊室%";

SELECT * from DHCBorExaRoom;

SELECT * from DHCRoomComp;

select * from DHCExaBorDep;

SELECT * from DHC_VIS_VoiceServer 
-- 服务器
SELECT * from 	DHC_VIS_ClientInfo
-- 客户端
SELECT * from DHC_VIS_VoiceClient 
SELECT OEORI_Action_DR,* from OE_OrdItem 
SELECT * FROM OEC_Action 
-- 皮试备注

select * from dhc_taritem
-- 收费项
select * from dhc_orderlinktar
-- 收费项医嘱项对照

update PA_PatMas set PAPMI_IPNo = '0'||PAPMI_IPNo, PAPMI_OPNo = '0'||PAPMI_OPNo

SELECT * from dbo.BT_TestSetSpecimen 

SELECT * from dbo.BT_TestSet

SELECT * from dbo.BT_Container

select * from dbo.BT_Specimen 

SELECT * from DHCOPAdmRegPayLoc;
-- 支付日志

SELECT NOW();
-- https://docs.intersystems.com/iris20241/csp/docbook/DocBook.UI.Page.cls?KEY=RSQL_FUNCTIONS

select DARCIM_CanCrossDay ,* from DHC_ItmMast ;
-- 医嘱项扩展设定

UPDATE DHC_ItmMast
SET DARCIM_CanCrossDay = NULL
WHERE DARCIM_CanCrossDay = 'N';

select * from DHC_CardHardComManager ;

select * from DHC_CardHardComGroup ;
-- 设备
SELECT * FROM 	OEC_Priority

SELECT * FROM MR_DiagType


select * from CT_LockSchedule
-- 锁号

-- 检查检验树
-- User.DHCAppTreeAdd
-- User.DHCAppTreeLink
-- User.DHCAppPart

SELECT other.AP_Desc, self.Ap_Desc 
FROM DHC_AppPart self
JOIN DHC_AppPart other ON self.ap_lastrowid = other.AP_RowId
order by other.AP_RowId;
-- 检查部位

select * from insuqc_po_ch.PersonDiag;
select * from insuqc_po_ch.DiagDic;
-- 慢病病种

select * from DHCDoc_OrderVirtualtLong;
-- 虚拟长期

select RegfeeAdmDr ,* from DHCRegistrationFee ;
select * from RB_ResEffDate ;
select SESS_Room_DR ,* from RB_ResEffDateSession ;
select AS_RBEffDateSession_DR ,* from RB_ApptSchedule ;
select SESS_Room_DR ,* from RB_ResEffDateSession;
-- 排班模板 坐诊信息

select * from PHC_Freq ;
select * from PHC_DispensingTime;
-- 频次 分发时间

select transfer_Input ,* from Ens_InterfaceV8 order by 1 desc;
-- 平台日志

SELECT MRDIA_DocCode_DR->CTPCP_desc, MRDIA_ICDCode_DR ->MRCID_Desc, COUNT(*) as diagnosis_count
FROM MR_Diagnos
GROUP BY MRDIA_DocCode_DR, MRDIA_ICDCode_DR
ORDER BY MRDIA_DocCode_DR, diagnosis_count DESC;

select * from DHC_AppRepPart ;
select * from DHC_AppRepPos ;
-- 部位
-- 体位
select * from DHC_AppPosition ;
select * from DHC_AppPart ;
select * from DHC_AppRepTarItm;


select * from  CT_BDP_CT.DischargeMethod;

select * from DHC_RBCSessionTypeService;

select * from DHC_RBSessContrast ;
-- 医护人员类型 职称 对照

select * from DHC_DischargeHistory where DHCDis_PAAdmExt_ParRef = 1384;

select * from dhc_appPisMaster

select * from DHC_AppArcLink ;

select * from DHC_AppRepArc ;

select * from OE_OrdItem ;

select * from PHC_DrgForm;
select PHCD_PHCPO_DR,* from PHC_DrgMast WHERE PHCD_PHCPO_DR is not null;
select * from PHC_Poison;

select * from RBC_SessionType;

select * from PHC_Freq ;

select * from PHC_FormDoseEquiv WHERE PHC_FormDoseEquiv.EQ_ParRef = "608||1";


SELECT rea_admsource,* FROM pac_admreason;
-- >0 医保

SELECT SSUSR_Mobile, SSUSR_FreeText1, * FROM SS_User WHERE SSUSR_Name = "张慧敏";
-- 手机号 身份证号


select dhcaction_code,DHCAction_Desc,* from websys.DHCMessageActionType where DHCAction_Desc like "%抗菌%";

