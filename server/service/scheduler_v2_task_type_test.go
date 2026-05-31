package service

import (
	"testing"
	"time"

	"daidai-panel/database"
	"daidai-panel/model"
	"daidai-panel/testutil"
)

func TestSchedulerV2AddJobRegistersEnabledManualTask(t *testing.T) {
	testutil.SetupTestEnv(t)

	scheduler := NewSchedulerV2(SchedulerConfig{
		WorkerCount:  1,
		QueueSize:    10,
		RateInterval: time.Hour,
	}, nil)

	task := &model.Task{
		Name:     "manual task",
		Command:  "echo hi",
		TaskType: model.TaskTypeManual,
		Status:   model.TaskStatusEnabled,
	}
	if err := scheduler.AddJob(task); err != nil {
		t.Fatalf("add manual task job: %v", err)
	}
	if !scheduler.HasJob(task.ID) {
		t.Fatal("expected enabled manual task to be registered for state restoration")
	}
}

func TestSchedulerV2EnqueueStartupTasks(t *testing.T) {
	testutil.SetupTestEnv(t)

	startupTask := &model.Task{
		Name:     "startup task",
		Command:  "echo boot",
		TaskType: model.TaskTypeStartup,
		Status:   model.TaskStatusEnabled,
	}
	if err := database.DB.Create(startupTask).Error; err != nil {
		t.Fatalf("create startup task: %v", err)
	}
	disabledStartupTask := &model.Task{
		Name:     "disabled startup task",
		Command:  "echo no",
		TaskType: model.TaskTypeStartup,
		Status:   model.TaskStatusDisabled,
	}
	if err := database.DB.Create(disabledStartupTask).Error; err != nil {
		t.Fatalf("create disabled startup task: %v", err)
	}

	scheduler := NewSchedulerV2(SchedulerConfig{
		WorkerCount:  1,
		QueueSize:    10,
		RateInterval: time.Hour,
	}, nil)

	if err := scheduler.AddJob(startupTask); err != nil {
		t.Fatalf("register startup task: %v", err)
	}

	count := scheduler.EnqueueStartupTasks()
	if count != 1 {
		t.Fatalf("expected 1 startup task to be enqueued, got %d", count)
	}
	if got := len(scheduler.taskQueue); got != 1 {
		t.Fatalf("expected queue length 1, got %d", got)
	}

	var updated model.Task
	if err := database.DB.First(&updated, startupTask.ID).Error; err != nil {
		t.Fatalf("reload startup task: %v", err)
	}
	if updated.Status != model.TaskStatusQueued {
		t.Fatalf("expected startup task status queued, got %v", updated.Status)
	}
}

func TestSchedulerV2RejectsEnqueueAfterStop(t *testing.T) {
	testutil.SetupTestEnv(t)

	scheduler := NewSchedulerV2(SchedulerConfig{
		WorkerCount:  1,
		QueueSize:    10,
		RateInterval: time.Hour,
	}, nil)
	scheduler.Start()
	scheduler.Stop()

	err := scheduler.Enqueue(&ExecutionRequest{
		TaskID: 1,
		Task: &model.Task{
			ID:      1,
			Name:    "stopped task",
			Command: "echo no",
			Status:  model.TaskStatusEnabled,
		},
	})
	if err == nil {
		t.Fatal("expected stopped scheduler to reject enqueue")
	}
}
