package service

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	"daidai-panel/config"
	"daidai-panel/database"
	"daidai-panel/model"
	"daidai-panel/pkg/cron"

	"gorm.io/gorm"
)

type PullCallback func(line string)

func PullSubscription(sub *model.Subscription) (string, error) {
	return PullSubscriptionWithCallback(sub, nil)
}

func PullSubscriptionWithCallback(sub *model.Subscription, onOutput PullCallback) (string, error) {
	return PullSubscriptionWithContext(context.Background(), sub, onOutput)
}

func PullSubscriptionWithContext(ctx context.Context, sub *model.Subscription, onOutput PullCallback) (string, error) {
	if ctx == nil {
		ctx = context.Background()
	}
	startTime := time.Now()

	var sshKeyPath string
	if sub.SSHKeyID != nil {
		var sshKey model.SSHKey
		if err := database.DB.First(&sshKey, *sub.SSHKeyID).Error; err == nil {
			tmpFile, err := writeTempSSHKey(sshKey.PrivateKey)
			if err != nil {
				return "", fmt.Errorf("写入 SSH 密钥失败: %w", err)
			}
			defer os.Remove(tmpFile)
			sshKeyPath = tmpFile
		}
	}
	authCfg, err := buildGitAuthConfig(os.Environ(), sub.URL, sub, sshKeyPath)
	if err != nil {
		return "", err
	}
	defer authCfg.CleanupFunc()

	var fullLog strings.Builder
	emit := func(line string) {
		fullLog.WriteString(line)
		fullLog.WriteString("\n")
		if onOutput != nil {
			onOutput(line)
		}
	}

	emit(fmt.Sprintf("[开始拉取] %s (%s)", sub.Name, sub.Type))

	var output string
	var pullErr error

	switch sub.Type {
	case model.SubTypeSingleFile:
		output, pullErr = pullSingleFileWithCallback(ctx, sub, sshKeyPath, emit)
	default:
		output, pullErr = pullGitRepoWithCallback(ctx, sub, authCfg, emit)
	}

	if pullErr == nil && ctx.Err() != nil {
		pullErr = fmt.Errorf("拉取已停止")
	}
	if pullErr == nil {
		pullErr = runSubscriptionHookIfConfigured(sub, emit)
	}
	if pullErr == nil && ctx.Err() != nil {
		pullErr = fmt.Errorf("拉取已停止")
	}
	if pullErr == nil {
		syncSubscriptionTasks(sub, emit)
	}

	duration := time.Since(startTime).Seconds()

	status := 0
	if pullErr != nil {
		status = 1
		emit(fmt.Sprintf("[错误] %s", pullErr.Error()))
	}

	emit(fmt.Sprintf("[完成] 耗时 %.2f 秒, 状态: %s", duration, map[int]string{0: "成功", 1: "失败"}[status]))

	subLog := model.SubLog{
		SubscriptionID: sub.ID,
		Status:         status,
		Content:        fullLog.String(),
		Duration:       duration,
	}
	database.DB.Create(&subLog)

	now := time.Now()
	database.DB.Model(sub).Updates(map[string]interface{}{
		"last_pull_at": &now,
		"status":       status,
	})

	return output, pullErr
}

func runCmdWithCallback(ctx context.Context, cmd *exec.Cmd, emit PullCallback) (string, error) {
	pipe, err := cmd.StdoutPipe()
	if err != nil {
		return "", err
	}
	cmd.Stderr = cmd.Stdout

	if err := cmd.Start(); err != nil {
		return "", err
	}

	var buf strings.Builder
	scanner := bufio.NewScanner(pipe)
	scanner.Buffer(make([]byte, 64*1024), 256*1024)
	for scanner.Scan() {
		line := scanner.Text()
		buf.WriteString(line)
		buf.WriteString("\n")
		emit(line)
	}
	if scanErr := scanner.Err(); scanErr != nil {
		if ctx != nil && ctx.Err() != nil {
			return buf.String(), fmt.Errorf("拉取已停止")
		}
		return buf.String(), scanErr
	}

	err = cmd.Wait()
	if ctx != nil && ctx.Err() != nil {
		return buf.String(), fmt.Errorf("拉取已停止")
	}
	return buf.String(), err
}

func gitHasWorkingTreeChanges(ctx context.Context, repoDir string, env []string) (bool, error) {
	cmd := exec.CommandContext(ctx, "git", "status", "--porcelain", "--untracked-files=all")
	cmd.Dir = repoDir
	cmd.Env = env

	output, err := cmd.Output()
	if err != nil {
		if ctx != nil && ctx.Err() != nil {
			return false, fmt.Errorf("拉取已停止")
		}
		return false, err
	}

	return strings.TrimSpace(string(output)) != "", nil
}

