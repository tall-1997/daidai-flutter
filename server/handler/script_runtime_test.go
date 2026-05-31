package handler

import "testing"

func TestScriptCommandParts(t *testing.T) {
	parts, err := scriptCommandParts(".py", "demo.py")
	if err != nil {
		t.Fatalf("expected python command, got error: %v", err)
	}
	if len(parts) != 3 || parts[0] != "python" || parts[1] != "-u" || parts[2] != "demo.py" {
		t.Fatalf("unexpected command parts: %#v", parts)
	}
}

func TestScriptCommandPartsSupportsGo(t *testing.T) {
	parts, err := scriptCommandParts(".go", "demo.go")
	if err != nil {
		t.Fatalf("expected go command, got error: %v", err)
	}
	if len(parts) != 3 || parts[0] != "go" || parts[1] != "run" || parts[2] != "demo.go" {
		t.Fatalf("unexpected go command parts: %#v", parts)
	}
}

func TestScriptCommandPartsSupportsMJS(t *testing.T) {
	parts, err := scriptCommandParts(".mjs", "demo.mjs")
	if err != nil {
		t.Fatalf("expected mjs command, got error: %v", err)
	}
	if len(parts) != 2 || parts[0] != "node" || parts[1] != "demo.mjs" {
		t.Fatalf("unexpected mjs command parts: %#v", parts)
	}
}

func TestScriptCommandPartsRejectsUnsupportedExtension(t *testing.T) {
	if _, err := scriptCommandParts(".rb", "demo.rb"); err == nil {
		t.Fatal("expected unsupported extension error")
	}
}

func TestScriptLanguageExtMapSupportsGo(t *testing.T) {
	if got := scriptLanguageExtMap["go"]; got != ".go" {
		t.Fatalf("expected go language map to .go, got %q", got)
	}
}

func TestScriptLanguageExtMapSupportsNodeMJS(t *testing.T) {
	if got := scriptLanguageExtMap["node"]; got != ".mjs" {
		t.Fatalf("expected node language map to .mjs, got %q", got)
	}
}

func TestDebugRunFinishDoesNotOverrideStoppedStatus(t *testing.T) {
	exitCode := -1
	run := &debugRun{
		Logs:     []string{"before"},
		Done:     true,
		ExitCode: &exitCode,
		Status:   "stopped",
	}

	run.finish(1, nil, 0.25)

	if run.Status != "stopped" {
		t.Fatalf("expected stopped status to be preserved, got %q", run.Status)
	}
	if !run.Done {
		t.Fatal("expected done flag to stay true")
	}
	if got := len(run.Logs); got != 1 {
		t.Fatalf("expected finish to avoid appending logs for stopped run, got %d entries", got)
	}
}
