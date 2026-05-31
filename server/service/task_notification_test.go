package service

import (
	"fmt"
	"strings"
	"testing"
	"time"

	"daidai-panel/model"
)

func TestBuildTaskExecutionNotificationIncludesFailureExcerpt(t *testing.T) {
	task := &model.Task{ID: 9, Name: "签到任务"}
	endedAt := time.Date(2026, 3, 22, 12, 34, 56, 789000000, time.Local)

	title, content, context := buildTaskExecutionNotification(
		task,
		42,
		false,
		7,
		3.4,
		endedAt,
		"第一行错误\n第二行错误\n第三行错误",
	)

	if title != "任务执行失败" {
		t.Fatalf("unexpected title: %q", title)
	}
	if !strings.Contains(content, "定时任务「签到任务」执行失败") {
		t.Fatalf("expected unified failure summary line, got %q", content)
	}
	if !strings.Contains(content, "完成时间: 2026-03-22 12:34:56.789") {
		t.Fatalf("expected content to include completed time, got %q", content)
	}
	if !strings.Contains(content, "日志ID: 42") {
		t.Fatalf("expected content to include task log id, got %q", content)
	}
	if !strings.Contains(content, "退出码: 7") {
		t.Fatalf("expected content to include exit code, got %q", content)
	}
	if !strings.Contains(content, "失败原因:") {
		t.Fatalf("expected content to include failure excerpt, got %q", content)
	}
	if got := context["task_name"]; got != "签到任务" {
		t.Fatalf("expected task_name context, got %q", got)
	}
	if got := context["task_log_id"]; got != "42" {
		t.Fatalf("expected task_log_id context, got %q", got)
	}
	if got := context["result_summary"]; got != "定时任务「签到任务」执行失败" {
		t.Fatalf("expected result_summary context, got %q", got)
	}
	if got := context["error_log"]; got == "" {
		t.Fatal("expected error_log context to be populated")
	}
	if got := context["reason"]; got == "" {
		t.Fatal("expected reason context to be populated")
	}
	if got := context["failure_reason"]; got == "" {
		t.Fatal("expected failure_reason context to be populated")
	}
}

func TestBuildTaskExecutionNotificationUsesUnifiedSuccessLayout(t *testing.T) {
	task := &model.Task{ID: 10, Name: "电信签到"}
	endedAt := time.Date(2026, 3, 23, 0, 0, 20, 759000000, time.Local)

	title, content, context := buildTaskExecutionNotification(
		task,
		34,
		true,
		0,
		20.7,
		endedAt,
		"",
	)

	if title != "任务执行成功" {
		t.Fatalf("unexpected title: %q", title)
	}
	if !strings.Contains(content, "定时任务「电信签到」执行成功") {
		t.Fatalf("expected unified success summary line, got %q", content)
	}
	if strings.Contains(content, "退出码") {
		t.Fatalf("did not expect exit code in success content, got %q", content)
	}
	if !strings.Contains(content, "完成时间: 2026-03-23 00:00:20.759") {
		t.Fatalf("expected content to include completed time, got %q", content)
	}
	if got := context["status_text"]; got != "成功" {
		t.Fatalf("expected success status_text, got %q", got)
	}
	if got := context["result_summary"]; got != "定时任务「电信签到」执行成功" {
		t.Fatalf("expected success result_summary, got %q", got)
	}
}

func TestBuildTaskExecutionNotificationIncludesSuccessLogExcerpt(t *testing.T) {
	task := &model.Task{ID: 11, Name: "慧生活798"}
	endedAt := time.Date(2026, 4, 18, 0, 42, 31, 535000000, time.Local)

	output := strings.Join([]string{
		"=== 开始执行 [2026-04-18 00:31:36] ===",
		"[执行前置脚本]",
		"慧生活798 2026-04-18 00:31:36",
		"共 3 个账号",
		"[账号 1/3] abcd...wxyz",
		"  当前积分: 1234",
		"  签到: 成功",
		"  广告: 5/5",
		"  视频: 5/5",
		"  今日积分: +80",
		"完成 3/3 个账号 00:42:31",
		"=== 执行结束 [2026-04-18 00:42:31] 耗时 655.20 秒 退出码 0 ===",
	}, "\n")

	_, content, context := buildTaskExecutionNotification(task, 602, true, 0, 655.2, endedAt, output)

	if !strings.Contains(content, "执行日志:") {
		t.Fatalf("expected content to include 执行日志 section, got %q", content)
	}
	if !strings.Contains(content, "今日积分: +80") {
		t.Fatalf("expected content to include recent script output, got %q", content)
	}
	if strings.Contains(content, "[执行前置脚本]") {
		t.Fatalf("did not expect panel meta lines in excerpt, got %q", content)
	}
	if strings.Contains(content, "=== 开始执行") {
		t.Fatalf("did not expect banner lines in excerpt, got %q", content)
	}
	if got := context["log_excerpt"]; !strings.Contains(got, "今日积分: +80") {
		t.Fatalf("expected log_excerpt context populated with script output, got %q", got)
	}
	if got := context["success_log"]; got == "" {
		t.Fatal("expected success_log context to be populated")
	}
}