func pullGitRepoWithCallback(ctx context.Context, sub *model.Subscription, authCfg gitAuthConfig, emit PullCallback) (string, error) {
	saveDir := sub.SaveDir
	if saveDir == "" {
		saveDir = sub.Alias
		if saveDir == "" {
			parts := strings.Split(sub.URL, "/")
			saveDir = strings.TrimSuffix(parts[len(parts)-1], ".git")
		}
	}

	destDir := filepath.Join(config.C.Data.ScriptsDir, saveDir)
	if absDestDir, err := filepath.Abs(destDir); err == nil {
		destDir = absDestDir
	}
	env := authCfg.Env

	if IsGitRepo(destDir) {
		var fullOutput strings.Builder
		branchLabel := "默认分支"
		if strings.TrimSpace(sub.Branch) != "" {
			branchLabel = strings.TrimSpace(sub.Branch)
		}

		emit(fmt.Sprintf("[检测到已有仓库] %s 已存在 Git 仓库，接下来会同步远端并覆盖更新本地文件", saveDir))
		emit(fmt.Sprintf("[同步远端地址] 正在校正订阅地址 -> %s", authCfg.DisplayURL))
		output, err := syncGitRemoteWithCallback(ctx, destDir, authCfg.RemoteURL, env, emit)
		fullOutput.WriteString(output)
		if err != nil {
			return fullOutput.String(), err
		}

		fetchArgs := []string{"fetch", "--depth", "1", "--prune", "origin"}
		if strings.TrimSpace(sub.Branch) != "" {
			fetchArgs = append(fetchArgs, strings.TrimSpace(sub.Branch))
		}
		emit(fmt.Sprintf("[拉取远端更新] 正在获取分支 %s 的最新提交", branchLabel))
		cmd := exec.CommandContext(ctx, "git", fetchArgs...)
		cmd.Dir = destDir
		cmd.Env = env
		output, err = runCmdWithCallback(ctx, cmd, emit)
		fullOutput.WriteString(output)
		if err != nil {
			return fullOutput.String(), err
		}

		if err := applySparseCheckout(ctx, destDir, sub.SubPath, env, emit); err != nil {
			return fullOutput.String(), err
		}

		forceOverwrite := sub.ForceOverwrite == nil || *sub.ForceOverwrite
		if forceOverwrite {
			emit("[覆盖更新本地文件] 正在用远端最新提交覆盖当前订阅目录中的仓库内容")
			cmd = exec.CommandContext(ctx, "git", "reset", "--hard", "FETCH_HEAD")
			cmd.Dir = destDir
			cmd.Env = env
			output, err = runCmdWithCallback(ctx, cmd, emit)
			fullOutput.WriteString(output)
			if err != nil {
				return fullOutput.String(), err
			}

			emit("[清理旧文件] 正在删除远端仓库已移除、但本地仍残留的文件和目录")
			cmd = exec.CommandContext(ctx, "git", "clean", "-fd")
			cmd.Dir = destDir
			cmd.Env = env
			output, err = runCmdWithCallback(ctx, cmd, emit)
			fullOutput.WriteString(output)
		} else {
			emit("[保留本地修改] 正在合并远端更新（保留本地修改的文件）")
			hasStash, err := gitHasWorkingTreeChanges(ctx, destDir, env)
			if err != nil {
				return fullOutput.String(), err
			}
			if hasStash {
				cmd = exec.CommandContext(ctx, "git", "stash", "push", "--include-untracked", "-m", "daidai-panel-subscription-update")
				cmd.Dir = destDir
				cmd.Env = env
				output, err = runCmdWithCallback(ctx, cmd, emit)
				fullOutput.WriteString(output)
				if err != nil {
					return fullOutput.String(), err
				}
			} else {
				emit("[保留本地修改] 未检测到本地改动，跳过暂存恢复")
			}

			cmd = exec.CommandContext(ctx, "git", "reset", "--hard", "FETCH_HEAD")
			cmd.Dir = destDir
			cmd.Env = env
			output, err = runCmdWithCallback(ctx, cmd, emit)
			fullOutput.WriteString(output)
			if err != nil {
				return fullOutput.String(), err
			}

			if hasStash {
				emit("[恢复本地修改] 正在恢复之前暂存的本地修改")
				cmd = exec.CommandContext(ctx, "git", "stash", "pop")
				cmd.Dir = destDir
				cmd.Env = env
				output, err = runCmdWithCallback(ctx, cmd, emit)
				fullOutput.WriteString(output)
				if err != nil {
					emit("[提示] 本地修改与远端更新存在冲突，请手动处理")
				}
			}
		}
		return fullOutput.String(), err
	}

	if destInfo, err := os.Stat(destDir); err == nil {
		if !destInfo.IsDir() {
			return "", fmt.Errorf("保存目录已被文件占用: %s", saveDir)
		}

		entries, readErr := os.ReadDir(destDir)
		if readErr != nil {
			return "", fmt.Errorf("读取保存目录失败: %w", readErr)
		}
		if len(entries) > 0 {
			var fullOutput strings.Builder
			branchLabel := "默认分支"
			if strings.TrimSpace(sub.Branch) != "" {
				branchLabel = strings.TrimSpace(sub.Branch)
			}

			emit(fmt.Sprintf("[检测到已存在脚本目录] %s 当前不是 Git 仓库，接下来会原地初始化仓库并覆盖本地文件", saveDir))
			emit("[git init] 正在初始化本地仓库")
			cmd := exec.CommandContext(ctx, "git", "init")
			cmd.Dir = destDir
			cmd.Env = env
			output, err := runCmdWithCallback(ctx, cmd, emit)
			fullOutput.WriteString(output)
			if err != nil {
				return fullOutput.String(), err
			}

			emit(fmt.Sprintf("[同步远端地址] 正在校正订阅地址 -> %s", authCfg.DisplayURL))
			output, err = syncGitRemoteWithCallback(ctx, destDir, authCfg.RemoteURL, env, emit)
			fullOutput.WriteString(output)
			if err != nil {
				return fullOutput.String(), err
			}

			fetchArgs := []string{"fetch", "--depth", "1", "--prune", "origin"}
			if strings.TrimSpace(sub.Branch) != "" {
				fetchArgs = append(fetchArgs, strings.TrimSpace(sub.Branch))
			}
			emit(fmt.Sprintf("[拉取远端更新] 正在获取分支 %s 的最新提交", branchLabel))
			cmd = exec.CommandContext(ctx, "git", fetchArgs...)
			cmd.Dir = destDir
			cmd.Env = env
			output, err = runCmdWithCallback(ctx, cmd, emit)
			if err != nil {
				fullOutput.WriteString(output)
				return fullOutput.String(), err
			}
			fullOutput.WriteString(output)
			if ctx.Err() != nil {
				return fullOutput.String(), fmt.Errorf("拉取已停止")
			}

			if err := applySparseCheckout(ctx, destDir, sub.SubPath, env, emit); err != nil {
				return fullOutput.String(), err
			}

			forceOverwrite := sub.ForceOverwrite == nil || *sub.ForceOverwrite
			emit("[覆盖更新本地文件] 正在用远端最新提交覆盖当前脚本目录内容")
			cmd = exec.CommandContext(ctx, "git", "reset", "--hard", "FETCH_HEAD")
			cmd.Dir = destDir
			cmd.Env = env
			output, err = runCmdWithCallback(ctx, cmd, emit)
			fullOutput.WriteString(output)
			if err != nil {
				return fullOutput.String(), err
			}

			if forceOverwrite {
				emit("[清理旧文件] 正在删除远端仓库已移除、但本地仍残留的文件和目录")
				cmd = exec.CommandContext(ctx, "git", "clean", "-fd")
				cmd.Dir = destDir
				cmd.Env = env
				output, err = runCmdWithCallback(ctx, cmd, emit)
				fullOutput.WriteString(output)
				if err != nil {
					return fullOutput.String(), err
				}
			} else {
				emit("[保留本地文件] 跳过清理本地多余文件")
			}
			return fullOutput.String(), nil
		}
	}

	emit(fmt.Sprintf("[git clone] %s -> %s", authCfg.DisplayURL, saveDir))
	os.MkdirAll(destDir, 0755)
	args := []string{"clone", "--depth", "1"}
	if sub.Branch != "" {
		args = append(args, "-b", sub.Branch)
	}
	args = append(args, authCfg.RemoteURL, destDir)
	cmd := exec.CommandContext(ctx, "git", args...)
	cmd.Dir = config.C.Data.ScriptsDir
	cmd.Env = env
	output, err := runCmdWithCallback(ctx, cmd, emit)
	if err != nil {
		return output, err
	}
	if spErr := applySparseCheckout(ctx, destDir, sub.SubPath, env, emit); spErr != nil {
		return output, spErr
	}
	return output, nil
}

