package handler

import (
	"fmt"
	"net/http"
	"strings"

	"daidai-panel/database"
	"daidai-panel/model"
	panelcron "daidai-panel/pkg/cron"
	"daidai-panel/pkg/response"

	"github.com/gin-gonic/gin"
)

func (h *TaskHandler) Export(c *gin.Context) {
	var tasks []model.Task
	database.DB.Find(&tasks)
	notificationChannels := loadTaskNotificationChannelMap(tasks)

	data := make([]map[string]interface{}, len(tasks))
	for i, task := range tasks {
		var notificationChannelName string
		if task.NotificationChannelID != nil {
			if channel, exists := notificationChannels[*task.NotificationChannelID]; exists {
				notificationChannelName = channel.Name
			}
		}
		data[i] = map[string]interface{}{
			"name":                      task.Name,
			"command":                   task.Command,
			"cron_expression":           task.CronExpression,
			"task_type":                 task.GetTaskType(),
			"status":                    task.Status,
			"labels":                    task.GetLabels(),
			"timeout":                   task.Timeout,
			"random_delay_seconds":      task.RandomDelaySeconds,
			"max_retries":               task.MaxRetries,
			"retry_interval":            task.RetryInterval,
			"notify_on_failure":         task.NotifyOnFailure,
			"notify_on_success":         task.NotifyOnSuccess,
			"notification_channel_id":   task.NotificationChannelID,
			"notification_channel_name": notificationChannelName,
			"depends_on":                task.DependsOn,
			"sort_order":                task.SortOrder,
			"task_before":               task.TaskBefore,
			"task_after":                task.TaskAfter,
			"allow_multiple_instances":  task.AllowMultipleInstances,
		}
	}
	response.Success(c, gin.H{"data": data})
}

func (h *TaskHandler) Import(c *gin.Context) {
	var req struct {
		Tasks []map[string]interface{} `json:"tasks" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "请求参数错误")
		return
	}

	imported := 0
	errors := make([]string, 0)

	for i, taskData := range req.Tasks {
		name, _ := taskData["name"].(string)
		command, _ := taskData["command"].(string)
		cronExpr, _ := taskData["cron_expression"].(string)
		taskType := model.TaskTypeCron
		if rawTaskType, ok := taskData["task_type"].(string); ok && strings.TrimSpace(rawTaskType) != "" {
			taskType = model.NormalizeTaskType(rawTaskType)
		} else if strings.TrimSpace(cronExpr) == "" {
			taskType = model.TaskTypeManual
		}

		if name == "" || command == "" {
			errors = append(errors, fmt.Sprintf("任务 %d: 缺少必填字段", i+1))
			continue
		}
		if taskType == "" {
			errors = append(errors, fmt.Sprintf("任务 %d: 无效的任务类型", i+1))
			continue
		}
		if taskType == model.TaskTypeCron {
			result := panelcron.Parse(cronExpr)
			if !result.Valid {
				errors = append(errors, fmt.Sprintf("任务 %d: 无效的 cron 表达式", i+1))
				continue
			}
		} else {
			cronExpr = ""
		}

		task := model.Task{
			Name:            name,
			Command:         command,
			CronExpression:  cronExpr,
			TaskType:        taskType,
			Status:          model.TaskStatusDisabled,
			Timeout:         86400,
			RetryInterval:   60,
			NotifyOnFailure: true,
		}

		if value, ok := taskData["timeout"].(float64); ok {
			task.Timeout = int(value)
		}
		if value, exists := taskData["random_delay_seconds"]; exists {
			randomDelayValue, err := normalizeTaskRandomDelaySecondsValue(value)
			if err != nil {
				errors = append(errors, fmt.Sprintf("任务 %d: %s", i+1, err.Error()))
				continue
			}
			task.RandomDelaySeconds = randomDelayValue
		}
		if value, ok := taskData["max_retries"].(float64); ok {
			task.MaxRetries = int(value)
		}
		if value, ok := taskData["retry_interval"].(float64); ok {
			task.RetryInterval = int(value)
		}
		if value, ok := taskData["notify_on_failure"].(bool); ok {
			task.NotifyOnFailure = value
		}
		if value, ok := taskData["notify_on_success"].(bool); ok {
			task.NotifyOnSuccess = value
		}
		if channelID, warningMessage, err := resolveImportedTaskNotificationChannel(taskData); err != nil {
			errors = append(errors, fmt.Sprintf("任务 %d: 解析通知渠道失败: %s", i+1, err.Error()))
		} else {
			task.NotificationChannelID = channelID
			if warningMessage != "" {
				errors = append(errors, fmt.Sprintf("任务 %d: %s", i+1, warningMessage))
			}
		}
		if labels, ok := taskData["labels"].([]interface{}); ok {
			values := make([]string, len(labels))
			for j, label := range labels {
				values[j] = fmt.Sprintf("%v", label)
			}
			task.SetLabelsFromSlice(values)
		}
		if value, ok := taskData["task_before"].(string); ok {
			task.TaskBefore = &value
		}
		if value, ok := taskData["task_after"].(string); ok {
			task.TaskAfter = &value
		}

		if err := database.DB.Select("*").Create(&task).Error; err != nil {
			errors = append(errors, fmt.Sprintf("task %d: %s", i+1, err.Error()))
			continue
		}
		imported++
	}

	if imported == 0 && len(errors) > 0 {
		response.BadRequest(c, "没有成功导入任何任务")
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": fmt.Sprintf("成功导入 %d 个任务", imported),
		"errors":  errors,
	})
}
