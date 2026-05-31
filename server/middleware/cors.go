package middleware

import (
	"log"
	"net"
	"net/url"
	"strings"
	"sync"
	"time"

	"daidai-panel/config"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func matchesConfiguredOrigin(origin string, allowedOrigins []string) bool {
	normalizedOrigin := normalizeConfiguredOrigin(origin)
	for _, allowed := range allowedOrigins {
		if normalizeConfiguredOrigin(allowed) == normalizedOrigin {
			return true
		}
	}
	return false
}

func normalizeConfiguredOrigin(origin string) string {
	trimmed := strings.TrimSpace(origin)
	if trimmed == "" {
		return ""
	}

	parsed, err := url.Parse(trimmed)
	if err != nil || parsed.Scheme == "" || parsed.Host == "" {
		return strings.ToLower(trimmed)
	}

	hostname := strings.ToLower(parsed.Hostname())
	if isLoopbackHost(hostname) {
		hostname = "loopback"
	}

	port := parsed.Port()
	if port != "" {
		hostname = net.JoinHostPort(hostname, port)
	}

	return strings.ToLower(parsed.Scheme) + "://" + hostname
}

func isLoopbackHost(hostname string) bool {
	switch hostname {
	case "localhost", "127.0.0.1", "::1":
		return true
	default:
		return false
	}
}

func extractHost(value string) string {
	value = strings.TrimSpace(value)
	if value == "" {
		return ""
	}

	if strings.Contains(value, ",") {
		value = strings.TrimSpace(strings.Split(value, ",")[0])
	}

	if parsed, err := url.Parse(value); err == nil && parsed.Host != "" {
		return strings.ToLower(parsed.Host)
	}

	return strings.ToLower(value)
}

func isSameOriginRequest(c *gin.Context, origin string) bool {
	originHost := extractHost(origin)
	if originHost == "" {
		return false
	}

	candidates := []string{
		c.Request.Host,
		c.GetHeader("X-Forwarded-Host"),
		c.GetHeader("X-Original-Host"),
	}
	if forwarded := c.GetHeader("Forwarded"); forwarded != "" {
		candidates = append(candidates, parseForwardedHosts(forwarded)...)
	}

	for _, candidate := range candidates {
		if extractHost(candidate) == originHost {
			return true
		}
	}

	return false
}

// parseForwardedHosts 从 RFC 7239 `Forwarded` header 中解析所有 host= 字段。
// 例如：Forwarded: for=192.0.2.60;proto=http;host=example.com, for=198.51.100.17
func parseForwardedHosts(value string) []string {
	var hosts []string
	for _, segment := range strings.Split(value, ",") {
		for _, pair := range strings.Split(segment, ";") {
			pair = strings.TrimSpace(pair)
			if len(pair) < 5 {
				continue
			}
			if !strings.EqualFold(pair[:5], "host=") {
				continue
			}
			host := strings.Trim(pair[5:], `"`)
			if host != "" {
				hosts = append(hosts, host)
			}
		}
	}
	return hosts
}

// isPrivateOrLoopbackOrigin 判断 Origin 的 host 是否为 IP 且在私有/局域网/Loopback 网段。
// 命中后视为可信来源（典型场景：飞牛 OS / 群晖 / 家用 NAS 等通过 LAN IP 访问），跳过严格 CORS 检查。
// 域名 origin 不会命中本函数，仍需走 allowedOrigins 或同源校验。
func isPrivateOrLoopbackOrigin(origin string) bool {
	host := extractHost(origin)
	if host == "" {
		return false
	}
	if h, _, err := net.SplitHostPort(host); err == nil {
		host = h
	}
	host = strings.Trim(host, "[]")
	ip := net.ParseIP(host)
	if ip == nil {
		return false
	}
	return isPrivateOrLocalIP(ip)
}

var (
	corsRejectLogOnce sync.Map
	corsRejectLogTTL  = 5 * time.Minute
)

func logCORSRejection(c *gin.Context, origin string) {
	key := origin + "|" + c.Request.Host
	now := time.Now()
	if last, ok := corsRejectLogOnce.Load(key); ok {
		if when, ok := last.(time.Time); ok && now.Sub(when) < corsRejectLogTTL {
			return
		}
	}
	corsRejectLogOnce.Store(key, now)

	log.Printf(
		"[CORS] 拒绝跨域请求 origin=%q host=%q X-Forwarded-Host=%q Forwarded=%q method=%s path=%s — 如需放行请在 config.yaml 的 cors.origins 中加入该 origin",
		origin,
		c.Request.Host,
		c.GetHeader("X-Forwarded-Host"),
		c.GetHeader("Forwarded"),
		c.Request.Method,
		c.Request.URL.Path,
	)
}

func CORS() gin.HandlerFunc {
	allowedOrigins := []string{
		"http://localhost:5173",
		"http://localhost:5700",
	}
	if config.C != nil && len(config.C.CORS.Origins) > 0 {
		allowedOrigins = config.C.CORS.Origins
	}

	return cors.New(cors.Config{
		AllowOriginWithContextFunc: func(c *gin.Context, origin string) bool {
			if origin == "" || origin == "null" {
				return true
			}
			if matchesConfiguredOrigin(origin, allowedOrigins) {
				return true
			}
			if isSameOriginRequest(c, origin) {
				return true
			}
			if isPrivateOrLoopbackOrigin(origin) {
				return true
			}
			logCORSRejection(c, origin)
			return false
		},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization", "Accept", "X-Requested-With"},
		ExposeHeaders:    []string{"Content-Length", "Content-Disposition"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	})
}