func applySparseCheckout(ctx context.Context, repoDir string, subPath string, env []string, emit PullCallback) error {
	subPath = strings.TrimSpace(subPath)
	if subPath == "" {
		return nil
	}

	var paths []string
	for _, p := range strings.Split(subPath, ",") {
		p = strings.TrimSpace(p)
		if p != "" {
			paths = append(paths, p)
		}
	}
	if len(paths) == 0 {
		return nil
	}

	emit(fmt.Sprintf("[sparse-checkout] 设置子目录过滤: %s", strings.Join(paths, ", ")))

	cmd := exec.CommandContext(ctx, "git", "sparse-checkout", "init", "--cone")
	cmd.Dir = repoDir
	cmd.Env = env
	if _, err := runCmdWithCallback(ctx, cmd, emit); err != nil {
		return fmt.Errorf("sparse-checkout init 失败: %w", err)
	}

	args := append([]string{"sparse-checkout", "set"}, paths...)
	cmd = exec.CommandContext(ctx, "git", args...)
	cmd.Dir = repoDir
	cmd.Env = env
	if _, err := runCmdWithCallback(ctx, cmd, emit); err != nil {
		return fmt.Errorf("sparse-checkout set 失败: %w", err)
	}

	return nil
}

func pullSingleFileWithCallback(ctx context.Context, sub *model.Subscription, _ string, emit PullCallback) (string, error) {
	saveDir := sub.SaveDir
	if saveDir == "" {
		saveDir = "downloads"
	}

	parts := strings.Split(sub.URL, "/")
	filename := parts[len(parts)-1]
	if sub.Alias != "" {
		filename = sub.Alias
	}

	destPath := filepath.Join(config.C.Data.ScriptsDir, saveDir, filename)
	emit(fmt.Sprintf("[下载] %s -> %s/%s", sub.URL, saveDir, filename))
	output, err := DownloadFileWithContext(ctx, sub.URL, destPath)
	if output != "" {
		emit(output)
	}
	return output, err
}