func TestSummarizeTaskSuccessOutputDropsBannersAndMeta(t *testing.T) {
	output := strings.Join([]string{
		"=== 开始执行 [2026-04-18 00:00:00] ===",
		"[执行前置脚本]",
		"[第 1 次重试，等待 5 秒]",
		"[检测到缺失依赖: requests，正在自动安装...]",
		"[安装成功: requests]",
		"[依赖已安装 (1/5)，自动重试执行]",
		"签到: 成功",
		"今日积分: +80",
		"=== 执行结束 [2026-04-18 00:00:10] 耗时 10.00 秒 退出码 0 ===",
	}, "\n")

	summary := summarizeTaskSuccessOutput(output)
	if strings.Contains(summary, "=== 开始执行") || strings.Contains(summary, "=== 执行结束") {
		t.Fatalf("expected banner lines removed, got %q", summary)
	}
	for _, meta := range []string{"[执行前置脚本]", "[第 1 次重试", "[检测到缺失依赖", "[安装成功", "[依赖已安装"} {
		if strings.Contains(summary, meta) {
			t.Fatalf("expected panel meta %q removed, got %q", meta, summary)
		}
	}
	if !strings.Contains(summary, "签到: 成功") || !strings.Contains(summary, "今日积分: +80") {
		t.Fatalf("expected user output retained, got %q", summary)
	}
}

func TestSummarizeTaskSuccessOutputTruncatesLongLogs(t *testing.T) {
	var builder strings.Builder
	for i := 0; i < 200; i++ {
		builder.WriteString(fmt.Sprintf("line %d 内容\n", i))
	}
	summary := summarizeTaskSuccessOutput(builder.String())
	if got := strings.Count(summary, "\n"); got > 30 {
		t.Fatalf("expected at most 30 lines in summary, got %d newlines", got)
	}
	if len([]rune(summary)) > 1500 {
		t.Fatalf("expected summary truncated to 1500 runes, got %d", len([]rune(summary)))
	}
	if !strings.Contains(summary, "line 199 内容") {
		t.Fatalf("expected tail of log retained, got %q", summary)
	}
}

func TestSummarizeTaskFailureOutputKeepsRecentLines(t *testing.T) {
	output := strings.Join([]string{
		"=== 开始执行 [2026-03-22 12:00:00] ===",
		"准备中",
		"请求接口失败",
		"HTTP 500",
		"token expired",
		"=== 执行结束 [2026-03-22 12:00:01] 耗时 1.00 秒 退出码 1 ===",
	}, "\n")

	summary := summarizeTaskFailureOutput(output)
	if strings.Contains(summary, "=== 开始执行") {
		t.Fatalf("expected summary to drop banner lines, got %q", summary)
	}
	if !strings.Contains(summary, "token expired") {
		t.Fatalf("expected summary to keep recent failure details, got %q", summary)
	}
}

func TestSummarizeTaskFailureOutputCondensesPythonTraceback(t *testing.T) {
	output := strings.Join([]string{
		"=== 开始执行 [2026-03-23 00:00:00] ===",
		"Traceback (most recent call last):",
		`  File "/usr/lib/python3.11/asyncio/runners.py", line 190, in run`,
		"    return runner.run(main)",
		"    ^^^^^^^^^^^^^^^^^^^^^^^",
		`  File "/app/Dumb-Panel/scripts/电信营业厅/电信.py", line 1118, in main`,
		"    sign, accId = await getSign(ticket, session)",
		"    ^^^^^^^^^^^",
		"TypeError: cannot unpack non-iterable NoneType object",
	}, "\n")

	summary := summarizeTaskFailureOutput(output)
	if strings.Contains(summary, "asyncio/runners.py") {
		t.Fatalf("expected runtime traceback frames to be removed, got %q", summary)
	}
	if strings.Contains(summary, "^^^^^^^^") {
		t.Fatalf("expected caret indicator lines to be removed, got %q", summary)
	}
	if !strings.Contains(summary, "TypeError: cannot unpack non-iterable NoneType object") {
		t.Fatalf("expected summary to keep final exception, got %q", summary)
	}
	if !strings.Contains(summary, "电信营业厅/电信.py:1118") {
		t.Fatalf("expected summary to keep relevant script frame, got %q", summary)
	}
}

func TestBuildModuleCompatibilityHintRecognizesRequireEsmFailure(t *testing.T) {
	output := strings.Join([]string{
		`const { v4: uuidv4 } = require('uuid');`,
		"                       ^",
		"Error [ERR_REQUIRE_ESM]: require() of ES Module /app/Dumb-Panel/deps/nodejs/node_modules/uuid/dist-node/index.js from /app/Dumb-Panel/scripts/wc.js not supported.",
		"Instead change the require of index.js in /app/Dumb-Panel/scripts/wc.js to a dynamic import() which is available in all CommonJS modules.",
	}, "\n")

	hint := BuildModuleCompatibilityHint(output)
	if hint == "" {
		t.Fatal("expected module compatibility hint to be generated")
	}
	if !strings.Contains(hint, "ESM 模块") {
		t.Fatalf("expected hint to mention ESM module, got %q", hint)
	}
}

func TestSummarizeTaskFailureOutputPrefersModuleCompatibilityHint(t *testing.T) {
	output := strings.Join([]string{
		"[安装成功: uuid]",
		"[依赖已安装 (1/5)，自动重试执行]",
		`const { v4: uuidv4 } = require('uuid');`,
		"Error [ERR_REQUIRE_ESM]: require() of ES Module /app/Dumb-Panel/deps/nodejs/node_modules/uuid/dist-node/index.js from /app/Dumb-Panel/scripts/wc.js not supported.",
		"Instead change the require of index.js in /app/Dumb-Panel/scripts/wc.js to a dynamic import() which is available in all CommonJS modules.",
	}, "\n")

	summary := summarizeTaskFailureOutput(output)
	if !strings.Contains(summary, "ESM 模块") {
		t.Fatalf("expected summary to surface module compatibility hint, got %q", summary)
	}
	if !strings.Contains(summary, "require()") {
		t.Fatalf("expected summary to mention require(), got %q", summary)
	}
}
