package model

import (
	"strings"
	"time"
)

const (
	TaskStatusDisabled = 0
	TaskStatusQueued   = 0.5
	TaskStatusEnabled  = 1
	TaskStatusRunning  = 2

	TaskTypeCron    = "cron"
	TaskTypeManual  = "manual"
	TaskTypeStartup = "startup"

	RunSuccess = 0
	RunFailed  = 1
)

type Task struct {
	ID                     uint       `gorm:"primarykey" json:"id"`
	Name                   string     `gorm:"size:128;not null" json:"name"`
	Command                string     `gorm:"type:text;not null" json:"command"`
	CronExpression         string     `gorm:"type:text;not null" json:"cron_expression"`
	TaskType               string     `gorm:"size:16;not null;default:'cron'" json:"task_type"`
	Status                 float64    `gorm:"not null" json:"status"`
	Labels                 string     `gorm:"size:256;default:''" json:"-"`
	LastRunAt              *time.Time `json:"last_run_at"`
	LastRunStatus          *int       `json:"last_run_status"`
	Timeout                int        `json:"timeout"`
	RandomDelaySeconds     *int       `json:"random_delay_seconds"`
	MaxRetries             int        `json:"max_retries"`
	RetryInterval          int        `json:"retry_interval"`
	NotifyOnFailure        bool       `json:"notify_on_failure"`
	NotifyOnSuccess        bool       `json:"notify_on_success"`
	NotificationChannelID  *uint      `gorm:"index" json:"notification_channel_id"`
	DependsOn              *uint      `gorm:"index" json:"depends_on"`
	SortOrder              int        `json:"sort_order"`
	IsPinned               bool       `json:"is_pinned"`
	PID                    *int       `gorm:"column:pid" json:"pid"`
	LogPath                *string    `gorm:"size:256" json:"log_path"`
	LastRunningTime        *float64   `json:"last_running_time"`
	TaskBefore             *string    `gorm:"type:text" json:"task_before"`
	TaskAfter              *string    `gorm:"type:text" json:"task_after"`
	AllowMultipleInstances bool       `json:"allow_multiple_instances"`
	StopSchedule           string     `gorm:"type:text;default:''" json:"stop_schedule"`
	CreatedAt              time.Time  `json:"created_at"`
	UpdatedAt              time.Time  `json:"updated_at"`
}

func (Task) TableName() string {
	return "tasks"
}

func (t *Task) ToDict() map[string]interface{} {
	labels := []string{}
	if t.Labels != "" {
		labels = strings.Split(t.Labels, ",")
	}
	cronExpressions := splitTaskCronExpressions(t.CronExpression)

	return map[string]interface{}{
		"id":                       t.ID,
		"name":                     t.Name,
		"command":                  t.Command,
		"cron_expression":          t.CronExpression,
		"cron_expressions":         cronExpressions,
		"task_type":                t.GetTaskType(),
		"status":                   t.Status,
		"labels":                   labels,
		"last_run_at":              t.LastRunAt,
		"last_run_status":          t.LastRunStatus,
		"timeout":                  t.Timeout,
		"random_delay_seconds":     t.RandomDelaySeconds,
		"max_retries":              t.MaxRetries,
		"retry_interval":           t.RetryInterval,
		"notify_on_failure":        t.NotifyOnFailure,
		"notify_on_success":        t.NotifyOnSuccess,
		"notification_channel_id":  t.NotificationChannelID,
		"depends_on":               t.DependsOn,
		"sort_order":               t.SortOrder,
		"is_pinned":                t.IsPinned,
		"pid":                      t.PID,
		"log_path":                 t.LogPath,
		"last_running_time":        t.LastRunningTime,
		"task_before":              t.TaskBefore,
		"task_after":               t.TaskAfter,
		"allow_multiple_instances": t.AllowMultipleInstances,
		"stop_schedule":            t.StopSchedule,
		"created_at":               t.CreatedAt,
		"updated_at":               t.UpdatedAt,
	}
}

func splitTaskCronExpressions(raw string) []string {
	lines := strings.FieldsFunc(raw, func(r rune) bool {
		return r == '\n' || r == '\r'
	})
	result := make([]string, 0, len(lines))
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line != "" {
			result = append(result, line)
		}
	}
	return result
}

func NormalizeTaskType(taskType string) string {
	switch strings.ToLower(strings.TrimSpace(taskType)) {
	case "", TaskTypeCron:
		return TaskTypeCron
	case TaskTypeManual:
		return TaskTypeManual
	case TaskTypeStartup:
		return TaskTypeStartup
	default:
		return ""
	}
}

func IsValidTaskType(taskType string) bool {
	return NormalizeTaskType(taskType) != ""
}

func (t *Task) GetTaskType() string {
	if t == nil {
		return TaskTypeCron
	}
	return NormalizeTaskType(t.TaskType)
}

func (t *Task) UsesCronSchedule() bool {
	return t.GetTaskType() == TaskTypeCron
}

func (t *Task) SetLabelsFromSlice(labels []string) {
	t.Labels = strings.Join(labels, ",")
}

func (t *Task) GetLabels() []string {
	if t.Labels == "" {
		return []string{}
	}
	return strings.Split(t.Labels, ",")
}