func syncGitRemoteWithCallback(ctx context.Context, repoDir, remoteURL string, env []string, emit PullCallback) (string, error) {
	cmd := exec.CommandContext(ctx, "git", "remote")
	cmd.Dir = repoDir
	cmd.Env = env

	remoteOutput, err := cmd.Output()
	if err != nil {
		return "", err
	}

	args := []string{"remote", "add", "origin", remoteURL}
	for _, name := range strings.Fields(string(remoteOutput)) {
		if name == "origin" {
			args = []string{"remote", "set-url", "origin", remoteURL}
			break
		}
	}

	cmd = exec.CommandContext(ctx, "git", args...)
	cmd.Dir = repoDir
	cmd.Env = env
	return runCmdWithCallback(ctx, cmd, emit)
}

func writeTempSSHKey(privateKey string) (string, error) {
	tmpFile, err := os.CreateTemp("", "ssh_key_*")
	if err != nil {
		return "", err
	}
	defer tmpFile.Close()

	if _, err := tmpFile.WriteString(privateKey); err != nil {
		os.Remove(tmpFile.Name())
		return "", err
	}

	os.Chmod(tmpFile.Name(), 0600)
	return tmpFile.Name(), nil
}

var (
	// 兼容多种 cron 声明前缀：
	//   cron: 30 8 * * *
	//   # cron: 30 8 * * *
	//   #cron 8 9,10,11 * * *
	//   cron 0 12 * * *
	//   * cron 8 10 * * *           (JSDoc 块注释每行的 `*` 前缀)
	//   * cron: 12 8 * * *
	//   @cron: 30 8 * * *           (JSDoc `@cron` 标签)
	//   * @cron 0 0 * * *
	//   // cron: 0 0 * * *
	// 通过 `\b` 词界避免误匹配 `crontab` / `cron-utils` 等关键字。
	cronLabelPrefixRe      = regexp.MustCompile(`(?im)^[\s#*@/]*@?cron\b\s*[:：]?\s*(\S.*)$`)
	subscriptionTaskNameRe = regexp.MustCompile(`new\s+Env\s*\(\s*['"` + "`" + `]([^'"` + "`" + `]+)['"` + "`" + `]\s*\)`)
	// 青龙风格 `cron "EXPR" filename, tag:xxx` 单行声明，常见于 JS 顶部注释。
	// 例如：cron "6 6 6 6 *" jd_CheckCK.js, tag:京东CK检测by-ccwav
	cronDirectiveLineRe = regexp.MustCompile(`(?i)\bcron\s+["']([^"'\n\r]+)["']\s+([^\s,;]+)`)
)

type subscriptionTaskSyncOptions struct {
	autoAdd     bool
	autoDelete  bool
	defaultCron string
	allowedExts map[string]bool
}

type subscriptionTaskCandidate struct {
	Name           string
	Command        string
	CronExpression string
}

func subscriptionTaskLabel(subID uint) string {
	return fmt.Sprintf("subscription:%d", subID)
}

