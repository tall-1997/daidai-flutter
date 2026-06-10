#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
=============================================================================
元宝派 - 免费 Bot 创建脚本【高性能优化版】
=============================================================================

【优化点】
    1. 使用连接池复用 TCP 连接，减少握手开销
    2. 使用异步并发（asyncio + aiohttp），更高效率
    3. 精确时间控制，毫秒级提前量
    4. 动态请求间隔，越接近目标时间越密集
    5. 增加请求超时时间控制
    6. 支持多账号并发

【青龙定时规则】
    上午场: 58 11 * * *   （11:58 启动，抢 12:00 场）
    下午场: 58 19 * * *   （19:58 启动，抢 20:00 场）

【环境变量】
    变量名: YUANBAO_COOKIE
    变量值: 完整的 Cookie 字符串（多个账号用 & 分隔）

=============================================================================
"""

import os
import re
import time
import asyncio
import aiohttp
from datetime import datetime, timedelta

# 青龙面板推送
try:
    from notify import send
    SEND_FLAG = True
except Exception:
    SEND_FLAG = False
    def send(title: str, content: str) -> None:
        print(f"[推送] {title}: {content[:200]}")

# ========== 优化配置 ==========
ADVANCE_SECONDS = 3        # 提前秒数开始高频请求（越小越精准）
WARMUP_SECONDS = 60        # 预热阶段提前秒数（低频请求）
MAX_RETRY_SECONDS = 90     # 整点后最多继续抢多少秒
CONCURRENCY = 50           # 并发数（协程数）
REQUEST_TIMEOUT = 3        # 单次请求超时（秒）

# 预热阶段间隔（毫秒）
WARMUP_INTERVAL_MS = 500
# 高频阶段间隔（毫秒）
HOT_INTERVAL_MS = 20
# 整点后间隔（毫秒）
COOLDOWN_INTERVAL_MS = 50

# ========== 从环境变量获取 Cookie ==========
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
    
    # 支持多账号，用 & 分隔
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
    """精确睡眠，使用 busy wait"""
    if seconds <= 0:
        return
    end = time.monotonic() + seconds
    while time.monotonic() < end:
        remaining = end - time.monotonic()
        if remaining > 0.01:
            time.sleep(remaining * 0.8)
        # 最后阶段 busy wait

# ========== 核心抢购逻辑 ==========
async def grab_single(session, account, target_time, result_holder):
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
        try:
            request_count += 1
            start = time.monotonic()
            
            async with session.post(
                url, 
                json=payload, 
                headers=headers,
                timeout=aiohttp.ClientTimeout(total=REQUEST_TIMEOUT)
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
                        print(f"\n{'='*50}")
                        print(f"✅ 抢 Bot 成功！")
                        print(f"   账号: {account['hy_user'][:20]}...")
                        print(f"   耗时: {cost}ms")
                        print(f"   请求次数: {request_count}")
                        print(f"{'='*50}")
                        return True
                    else:
                        now = datetime.now()
                        remaining = (target_time - now).total_seconds()
                        if remaining > 0:
                            print(f"[{now.strftime('%H:%M:%S.%f')[:-3]}] 预热中... {remaining:.1f}s后开始", end="\r")
                        else:
                            print(f"[{now.strftime('%H:%M:%S.%f')[:-3]}] 第{request_count}次 | code={code} | {cost}ms", end="\r")
                else:
                    print(f"[{datetime.now().strftime('%H:%M:%S.%f')[:-3]}] 第{request_count}次 | HTTP{resp.status}", end="\r")
                    
        except asyncio.TimeoutError:
            print(f"[{datetime.now().strftime('%H:%M:%S.%f')[:-3]}] 第{request_count}次 | 超时", end="\r")
        except Exception as e:
            print(f"[{datetime.now().strftime('%H:%M:%S.%f')[:-3]}] 第{request_count}次 | {str(e)[:15]}", end="\r")
        
        # 动态间隔：越接近目标时间越密集
        now = datetime.now()
        remaining = (target_time - now).total_seconds()
        
        if remaining > WARMUP_SECONDS:
            # 远未到时间，低频
            await asyncio.sleep(WARMUP_INTERVAL_MS / 1000)
        elif remaining > ADVANCE_SECONDS:
            # 预热阶段
            await asyncio.sleep(WARMUP_INTERVAL_MS / 1000)
        elif remaining > 0:
            # 高频阶段（目标时间前）
            await asyncio.sleep(HOT_INTERVAL_MS / 1000)
        else:
            # 整点后
            await asyncio.sleep(COOLDOWN_INTERVAL_MS / 1000)
    
    return False

async def grab_batch(accounts, target_time, target_desc):
    """批量并发抢购"""
    result_holder = {
        "success": False,
        "account": None,
        "cost": 0,
        "count": 0,
    }
    
    # 计算总并发数
    total_concurrency = CONCURRENCY * len(accounts)
    
    print(f"\n🚀 高性能抢购启动！")
    print(f"   目标场次: {target_desc}")
    print(f"   账号数量: {len(accounts)}")
    print(f"   并发协程: {total_concurrency}")
    print(f"   目标时间: {target_time.strftime('%H:%M:%S.%f')[:-3]}")
    print(f"   提前量: {ADVANCE_SECONDS}s")
    print("-" * 60)
    
    # 创建连接器（连接池）
    connector = aiohttp.TCPConnector(
        limit=total_concurrency,
        limit_per_host=total_concurrency,
        ttl_dns_cache=300,
        enable_cleanup_closed=True,
    )
    
    async with aiohttp.ClientSession(connector=connector) as session:
        tasks = []
        for account in accounts:
            for _ in range(CONCURRENCY):
                task = asyncio.create_task(
                    grab_single(session, account, target_time, result_holder)
                )
                tasks.append(task)
        
        # 等待成功或超时
        done, pending = await asyncio.wait(
            tasks,
            timeout=MAX_RETRY_SECONDS + (target_time - datetime.now()).total_seconds() + 5,
            return_when=asyncio.FIRST_COMPLETED,
        )
        
        # 取消剩余任务
        for task in pending:
            task.cancel()
        
        # 等待所有任务完成/取消
        await asyncio.gather(*pending, return_exceptions=True)
    
    return result_holder

# ========== 主函数 ==========
async def main():
    print("\n" + "=" * 60)
    print("元宝派 Bot 抢购脚本【高性能优化版】")
    print("=" * 60 + "\n")
    
    accounts = parse_cookies()
    
    print(f"✅ 加载 {len(accounts)} 个账号:")
    for i, acc in enumerate(accounts, 1):
        print(f"   {i}. {acc['hy_user'][:20]}...")
    print()
    
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
    result = await grab_batch(accounts, target_time, target_desc)
    
    # 推送结果
    if result["success"]:
        title = "元宝派 Bot 抢购成功【优化版】"
        content = (
            f"✅ 抢购成功！\n"
            f"场次: {target_desc}\n"
            f"账号: {result['account']}...\n"
            f"耗时: {result['cost']}ms\n"
            f"并发数: {CONCURRENCY * len(accounts)}"
        )
    else:
        title = "元宝派 Bot 抢购失败【优化版】"
        content = f"❌ 未抢到名额\n场次: {target_desc}\n账号数: {len(accounts)}"
    
    if SEND_FLAG:
        try:
            send(title, content)
            print("\n✅ 推送已发送")
        except Exception as e:
            print(f"\n❌ 推送失败: {e}")
    else:
        print(f"\n{'='*50}")
        print(f"【{title}】")
        print(content)
        print("=" * 50)

if __name__ == "__main__":
    asyncio.run(main())
