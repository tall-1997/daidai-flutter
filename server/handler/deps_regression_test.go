package handler

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"slices"
	"sync"
	"testing"
	"time"

	"daidai-panel/database"
	"daidai-panel/model"
	"daidai-panel/testutil"

	"github.com/gin-gonic/gin"
)

func newDepsTestRouter() *gin.Engine {
	engine := gin.New()
	api := engine.Group("/api/v1")
	NewDepsHandler().RegisterRoutes(api)
	return engine
}

func performDepsJSONRequest(engine *gin.Engine, method, path string, body any, headers map[string]string) *httptest.ResponseRecorder {
	payload, _ := json.Marshal(body)
	req := httptest.NewRequest(method, path, bytes.NewReader(payload))
	req.Header.Set("Content-Type", "application/json")
	for key, value := range headers {
		req.Header.Set(key, value)
	}

	rec := httptest.NewRecorder()
	engine.ServeHTTP(rec, req)
	return rec
}

func TestBatchReinstallRunsSequentially(t *testing.T) {
	testutil.SetupTestEnv(t)

	deps := []model.Dependency{
		{Name: "requests", Type: model.DepTypePython, Status: model.DepStatusFailed},
		{Name: "httpx", Type: model.DepTypePython, Status: model.DepStatusCancelled},
	}
	for i := range deps {
		if err := database.DB.Create(&deps[i]).Error; err != nil {
			t.Fatalf("create dep %d: %v", i, err)
		}
	}

	originalRunner := dependencyInstallRunner
	defer func() {
		dependencyInstallRunner = originalRunner
	}()

	var (
		mu    sync.Mutex
		order []uint
		done  = make(chan struct{})
	)
	dependencyInstallRunner = func(id uint, depType, name string) {
		mu.Lock()
		order = append(order, id)
		count := len(order)
		mu.Unlock()

		database.DB.Model(&model.Dependency{}).Where("id = ?", id).Updates(map[string]interface{}{
			"status": model.DepStatusInstalled,
			"log":    "[测试] 已重装完成",
		})

		if count == len(deps) {
			close(done)
		}
	}

	engine := newDepsTestRouter()
	token := testutil.MustCreateAccessToken(t, "admin", "admin")
	rec := performDepsJSONRequest(engine, http.MethodPost, "/api/v1/deps/batch-reinstall", map[string]any{
		"ids": []uint{deps[0].ID, deps[1].ID},
	}, map[string]string{
		"Authorization": "Bearer " + token,
	})
	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}

	select {
	case <-done:
	case <-time.After(2 * time.Second):
		t.Fatal("timed out waiting for sequential batch reinstall")
	}

	mu.Lock()
	gotOrder := append([]uint(nil), order...)
	mu.Unlock()
	wantOrder := []uint{deps[0].ID, deps[1].ID}
	if !slices.Equal(gotOrder, wantOrder) {
		t.Fatalf("expected install order %v, got %v", wantOrder, gotOrder)
	}
}

func TestBuildDependencyExportLinesUsesExpectedFormat(t *testing.T) {
	deps := []model.Dependency{
		{Name: "requests"},
		{Name: "httpx"},
		{Name: "pendulum"},
	}

	lines := buildDependencyExportLinesFromVersions(deps, map[string]string{
		"requests": "2.32.3",
		"httpx":    "0.28.1",
	})

	want := []string{
		"requests==>2.32.3",
		"httpx==>0.28.1",
		"pendulum==>未知版本",
	}
	if !slices.Equal(lines, want) {
		t.Fatalf("expected export lines %v, got %v", want, lines)
	}
}