func hasLabel(labels []string, target string) bool {
	for _, item := range labels {
		if item == target {
			return true
		}
	}
	return false
}

func withLabel(labels []string, target string) []string {
	if hasLabel(labels, target) {
		return labels
	}
	return append(labels, target)
}

func subscriptionSaveDir(sub *model.Subscription) string {
	saveDir := sub.SaveDir
	if saveDir == "" {
		saveDir = sub.Alias
		if saveDir == "" {
			parts := strings.Split(sub.URL, "/")
			saveDir = strings.TrimSuffix(parts[len(parts)-1], ".git")
		}
	}
	return saveDir
}

func matchesSubscriptionFilters(sub *model.Subscription, filename string) bool {
	if sub.Whitelist != "" {
		matched := false
		for _, pattern := range strings.Split(sub.Whitelist, ",") {
			pattern = strings.TrimSpace(pattern)
			if pattern != "" && strings.Contains(filename, pattern) {
				matched = true
				break
			}
		}
		if !matched {
			return false
		}
	}
	if sub.Blacklist != "" {
		for _, pattern := range strings.Split(sub.Blacklist, ",") {
			pattern = strings.TrimSpace(pattern)
			if pattern != "" && strings.Contains(filename, pattern) {
				return false
			}
		}
	}
	return true
}

func syncSubscriptionTasks(sub *model.Subscription, emit PullCallback) {
	options := getSubscriptionTaskSyncOptions(sub)
	if !options.autoAdd && !options.autoDelete {
		emit("[跳过自动同步任务] 订阅与系统设置中均未启用 auto_add_cron / auto_del_cron")
		return
	}

	saveDir := subscriptionSaveDir(sub)
	scriptsDir := filepath.Join(config.C.Data.ScriptsDir, saveDir)
	candidates := collectSubscriptionTaskCandidates(sub, options)
	label := subscriptionTaskLabel(sub.ID)

	// 可观测兜底：v2.2.8 之前任何空候选 / DB 创建失败都被静默吞掉，用户只看到
	// "[完成]" 就以为同步成功了。这里把每一步都打日志出来。
	scannedFileCount := countSubscriptionScriptFiles(scriptsDir, options.allowedExts, sub)
	emit(fmt.Sprintf("[扫描脚本] 目录 %s 共扫描 %d 个候选文件（按白/黑名单过滤后），识别出 %d 个含 cron 的脚本",
		scriptsDir, scannedFileCount, len(candidates)))
	if len(candidates) == 0 && scannedFileCount > 0 {
		emit("[提示] 仓库内有脚本但没有识别到 cron 表达式：请检查脚本头部是否含 `cron <表达式>` 注释，或在系统设置 default_cron_rule 里配置默认 cron")
	}

	var managedTasks []model.Task
	queryTasksByLabel(label).Find(&managedTasks)
	managedByCommand := make(map[string]*model.Task, len(managedTasks))
	for i := range managedTasks {
		managedByCommand[strings.TrimSpace(managedTasks[i].Command)] = &managedTasks[i]
	}

	created := 0
	updated := 0
	deleted := 0
	adopted := 0
	failed := 0

	if options.autoAdd {
		for command, candidate := range candidates {
			if existing, ok := managedByCommand[command]; ok {
				changes := map[string]interface{}{}
				if existing.Name != candidate.Name {
					changes["name"] = candidate.Name
					existing.Name = candidate.Name
				}
				if existing.CronExpression != candidate.CronExpression {
					changes["cron_expression"] = candidate.CronExpression
					existing.CronExpression = candidate.CronExpression
				}
				if len(changes) > 0 {
					if err := database.DB.Model(existing).Updates(changes).Error; err != nil {
						failed++
						emit(fmt.Sprintf("[自动更新任务失败] %s: %v", candidate.Name, err))
					} else {
						GetSchedulerV2().UpdateJob(existing)
						updated++
						emit(fmt.Sprintf("[自动更新任务] %s (cron: %s)", candidate.Name, candidate.CronExpression))
					}
				}
				continue
			}

			var existing model.Task
			if err := database.DB.Where("command = ?", command).First(&existing).Error; err == nil {
				labels := withLabel(existing.GetLabels(), label)
				existing.SetLabelsFromSlice(labels)
				if err := database.DB.Model(&existing).Update("labels", existing.Labels).Error; err != nil {
					failed++
					emit(fmt.Sprintf("[关联已有任务失败] %s: %v", existing.Name, err))
				} else {
					managedByCommand[command] = &existing
					adopted++
					emit(fmt.Sprintf("[关联已有任务] %s", existing.Name))
				}
				continue
			}

			task := model.Task{
				Name:            candidate.Name,
				Command:         candidate.Command,
				CronExpression:  candidate.CronExpression,
				TaskType:        model.TaskTypeCron,
				Status:          model.TaskStatusEnabled,
				Timeout:         86400,
				NotifyOnFailure: true,
			}
			task.SetLabelsFromSlice([]string{label})
			if err := database.DB.Select("*").Create(&task).Error; err != nil {
				failed++
				emit(fmt.Sprintf("[自动添加任务失败] %s (cron: %s) command=%s err=%v",
					candidate.Name, candidate.CronExpression, candidate.Command, err))
			} else {
				GetSchedulerV2().AddJob(&task)
				managedByCommand[command] = &task
				created++
				emit(fmt.Sprintf("[自动添加任务] %s (cron: %s)", candidate.Name, candidate.CronExpression))
			}
		}
	}

	if options.autoDelete {
		for _, task := range managedTasks {
			command := strings.TrimSpace(task.Command)
			if !strings.HasPrefix(command, "task ") {
				continue
			}
			if _, ok := candidates[command]; ok {
				continue
			}

			GetSchedulerV2().RemoveJob(task.ID)
			database.DB.Where("task_id = ?", task.ID).Delete(&model.TaskLog{})
			database.DB.Delete(&task)
			deleted++
			emit(fmt.Sprintf("[自动删除任务] %s", task.Name))
		}
	}

	if created > 0 {
		emit(fmt.Sprintf("[共自动添加 %d 个定时任务]", created))
	}
	if updated > 0 {
		emit(fmt.Sprintf("[共自动更新 %d 个定时任务]", updated))
	}
	if adopted > 0 {
		emit(fmt.Sprintf("[共关联 %d 个已有任务]", adopted))
	}
	if deleted > 0 {
		emit(fmt.Sprintf("[共自动删除 %d 个失效任务]", deleted))
	}
	if failed > 0 {
		emit(fmt.Sprintf("[警告] 共 %d 个任务操作失败，详见上方日志", failed))
	}
	if created == 0 && updated == 0 && adopted == 0 && deleted == 0 && failed == 0 {
		emit("[同步完成] 本次未对定时任务做任何变更")
	}
}

