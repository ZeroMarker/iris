return Promise.race([
    new Promise(function(resolve,rejected){
        // 检查检验互认审核
        if ((HRConfigObj.HROpenFlag=="1")){
            HRSignObj.CheckOrdHR(GlobalObj.EpisodeID,UpdateObj.OrderItemStr,resolve);
        }else{
            resolve(true);
        }
    }),
    timeout(3000) // 设置超时时间为3000毫秒
]);