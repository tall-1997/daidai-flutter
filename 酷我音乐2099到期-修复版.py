"""
酷我音乐 2099 到期 - 修复优化版
使用说明:
1. 环境变量使用 `kwyy`。
2. 单账号格式: 手机号#密码
3. 备注格式: 备注#手机号#密码
4. 多账号用 `&` 分隔:
   kwyy="备注#1手机号1#密码1&备注2#手机号2#密码2"
"""

import os
import base64
import random
import string
import uuid
import time
import re
import json
import hashlib
import requests
import urllib3
from datetime import datetime
from urllib.parse import quote
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad, unpad

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# ========== 通知函数 ==========
try:
    from notify import send
    SEND_FLAG = True
except ImportError:
    SEND_FLAG = False
    def send(title: str, content: str) -> None:
        print(f"[通知] {title}: {content}")

# ========== API URLs ==========
SIGN_BASE = 'https://integralapi.kuwo.cn/api/v1/online/sign'
URLS = {
    'new_user_sign_list': SIGN_BASE + '/v1/earningSignIn/newUserSignList',
    'user_asset': SIGN_BASE + '/v1/earningSignIn/earningUserSignList',
    'new_do_listen': SIGN_BASE + '/v1/earningSignIn/newDoListen',
    'everyday_do_listen': SIGN_BASE + '/v1/earningSignIn/everydaymusic/doListen',
    'box_renew': SIGN_BASE + '/new/boxRenew',
    'new_box_list': SIGN_BASE + '/new/newBoxList',
    'new_box_finish': SIGN_BASE + '/new/newBoxFinish',
    'freemium_switch': 'https://wapi.kuwo.cn/openapi/v1/user/freemium/h5/switches',
    'lottery': 'https://integralapi.kuwo.cn/api/v1/online/sign/loterry/getLucky',
    'login': 'http://ar.i.kuwo.cn/US_NEW/kuwo/login_kw',
}

DONE_KEYWORDS = [
    '今天已完成任务', '已完成', '已领取', '已签到',
    '已达到当日观看额外视频次数', '已达', '上限',
    '次数用完', '免费次数用完了', '视频次数用完了',
]

# ========== DES 加密相关 ==========
STATIC_C = [1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768,
            65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608, 16777216,
            33554432, 67108864, 134217728, 268435456, 536870912, 1073741824, 2147483648,
            4294967296, 8589934592, 17179869184, 34359738368, 68719476736, 137438953472,
            274877906944, 549755813888, 1099511627776, 2199023255552, 4398046511104,
            8796093022208, 17592186044416, 35184372088832, 70368744177664, 140737488355328,
            281474976710656, 562949953421312, 1125899906842624, 2251799813685248,
            4503599627370496, 9007199254740992, 18014398509481984, 36028797018963968,
            72057594037927936, 144115188075855872, 288230376151711744, 576460752303423488,
            1152921504606846976, 2305843009213693952, 4611686018427387904, -9223372036854775808]

STATIC_I = [56, 48, 40, 32, 24, 16, 8, 0, 57, 49, 41, 33, 25, 17, 9, 1, 58, 50, 42, 34,
            26, 18, 10, 2, 59, 51, 43, 35, 62, 54, 46, 38, 30, 22, 14, 6, 61, 53, 45, 37,
            29, 21, 13, 5, 60, 52, 44, 36, 28, 20, 12, 4, 27, 19, 11, 3]

STATIC_E = [31, 0, 1, 2, 3, 4, -1, -1, 3, 4, 5, 6, 7, 8, -1, -1, 7, 8, 9, 10, 11, 12, -1, -1,
            11, 12, 13, 14, 15, 16, -1, -1, 15, 16, 17, 18, 19, 20, -1, -1, 19, 20, 21, 22, 23,
            24, -1, -1, 23, 24, 25, 26, 27, 28, -1, -1, 27, 28, 29, 30, 31, 30, -1, -1]

STATIC_L = [0, 1048577, 3145731]
STATIC_G = [15, 6, 19, 20, 28, 11, 27, 16, 0, 14, 22, 25, 4, 17, 30, 9, 1, 7, 23, 13, 31, 26,
            2, 8, 18, 12, 29, 5, 21, 10, 3, 24]
STATIC_K = [1, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1]

STATIC_F = [
    [14, 4, 3, 15, 2, 13, 5, 3, 13, 14, 6, 9, 11, 2, 0, 5, 4, 1, 10, 12, 15, 6, 9, 10, 1, 8, 12, 7, 8, 11, 7, 0,
     0, 15, 10, 5, 14, 4, 9, 10, 7, 8, 12, 3, 13, 1, 3, 6, 15, 12, 6, 11, 2, 9, 5, 0, 4, 2, 11, 14, 1, 7, 8, 13],
    [15, 0, 9, 5, 6, 10, 12, 9, 8, 7, 2, 12, 3, 13, 5, 2, 1, 14, 7, 8, 11, 4, 0, 3, 14, 11, 13, 6, 4, 1, 10, 15,
     3, 13, 12, 11, 15, 3, 6, 0, 4, 10, 1, 7, 8, 4, 11, 14, 13, 8, 0, 6, 2, 15, 9, 5, 7, 1, 10, 12, 14, 2, 5, 9],
    [10, 13, 1, 11, 6, 8, 11, 5, 9, 4, 12, 2, 15, 3, 2, 14, 0, 6, 13, 1, 3, 15, 4, 10, 14, 9, 7, 12, 5, 0, 8, 7,
     13, 1, 2, 4, 3, 6, 12, 11, 0, 13, 5, 14, 6, 8, 15, 2, 7, 10, 8, 15, 4, 9, 11, 5, 9, 0, 14, 3, 10, 7, 1, 12],
    [7, 10, 1, 15, 0, 12, 11, 5, 14, 9, 8, 3, 9, 7, 4, 8, 13, 6, 2, 1, 6, 11, 12, 2, 3, 0, 5, 14, 10, 13, 15, 4,
     13, 3, 4, 9, 6, 10, 1, 12, 11, 0, 2, 5, 0, 13, 14, 2, 8, 15, 7, 4, 15, 1, 10, 7, 5, 6, 12, 11, 3, 8, 9, 14],
    [2, 4, 8, 15, 7, 10, 13, 6, 4, 1, 3, 12, 11, 7, 14, 0, 12, 2, 5, 9, 10, 13, 0, 3, 1, 11, 15, 5, 6, 8, 9, 14,
     14, 11, 5, 6, 4, 1, 3, 10, 2, 12, 15, 0, 13, 2, 8, 5, 11, 8, 0, 15, 7, 14, 9, 4, 12, 7, 10, 9, 1, 13, 6, 3],
    [12, 9, 0, 7, 9, 2, 14, 1, 10, 15, 3, 4, 6, 12, 5, 11, 1, 14, 13, 0, 2, 8, 7, 13, 15, 5, 4, 10, 8, 3, 11, 6,
     10, 4, 6, 11, 7, 9, 0, 6, 4, 2, 13, 1, 9, 15, 3, 8, 15, 3, 1, 14, 12, 5, 11, 0, 2, 12, 14, 7, 5, 10, 8, 13],
    [4, 1, 3, 10, 15, 12, 5, 0, 2, 11, 9, 6, 8, 7, 6, 9, 11, 4, 12, 15, 0, 3, 10, 5, 14, 13, 7, 8, 13, 14, 1, 2,
     13, 6, 14, 9, 4, 1, 2, 14, 11, 13, 5, 0, 1, 10, 8, 3, 0, 11, 3, 5, 9, 4, 15, 2, 7, 8, 12, 15, 10, 7, 6, 12],
    [13, 7, 10, 0, 6, 9, 5, 15, 8, 4, 3, 10, 11, 14, 12, 5, 2, 11, 9, 6, 15, 12, 0, 3, 4, 1, 14, 13, 1, 2, 7, 8,
     1, 2, 12, 15, 10, 4, 0, 3, 13, 14, 6, 9, 7, 8, 9, 6, 15, 1, 5, 12, 3, 10, 14, 5, 8, 7, 11, 0, 4, 13, 2, 11]
]