// countSubscriptionScriptFiles 统计 scriptsDir 下符合扩展名 + 白/黑名单过滤的文件数。
// 仅用于日志可观测：让用户知道"扫到了 X 个候选文件、识别出 Y 个 cron"——
// 当 X>0 而 Y=0 时能立刻看出是 cron 解析问题而不是路径问题。
func countSubscriptionScriptFiles(scriptsDir string, allowedExts map[string]bool, sub *model.Subscription) int {
	if _, err := os.Stat(scriptsDir); err != nil {
		return 0
	}
	count := 0
	filepath.Walk(scriptsDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil
		}
		if info.IsDir() {
			switch strings.ToLower(info.Name()) {
			case ".git", "node_modules", "__pycache__":
				return filepath.SkipDir
			}
			return nil
		}
		if shouldManageSubscriptionFile(sub, info.Name(), allowedExts) {
			count++
		}
		return nil
	})
	return count
}

// FallbackSubscriptionCron 是订阅脚本未声明 cron 时使用的"硬兜底"。
// 用户既没在脚本头部写 cron 注释、也没在系统设置 default_cron_rule 里配自定义默认值时，
// 用这个兜底——每天 0 点跑一次，保证 git 拉到的脚本都会变成定时任务。
// 用户可以在任务详情里手动改 cron，或者把脚本注释加上 cron 头让下次同步用真值覆盖。
const FallbackSubscriptionCron = "0 0 * * *"

func getSubscriptionTaskSyncOptions(sub *model.Subscription) subscriptionTaskSyncOptions {
	defaultCron := strings.TrimSpace(model.GetRegisteredConfig("default_cron_rule"))
	if defaultCron != "" && !cron.Parse(defaultCron).Valid {
		defaultCron = ""
	}
	// 系统设置里 default_cron_rule 是空时，落到硬兜底。这是用户"git 拉了但一个任务都没建"
	// 困惑的根因：原默认是 "" → cron 头没识别就 skip，整个仓库一个任务都建不出来。
	// v2.2.10 起改为：默认兜底 = 每天 0 点。用户想关闭兜底，可以把 default_cron_rule
	// 设成非法值（比如 "off"），代码会回退到 "" 然后跳过没 cron 的脚本。
	if defaultCron == "" {
		defaultCron = FallbackSubscriptionCron
	}

	return subscriptionTaskSyncOptions{
		autoAdd:     sub.AutoAddTask || isConfigEnabled("auto_add_cron", true),
		autoDelete:  sub.AutoDelTask || isConfigEnabled("auto_del_cron", true),
		defaultCron: defaultCron,
		allowedExts: getSubscriptionAllowedExtensions(model.GetRegisteredConfig("repo_file_extensions")),
	}
}

