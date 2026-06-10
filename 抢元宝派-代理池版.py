#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
=============================================================================
元宝派 - 免费 Bot 创建脚本【代理池优化版】
=============================================================================

【优化点】
    1. 内置公共免费代理IP池
    2. 启动时自动检测可用代理
    3. 预创建连接池，减少连接开销
    4. 代理轮询，避免单IP被风控
    5. 支持多账号并发

【青龙定时规则】
    上午场: 58 11 * * *   （11:58 启动，抢 12:00 场）
    下午场: 58 19 * * *   （19:58 启动，抢 20:00 场）

【环境变量】
    变量名: YUANBAO_COOKIE
    变量值: 完整的 Cookie 字符串（多个账号用 & 分隔）
    变量名: CUSTOM_PROXIES （可选）
    变量值: 自定义代理列表，格式 ip:port，多个用逗号分隔

=============================================================================
"""

import os
import re
import time
import asyncio
import aiohttp
import random
from datetime import datetime, timedelta
from typing import List, Dict, Optional, Tuple

# 青龙面板推送
try:
    from notify import send
    SEND_FLAG = True
except Exception:
    SEND_FLAG = False
    def send(title: str, content: str) -> None:
        print(f"[推送] {title}: {content[:200]}")

# ========== 配置 ==========
ADVANCE_SECONDS = 3        # 提前秒数开始高频请求
WARMUP_SECONDS = 60        # 预热阶段提前秒数
MAX_RETRY_SECONDS = 90     # 整点后最多继续抢多少秒
CONCURRENCY = 30           # 单账号并发数
REQUEST_TIMEOUT = 5        # 单次请求超时（秒）
PROXY_CHECK_TIMEOUT = 3    # 代理检测超时（秒）
PROXY_CHECK_URL = "https://httpbin.org/ip"  # 代理检测地址

# 预热阶段间隔（毫秒）
WARMUP_INTERVAL_MS = 500
# 高频阶段间隔（毫秒）
HOT_INTERVAL_MS = 30
# 整点后间隔（毫秒）
COOLDOWN_INTERVAL_MS = 50

# ========== 内置公共免费代理IP ==========
# 来源：公开代理聚合站，仅供学习测试
BUILTIN_PROXIES = [
    # 国内代理（HTTP）
    "http://114.231.42.166:7890",
    "http://112.91.72.128:9000",
    "http://183.247.217.118:3000",
    "http://123.163.97.121:9000",
    "http://223.247.179.226:9000",
    "http://117.68.189.102:9000",
    "http://36.134.92.170:8080",
    "http://110.42.228.148:8080",
    "http://121.5.116.114:1080",
    "http://47.109.67.128:8080",
    # 国外代理（HTTP）
    "http://47.88.31.222:8080",
    "http://47.251.70.179:8080",
    "http://47.251.42.101:8080",
    "http://47.251.47.107:8080",
    "http://47.89.184.18:8080",
    "http://38.54.71.55:8080",
    "http://38.54.2.250:8080",
    "http://154.26.135.113:999",
    "http://156.228.102.118:3128",
    "http://156.228.100.52:3128",
    # HTTPS 代理
    "https://47.88.31.222:8080",
    "https://47.251.70.179:8080",
    "https://47.251.42.101:8080",
]

# ========== 代理管理器 ==========
class ProxyManager:
    """代理池管理器"""
    
    def __init__(self, custom_proxies: List[str] = None):
        self.all_proxies = list(set(BUILTIN_PROXIES + (custom_proxies or [])))
        self.available_proxies: List[str] = []
        self.proxy_stats: Dict[str, Dict] = {}
        self.current_index = 0
        self.lock = asyncio.Lock()
    
    async def check_proxy(self, session: aiohttp.ClientSession, proxy: str) -> Tuple[str, bool, float]:
        """检测单个代理可用性"""
        try:
            start = time.monotonic()
            async with session.get(
                PROXY_CHECK_URL,
                proxy=proxy,
                timeout=aiohttp.ClientTimeout(total=PROXY_CHECK_TIMEOUT),
                ssl=False
            ) as resp:
                if resp.status == 200:
                    latency = (time.monotonic() - start) * 1000
                    return proxy, True, latency
        except Exception:
            pass
        return proxy, False, 9999.0
    
    async def check_all_proxies(self, concurrency: int = 20) -> List[str]:
        """并发检测所有代理"""
        print(f"\n🔍 开始检测 {len(self.all_proxies)} 个代理...")
        
        connector = aiohttp.TCPConnector(limit=concurrency, ssl=False)
        async with aiohttp.ClientSession(connector=connector) as session:
            tasks = [self.check_proxy(session, p) for p in self.all_proxies]
            results = await asyncio.gather(*tasks, return_exceptions=True)
        
        available = []
        for result in results:
            if isinstance(result, Exception):
                continue
            proxy, success, latency = result
            if success and latency < 2000:  # 延迟小于2秒
                available.append((proxy, latency))
                self.proxy_stats[proxy] = {"latency": latency, "success": 0, "fail": 0}
        
        # 按延迟排序
        available.sort(key=lambda x: x[1])
        self.available_proxies = [p[0] for p in available]
        
        print(f"✅ 可用代理: {len(self.available_proxies)}/{len(self.all_proxies)}")
        if self.available_proxies:
            print(f"   最快代理: {self.available_proxies[0]} ({available[0][1]:.0f}ms)")
        
        return self.available_proxies
    
    def get_proxy(self) -> Optional[str]:
        """获取下一个代理（轮询）"""
        if not self.available_proxies:
            return None
        
        async def _get():
            async with self.lock:
                proxy = self.available_proxies[self.current_index % len(self.available_proxies)]
                self.current_index += 1
                return proxy
        
        # 简化：直接返回，不使用异步锁
        proxy = self.available_proxies[self.current_index % len(self.available_proxies)]
        self.current_index += 1
        return proxy
    
    def report_success(self, proxy: str):
        """报告代理成功"""
        if proxy in self.proxy_stats:
            self.proxy_stats[proxy]["success"] += 1
    
    def report_fail(self, proxy: str):
        """报告代理失败"""
        if proxy in self.proxy_stats:
            self.proxy_stats[proxy]["fail"] += 1
    
    def get_stats(self) -> str:
        """获取代理统计"""
        if not self.proxy_stats:
            return "无代理统计"
        
        lines = ["代理使用统计:"]
        for proxy, stats in sorted(self.proxy_stats.items(), key=lambda x: x[1]["success"], reverse=True)[:5]:
            lines.append(f"  {proxy}: 成功{stats['success']} 失败{stats['fail']}")
        return "\n".join(lines)

# ========== Cookie解析 ==========
def get_cookie_value(cookie_str, key):
    match = re.search(rf'{key}=([^;]+)', cookie_str)
    return match.group(1) if match else None

def parse_cookies():
    """解析多个账号的 Cookie"""
    cookie_str = os.environ.get("YUANBAO_COOKIE", "")
    if not cookie_str:
        print("=" * 50)
        print("❌ 错误: 未设置环境变量 YUANBAO_COOKIE")
        print("=" * 50)
        exit(1)
    
    accounts = []
    for cookie in cookie_str.split("&"):
        cookie = cookie.strip()
        if not cookie:
            continue
        
        hy_token = get_cookie_value(cookie, "hy_token")
        hy_user = get_cookie_value(cookie, "hy_user")
        
        if not hy_token or not hy_user:
            print(f"⚠️ 警告: Cookie 中未找到 hy_token 或 hy_user: {cookie[:30]}...")
            continue
        
        accounts.append({
            "cookie": cookie,
            "hy_token": hy_token,
            "hy_user": hy_user,
        })
    
    if not accounts:
        print("=" * 50)
        print("❌ 错误: 没有有效的账号")
        print("=" * 50)
        exit(1)
    
    return accounts

def parse_custom_proxies():
    """解析自定义代理"""
    proxy_str = os.environ.get("CUSTOM_PROXIES", "")
    if not proxy_str:
        return []
    
    proxies = []
    for p in proxy_str.split(","):
        p = p.strip()
        if p:
            if not p.startswith("http"):
                p = f"http://{p}"
            proxies.append(p)
    return proxies

# ========== 时间工具 ==========
def get_target_time():
    """获取目标场次时间"""
    now = datetime.now()
    if now.hour < 12 or (now.hour == 11 and now.minute >= 55):
        return now.replace(hour=12, minute=0, second=0, microsecond=0), "12:00"
    elif now.hour < 20 or (now.hour == 19 and now.minute >= 55):
        return now.replace(hour=20, minute=0, second=0, microsecond=0), "20:00"
    else:
        return None, None

def precise_sleep(seconds):
    """精确睡眠"""
    if seconds <= 0:
        return
    end = time.monotonic() + seconds
    while time.monotonic() < end:
        remaining = end - time.monotonic()
        if remaining > 0.01:
            time.sleep(remaining * 0.8)

# ========== 核心抢购逻辑 ==========
async def grab_single(
    session: aiohttp.ClientSession,
    account: Dict,
    proxy_manager: ProxyManager,
    target_time: datetime,
    result_holder: Dict
):
    """单个协程的抢购逻辑"""
    url = "https://yuanbao.tencent.com/api/v5/robotLogic/create"
    headers = {
        "Host": "yuanbao.tencent.com",
        "Origin": "https://yuanbao.tencent.com",
        "Referer": "https://yuanbao.tencent.com/e/claw/manage",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36",
        "Content-Type": "application/json",
        "Accept": "application/json, text/plain, */*",
        "Cookie": account["cookie"],
    }
    payload = {"type": 1, "create_type": 1}
    
    request_count = 0
    end_time = target_time + timedelta(seconds=MAX_RETRY_SECONDS)
    
    while not result_holder["success"] and datetime.now() < end_time:
        proxy = proxy_manager.get_proxy()
        
        try:
            request_count += 1
            start = time.monotonic()
            
            async with session.post(
                url,
                json=payload,
                headers=headers,
                proxy=proxy,
                timeout=aiohttp.ClientTimeout(total=REQUEST_TIMEOUT),
                ssl=False
            ) as resp:
                cost = int((time.monotonic() - start) * 1000)
                
                if resp.status == 200:
                    data = await resp.json()
                    code = data.get("code", -1)
                    msg = data.get("msg", "")
                    
                    if code == 0:
                        result_holder["success"] = True
                        result_holder["account"] = account["hy_user"][:20]
                        result_holder["cost"] = cost
                        result_holder["count"] = request_count
                        result_holder["proxy"] = proxy
                        proxy_manager.report_success(proxy)
                        
                        print(f"\n{'='*60}")
                        print(f"✅ 抢 Bot 成功！")
                        print(f"   账号: {account['hy_user'][:20]}...")
                        print(f"   代理: {proxy}")
                        print(f"   耗时: {cost}ms")
                        print(f"   请求次数: {request_count}")
                        print(f"{'='*60}")
                        return True
                    else:
                        now = datetime.now()
                        remaining = (target_time - now).total_seconds()
                        if remaining > 0:
                            print(f"[{now.strftime('%H:%M:%S')}] 预热中... {remaining:.1f}s | 代理:{proxy[-15:]}", end="\r")
                        else:
                            print(f"[{now.strftime('%H:%M:%S')}] #{request_count} code={code} {cost}ms proxy={proxy[-15:]}", end="\r")
                        
                        proxy_manager.report_success(proxy)
                else:
                    proxy_manager.report_fail(proxy)
                    print(f"[{datetime.now().strftime('%H:%M:%S')}] #{request_count} HTTP{resp.status} proxy={proxy[-15:]}", end="\r")
                    
        except asyncio.TimeoutError:
            proxy_manager.report_fail(proxy)
            print(f"[{datetime.now().strftime('%H:%M:%S')}] #{request_count} 超时 proxy={proxy[-15:]}", end="\r")
        except Exception as e:
            proxy_manager.report_fail(proxy)
            print(f"[{datetime.now().strftime('%H:%M:%S')}] #{request_count} {str(e)[:15]} proxy={proxy[-15:]}", end="\r")
        
        # 动态间隔
        now = datetime.now()
        remaining = (target_time - now).total_seconds()
        
        if remaining > WARMUP_SECONDS:
            await asyncio.sleep(WARMUP_INTERVAL_MS / 1000)
        elif remaining > ADVANCE_SECONDS:
            await asyncio.sleep(WARMUP_INTERVAL_MS / 1000)
        elif remaining > 0:
            await asyncio.sleep(HOT_INTERVAL_MS / 1000)
        else:
            await asyncio.sleep(COOLDOWN_INTERVAL_MS / 1000)
    
    return False

async def grab_batch(accounts, proxy_manager, target_time, target_desc):
    """批量并发抢购"""
    result_holder = {
        "success": False,
        "account": None,
        "cost": 0,
        "count": 0,
        "proxy": None,
    }
    
    total_concurrency = CONCURRENCY * len(accounts)
    has_proxies = len(proxy_manager.available_proxies) > 0
    
    print(f"\n🚀 高性能抢购启动！")
    print(f"   目标场次: {target_desc}")
    print(f"   账号数量: {len(accounts)}")
    print(f"   并发协程: {total_concurrency}")
    print(f"   可用代理: {len(proxy_manager.available_proxies)}")
    print(f"   目标时间: {target_time.strftime('%H:%M:%S.%f')[:-3]}")
    print(f"   提前量: {ADVANCE_SECONDS}s")
    print("-" * 60)
    
    # 预创建连接池
    connector = aiohttp.TCPConnector(
        limit=total_concurrency,
        limit_per_host=total_concurrency,
        ttl_dns_cache=300,
        enable_cleanup_closed=True,
        force_close=False,
    )
    
    async with aiohttp.ClientSession(connector=connector) as session:
        tasks = []
        for account in accounts:
            for _ in range(CONCURRENCY):
                task = asyncio.create_task(
                    grab_single(session, account, proxy_manager, target_time, result_holder)
                )
                tasks.append(task)
        
        # 等待成功或超时
        timeout = MAX_RETRY_SECONDS + max(0, (target_time - datetime.now()).total_seconds()) + 5
        done, pending = await asyncio.wait(
            tasks,
            timeout=timeout,
            return_when=asyncio.FIRST_COMPLETED,
        )
        
        # 取消剩余任务
        for task in pending:
            task.cancel()
        
        await asyncio.gather(*pending, return_exceptions=True)
    
    return result_holder

# ========== 主函数 ==========
async def main():
    print("\n" + "=" * 60)
    print("元宝派 Bot 抢购脚本【代理池优化版】")
    print("=" * 60 + "\n")
    
    # 解析配置
    accounts = parse_cookies()
    custom_proxies = parse_custom_proxies()
    
    # 初始化代理管理器
    proxy_manager = ProxyManager(custom_proxies)
    
    print(f"✅ 加载 {len(accounts)} 个账号:")
    for i, acc in enumerate(accounts, 1):
        print(f"   {i}. {acc['hy_user'][:20]}...")
    
    # 检测代理
    if proxy_manager.all_proxies:
        await proxy_manager.check_all_proxies(concurrency=20)
    else:
        print("\n⚠️ 无代理可用，将直连抢购")
    
    print()
    
    # 获取目标时间
    target_time, target_desc = get_target_time()
    if not target_time:
        print("⚠️ 当前时间不在抢购时段")
        return
    
    # 等待到预热时间
    warmup_time = target_time - timedelta(seconds=WARMUP_SECONDS)
    now = datetime.now()
    
    if now < warmup_time:
        wait_seconds = (warmup_time - now).total_seconds()
        print(f"⏰ 等待 {wait_seconds:.0f} 秒后进入预热阶段...")
        precise_sleep(wait_seconds)
    
    # 开始抢购
    result = await grab_batch(accounts, proxy_manager, target_time, target_desc)
    
    # 输出代理统计
    print(f"\n{proxy_manager.get_stats()}")
    
    # 推送结果
    if result["success"]:
        title = "元宝派 Bot 抢购成功【代理池版】"
        content = (
            f"✅ 抢购成功！\n"
            f"场次: {target_desc}\n"
            f"账号: {result['account']}...\n"
            f"代理: {result['proxy']}\n"
            f"耗时: {result['cost']}ms\n"
            f"并发数: {CONCURRENCY * len(accounts)}"
        )
    else:
        title = "元宝派 Bot 抢购失败【代理池版】"
        content = (
            f"❌ 未抢到名额\n"
            f"场次: {target_desc}\n"
            f"账号数: {len(accounts)}\n"
            f"代理数: {len(proxy_manager.available_proxies)}"
        )
    
    if SEND_FLAG:
        try:
            send(title, content)
            print("\n✅ 推送已发送")
        except Exception as e:
            print(f"\n❌ 推送失败: {e}")
    else:
        print(f"\n{'='*60}")
        print(f"【{title}】")
        print(content)
        print("=" * 60)

if __name__ == "__main__":
    asyncio.run(main())
