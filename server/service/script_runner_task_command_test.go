package service

import (
	"os"
	"path/filepath"
	"reflect"
	"testing"

	"daidai-panel/config"
	"daidai-panel/testutil"
)

func TestParseCommandExecutionPlanSupportsTaskModesAndArgs(t *testing.T) {
	testutil.SetupTestEnv(t)

	spacedScript := filepath.Join(config.C.Data.ScriptsDir, "demo folder", "my script.py")
	if err := os.MkdirAll(filepath.Dir(spacedScript), 0755); err != nil {
		t.Fatalf("mkdir spaced script dir: %v", err)
	}
	if err := os.WriteFile(spacedScript, []byte("print('ok')\n"), 0644); err != nil {
		t.Fatalf("write spaced script: %v", err)
	}

	simpleScript := filepath.Join(config.C.Data.ScriptsDir, "simple.sh")
	if err := os.WriteFile(simpleScript, []byte("echo ok\n"), 0755); err != nil {
		t.Fatalf("write simple script: %v", err)
	}

	goScript := filepath.Join(config.C.Data.ScriptsDir, "worker.go")
	if err := os.WriteFile(goScript, []byte("package main\nfunc main() {}\n"), 0644); err != nil {
		t.Fatalf("write go script: %v", err)
	}

	mjsScript := filepath.Join(config.C.Data.ScriptsDir, "esm-demo.mjs")
	if err := os.WriteFile(mjsScript, []byte("console.log('esm ok')\n"), 0644); err != nil {
		t.Fatalf("write mjs script: %v", err)
	}

	t.Run("parses now mode with timeout override and passthrough args", func(t *testing.T) {
		plan, err := ParseCommandExecutionPlan(`task -m 5m demo folder/my script.py now -- -u whyour -p password`, config.C.Data.ScriptsDir)
		if err != nil {
			t.Fatalf("parse task now plan: %v", err)
		}

		if plan.Interpreter != "python3" {
			t.Fatalf("expected python3 interpreter, got %q", plan.Interpreter)
		}
		expectedInfo, err := os.Stat(spacedScript)
		if err != nil {
			t.Fatalf("stat expected spaced script: %v", err)
		}
		actualInfo, err := os.Stat(plan.FullPath)
		if err != nil {
			t.Fatalf("stat actual spaced script: %v", err)
		}
		if !os.SameFile(expectedInfo, actualInfo) {
			t.Fatalf("expected plan path %q to reference %q", plan.FullPath, spacedScript)
		}
		if plan.TimeoutOverride == nil || *plan.TimeoutOverride != 300 {
			t.Fatalf("expected timeout override 300, got %#v", plan.TimeoutOverride)
		}
		if !plan.SkipRandomDelay {
			t.Fatal("expected now mode to skip random delay")
		}
		if plan.Mode != commandModeNow {
			t.Fatalf("expected now mode, got %q", plan.Mode)
		}
		if !reflect.DeepEqual(plan.ScriptArgs, []string{"-u", "whyour", "-p", "password"}) {
			t.Fatalf("unexpected script args: %#v", plan.ScriptArgs)
		}
	})

	t.Run("parses conc mode with env and account spec", func(t *testing.T) {
		plan, err := ParseCommandExecutionPlan(`task simple.sh conc JD_COOKIE 1-2`, config.C.Data.ScriptsDir)
		if err != nil {
			t.Fatalf("parse task conc plan: %v", err)
		}

		if plan.Mode != commandModeConc {
			t.Fatalf("expected conc mode, got %q", plan.Mode)
		}
		if !plan.SuppressLiveOutput {
			t.Fatal("expected conc mode to suppress live output")
		}
		if plan.EnvName != "JD_COOKIE" {
			t.Fatalf("expected env name JD_COOKIE, got %q", plan.EnvName)
		}
		if plan.AccountSpec != "1-2" {
			t.Fatalf("expected account spec 1-2, got %q", plan.AccountSpec)
		}
	})

	t.Run("parses designated env selection", func(t *testing.T) {
		plan, err := ParseCommandExecutionPlan(`task simple.sh desi JD_COOKIE 2`, config.C.Data.ScriptsDir)
		if err != nil {
			t.Fatalf("parse task desi plan: %v", err)
		}

		if plan.Mode != commandModeDesi {
			t.Fatalf("expected desi mode, got %q", plan.Mode)
		}
		if plan.EnvName != "JD_COOKIE" {
			t.Fatalf("expected env name JD_COOKIE, got %q", plan.EnvName)
		}
		if plan.AccountSpec != "2" {
			t.Fatalf("expected account spec 2, got %q", plan.AccountSpec)
		}
	})

	t.Run("parses go task script", func(t *testing.T) {
		plan, err := ParseCommandExecutionPlan(`task worker.go now`, config.C.Data.ScriptsDir)
		if err != nil {
			t.Fatalf("parse go task plan: %v", err)
		}

		if plan.Interpreter != "go" {
			t.Fatalf("expected go interpreter, got %q", plan.Interpreter)
		}
		if plan.Mode != commandModeNow {
			t.Fatalf("expected now mode, got %q", plan.Mode)
		}
		if !plan.SkipRandomDelay {
			t.Fatal("expected go now mode to skip random delay")
		}
	})

	t.Run("parses direct go command", func(t *testing.T) {
		plan, err := ParseCommandExecutionPlan(`go worker.go`, config.C.Data.ScriptsDir)
		if err != nil {
			t.Fatalf("parse direct go plan: %v", err)
		}

		if plan.Interpreter != "go" {
			t.Fatalf("expected go interpreter, got %q", plan.Interpreter)
		}
		if filepath.Base(plan.FullPath) != "worker.go" {
			t.Fatalf("expected worker.go path, got %q", plan.FullPath)
		}
	})

	t.Run("parses mjs task script", func(t *testing.T) {
		plan, err := ParseCommandExecutionPlan(`task esm-demo.mjs now`, config.C.Data.ScriptsDir)
		if err != nil {
			t.Fatalf("parse mjs task plan: %v", err)
		}

		if plan.Interpreter != "node" {
			t.Fatalf("expected node interpreter, got %q", plan.Interpreter)
		}
		if filepath.Base(plan.FullPath) != "esm-demo.mjs" {
			t.Fatalf("expected esm-demo.mjs path, got %q", plan.FullPath)
		}
		if plan.Mode != commandModeNow {
			t.Fatalf("expected now mode, got %q", plan.Mode)
		}
	})

}

