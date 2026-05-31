package service

import (
	"errors"
	"testing"

	"daidai-panel/database"
	"daidai-panel/model"
	"daidai-panel/testutil"
)

func TestTaskExecutorOnTaskFailedCreatesLogForPreExecutionFailure(t *testing.T) {
	testutil.SetupTestEnv(t)
	database.EnsureColumns()

	previousScheduler := globalScheduler
	globalScheduler = nil
	t.Cleanup(func() {
		globalScheduler = previousScheduler
	})

	task := &model.Task{
		Name:           "bad command",
		Command:        "echo hello",
		TaskType:       model.TaskTypeCron,
		CronExpression: "0 0 * * *",
		Status:         model.TaskStatusEnabled,
		Timeout:        60,
	}
	if err := database.DB.Create(task).Error; err != nil {
		t.Fatalf("create task: %v", err)
	}

	executor := NewTaskExecutor()
	req := &ExecutionRequest{
		TaskID: task.ID,
		Task:   task,
	}

	executor.OnTaskFailed(req, errors.New("不支持的解释器: echo"))

	var updated model.Task
	if err := database.DB.First(&updated, task.ID).Error; err != nil {
		t.Fatalf("reload task: %v", err)
	}
	if updated.LastRunAt == nil {
		t.Fatal("expected last_run_at to be recorded")
	}
	if updated.LastRunStatus == nil || *updated.LastRunStatus != model.RunFailed {
		t.Fatalf("expected last_run_status=failed, got %#v", updated.LastRunStatus)
	}
	if updated.Status != model.TaskStatusEnabled {
		t.Fatalf("expected task to return to enabled, got %v", updated.Status)
	}
	if updated.LastRunningTime == nil || *updated.LastRunningTime != 0 {
		t.Fatalf("expected last_running_time=0, got %#v", updated.LastRunningTime)
	}

	var taskLog model.TaskLog
	if err := database.DB.Where("task_id = ?", task.ID).First(&taskLog).Error; err != nil {
		t.Fatalf("expected failure log to be created: %v", err)
	}
	if taskLog.Status == nil || *taskLog.Status != model.LogStatusFailed {
		t.Fatalf("expected failed log status, got %#v", taskLog.Status)
	}
	if taskLog.EndedAt == nil {
		t.Fatal("expected ended_at to be recorded")
	}
	if taskLog.Duration == nil || *taskLog.Duration != 0 {
		t.Fatalf("expected duration=0 for pre-execution failure, got %#v", taskLog.Duration)
	}
	if taskLog.Content == "" {
		t.Fatal("expected failure log content to be recorded")
	}
}
