# B01.006.01

## 网络架构

HA High Available
内网 -> 负载均衡 -> web + ECP -> HISDB, HISMirror, 快照和CDP验证

Browser -> Apache / IIS -> CSP Gateway -> Cache
Client -> Web Server -> Cache

CSP Gateway -> Web / Web + ECP
    企业缓存协议，访问远程数据库的global，routine

Mirror服务器，copy journal

- HA高可用方案
- DR灾备方案
- Replication数据复制

RTO(Recovery Time Objective)：灾难发生后,信息系统或业务功能从停顿到必须恢复的时间要求。

RPO(Recovery Point Objective)：灾难发生后,系统和数据必须恢复到的时间点要求。

- FailOver Primary -> Backup
- DisasterRecovery Primary -> Async DR

## database namespace mapping

数据代码都存在database

database物理容器
namespace逻辑引用

## mapping

global mapping
routine mapping
package mapping

## 存储

多维数组 树状
节点对应磁盘块

## 系统数据库

CACHESYS
CACHELIB
CACHEAUDIT
CACHETEMP
CACHE
DOCBOOK
SAMPLES
USER

## WIJ JRN

Write Image Journal

Journal

WIJ
数据块级别
JRN
应用事务级别

## open transaction

## process

CONTROL
WRTDMN  Write Daemon
GARCOL
EXPDMN
JRNDMN
CLNDMN
MONITOR

## locks

共享锁  r-
排他锁  rw

## ECP协议

客户端  ECP服务器
服务端  DB服务器
