package service

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	"database/sql"

	_ "github.com/glebarez/sqlite"
)

func TestMapQingLongConfigToSystemConfig(t *testing.T) {
	key, value, ok := mapQingLongConfigToSystemConfig("CommandTimeoutTime", "1h")
	if !ok {
		t.Fatal("expected command timeout to be mapped")
	}
	if key != "command_timeout" {
		t.Fatalf("expected command_timeout key, got %q", key)
	}
	if value != "3600" {
		t.Fatalf("expected 3600 seconds, got %q", value)
	}
}

func TestMapQingLongDependencyType(t *testing.T) {
	if got := mapQingLongDependencyType(0); got != "nodejs" {
		t.Fatalf("expected nodejs, got %q", got)
	}
	if got := mapQingLongDependencyType(1); got != "python" {
		t.Fatalf("expected python, got %q", got)
	}
	if got := mapQingLongDependencyType(99); got != "" {
		t.Fatalf("expected empty mapping for unknown type, got %q", got)
	}
}

func TestBuildQingLongNotificationChannels(t *testing.T) {
	channels := buildQingLongNotificationChannels(map[string]string{
		"PUSH_KEY":           "SCT123456",
		"DD_BOT_TOKEN":       "ding-token",
		"DD_BOT_SECRET":      "ding-secret",
		"QYWX_KEY":           "qywx-key",
		"BARK_PUSH":          "https://api.day.app/device-key",
		"DEER_KEY":           "pushdeer-key",
		"DEER_URL":           "https://api2.pushdeer.com",
		"PUSHME_KEY":         "pushme-key",
		"PUSHME_URL":         "https://push.i-i.me/",
		"QMSG_KEY":           "qmsg-key",
		"QMSG_TYPE":          "group",
		"WEBHOOK_URL":        "https://example.com/webhook",
		"WEBHOOK_HEADERS":    "Authorization: Bearer demo\nX-Test: 1",
		"WEBHOOK_METHOD":     "POST",
		"WEBHOOK_BODY":       "{\"msg\":\"{{title}}\"}",
		"FSKEY":              "feishu-key",
		"FSSECRET":           "feishu-secret",
		"NTFY_TOPIC":         "demo-topic",
		"NTFY_URL":           "https://ntfy.sh",
		"NTFY_PRIORITY":      "4",
		"NTFY_TOKEN":         "secret-token",
		"PUSH_PLUS_TOKEN":    "pushplus-token",
		"PUSH_PLUS_USER":     "group-1",
		"PUSH_PLUS_TEMPLATE": "markdown",
		"WXPUSHER_APP_TOKEN": "wxpusher-token",
		"WXPUSHER_TOPIC_IDS": "101;102",
		"WXPUSHER_UIDS":      "UID_demo_1;UID_demo_2",
		"QYWX_AM":            "ww-demo,secret-demo,@all,1000001,markdown",
	})

	byType := make(map[string]map[string]string, len(channels))
	for _, channel := range channels {
		var cfg map[string]string
		if err := json.Unmarshal([]byte(channel.Config), &cfg); err != nil {
			t.Fatalf("unmarshal %s config: %v", channel.Type, err)
		}
		byType[channel.Type] = cfg
	}

	if got := byType["serverchan"]["key"]; got != "SCT123456" {
		t.Fatalf("expected serverchan key, got %q", got)
	}
	if got := byType["dingtalk"]["webhook"]; got != "https://oapi.dingtalk.com/robot/send?access_token=ding-token" {
		t.Fatalf("unexpected dingtalk webhook: %q", got)
	}
	if got := byType["wecom"]["webhook"]; got != "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=qywx-key" {
		t.Fatalf("unexpected wecom webhook: %q", got)
	}
	if got := byType["wecom_app"]["corp_id"]; got != "ww-demo" {
		t.Fatalf("unexpected wecom app corp_id: %q", got)
	}
	if got := byType["wecom_app"]["agent_id"]; got != "1000001" {
		t.Fatalf("unexpected wecom app agent_id: %q", got)
	}
	if got := byType["wecom_app"]["msg_type"]; got != "markdown" {
		t.Fatalf("unexpected wecom app msg_type: %q", got)
	}
	if got := byType["bark"]["key"]; got != "device-key" {
		t.Fatalf("unexpected bark key: %q", got)
	}
	if got := byType["pushdeer"]["server"]; got != "https://api2.pushdeer.com" {
		t.Fatalf("unexpected pushdeer server: %q", got)
	}
	if got := byType["pushme"]["server"]; got != "https://push.i-i.me/" {
		t.Fatalf("unexpected pushme server: %q", got)
	}
	if got := byType["qmsg"]["mode"]; got != "group" {
		t.Fatalf("unexpected qmsg mode: %q", got)
	}
	if got := byType["custom"]["headers"]; got == "" {
		t.Fatal("expected custom webhook headers to be normalized into JSON")
	}
	if got := byType["feishu"]["secret"]; got != "feishu-secret" {
		t.Fatalf("unexpected feishu secret: %q", got)
	}
	if got := byType["ntfy"]["topic"]; got != "demo-topic" {
		t.Fatalf("unexpected ntfy topic: %q", got)
	}
	if got := byType["pushplus"]["topic"]; got != "group-1" {
		t.Fatalf("unexpected pushplus topic: %q", got)
	}
	if got := byType["wxpusher"]["app_token"]; got != "wxpusher-token" {
		t.Fatalf("unexpected wxpusher app token: %q", got)
	}
	if got := byType["wxpusher"]["topic_ids"]; got != "101;102" {
		t.Fatalf("unexpected wxpusher topic ids: %q", got)
	}
	if got := byType["wxpusher"]["uids"]; got != "UID_demo_1;UID_demo_2" {
		t.Fatalf("unexpected wxpusher uids: %q", got)
	}
	if got := byType["wxpusher"]["content_type"]; got != "2" {
		t.Fatalf("unexpected wxpusher content type: %q", got)
	}
}

