package handler

import (
	"fmt"
	"strconv"
	"strings"

	"daidai-panel/database"
	"daidai-panel/model"
	panelcron "daidai-panel/pkg/cron"
	"daidai-panel/pkg/response"
	"daidai-panel/service"

	"github.com/gin-gonic/gin"
)

func normalizeTaskRandomDelaySecondsValue(value interface{}) (*int, error) {
	if value == nil {
		return nil, nil
	}

	switch typed := value.(type) {
	case float64:
		delay := int(typed)
		if float64(delay) != typed {
			return nil, fmt.Errorf("随机延迟最大秒数必须为整数")
		}
		if delay < 0 || delay > 86400 {
			return nil, fmt.Errorf("随机延迟最大秒数需在 0-86400 之间")
		}
		return &delay, nil
	case int:
		if typed < 0 || typed > 86400 {
			return nil, fmt.Errorf("随机延迟最大秒数需在 0-86400 之间")
		}
		delay := typed
		return &delay, nil
	default:
		return nil, fmt.Errorf("随机延迟最大秒数无效")
	}
}

func (h *TaskHandler) Create(c *gin.Context) {
	var req struct {
		Name                   string   `json:"name" binding:"required"`
		Command                string   `json:"command" binding:"required"`
		CronExpression         string   `json:"cron_expression"`
		TaskType               string   `json:"task_type"`
		Timeout                *int     `json:"timeout"`
		RandomDelaySeconds     *int     `json:"random_delay_seconds"`
		MaxRetries             *int     `json:"max_retries"`
		RetryInterval          *int     `json:"retry_interval"`
		NotifyOnFailure        *bool    `json:"notify_on_failure"`
		NotifyOnSuccess        *bool    `json:"notify_on_success"`
		NotificationChannelID  *uint    `json:"notification_channel_id"`
		Labels                 []string `json:"labels"`
		DependsOn              *uint    `json:"depends_on"`
		TaskBefore             *string  `json:"task_before"`
		TaskAfter              *string  `json:"task_after"`
		AllowMultipleInstances *bool    `json:"allow_multiple_instances"`
		StopSchedule           *string  `json:"stop_schedule"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "请求参数错误")
		return
	}

	taskType := model.NormalizeTaskType(req.TaskType)
	if taskType == "" {
		response.BadRequest(c, "无效的任务类型")
		return
	}
	if taskType == model.TaskTypeCron {
		req.CronExpression = panelcron.NormalizeExpressions(req.CronExpression)
		if err := panelcron.ValidateExpressions(req.CronExpression); err != nil {
			response.BadRequest(c, err.Error())
			return
		}
	} else {
		req.CronExpression = ""
	}

	task := model.Task{
		Name:            req.Name,
		Command:         req.Command,
		CronExpression:  req.CronExpression,
		TaskType:        taskType,
		Status:          model.TaskStatusEnabled,
		Timeout:         86400,
		RetryInterval:   60,
		NotifyOnFailure: false,
	}

	if req.Timeout != nil {
		task.Timeout = *req.Timeout
	}
	if req.RandomDelaySeconds != nil {
		randomDelayValue, err := normalizeTaskRandomDelaySecondsValue(*req.RandomDelaySeconds)
		if err != nil {
			response.BadRequest(c, err.Error())
			return
		}
		task.RandomDelaySeconds = randomDelayValue
	}
	if req.MaxRetries != nil {
		task.MaxRetries = *req.MaxRetries
	}
	if req.RetryInterval != nil {
		task.RetryInterval = *req.RetryInterval
	}
	if req.NotifyOnFailure != nil {
		task.NotifyOnFailure = *req.NotifyOnFailure
	}
	if req.NotifyOnSuccess != nil {
		task.NotifyOnSuccess = *req.NotifyOnSuccess
	}
	if req.NotificationChannelID != nil {
		if *req.NotificationChannelID == 0 {
			task.NotificationChannelID = nil
		} else if err := validateTaskNotificationChannelID(req.NotificationChannelID); err != nil {
			response.BadRequest(c, err.Error())
			return
		} else {
			task.NotificationChannelID = req.NotificationChannelID
		}
	}
	if req.Labels != nil {
		task.SetLabelsFromSlice(req.Labels)
	}
	if req.DependsOn != nil {
		task.DependsOn = req.DependsOn
	}
	if req.TaskBefore != nil {
		task.TaskBefore = req.TaskBefore
	}
	if req.TaskAfter != nil {
		task.TaskAfter = req.TaskAfter
	}
	if req.AllowMultipleInstances != nil {
		task.AllowMultipleInstances = *req.AllowMultipleInstances
	}
	if req.StopSchedule != nil {
		task.StopSchedule = *req.StopSchedule
	}

	if err := database.DB.Select("*").Create(&task).Error; err != nil {
		response.InternalError(c, "创建任务失败")
		return
	}

	if scheduler := service.GetSchedulerV2(); scheduler != nil {
		scheduler.AddJob(&task)
	}

	response.Created(c, gin.H{
		"message": "创建成功",
		"data":    task.ToDict(),
	})
}

func (h *TaskHandler) Update(c *gin.Context) {
	taskID, _ := strconv.ParseUint(c.Param("id"), 10, 32)

	var task model.Task
	if err := database.DB.First(&task, taskID).Error; err != nil {
		response.NotFound(c, "任务不存在")
		return
	}

	var req map[string]interface{}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "请求参数错误")
		return
	}

	if labels, ok := req["labels"].([]interface{}); ok {
		values := make([]string, len(labels))
		for i, label := range labels {
			values[i] = fmt.Sprintf("%v", label)
		}
		req["labels"] = strings.Join(values, ",")
	}

	resolvedTaskType := task.GetTaskType()
	if rawTaskType, exists := req["task_type"]; exists {
		value, ok := rawTaskType.(string)
		if !ok {
			response.BadRequest(c, "无效的任务类型")
			return
		}
		resolvedTaskType = model.NormalizeTaskType(value)
		if resolvedTaskType == "" {
			response.BadRequest(c, "无效的任务类型")
			return
		}
		req["task_type"] = resolvedTaskType
	}

	if resolvedTaskType == model.TaskTypeCron {
		cronExpr := task.CronExpression
		if value, ok := req["cron_expression"].(string); ok {
			cronExpr = panelcron.NormalizeExpressions(value)
			req["cron_expression"] = cronExpr
		}
		if err := panelcron.ValidateExpressions(cronExpr); err != nil {
			response.BadRequest(c, err.Error())
			return
		}
	} else {
		req["cron_expression"] = ""
	}

	allowedFields := map[string]bool{
		"name": true, "command": true, "cron_expression": true,
		"task_type": true,
		"timeout":   true, "random_delay_seconds": true, "max_retries": true, "retry_interval": true,
		"notify_on_failure": true, "notify_on_success": true, "notification_channel_id": true, "labels": true, "depends_on": true,
		"sort_order": true, "task_before": true, "task_after": true,
		"allow_multiple_instances": true, "stop_schedule": true,
	}

	updates := make(map[string]interface{})
	for key, value := range req {
		if key == "random_delay_seconds" {
			randomDelayValue, err := normalizeTaskRandomDelaySecondsValue(value)
			if err != nil {
				response.BadRequest(c, err.Error())
				return
			}
			updates[key] = randomDelayValue
			continue
		}
		if key == "notification_channel_id" {
			channelID, err := normalizeTaskNotificationChannelIDValue(value)
			if err != nil {
				response.BadRequest(c, err.Error())
				return
			}
			if channelID == nil {
				updates[key] = nil
			} else {
				updates[key] = *channelID
			}
			continue
		}
		if allowedFields[key] {
			updates[key] = value
		}
	}

	if len(updates) > 0 {
		database.DB.Model(&task).Updates(updates)
	}

	database.DB.First(&task, taskID)
	if scheduler := service.GetSchedulerV2(); scheduler != nil {
		scheduler.UpdateJob(&task)
	}

	response.Success(c, gin.H{
		"message": "task updated",
		"data":    task.ToDict(),
	})
}

func (h *TaskHandler) Delete(c *gin.Context) {
	taskID, _ := strconv.ParseUint(c.Param("id"), 10, 32)

	var task model.Task
	if err := database.DB.First(&task, taskID).Error; err != nil {
		response.NotFound(c, "任务不存在")
		return
	}

	if scheduler := service.GetSchedulerV2(); scheduler != nil {
		scheduler.RemoveJob(uint(taskID))
	}
	database.DB.Where("task_id = ?", taskID).Delete(&model.TaskLog{})
	database.DB.Delete(&task)

	response.Success(c, gin.H{"message": "删除成功"})
}

func (h *TaskHandler) Pin(c *gin.Context) {
	taskID, _ := strconv.ParseUint(c.Param("id"), 10, 32)
	database.DB.Model(&model.Task{}).Where("id = ?", taskID).Update("is_pinned", true)
	response.Success(c, gin.H{"message": "已置顶"})
}

func (h *TaskHandler) Unpin(c *gin.Context) {
	taskID, _ := strconv.ParseUint(c.Param("id"), 10, 32)
	database.DB.Model(&model.Task{}).Where("id = ?", taskID).Update("is_pinned", false)
	response.Success(c, gin.H{"message": "已取消置顶"})
}

func (h *TaskHandler) Copy(c *gin.Context) {
	taskID, _ := strconv.ParseUint(c.Param("id"), 10, 32)

	var task model.Task
	if err := database.DB.First(&task, taskID).Error; err != nil {
		response.NotFound(c, "任务不存在")
		return
	}

	newTask := model.Task{
		Name:                   task.Name + " (副本)",
		Command:                task.Command,
		CronExpression:         task.CronExpression,
		TaskType:               task.GetTaskType(),
		Status:                 model.TaskStatusDisabled,
		Labels:                 task.Labels,
		Timeout:                task.Timeout,
		RandomDelaySeconds:     task.RandomDelaySeconds,
		MaxRetries:             task.MaxRetries,
		RetryInterval:          task.RetryInterval,
		NotifyOnFailure:        task.NotifyOnFailure,
		NotifyOnSuccess:        task.NotifyOnSuccess,
		NotificationChannelID:  task.NotificationChannelID,
		DependsOn:              task.DependsOn,
		TaskBefore:             task.TaskBefore,
		TaskAfter:              task.TaskAfter,
		AllowMultipleInstances: task.AllowMultipleInstances,
	}
	database.DB.Select("*").Create(&newTask)
	response.Created(c, gin.H{"message": "复制成功", "data": newTask.ToDict()})
}
