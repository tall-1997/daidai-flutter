package handler_test

import (
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"daidai-panel/config"
	"daidai-panel/testutil"
)

func TestScriptGetContentRejectsDirectoryTarget(t *testing.T) {
	testutil.SetupTestEnv(t)

	engine := newProtectedRouter()
	user := testutil.MustCreateUser(t, "script-open-dir", "operator")
	token := testutil.MustCreateAccessToken(t, user.Username, user.Role)

	dirPath := filepath.Join(config.C.Data.ScriptsDir, "folder")
	if err := os.MkdirAll(dirPath, 0o755); err != nil {
		t.Fatalf("mkdir target dir: %v", err)
	}

	rec := performRequest(
		engine,
		http.MethodGet,
		"/api/v1/scripts/content?path=folder",
		map[string]string{"Authorization": "Bearer " + token},
	)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d body=%s", rec.Code, rec.Body.String())
	}
	if !strings.Contains(rec.Body.String(), "当前路径是目录") {
		t.Fatalf("expected directory target error, body=%s", rec.Body.String())
	}
}