func TestResolveQingLongDataDirSupportsNestedBackupRoot(t *testing.T) {
	root := t.TempDir()
	dataDir := filepath.Join(root, "ql", "data")
	if err := os.MkdirAll(filepath.Join(dataDir, "config"), 0o755); err != nil {
		t.Fatalf("mkdir config: %v", err)
	}
	if err := os.MkdirAll(filepath.Join(dataDir, "db"), 0o755); err != nil {
		t.Fatalf("mkdir db: %v", err)
	}

	resolved, err := resolveQingLongDataDir(root)
	if err != nil {
		t.Fatalf("resolve data dir: %v", err)
	}
	if resolved != dataDir {
		t.Fatalf("expected %q, got %q", dataDir, resolved)
	}
}

func TestLoadQingLongTasksSupportsLegacySchemaWithoutOptionalColumns(t *testing.T) {
	dbPath := filepath.Join(t.TempDir(), "qinglong.db")
	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		t.Fatalf("open sqlite: %v", err)
	}
	defer db.Close()

	if _, err := db.Exec(`
		CREATE TABLE Crontabs (
			id INTEGER PRIMARY KEY,
			name TEXT,
			command TEXT,
			schedule TEXT,
			isDisabled INTEGER
		);
		INSERT INTO Crontabs (id, name, command, schedule, isDisabled)
		VALUES (1, '每日签到', 'task /ql/scripts/demo.js', '0 0 * * *', 0);
	`); err != nil {
		t.Fatalf("init legacy crontabs: %v", err)
	}

	tasks, err := loadQingLongTasks(db)
	if err != nil {
		t.Fatalf("load qinglong tasks: %v", err)
	}
	if len(tasks) != 1 {
		t.Fatalf("expected 1 task, got %d", len(tasks))
	}
	if tasks[0].Name != "每日签到" {
		t.Fatalf("unexpected task name: %q", tasks[0].Name)
	}
	if tasks[0].AllowMultipleInstances {
		t.Fatalf("expected allow_multiple_instances default false")
	}
}