func isConfigEnabled(key string, defaultValue bool) bool {
	if _, exists := model.GetSystemConfigDefinition(key); exists {
		return model.GetRegisteredConfigBool(key)
	}
	return model.GetConfigBool(key, defaultValue)
}

func getSubscriptionAllowedExtensions(raw string) map[string]bool {
	exts := make(map[string]bool)
	for _, token := range strings.FieldsFunc(raw, func(r rune) bool {
		return r == ',' || r == ';' || r == '\n' || r == '\r' || r == '\t' || r == ' '
	}) {
		token = strings.TrimSpace(strings.ToLower(token))
		token = strings.TrimPrefix(token, "*")
		if token == "" {
			continue
		}
		if !strings.HasPrefix(token, ".") {
			token = "." + token
		}
		exts[token] = true
	}
	if len(exts) > 0 {
		return exts
	}

	return map[string]bool{
		".js": true,
		".mjs": true,
		".ts": true,
		".py": true,
		".sh": true,
	}
}

// subscriptionHelperScriptNames 列出"通知辅助脚本"——这些脚本本身不是定时任务，
// 而是被业务脚本 require/import 调用的工具。订阅同步时不应该为它们建定时任务，
// 即使没有 cron 头并且系统配置了 default_cron_rule 兜底也不建。
// 名字按"去掉扩展名后的 basename，小写"匹配。
var subscriptionHelperScriptNames = map[string]bool{
	"sendnotify":   true, // QLScriptPublic / jdpro 风格的通知 helper（多种大小写拼写都收）
	"sendnofity":   true, // 实际仓库里 sendNofity.js 这种笔误也常见
	"notify":       true, // 青龙原版 notify.py
	"sendnotify_":  true, // sendNotify_.js 这种带下划线后缀的变体
	"jdcookie":     true,
	"ql":           true,
	"qlapi":        true,
	"utils":        true,
	"util":         true,
	"common":       true,
	"helper":       true,
	"sign":         true, // 通用签名 helper
	"magic":        true, // jd_magic 类
	"jsencrypt":    true,
	"cryptojs":     true,
}

// isSubscriptionHelperScript 判断"该脚本是不是被业务脚本调用的辅助脚本"。
// 注意：只在脚本本身没有 cron 头注释时才用——脚本明确写了 cron 表达式
// 视为用户主动声明"这是定时任务"，必须建。
func isSubscriptionHelperScript(filename string) bool {
	base := strings.ToLower(strings.TrimSuffix(filename, filepath.Ext(filename)))
	return subscriptionHelperScriptNames[base]
}

func shouldManageSubscriptionFile(sub *model.Subscription, filename string, allowedExts map[string]bool) bool {
	ext := strings.ToLower(filepath.Ext(filename))
	if !allowedExts[ext] {
		return false
	}
	return matchesSubscriptionFilters(sub, filename)
}

func collectSubscriptionTaskCandidates(sub *model.Subscription, options subscriptionTaskSyncOptions) map[string]subscriptionTaskCandidate {
	candidates := make(map[string]subscriptionTaskCandidate)
	saveDir := subscriptionSaveDir(sub)
	scriptsDir := filepath.Join(config.C.Data.ScriptsDir, saveDir)

	if _, err := os.Stat(scriptsDir); err != nil {
		return candidates
	}

	filepath.Walk(scriptsDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil
		}
		if info.IsDir() {
			switch strings.ToLower(info.Name()) {
			case ".git", "node_modules", "__pycache__":
				return filepath.SkipDir
			}
			return nil
		}

		if !shouldManageSubscriptionFile(sub, info.Name(), options.allowedExts) {
			return nil
		}

		// 先尝试从脚本头部识别 cron。脚本明确写了 cron 就完全按它来。
		cronExpr := resolveCronForSubscriptionTask(path, "")
		if cronExpr == "" {
			// 脚本头没 cron 注释。两种处理：
			//   1) 已知是通知/工具辅助脚本（sendNotify.js / notify.py 等）→ 不建任务
			//   2) 否则用兜底 cron（系统配置 default_cron_rule，或硬兜底每天 0 点）
			//      —— 保证 git 拉到的业务脚本必定变成任务，不会"明明拉成功但任务列表空"
			if isSubscriptionHelperScript(info.Name()) {
				return nil
			}
			cronExpr = options.defaultCron
			if cronExpr == "" {
				return nil
			}
		}

		relPath, err := filepath.Rel(config.C.Data.ScriptsDir, path)
		if err != nil {
			return nil
		}
		command := "task " + relPath
		taskName := resolveSubscriptionTaskName(path, strings.TrimSuffix(info.Name(), filepath.Ext(info.Name())))
		candidates[command] = subscriptionTaskCandidate{
			Name:           taskName,
			Command:        command,
			CronExpression: cronExpr,
		}
		return nil
	})

	return candidates
}

