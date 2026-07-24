package sbxkits_test

import (
	"os"
	"path/filepath"
	"sort"
	"testing"

	"github.com/docker/sbx-kits-contrib/tck"
)

func TestKits(t *testing.T) {
	for _, kitPath := range kitPaths(t) {
		t.Run(filepath.Base(kitPath), func(t *testing.T) {
			suite, err := tck.NewSuiteFromDir(kitPath)
			if err != nil {
				t.Fatalf("load kit %q: %v", kitPath, err)
			}
			suite.RunAll(t)
		})
	}
}

func kitPaths(t *testing.T) []string {
	t.Helper()

	if kitPath := os.Getenv("KIT"); kitPath != "" {
		return []string{absolutePath(t, kitPath)}
	}

	directories := make(map[string]struct{})
	for _, pattern := range []string{"*/spec.yaml", "*/spec.yml"} {
		matches, err := filepath.Glob(pattern)
		if err != nil {
			t.Fatalf("glob %q: %v", pattern, err)
		}
		for _, match := range matches {
			directories[filepath.Dir(match)] = struct{}{}
		}
	}

	paths := make([]string, 0, len(directories))
	for directory := range directories {
		paths = append(paths, absolutePath(t, directory))
	}
	sort.Strings(paths)
	if len(paths) == 0 {
		t.Fatal("no kits found; expected a top-level directory containing spec.yaml or spec.yml")
	}
	return paths
}

func absolutePath(t *testing.T, path string) string {
	t.Helper()

	absPath, err := filepath.Abs(path)
	if err != nil {
		t.Fatalf("resolve kit path %q: %v", path, err)
	}
	info, err := os.Stat(absPath)
	if err != nil {
		t.Fatalf("stat kit path %q: %v", absPath, err)
	}
	if !info.IsDir() {
		t.Fatalf("kit path %q is not a directory", absPath)
	}
	return absPath
}
