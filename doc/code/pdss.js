/**
 * 审查函数
 */
function TakCheck() {

    /**
     * 初始化创建 PDSS 对象
     */
    var pdss = new PDSS({});

    /**
     * 初始化审核对象
     */
    var PdssObj = {
        "Action": "", // 应用场景（CheckRule：用药审查,EduRule 用药指导,Cdss:cdss 应用）
        "UseType": "", // 调用场景类型(Doc:医生站, Pha:药房, Nur:护士站)
        "CheckFlag": "", // 每次调用是否重新审查 (Y/N)
        "MsgID": "", // 监测日志 id（回写数据用）
        "PatName": "张三", // 姓名
        "SexProp": "男", // 性别
        "AgeProp": "1993-02-10", // 出生日期
        "Height": "170", // 身高(厘米值)
        "Weight": "51", // 体重(kg)
        "BillType": "医保", // 费别 (医保,自费)
        "BloodPress": "", // 血压
        "SpecGrps": ["肾功能不全", "孕妇"], //特殊人群
        "ProfessProp": "运动员", // 职业
        "PatType": "门诊", // 患者类别(门诊,住院,急诊)
        "PatLoc": "消化内科", // 就诊科室
        "MainDoc": "石亚飞", // 主管医生
        "Hospital": "东华标准版数字化医院[总院]", // 医院(登录信息)
        "Profess": "主管药师", // 职称(登录用户)
        "Group": "安全用药智能决策", // 安全组
        "LgCtLoc": "呼吸内科门诊", // 登录科室 2020/12/1
        "LgUser": "萧亚轩", // 登录用户 2020/12/1
        "EpisodeID": "001", // 就诊 ID
        "ItemAyg": [ // 过敏记录
            {
                "id": "itemAyg", // 标识
                "item": "青霉素" // 过敏项目
            }
        ],
        "ItemDis": [ // 疾病
            {
                "id": "itemDis", // 标识
                "item": "肺炎" // 疾病
            },
            {
                "id": "itemDis",
                "item": "中耳炎"
            }
        ],
        "ItemLab": [ // 检验
            {
                "id": "itemLab", // 标识
                "item": "白细胞" // 检验项目
            }
        ],
        "ItemLabDetail": [ // 检验项目明细
            {
                "Val": "10", // 检验结果值
                "Unit": "mg", // 检验结果值单位
                "id": "labDetail", // 标识
                "item": "白细胞" // 检验项目
            }
        ],
        "ItemOper": [ // 手术
            {
                "id": "itemOper", // 标识
                "item": "颅部切合术" // 手术名称
            }
        ],
        "ItemOrder": [ // 药品
            {
                "ArciMastId": "1||1", // 医嘱项 id
                "SeqNo": "1", // 医嘱序号
                "PhCode": "xy0000001", // 药品编码(医嘱项编码)
                "PhDesc": "阿司匹林肠溶片", // 药品名称 (医嘱项名称)
                "FormProp": "片剂", // 剂型
                "OnceDose": "200", // 单次剂量
                "Unit": "mg", // 单次剂量单位
                "DrugPreMet": "口服", // 用法
                "DrugFreq": "tid", // 频次
                "Treatment": "1 天", // 疗程
                "id": "itemOrder", // 标识
                "LinkSeqNo": "1", // 关联序号(1, 1.1, 1.2)
                "OrdDate": "2020-03-06", // 医嘱日期
                "IsFirstUseProp": "首次", // 是否首次(首次/非首次)
                "DurgSpeedProp": "", // 给药速度
                "DrugSpeedPropUnit": "", // 给药速度单位
                "OrdEndDate": "", // 医嘱结束日期
                "OrderPackQty": "1", // 数量
                "OrderPackQtyUnit": "瓶" // 数量单位
            },
            {
                "ArciMastId": "2||1", // 医嘱项 id
                "SeqNo": "2", // 医嘱序号
                "PhCode": "xy0000002", // 药品编码(医嘱项编码)
                "PhDesc": "盐酸丙美卡因滴眼液", // 药品名称(医嘱项名称)
                "FormProp": "滴眼剂", // 剂型
                "OnceDose": "2", // 单次剂量
                "Unit": "滴", // 单次剂量单位
                "DrugPreMet": "滴眼", // 用法
                "DrugFreq": "每日 4 次", // 频次
                "Treatment": "2 天", // 疗程
                "LinkSeqNo": "2.2", // 关联序号(1, 1.1, 1.2)
                "id": "itemOrder", // 标识
                "OrdDate": "2020-03-06", // 医嘱日期
                "IsFirstUseProp": "首次", // 是否首次(首次/非首次)
                "DurgSpeedProp": "1", // 给药速度
                "DrugSpeedPropUnit": "滴/分", // 给药速度单位
                "OrdEndDate": "", // 医嘱结束日期
                "OrderPackQty": "1", // 数量
                "OrderPackQtyUnit": "瓶" // 数量单位
            }
        ],
        "ItemHisOrder": [ // 历史医嘱
            {
                "ArciMastId": "2||1", // 医嘱项 id
                "SeqNo": "1", // 医嘱序号
                "PhCode": "xy0000003", // 药品编码(医嘱项编码)
                "PhDesc": "阿司匹林肠溶片", // 药品名称(医嘱项名称)
                "FormProp": "片剂", // 剂型
                "OnceDose": "200", // 单次剂量
                "Unit": "mg", // 单次剂量单位
                "DrugPreMet": "口服", // 用法
                "DrugFreq": "tid", // 频次
                "Treatment": "1 天", // 疗程
                "id": "itemOrder", // 标识
                "LinkSeqNo": "1", // 关联序号(1, 1.1, 1.2)
                "OrdDate": "2020-03-06", // 医嘱日期
                "IsFirstUseProp": "首次", // 是否首次(首次/非首次)
                "DurgSpeedProp": "", // 给药速度
                "DrugSpeedPropUnit": "", // 给药速度单位
                "OrdEndDate": "", // 医嘱结束日期
                "OrderPackQty": "1", // 数量
                "OrderPackQtyUnit": "瓶" // 数量单位
            }
        ]
    }

    /**
     * 调用审查接口
     * 参数说明：
     * 第一个参数：审核对象
     * 第二个参数：回调函数，回调函数为空时，传 null 即可
     * 第三个参数：审查方式，0 审核不通过时，显示问题灯； 1 - 审查不通过时，显示问题明细窗口，其他值不显示问题
     */
    pdss.refresh(PdssObj, pdssCallBack, 1); /// 调用审查接口

}

/**
 * 审查回调函数
 * 参数说明：
 * option:对象说明（2020-09-27）
 * option.controlFlag // 是否强制审核 Y 强制审核 N 不强制审核
 * option.manLevel // 管理级别 审核结果警示级别，提示、提醒、警示、禁止
 * option.manLev // 管理级别代码 审核结果警示级别:提示(normal)、提醒(tips)、警示(warn)、禁止(forbid)
 * option.passFlag // 通过标志 0 - 不通过、1 - 通过
 * option.MsgID = ”” ; /// 安全用药调用标识
 * option.drugUniqueStr = ""; // 药品唯一标识串 unique(药品唯一标识-安全用药生成)_"^"_arciId(医嘱项 id)_"^"_seqNo(医嘱序号)_"^"_drugPassFlag(药品通过标志 Y/N)多条标识串由!!分割
 * option.close() // 关闭插件弹窗方法
 */
function pdssCallBack(option) {
    /// do something 业务代码
}