func queryTasksByLabel(label string) *gorm.DB {
	return database.DB.Where(
		"labels = ? OR labels LIKE ? OR labels LIKE ? OR labels LIKE ?",
		label,
		label+",%",
		"%,"+label,
		"%,"+label+",%",
	)
}

func resolveCronForSubscriptionTask(path string, defaultCron string) string {
	f, err := os.Open(path)
	if err != nil {
		return ""
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	lineCount := 0
	scriptBase := strings.ToLower(filepath.Base(path))
	for scanner.Scan() {
		lineCount++
		if lineCount > 50 {
			break
		}
		line := scanner.Text()
		if expr := extractSubscriptionCronExpression(line, scriptBase); expr != "" {
			return expr
		}
	}
	return strings.TrimSpace(defaultCron)
}

func resolveSubscriptionTaskName(path, fallback string) string {
	fallback = strings.TrimSpace(fallback)

	f, err := os.Open(path)
	if err != nil {
		return fallback
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	lineCount := 0
	for scanner.Scan() {
		lineCount++
		if lineCount > 120 {
			break
		}

		if matches := subscriptionTaskNameRe.FindStringSubmatch(scanner.Text()); len(matches) > 1 {
			name := strings.TrimSpace(matches[1])
			if name != "" {
				return name
			}
		}
	}

	return fallback
}

func extractSubscriptionCronExpression(line, scriptBase string) string {
	if expr := extractSubscriptionCronExpressionFromLabel(line); expr != "" {
		return expr
	}

	if matches := cronDirectiveLineRe.FindStringSubmatch(line); len(matches) > 2 && scriptBase != "" {
		expr := strings.TrimSpace(matches[1])
		fileToken := normalizeSubscriptionCronScriptToken(matches[2])
		if fileToken != "" &&
			strings.EqualFold(filepath.Base(fileToken), scriptBase) &&
			cron.Parse(expr).Valid {
			return expr
		}
	}

	return extractSubscriptionCronExpressionFromFilenameLine(line, scriptBase)
}

// extractSubscriptionCronExpressionFromLabel 处理“cron”标签开头的行，
// 兼容 `cron:`、`cron`（无冒号）、JSDoc `* cron`、`@cron:` 等多种写法。
// 当行尾跟随文件名提示（例如 `cron 8 10 * * *  qtx.js`）时，只截取前 5 或 6 个字段做 cron。
func extractSubscriptionCronExpressionFromLabel(line string) string {
	matches := cronLabelPrefixRe.FindStringSubmatch(line)
	if len(matches) < 2 {
		return ""
	}
	rest := strings.TrimSpace(matches[1])
	if rest == "" {
		return ""
	}

	if cron.Parse(rest).Valid {
		return rest
	}

	fields := strings.Fields(rest)
	for _, cnt := range []int{6, 5} {
		if len(fields) < cnt {
			continue
		}
		expr := strings.Join(fields[:cnt], " ")
		if cron.Parse(expr).Valid {
			return expr
		}
	}
	return ""
}

func extractSubscriptionCronExpressionFromFilenameLine(line, scriptBase string) string {
	trimmed := strings.TrimSpace(line)
	if trimmed == "" || scriptBase == "" {
		return ""
	}

	cleaned := strings.TrimSpace(strings.Trim(trimmed, `"'`))
	fields := strings.Fields(cleaned)
	if len(fields) < 6 {
		return ""
	}

	for _, cronFieldCount := range []int{6, 5} {
		if len(fields) <= cronFieldCount {
			continue
		}

		expr := strings.Join(fields[:cronFieldCount], " ")
		if !cron.Parse(expr).Valid {
			continue
		}

		fileToken := normalizeSubscriptionCronScriptToken(fields[cronFieldCount])
		if fileToken == "" {
			continue
		}

		if strings.EqualFold(filepath.Base(fileToken), scriptBase) {
			return expr
		}
	}

	return ""
}

func normalizeSubscriptionCronScriptToken(token string) string {
	token = strings.TrimSpace(token)
	token = strings.Trim(token, `"'`)
	token = strings.TrimRight(token, ",;:)")
	token = strings.TrimLeft(token, "(")
	return strings.TrimSpace(token)
}
