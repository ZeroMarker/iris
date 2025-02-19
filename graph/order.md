# Example

```mermaid
flowchart TD
    A[Order] -->|Create| B[Order Created]
    B -->|Update| C[Order Updated]
    C -->|Cancel| D[Order Cancelled]
    D -->|Complete| E[Order Completed]
```

## 泳道图示例

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#f9f9f9', 'primaryTextColor': '#333333', 'primaryBorderColor': '#cccccc'}}}%%
---
title: 泳道图示例
---

%% 定义泳道图
stateDiagram-v2
    [*] --> 开始
    state 开始 {
        [*] --> 执行
        执行 --> 结束
    }
    
    state "部门 A" as 部门A {
        [*] --> A任务1
        A任务1 --> A任务2
        A任务2 --> [*]
    }

    state "部门 B" as 部门B {
        [*] --> B任务1
        B任务1 --> B任务2
        B任务2 --> [*]
    }

    执行 --> 部门A
    部门A --> 部门B
    部门B --> 结束
```

## 甬道图示例

```mermaid
journey
    title 甬道图示例
    section 第一步
      用户输入信息: 5: 用户
      系统验证信息: 4: 系统
      用户等待结果: 3: 用户
    section 第二步
      系统处理请求: 4: 系统
      用户查看结果: 5: 用户
      用户反馈: 3: 用户
```

[process](https://drive.google.com/file/d/17-beBrLy1BqOIg2_pLHbhBZh34ZMsViU/view?usp=sharing)

## sub

```mermaid
flowchart TB
    subgraph 前端
        direction LR
        %%Front
        CI[QueCheckinclick]
        QA
    end
    subgraph 后端
        direction RL
        %%Back
        PA[PatArrive]
        PAG
    end
    
    %%Front[Alloc.NurseTriage.hui.js] --> CI
    %%Back[web.DHCAlloc] --> PA
    %%CI ----> QA
    %%CI -- 报到  --> PA
    %%QA -- 复诊 --> PAG
```

```mermaid
flowchart TB
    c1-->a2
    
    subgraph one
    a1-->a2
    end
    subgraph two
    b1-->b2
    end
    subgraph three
    c1-->c2
    end
```
