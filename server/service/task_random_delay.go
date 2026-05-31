package service

import "daidai-panel/model"

func resolveTaskRandomDelaySeconds(task *model.Task, plan *CommandExecutionPlan) int {
	if task == nil {
		return 0
	}
	if plan != nil && plan.SkipRandomDelay {
		return 0
	}

	if task.RandomDelaySeconds != nil {
		if *task.RandomDelaySeconds <= 0 {
			return 0
		}
		return *task.RandomDelaySeconds
	}

	randomDelay := model.GetRegisteredConfigInt("random_delay")
	if randomDelay <= 0 {
		return 0
	}

	delayExts := parseTaskExtensions(model.GetRegisteredConfig("random_delay_extensions"))
	if !shouldApplyRandomDelay(task.Command, delayExts) {
		return 0
	}

	return randomDelay
}