STATIC_H = [39, 7, 47, 15, 55, 23, 63, 31, 38, 6, 46, 14, 54, 22, 62, 30, 37, 5, 45, 13, 53, 21, 61, 29,
            36, 4, 44, 12, 52, 20, 60, 28, 35, 3, 43, 11, 51, 19, 59, 27, 34, 2, 42, 10, 50, 18, 58, 26,
            33, 1, 41, 9, 49, 17, 57, 25, 32, 0, 40, 8, 48, 16, 56, 24]

STATIC_D = [57, 49, 41, 33, 25, 17, 9, 1, 59, 51, 43, 35, 27, 19, 11, 3, 61, 53, 45, 37, 29, 21, 13, 5,
            63, 55, 47, 39, 31, 23, 15, 7, 56, 48, 40, 32, 24, 16, 8, 0, 58, 50, 42, 34, 26, 18, 10, 2,
            60, 52, 44, 36, 28, 20, 12, 4, 62, 54, 46, 38, 30, 22, 14, 6]

STATIC_J = [13, 16, 10, 23, 0, 4, -1, -1, 2, 27, 14, 5, 20, 9, -1, -1, 22, 18, 11, 3, 25, 7, -1, -1,
            15, 6, 26, 19, 12, 1, -1, -1, 40, 51, 30, 36, 46, 54, -1, -1, 29, 39, 50, 44, 32, 47, -1, -1,
            43, 48, 38, 55, 33, 52, -1, -1, 45, 41, 49, 35, 28, 31, -1, -1]

# ========== 通用工具函数 ==========
def to_int(value):
    """安全转换为整数"""
    try:
        if value is None:
            return 0
        text = str(value).strip()
        if not text or text.lower() == 'null':
            return 0
        return int(float(text)) if '.' in text else int(text)
    except (ValueError, TypeError):
        return 0

def is_done_like(text):
    """检查是否为已完成状态"""
    if not text:
        return False
    text_str = str(text)
    return any(keyword in text_str for keyword in DONE_KEYWORDS)

def is_video_limit_like(text):
    """检查是否为视频次数限制"""
    if not text:
        return False
    text_str = str(text)
    keywords = ['已达到当日观看额外视频次数', '视频次数用完了', '免费次数用完了', '观看额外视频次数']
    return any(keyword in text_str for keyword in keywords)

def create_session():
    """创建请求会话"""
    session = requests.Session()
    session.verify = False
    session.timeout = 30
    return session

# ========== DES 加密函数 ==========
def func_a1(i_arr, i2, j2):
    j3 = 0
    for i3 in range(i2):
        if i_arr[i3] >= 0:
            if (STATIC_C[i_arr[i3]] & j2) != 0:
                j3 |= STATIC_C[i3]
    return j3

def func_a2(j2, j_arr, i2):
    a2 = func_a1(STATIC_I, 56, j2)
    for i3 in range(16):
        a2 = ((a2 & ~STATIC_L[STATIC_K[i3]]) >> STATIC_L[STATIC_K[i3]]) | \
             ((STATIC_L[STATIC_K[i3]] & a2) << (28 - STATIC_L[STATIC_K[i3]]))
        j_arr[i3] = func_a1(STATIC_J, 64, a2)
    if i2 == 1:
        for i4 in range(8):
            j3 = j_arr[i4]
            i5 = 15 - i4
            j_arr[i4] = j_arr[i5]
            j_arr[i5] = j3

def func_a3(j_arr, j2):
    p = [0] * 2
    q = [0] * 8
    m = func_a1(STATIC_D, 64, j2)
    p[0] = int(m & 4294967295)
    p[1] = int((m & -4294967296) >> 32)

    for i2 in range(16):
        o = func_a1(STATIC_E, 64, p[1])
        o ^= j_arr[i2]
        for i3 in range(8):
            q[i3] = int((o >> (i3 * 8)) & 255)

        r = 0
        for i5 in range(7, -1, -1):
            r = (r << 4) | STATIC_F[i5][q[i5]]
            if r > 2147483647:
                r = -4294967296 + r

        o = func_a1(STATIC_G, 32, r)
        n = p[0]
        p[0] = p[1]
        xor_val = n ^ o
        if -2147483648 < xor_val < 2147483647:
            p[1] = int(xor_val)
        elif xor_val >= 2147483647:
            p[1] = xor_val - 4294967296
        else:
            p[1] = xor_val + 4294967296

    p[0], p[1] = p[1], p[0]
    m = ((p[1] << 32) & -4294967296) | (4294967295 & p[0])
    return func_a1(STATIC_H, 64, m)