func TestResolveTaskAccountSelections(t *testing.T) {
	envVars := map[string]string{
		"JD_COOKIE": "a&b&c",
	}

	selections, err := resolveTaskAccountSelections(envVars, "JD_COOKIE", "1-2 3")
	if err != nil {
		t.Fatalf("resolve task account selections: %v", err)
	}

	got := make([]string, 0, len(selections))
	for _, selection := range selections {
		got = append(got, selection.Value)
	}

	if !reflect.DeepEqual(got, []string{"a", "b", "c"}) {
		t.Fatalf("unexpected selected values: %#v", got)
	}
}

func TestResolveTaskAccountSelectionsSupportsDoubleAmpersandSeparator(t *testing.T) {
	envVars := map[string]string{
		"JD_COOKIE": "pt_key=one&a=1&&pt_key=two&b=2",
	}

	selections, err := resolveTaskAccountSelections(envVars, "JD_COOKIE", "1-2")
	if err != nil {
		t.Fatalf("resolve task account selections with double ampersand: %v", err)
	}

	got := make([]string, 0, len(selections))
	for _, selection := range selections {
		got = append(got, selection.Value)
	}

	if !reflect.DeepEqual(got, []string{"pt_key=one&a=1", "pt_key=two&b=2"}) {
		t.Fatalf("unexpected selected values: %#v", got)
	}
}

func TestResolveTaskAccountSelectionsSupportsEscapedAmpersands(t *testing.T) {
	envVars := map[string]string{
		"JD_COOKIE": `pt_key=one\&a=1&pt_key=two\&b=2`,
	}

	selections, err := resolveTaskAccountSelections(envVars, "JD_COOKIE", "2")
	if err != nil {
		t.Fatalf("resolve task account selections with escaped ampersands: %v", err)
	}

	if len(selections) != 1 || selections[0].Value != "pt_key=two&b=2" {
		t.Fatalf("unexpected selected values: %#v", selections)
	}
}

func TestApplyCommandEnvOverridesForDesi(t *testing.T) {
	plan := &CommandExecutionPlan{
		Mode:        commandModeDesi,
		EnvName:     "JD_COOKIE",
		AccountSpec: "2-3",
	}
	envVars := map[string]string{
		"JD_COOKIE": "a&b&c",
	}

	overridden, err := applyCommandEnvOverrides(plan, envVars)
	if err != nil {
		t.Fatalf("apply designated env overrides: %v", err)
	}
	if overridden["JD_COOKIE"] != "b&c" {
		t.Fatalf("expected designated env values b&c, got %q", overridden["JD_COOKIE"])
	}
	if overridden["envParam"] != "JD_COOKIE" {
		t.Fatalf("expected envParam JD_COOKIE, got %q", overridden["envParam"])
	}
	if overridden["numParam"] != "2 3" {
		t.Fatalf("expected numParam '2 3', got %q", overridden["numParam"])
	}
}

func TestApplyCommandEnvOverridesForDesiPreservesAmpersandsInSelectedValues(t *testing.T) {
	plan := &CommandExecutionPlan{
		Mode:        commandModeDesi,
		EnvName:     "JD_COOKIE",
		AccountSpec: "1-2",
	}
	envVars := map[string]string{
		"JD_COOKIE": "pt_key=one&a=1&&pt_key=two&b=2",
	}

	overridden, err := applyCommandEnvOverrides(plan, envVars)
	if err != nil {
		t.Fatalf("apply designated env overrides with ampersands: %v", err)
	}
	if overridden["JD_COOKIE"] != "pt_key=one&a=1&&pt_key=two&b=2" {
		t.Fatalf("expected designated env values to preserve embedded ampersands, got %q", overridden["JD_COOKIE"])
	}
}