func TestLoadQingLongAppsAllowsMissingScopesColumn(t *testing.T) {
	dbPath := filepath.Join(t.TempDir(), "qinglong.db")
	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		t.Fatalf("open sqlite: %v", err)
	}
	defer db.Close()

	if _, err := db.Exec(`
		CREATE TABLE Apps (
			id INTEGER PRIMARY KEY,
			name TEXT,
			client_id TEXT,
			client_secret TEXT
		);
		INSERT INTO Apps (id, name, client_id, client_secret)
		VALUES (1, 'demo', 'app-key', 'app-secret');
	`); err != nil {
		t.Fatalf("init legacy apps: %v", err)
	}

	apps, err := loadQingLongApps(db)
	if err != nil {
		t.Fatalf("load qinglong apps: %v", err)
	}
	if len(apps) != 1 {
		t.Fatalf("expected 1 app, got %d", len(apps))
	}
	if apps[0].AppKey != "app-key" || apps[0].AppSecret != "app-secret" {
		t.Fatalf("unexpected app payload: %+v", apps[0])
	}
}

func TestBuildQingLongManifestKeepsDBEnvVarsUnpinnedAndExcludesConfigExports(t *testing.T) {
	root := t.TempDir()
	dataDir := filepath.Join(root, "data")
	if err := os.MkdirAll(filepath.Join(dataDir, "config"), 0o755); err != nil {
		t.Fatalf("mkdir config dir: %v", err)
	}
	if err := os.MkdirAll(filepath.Join(dataDir, "db"), 0o755); err != nil {
		t.Fatalf("mkdir db dir: %v", err)
	}

	configBody := []byte(`
export RandomDelay="15"
export PUSH_KEY="SCT123456"
`)
	if err := os.WriteFile(filepath.Join(dataDir, "config", "config.sh"), configBody, 0o644); err != nil {
		t.Fatalf("write config.sh: %v", err)
	}

	dbPath := filepath.Join(dataDir, "db", "database.sqlite")
	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		t.Fatalf("open sqlite: %v", err)
	}
	defer db.Close()

	if _, err := db.Exec(`
		CREATE TABLE Envs (
			id INTEGER PRIMARY KEY,
			name TEXT,
			value TEXT,
			remarks TEXT,
			status INTEGER,
			position REAL
		);
		INSERT INTO Envs (id, name, value, remarks, status, position) VALUES
			(1, 'JD_COOKIE', 'cookie-a', 'first', 0, 10),
			(2, 'JD_COOKIE', 'cookie-b', 'second', 0, 20);
	`); err != nil {
		t.Fatalf("init env table: %v", err)
	}

	manifest, err := buildQingLongManifest(root)
	if err != nil {
		t.Fatalf("build qinglong manifest: %v", err)
	}

	if !manifest.Selection.EnvVars {
		t.Fatal("expected env vars selection to be enabled")
	}
	if len(manifest.Data.EnvVars) != 2 {
		t.Fatalf("expected 2 env vars from db, got %d", len(manifest.Data.EnvVars))
	}
	for idx, env := range manifest.Data.EnvVars {
		if env.Name != "JD_COOKIE" {
			t.Fatalf("expected only db env vars to be imported, got %q", env.Name)
		}
		if env.SortOrder != 0 {
			t.Fatalf("expected imported env %d to remain unpinned, got sort_order=%d", idx, env.SortOrder)
		}
	}

	configs := map[string]string{}
	for _, cfg := range manifest.Data.Configs.SystemConfigs {
		configs[cfg.Key] = cfg.Value
	}
	if got := configs["random_delay"]; got != "15" {
		t.Fatalf("expected exported RandomDelay to map to random_delay=15, got %q", got)
	}

	foundServerChan := false
	for _, channel := range manifest.Data.Configs.NotifyChannels {
		if channel.Type == "serverchan" {
			foundServerChan = true
			break
		}
	}
	if !foundServerChan {
		t.Fatal("expected PUSH_KEY export to become a notification channel")
	}
}