def generate_q(b_arr, b_arr2):
    length = len(b_arr)
    j_arr = [0] * 16
    j3 = 0
    for i3 in range(8):
        j3 |= b_arr2[i3] << (i3 * 8)
    func_a2(j3, j_arr, 0)

    i4 = length // 8
    j_arr2 = [0] * i4
    for i5 in range(i4):
        for i6 in range(8):
            j_arr2[i5] |= (b_arr[i5 * 8 + i6] & 255) << (i6 * 8)

    j_arr3 = [0] * (((i4 + 1) * 8 + 1) // 8)
    for i7 in range(i4):
        j_arr3[i7] = func_a3(j_arr, j_arr2[i7])

    i8 = length % 8
    i9 = i4 * 8
    i10 = length - i9
    r12 = list(b_arr[i9:i9 + i10])
    j2 = 0
    for i11 in range(i8):
        j2 |= (r12[i11] & 255) << (i11 * 8)
    j_arr3[i4] = func_a3(j_arr, j2)

    b_arr3 = [0] * (len(j_arr3) * 8)
    i12 = i13 = 0
    while i12 < len(j_arr3):
        i14 = i13
        for i15 in range(8):
            b_arr3[i14] = 255 & (j_arr3[i12] >> (i15 * 8))
            i14 += 1
        i12 += 1
        i13 = i14

    return base64.b64encode(bytearray(b_arr3)).decode()

def create_sx():
    """生成 sx 参数"""
    timestamp = int(time.time() * 1000)
    return str(timestamp)[:8]

def encrypt_devid(dev_id):
    """加密设备 ID"""
    padded_id = dev_id.ljust(16, '0')[:16]
    return base64.b64encode(padded_id.encode()).decode()

def get_q(username, password):
    """生成登录参数 q"""
    dev_id = ''.join(random.choices(string.digits, k=10))
    dev_name = '安卓设备'
    dev_type = 'arr'
    data = f"username={quote(username)}&password={quote(base64.b64encode(password.encode()).decode())}" \
           f"&dev_id={dev_id}&user={str(uuid.uuid4()).replace('-', '')}" \
           f"&dev_name={quote(dev_name)}&urlencode=0&src=kwplayer_ar11.1.4.1_40.apk" \
           f"&devResolution=720*1080&&from=android&devType={dev_type}&sx={create_sx()}&version=11.1.4.1"
    q_value = generate_q(data.encode('UTF-8'), 'kwks&@69'.encode('UTF-8'))
    encrypted_dev_id = encrypt_devid(dev_id)
    return q_value, encrypted_dev_id

def encrypt_phone(phone):
    """加密手机号"""
    key = b'ysiVkLJHHnvMWCHq'
    iv = b'ichYooX+Mb1gRetP'
    if isinstance(phone, str):
        phone = phone.encode('utf-8')
    cipher = AES.new(key, AES.MODE_CBC, iv)
    ciphertext = cipher.encrypt(pad(phone, AES.block_size))
    return base64.b64encode(ciphertext).decode('utf-8')

def generate_kuwo_token(device_id, timestamp):
    """生成酷我 token"""
    raw_string = f"{device_id}KUWO_COMIC{timestamp}"
    return hashlib.md5(raw_string.encode('utf-8')).hexdigest()

# ========== 账号解析 ==========
def parse_account_item(account_str):
    """解析单个账号字符串"""
    parts = [x.strip() for x in account_str.split('#')]
    if len(parts) < 2:
        return None
    if len(parts) == 2:
        phone, password = parts
    else:
        phone = parts[1]
        password = '#'.join(parts[2:])
    if not phone or not password:
        return None
    return {'phone': phone, 'password': password}

def get_accounts_from_env():
    """从环境变量获取账号列表"""
    env_value = os.getenv('kwyy', '').strip()
    if not env_value:
        return []
    accounts = []
    for account_str in env_value.split('&'):
        account_str = account_str.strip()
        if account_str:
            parsed = parse_account_item(account_str)
            if parsed:
                accounts.append(parsed)
    return accounts

# ========== HTTP 请求工具 ==========
def build_common_headers():
    """构建通用请求头"""
    return {
        'Host': 'integralapi.kuwo.cn',
        'Connection': 'keep-alive',
        'sec-ch-ua-platform': '"Android"',
        'User-Agent': 'Mozilla/5.0 (Linux; Android 13; Pixel 4a Build/TQ3A.230805.001.S2; wv) '
                      'AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/134.0.6998.135 '
                      'Mobile Safari/537.36/ kuwopage',
        'Accept': 'application/json, text/plain, */*',
        'sec-ch-ua': '"Chromium";v="134", "Not:A-Brand";v="24", "Android WebView";v="134"',
        'sec-ch-ua-mobile': '?1',
        'Origin': 'https://h5app.kuwo.cn',
        'X-Requested-With': 'cn.kuwo.player',
        'Sec-Fetch-Site': 'same-site',
        'Sec-Fetch-Mode': 'cors',
        'Sec-Fetch-Dest': 'empty',
        'Referer': 'https://h5app.kuwo.cn/',
        'Accept-Encoding': 'gzip, deflate, br, zstd',
        'Accept-Language': 'zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7',
    }

def safe_request(session, method, url, **kwargs):
    """安全的请求封装"""
    try:
        kwargs.setdefault('timeout', 30)
        kwargs.setdefault('verify', False)
        response = session.request(method, url, **kwargs)
        if response.status_code == 200:
            return response.json()
        return {'code': response.status_code, 'msg': f'HTTP {response.status_code}'}
    except Exception as e:
        return {'code': -1, 'msg': str(e)}

# ========== 登录功能 ==========
def login(session, username, password):
    """登录酷我账号"""
    try:
        q, encrypted_dev_id = get_q(username, password)
        headers = {
            'User-Agent': 'Dalvik/2.1.0 (Linux; U; Android 10; MI 8 MIUI/V12.5.2.0.QEACNXM)',
            'Accept': '*/*',
            'Host': 'ar.i.kuwo.cn',
            'Connection': 'Keep-Alive',
            'Accept-Encoding': 'gzip',
        }
        params = {'f': 'ar', 'q': q}
        response = session.get(URLS['login'], headers=headers, params=params)

        set_cookie = response.headers.get('Set-Cookie', '')
        username_match = re.search(r'uname3=([^;]+)', set_cookie)
        sid_match = re.search(r'websid=([^;]+)', set_cookie)
        uid_match = re.search(r'userid=([^;]+)', set_cookie)
        account_match = re.search(r't3kwid=([^;]+)', set_cookie)

        if all([username_match, sid_match, uid_match, account_match]):
            return {
                'loginUid': uid_match.group(1),
                'loginSid': sid_match.group(1),
                'username': username_match.group(1),
                'appUid': account_match.group(1),
                'encrypted_dev_id': encrypted_dev_id,
            }
        print('❌ 登录失败: Cookie解析失败')
        return None
    except Exception as e:
        print(f'❌ 登录异常: {e}')
        return None

# ========== 任务执行函数 ==========
def run_generic_task(session, title, url, params, verbose=True):
    """通用任务执行"""
    result = safe_request(session, 'GET', url, headers=build_common_headers(), params=params)
    code = result.get('code', 0)
    msg = result.get('msg', '未知错误')

    if code != 200:
        if verbose:
            print(f'❌ {title}请求失败: {msg}')
        return {'success': False, 'obtain': 0, 'description': msg, 'data': {}}

    data = result.get('data', {})
    if not isinstance(data, dict):
        data = {}

    status = data.get('status', 1)
    if isinstance(status, str) and status.isdigit():
        status = int(status)

    obtain = to_int(data.get('obtain') or data.get('goldNum') or 0)
    description = str(data.get('description') or result.get('msg') or '成功')

    if status == 1:
        if verbose:
            print(f'✅ {title}成功: +{obtain} 金币 - {description}')
        return {'success': True, 'obtain': obtain, 'description': description, 'data': data}

    if is_done_like(description):
        if verbose:
            print(f'⏭️ {title}: {description}')
        return {'success': True, 'done': True, 'obtain': obtain, 'description': description, 'data': data}

    if verbose:
        print(f'⚠️ {title}失败: {description}')
    return {'success': False, 'obtain': 0, 'description': description, 'data': data}

def run_new_do_listen_task(session, title, login_uid, login_sid, app_uid, phone, extra_params, verbose=True):
    """执行新听歌任务"""
    params = {
        'apiversion': '46', 'adverSpace': '', 'verifyStr': '',
        'loginUid': login_uid, 'loginSid': login_sid, 'appUid': app_uid,
        'terminal': 'ar', 'from': '', 'taskId': '', 'goldNum': '',
        'baseTaskGold': '0', 'adverId': '', 'token': '', 'extraGoldNum': '0',
        'clickExtraGoldNum': '0', 'secondRewardFlag': '0', 'yyzdSecondRewardFlag': '0',
        'surpriseType': '', 'mobile': phone, 'listenTime': 0, 'apiv': '10',
        'unit': '', 'dynamicVer': '46', 'kver': '1', 'rewardType': '0', 'pFrom': '',
    }
    params.update(extra_params or {})
    clean_params = {k: v for k, v in params.items() if v is not None}
    return run_generic_task(session, title, URLS['new_do_listen'], clean_params, verbose=verbose)

def run_everyday_do_listen_task(session, title, login_uid, login_sid, app_uid, extra_params, verbose=True):
    """执行每日听歌任务"""
    params = {'loginUid': login_uid, 'loginSid': login_sid, 'appUid': app_uid}
    params.update(extra_params or {})
    clean_params = {k: v for k, v in params.items() if v is not None}
    return run_generic_task(session, title, URLS['everyday_do_listen'], clean_params, verbose=verbose)

# ========== 签到任务 ==========
def fetch_sign_list(session, login_uid, login_sid, app_uid, extra_params=None, tag='签到列表'):
    """获取签到列表"""
    params = {'loginUid': login_uid, 'loginSid': login_sid, 'appUid': app_uid}
    params.update(extra_params or {})
    result = safe_request(session, 'GET', URLS['new_user_sign_list'], headers=build_common_headers(), params=params)

    if result.get('code') != 200:
        print(f'❌ {tag}请求失败: {result.get("msg")}')
        return {'success': False, 'data': {}}

    payload = result.get('data', {})
    if not isinstance(payload, dict):
        payload = {}
    return {'success': True, 'data': payload}

def has_listen_task_config(task_payload):
    """检查是否有听歌任务配置"""
    data_list = task_payload.get('dataList', [])
    if not isinstance(data_list, list):
        return False
    for item in data_list:
        if not isinstance(item, dict):
            continue
        task_type = str(item.get('taskType') or '').strip().lower()
        title = str(item.get('title') or '')
        listen_list = item.get('listenList')
        if task_type == 'listen' and isinstance(listen_list, list):
            return True
        if '听歌' in title and isinstance(listen_list, list):
            return True
    return False

def fetch_dynamic_task_payload(session, login_uid, login_sid, app_uid, first_payload):
    """获取动态任务配置"""
    if has_listen_task_config(first_payload):
        return first_payload

    dynamic_info = fetch_sign_list(
        session, login_uid, login_sid, app_uid,
        extra_params={'dynamicVer': '39', 'q36': '0302c7dcfc6616225938b018100018b19319'},
        tag='动态任务列表',
    )
    if dynamic_info.get('success'):
        payload = dynamic_info.get('data', {})
        dynamic_list = payload.get('dataList', [])
        if has_listen_task_config(payload) or (isinstance(dynamic_list, list) and dynamic_list):
            return payload
    return first_payload

def extract_listen_segment_candidates(task_payload):
    """提取听歌分段任务候选"""
    data_list = task_payload.get('dataList', [])
    if not isinstance(data_list, list):
        return []

    candidates = []
    seen = set()

    for item in data_list:
        if not isinstance(item, dict):
            continue
        title = str(item.get('title') or '')
        task_type = str(item.get('taskType') or '').strip().lower()
        listen_list = item.get('listenList')
        if not isinstance(listen_list, list):
            continue
        if not (task_type == 'listen' or '听歌' in title or listen_list):
            continue

        for idx, listen_item in enumerate(listen_list, 1):
            if not isinstance(listen_item, dict):
                continue
            listen_time = listen_item.get('time')
            unit = listen_item.get('unit')
            gold = listen_item.get('goldNum')
            extra_gold = listen_item.get('extraGoldNum')

            if gold and str(gold).lower() != 'null':
                key = ('g', str(listen_time or ''), str(unit or ''), str(gold))
                if key not in seen:
                    seen.add(key)
                    candidates.append({
                        'kind': 'gold', 'idx': idx,
                        'params': {'from': 'listen', 'goldNum': gold, 'listenTime': listen_time, 'unit': unit},
                    })

            if extra_gold and str(extra_gold).lower() != 'null':
                key = ('eg', str(listen_time or ''), '', str(extra_gold))
                if key not in seen:
                    seen.add(key)
                    candidates.append({
                        'kind': 'extra', 'idx': idx,
                        'params': {'from': 'listen', 'extraGoldNum': extra_gold, 'listenTime': listen_time},
                    })

    return candidates

def run_missing_listen_tasks(session, login_uid, login_sid, app_uid, encrypted_phone, verbose=True):
    """执行缺失的听歌任务"""
    base_result = run_new_do_listen_task(
        session, '每日听歌奖励', login_uid, login_sid, app_uid, encrypted_phone,
        {'goldNum': 18}, verbose=verbose
    )
    extra_result = run_new_do_listen_task(
        session, '每日听歌额外奖励', login_uid, login_sid, app_uid, encrypted_phone,
        {'extraGoldNum': 60}, verbose=verbose
    )
    return {'base': base_result, 'extra': extra_result}

def run_sign_task_chain(session, login_uid, login_sid, app_uid, encrypted_phone):
    """执行签到任务链"""
    sign_info = fetch_sign_list(session, login_uid, login_sid, app_uid)
    if not sign_info['success']:
        return

    payload = sign_info.get('data', {})
    sign_flag = payload.get('isSign')
    signed_today = sign_flag is True or str(sign_flag).strip().lower() in ['1', 'true', 'yes']

    if signed_today:
        print('⏭️ 今日已签到，跳过签到主链')
    else:
        run_new_do_listen_task(session, '签到视频奖励(new)', login_uid, login_sid, app_uid, encrypted_phone,
                               {'from': 'sign', 'extraGoldNum': 110}, verbose=True)
        run_everyday_do_listen_task(session, '签到视频奖励(old)', login_uid, login_sid, app_uid,
                                    {'from': 'sign', 'extraGoldNum': 110}, verbose=True)

    base_results = run_missing_listen_tasks(session, login_uid, login_sid, app_uid, encrypted_phone, verbose=True)
    extra_video_limited = is_video_limit_like(base_results.get('extra', {}).get('description', ''))

    task_payload = fetch_dynamic_task_payload(session, login_uid, login_sid, app_uid, payload)
    candidates = extract_listen_segment_candidates(task_payload)
    if not candidates:
        print('⏭️ 听歌分段任务: 未发现分段配置')
        return

    attempt_count = 0
    for candidate in candidates:
        if candidate.get('kind') == 'extra' and extra_video_limited:
            continue

        attempt_count += 1
        title = f'听歌任务#{candidate.get("idx")}'
        if candidate.get('kind') == 'extra':
            title = f'听歌额外#{candidate.get("idx")}'

        result = run_new_do_listen_task(
            session, title, login_uid, login_sid, app_uid, encrypted_phone,
            candidate.get('params') or {}, verbose=True
        )
        if candidate.get('kind') == 'extra' and is_video_limit_like(result.get('description')):
            extra_video_limited = True

    if attempt_count == 0:
        print('⏭️ 听歌分段任务: 可尝试项仅含额外视频奖励，当前视频次数受限')

# ========== 宝箱任务 ==========
def open_treasure_box(session, login_uid, login_sid, app_uid, encrypted_dev_id, gold_num=20, verbose=True):
    """开宝箱"""
    params = {
        'apiversion': '46', 'loginUid': login_uid, 'loginSid': login_sid,
        'devId': encrypted_dev_id, 'jfencv': 'devId', 'appUid': app_uid,
        'source': 'kwplayer_ar_12.0.4.1_newpcguanwangmobile.apk',
        'version': 'kwplayer_ar_12.0.4.1', 'dynamicVer': '46', 'kver': '1',
        'verifyStr': '', 'adverSpace': '', 'r': str(random.random()),
        'action': 'new', 'time': '', 'goldNum': str(gold_num),
        'baseTaskGold': '0', 'extraGoldnum': '0', 'clickExtraGoldNum': '0',
        'yyzdSecondRewardFlag': '0', 'secondRewardFlag': '0', 'apiv': '6',
    }
    result = safe_request(session, 'GET', URLS['new_box_finish'], headers=build_common_headers(), params=params)

    if result.get('code') == 200:
        data = result.get('data', {})
        if not isinstance(data, dict):
            data = {}
        status = data.get('status', 0)
        if status == 1:
            obtain = data.get('obtain', 0)
            extra_num = data.get('extraNum', 0)
            if verbose:
                msg = f'✅ 开宝箱成功: 获得 {obtain} 金币'
                if extra_num:
                    msg += f' (额外 {extra_num} 金币)'
                print(msg)
            return {'success': True, 'obtain': obtain, 'extra_num': extra_num, 'description': '成功'}
        description = data.get('description', '未知错误')
        if verbose:
            print(f'⚠️ 开宝箱失败: {description}')
        return {'success': False, 'obtain': 0, 'description': description}

    error_msg = result.get('msg', '未知错误')
    if verbose:
        print(f'❌ 开宝箱请求失败: {error_msg}')
    return {'success': False, 'obtain': 0, 'description': error_msg}

def run_activity_box_task(session, login_uid, login_sid, verbose=True):
    """执行活动宝箱任务"""
    params = {'loginUid': login_uid, 'loginSid': login_sid, 'from': 'sign', 'extraGoldNum': '110'}
    result = safe_request(session, 'GET', URLS['new_box_list'], headers=build_common_headers(), params=params)

    if result.get('code') != 200:
        if verbose:
            print(f'❌ 活动宝箱列表请求失败: {result.get("msg")}')
        return {'success': False, 'obtain': 0, 'description': result.get('msg')}

    data = result.get('data', {})
    if not isinstance(data, dict):
        data = {}
    gold_num = to_int(data.get('goldNum') or 0)
    if gold_num <= 0:
        if verbose:
            print('⏭️ 活动宝箱: 暂无可领取金币')
        return {'success': True, 'done': True, 'obtain': 0, 'description': '暂无可领取金币'}

    finish_params = {'loginUid': login_uid, 'loginSid': login_sid, 'action': 'new', 'goldNum': gold_num}
    finish_result = safe_request(session, 'GET', URLS['new_box_finish'], headers=build_common_headers(), params=finish_params)

    if finish_result.get('code') == 200:
        if verbose:
            print(f'✅ 活动宝箱成功: 获得 {gold_num} 金币')
        return {'success': True, 'obtain': gold_num, 'description': '成功'}

    msg = str(finish_result.get('msg', '未知错误'))
    if verbose:
        print(f'⚠️ 活动宝箱领取失败: {msg}')
    return {'success': False, 'obtain': 0, 'description': msg}

def run_box_renew_tasks(session, login_uid, login_sid, gold_num=30, verbose=True):
    """执行时段宝箱补领任务"""
    time_windows = ['00-08', '08-10', '10-12', '12-14', '14-16', '16-18', '18-20', '20-24']
    success_count = 0
    total_count = len(time_windows) * 2
    stop_all = False

    for time_window in time_windows:
        for action, action_name in [('new', '新宝箱'), ('old', '补宝箱')]:
            params = {
                'loginUid': login_uid, 'loginSid': login_sid,
                'action': action, 'time': time_window, 'goldNum': str(gold_num),
            }
            result = safe_request(session, 'GET', URLS['box_renew'], headers=build_common_headers(), params=params)

            if result.get('code') == 200:
                success_count += 1
                if verbose:
                    print(f'  ✅ {action_name}({time_window})')
            else:
                msg = str(result.get('msg', '未知错误'))
                if verbose:
                    print(f'  ❌ {action_name}({time_window}): {msg}')
                if is_done_like(msg):
                    stop_all = True

            if stop_all:
                break
        if stop_all:
            break

    if verbose:
        print(f'  汇总: 成功 {success_count}/{total_count}')
    return {'success_count': success_count, 'total_count': total_count}

# ========== 广告任务 ==========
def open_guanggao(session, login_uid, login_sid, app_uid, encrypted_dev_id, gold_num, phone, verbose=True):
    """观看广告"""
    params = {
        'apiversion': '46', 'adverSpace': '20130101',
        'loginUid': login_uid, 'loginSid': login_sid, 'appUid': app_uid,
        'terminal': 'ar', 'from': 'videoadver', 'taskId': '', 'goldNum': str(gold_num),
        'baseTaskGold': '0', 'adverId': '', 'mobile': phone,
        'listenTime': 0, 'apiv': 10, 'unit': '', 'dynamicVer': 46,
        'kver': 1, 'rewardType': 0, 'pFrom': 'HTTP/1.1',
    }
    result = safe_request(session, 'GET', URLS['new_do_listen'], headers=build_common_headers(), params=params)

    if result.get('code') == 200:
        data = result.get('data', {})
        if not isinstance(data, dict):
            data = {}
        status = data.get('status', 0)
        if status == 1:
            obtain = data.get('obtain', 0)
            description = data.get('description', '成功')
            if verbose:
                print(f'✅ 广告观看成功: 获得 {obtain} 金币 - {description}')
            return {'success': True, 'obtain': obtain, 'description': description}
        description = data.get('description', '未知错误')
        if verbose:
            print(f'⚠️ 广告观看失败: {description}')
        return {'success': False, 'obtain': 0, 'description': description}

    error_msg = result.get('msg', '未知错误')
    if verbose:
        print(f'❌ 广告观看请求失败: {error_msg}')
    return {'success': False, 'obtain': 0, 'description': error_msg}

def watch_surprise_ad(session, login_uid, login_sid, app_uid, encrypted_dev_id, phone, verbose=True):
    """观看惊喜广告"""
    params = {
        'apiversion': '46', 'adverSpace': '20130702', 'verifyStr': '',
        'loginUid': login_uid, 'loginSid': login_sid, 'appUid': app_uid,
        'terminal': 'ar', 'from': 'surprise', 'taskId': '', 'goldNum': '68',
        'baseTaskGold': '0', 'adverId': '20130702-77797065644-101', 'token': '',
        'clickExtraGoldNum': '0', 'secondRewardFlag': '0', 'yyzdSecondRewardFlag': '0',
        'verificationId': '', 'surpriseType': '', 'mobile': phone,
        'apiv': '10', 'dynamicVer': '46', 'kver': '1', 'rewardType': '0', 'pFrom': '',
    }
    result = safe_request(session, 'GET', URLS['new_do_listen'], headers=build_common_headers(), params=params)

    if result.get('code') == 200:
        data = result.get('data', {})
        if not isinstance(data, dict):
            data = {}
        status = data.get('status', 0)
        if status == 1:
            obtain = data.get('obtain', 0)
            description = data.get('description', '成功')
            if verbose:
                print(f'✅ 惊喜广告观看成功: 获得 {obtain} 金币 - {description}')
            return {'success': True, 'obtain': obtain, 'description': description}
        description = data.get('description', '未知错误')
        if verbose:
            print(f'⚠️ 惊喜广告观看失败: {description}')
        return {'success': False, 'obtain': 0, 'description': description}

    error_msg = result.get('msg', '未知错误')
    if verbose:
        print(f'❌ 惊喜广告观看请求失败: {error_msg}')
    return {'success': False, 'obtain': 0, 'description': error_msg}

def watch_dada_ad(session, login_uid, login_sid, app_uid, encrypted_dev_id, phone, verbose=True):
    """观看大大广告"""
    timestamp = str(int(time.time() * 1000))
    dynamic_token = generate_kuwo_token(encrypted_dev_id, timestamp)

    params = {
        'apiversion': '46', 'adverSpace': '20130401', 'verifyStr': '',
        'loginUid': login_uid, 'loginSid': login_sid, 'appUid': app_uid,
        'terminal': 'ar', 'from': 'videofix', 'taskId': '', 'goldNum': '50',
        'baseTaskGold': '0', 'adverId': '', 'token': dynamic_token,
        'extraGoldNum': '0', 'clickExtraGoldNum': '0', 'secondRewardFlag': '0',
        'yyzdSecondRewardFlag': '0', 'surpriseType': '', 'mobile': phone,
        'apiv': '10', 'dynamicVer': '46', 'kver': '1', 'rewardType': '0', 'pFrom': '',
    }
    result = safe_request(session, 'GET', URLS['new_do_listen'], headers=build_common_headers(), params=params)

    if result.get('code') == 200:
        data = result.get('data', {})
        if not isinstance(data, dict):
            data = {}
        status = data.get('status', 0)
        if status == 1:
            obtain = data.get('obtain', 0)
            description = data.get('description', '成功')
            if verbose:
                print(f'✅ 广告观看成功: 获得 {obtain} 金币 - {description}')
            return {'success': True, 'obtain': obtain, 'description': description}
        description = data.get('description', '未知错误')
        if verbose:
            print(f'⚠️ 广告观看失败: {description}')
        return {'success': False, 'obtain': 0, 'description': description}

    error_msg = result.get('msg', '未知错误')
    if verbose:
        print(f'❌ 广告观看请求失败: {error_msg}')
    return {'success': False, 'obtain': 0, 'description': error_msg}

# ========== 整点金币 ==========
def clock_bonus(session, login_uid, login_sid, app_uid, encrypted_dev_id, phone, verbose=True):
    """整点领金币"""
    clock_gold_num = 59
    try:
        task_payload = fetch_dynamic_task_payload(session, login_uid, login_sid, app_uid, {})
        data_list = task_payload.get('dataList', [])
        if isinstance(data_list, list):
            for item in data_list:
                if not isinstance(item, dict):
                    continue
                subtitle = str(item.get('subTitle') or '')
                task_type = str(item.get('taskType') or '')
                if '打卡' in subtitle or task_type == 'clock':
                    gold_num = to_int(item.get('goldNum'))
                    if gold_num > 0:
                        clock_gold_num = gold_num
                        break
    except Exception:
        pass

    return run_new_do_listen_task(
        session, '整点领金币', login_uid, login_sid, app_uid, phone,
        {'from': 'clock', 'goldNum': str(clock_gold_num)}, verbose=verbose
    )

# ========== 抽奖 ==========
def lottery_draw(session, login_uid, login_sid, app_uid, source='kwplayer_ar_12.0.4.1_newpcguanwangmobile.apk',
                 lottery_type='free', verbose=True):
    """抽奖"""
    params = {
        'loginUid': login_uid, 'loginSid': login_sid, 'appUid': app_uid,
        'source': source, 'type': lottery_type,
    }
    result = safe_request(session, 'GET', URLS['lottery'], headers=build_common_headers(), params=params)

    code = result.get('code', 0)
    msg = result.get('msg', '未知')

    if code == 200:
        data = result.get('data', {})
        if not isinstance(data, dict):
            data = {}
        reward_name = str(data.get('loterryname') or data.get('lotteryName') or msg)
        obtain = to_int(data.get('goldNum') or data.get('obtain') or data.get('awardScore') or data.get('score') or 0)
        if obtain <= 0:
            match = re.search(r'(\d+)\s*金币', f'{reward_name} {msg}')
            if match:
                obtain = to_int(match.group(1))
        if verbose:
            if obtain > 0:
                print(f'🎉 抽奖成功: {reward_name} (+{obtain} 金币)')
            else:
                print(f'🎉 抽奖成功: {reward_name}')
        return {'success': True, 'message': msg, 'reward_name': reward_name, 'obtain': obtain, 'data': data}

    if verbose:
        print(f'❌ 抽奖失败: {msg}')
    return {'success': False, 'message': msg, 'data': {}}

# ========== 累计奖励 ==========
def run_coin_accumulation_tasks(session, login_uid, login_sid, app_uid, encrypted_phone):
    """执行累计奖励任务"""
    for task_id in [1, 2, 3]:
        run_new_do_listen_task(
            session, f'累计奖励任务{task_id}', login_uid, login_sid, app_uid, encrypted_phone,
            {'from': 'coinAccumulationTask', 'taskId': task_id}
        )
        time.sleep(2)

# ========== 资产查询 ==========
def query_user_asset(session, login_uid, login_sid, app_uid, verbose=True):
    """查询用户资产"""
    params = {'loginUid': login_uid, 'loginSid': login_sid, 'appUid': app_uid}
    result = safe_request(session, 'GET', URLS['user_asset'], headers=build_common_headers(), params=params)

    if result.get('code') != 200:
        if verbose:
            print(f'❌ 资产查询失败: {result.get("msg")}')
        return {'success': False, 'score': 0}

    data = result.get('data', {})
    if not isinstance(data, dict):
        data = {}
    score = to_int(data.get('remainScore') or result.get('remainScore') or 0)
    if verbose:
        print(f'✅ 资产查询成功: 剩余金币 {score}')
    return {'success': True, 'score': score}

# ========== 免费听歌时长 ==========
def run_freemium_watch(session, login_uid, verbose=True):
    """执行免费听歌时长任务"""
    summary = {'success_count': 0, 'rounds': 0, 'total_minutes': 0, 'last_expiry': ''}
    if not str(login_uid).isdigit():
        if verbose:
            print('  ❌ loginUid 非数字，已跳过')
        return summary

    rounds = max(1, min(10, to_int(os.getenv('KUWO_FREEMIUM_LOOP', '1'))))
    summary['rounds'] = rounds

    headers = {
        'Content-Type': 'application/json;charset=utf-8',
        'User-Agent': 'Mozilla/5.0 (Linux; Android 13; Pixel 4a Build/TQ3A.230805.001.S2; wv) '
                      'AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/134.0.6998.135 '
                      'Mobile Safari/537.36/ kuwopage',
        'Accept': 'application/json, text/plain, */*',
    }

    for idx in range(rounds):
        req_id = ''.join(random.choices(string.hexdigits.lower(), k=32))
        url = f'{URLS["freemium_switch"]}?reqId={req_id}'
        body = {'loginUid': int(login_uid), 'status': 1}

        result = safe_request(session, 'POST', url, headers=headers, json=body)

        if result.get('code') == 200:
            data = result.get('data', {})
            if not isinstance(data, dict):
                data = {}
            single_time = to_int(data.get('singleTime') or 0)
            end_time = to_int(data.get('endTime') or 0)
            expiry_text = ''
            if end_time > 0:
                if end_time < 10**12:
                    end_time *= 1000
                expiry_text = datetime.fromtimestamp(end_time / 1000).strftime('%Y-%m-%d %H:%M:%S')
                summary['last_expiry'] = expiry_text
            summary['success_count'] += 1
            summary['total_minutes'] += single_time
            if verbose:
                msg = f'  第{idx + 1}/{rounds}次 ✅ +{single_time} 分钟'
                if expiry_text:
                    msg += f', 到期 {expiry_text}'
                print(msg)
        else:
            msg = str(result.get('msg', '未知错误'))
            if verbose:
                print(f'  第{idx + 1}/{rounds}次 ❌ {msg}')
            if is_done_like(msg):
                break

    if verbose:
        summary_line = f'  汇总: 成功 {summary["success_count"]}/{rounds}, 累计 {summary["total_minutes"]} 分钟'
        if summary['last_expiry']:
            summary_line += f', 到期 {summary["last_expiry"]}'
        print(summary_line)
    return summary

# ========== 主函数 ==========
def print_banner():
    """打印免责声明"""
    print('\n        免责声明:\n仅供学习与接口研究，请在法律法规允许范围内使用并自行承担风险。\n')

def check_expiration():
    """检查脚本是否过期"""
    expiration_time = datetime(2099, 5, 1, 19, 0, 0)
    if datetime.now() > expiration_time:
        print('\n' + '=' * 60)
        print('脚本已过期，请更新到新版本后再运行')
        print('=' * 60)
        return False
    return True

def main():
    """主函数"""
    print('=' * 60)
    print_banner()
    print('=' * 60)

    if not check_expiration():
        return

    accounts = get_accounts_from_env()
    if not accounts:
        print('\n❌ 未读取到有效账号，请设置环境变量 kwyy')
        print('格式1: kwyy="手机号#密码"')
        print('格式2: kwyy="备注#手机号#密码"')
        print('多账号: kwyy="手机号1#密码1&手机号2#密码2"')
        return

    print(f'\n📱 获取到 {len(accounts)} 个账号')

    for i, account in enumerate(accounts, 1):
        phone = account['phone']
        password = account['password']
        encrypted_phone = encrypt_phone(phone)

        print(f'\n{"=" * 50}')
        print(f'👤 账号 {i}/{len(accounts)}: {phone}')
        print('=' * 50)

        session = create_session()
        result = login(session, phone, password)

        if not result:
            print('❌ 登录失败，跳过后续测试')
            if i < len(accounts):
                print('\n⏳ 账号切换等待 10 秒...')
                time.sleep(10)
            continue

        login_uid = result['loginUid']
        login_sid = result['loginSid']
        app_uid = result['appUid']
        encrypted_dev_id = result['encrypted_dev_id']

        print('✅ 登录成功!')

        # 【1】资产查询
        print('\n【1】资产查询:')
        asset_result = query_user_asset(session, login_uid, login_sid, app_uid, verbose=False)
        if asset_result.get('success'):
            print(f'  结果: ✅ 剩余金币 {asset_result.get("score", 0)}')
        else:
            print('  结果: ❌ 查询失败')

        # 【2】签到听歌任务链
        print('\n【2】签到听歌任务链:')
        run_sign_task_chain(session, login_uid, login_sid, app_uid, encrypted_phone)

        # 【3】累计奖励任务
        print('\n【3】累计奖励任务:')
        run_coin_accumulation_tasks(session, login_uid, login_sid, app_uid, encrypted_phone)

        # 【4】开宝箱
        print('\n【4】开宝箱:')
        box_result = open_treasure_box(session, login_uid, login_sid, app_uid, encrypted_dev_id, gold_num=20, verbose=False)
        if box_result['success']:
            print(f'  结果: ✅ +{box_result.get("obtain", 0)} 金币')
        else:
            print(f'  结果: ❌ {box_result["description"]}')

        # 【4.1】活动宝箱
        print('\n【4.1】活动宝箱:')
        activity_box_result = run_activity_box_task(session, login_uid, login_sid, verbose=False)
        if activity_box_result.get('success'):
            if activity_box_result.get('done'):
                print(f'  结果: ⏭️ {activity_box_result.get("description", "已完成")}')
            else:
                print(f'  结果: ✅ +{activity_box_result.get("obtain", 0)} 金币')
        else:
            print(f'  结果: ❌ {activity_box_result.get("description", "失败")}')

        # 【4.2】时段宝箱补领
        print('\n【4.2】时段宝箱补领:')
        run_box_renew_tasks(session, login_uid, login_sid, gold_num=30, verbose=True)

        # 【5】看视频拆红包
        print('\n【5】看视频拆红包:')
        ad_success_count = 0
        ad_total_gold = 0
        for j in range(30):
            ad_result = open_guanggao(session, login_uid, login_sid, app_uid, encrypted_dev_id, 208, encrypted_phone, verbose=False)
            round_idx = j + 1
            if ad_result['success']:
                obtain = to_int(ad_result.get('obtain') or 0)
                ad_success_count += 1
                ad_total_gold += obtain
                print(f'  第{round_idx}/30次 ✅ +{obtain} 金币')
            else:
                print(f'  第{round_idx}/30次 ❌ {ad_result["description"]}')
                if is_done_like(ad_result.get('description')):
                    break
            time.sleep(5)
        print(f'  汇总: 成功 {ad_success_count}/30, 累计 {ad_total_gold} 金币')

        # 【6】整点领金币
        print('\n【6】整点领金币:')
        clock_result = clock_bonus(session, login_uid, login_sid, app_uid, encrypted_dev_id, encrypted_phone, verbose=False)
        if clock_result['success']:
            if clock_result.get('done'):
                print(f'  结果: ⏭️ {clock_result.get("description", "已完成")}')
            else:
                print(f'  结果: ✅ +{clock_result.get("obtain", 0)} 金币')
        else:
            print(f'  结果: ❌ {clock_result["description"]}')

        # 【8】免费抽奖
        print('\n【8】免费抽奖:')
        lottery_result = lottery_draw(session, login_uid, login_sid, app_uid, verbose=False)
        if lottery_result['success']:
            reward_name = str(lottery_result.get('reward_name') or lottery_result.get('message') or '成功')
            free_obtain = to_int(lottery_result.get('obtain') or 0)
            if free_obtain > 0:
                print(f'  结果: ✅ {reward_name} (+{free_obtain} 金币)')
            else:
                print(f'  结果: ✅ {reward_name}')
        else:
            print(f'  结果: ❌ {lottery_result["message"]}')

        # 【9】广告抽奖
        print('\n【9】广告抽奖:')
        lottery_video_success = 0
        lottery_video_total_gold = 0
        for j in range(9):
            lottery_result = lottery_draw(session, login_uid, login_sid, app_uid, lottery_type='video', verbose=False)
            round_idx = j + 1
            if lottery_result['success']:
                reward_name = str(lottery_result.get('reward_name') or lottery_result.get('message') or '成功')
                obtain = to_int(lottery_result.get('obtain') or 0)
                lottery_video_success += 1
                lottery_video_total_gold += obtain
                if obtain > 0:
                    print(f'  第{round_idx}/9次 ✅ {reward_name} (+{obtain} 金币)')
                else:
                    print(f'  第{round_idx}/9次 ✅ {reward_name}')
            else:
                print(f'  第{round_idx}/9次 ❌ {lottery_result["message"]}')
                if is_done_like(lottery_result.get('message')):
                    break
            time.sleep(5)
        print(f'  汇总: 成功 {lottery_video_success}/9, 累计 {lottery_video_total_gold} 金币')

        # 【10】观看惊喜广告
        print('\n【10】观看惊喜广告:')
        surprise_success_count = 0
        surprise_total_gold = 0
        for j in range(5):
            surprise_result = watch_surprise_ad(session, login_uid, login_sid, app_uid, encrypted_dev_id, encrypted_phone, verbose=False)
            round_idx = j + 1
            if surprise_result['success']:
                obtain = to_int(surprise_result.get('obtain') or 0)
                surprise_success_count += 1
                surprise_total_gold += obtain
                print(f'  第{round_idx}/5次 ✅ +{obtain} 金币')
            else:
                print(f'  第{round_idx}/5次 ❌ {surprise_result["description"]}')
                if is_done_like(surprise_result.get('description')):
                    break
            time.sleep(5)
        print(f'  汇总: 成功 {surprise_success_count}/5, 累计 {surprise_total_gold} 金币')

        # 【11】免费听歌时长任务
        print('\n【11】免费听歌时长任务:')
        run_freemium_watch(session, login_uid, verbose=True)

        # 关闭会话
        session.close()

        if i < len(accounts):
            print('\n⏳ 账号切换等待 10 秒...')
            time.sleep(10)

    print('\n' + '=' * 60)
    print('全部账号任务执行结束')
    print('=' * 60)

    # 发送通知
    if SEND_FLAG:
        try:
            send('酷我音乐任务完成', f'已完成 {len(accounts)} 个账号的任务执行')
        except Exception as e:
            print(f'通知发送失败: {e}')

if __name__ == '__main__':
    main()
