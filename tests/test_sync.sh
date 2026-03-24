#!/bin/bash
# Test suite for sync scripts

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

TEST_DIR="$(cd "$(dirname "$0")/.." && pwd)/.test_tmp"
MOCK_SKILLS_DIR="$TEST_DIR/mock_skills"
MOCK_REPO_DIR="$TEST_DIR/mock_repo"

cleanup() {
    rm -rf "$TEST_DIR"
}

setup() {
    cleanup
    mkdir -p "$MOCK_SKILLS_DIR" "$MOCK_REPO_DIR"
    
    for skill in git-workflow pr-create pr-review; do
        mkdir -p "$MOCK_SKILLS_DIR/$skill"
        echo "# $skill skill - local version" > "$MOCK_SKILLS_DIR/$skill/SKILL.md"
        mkdir -p "$MOCK_REPO_DIR/$skill"
        echo "# $skill skill - repo version" > "$MOCK_REPO_DIR/$skill/SKILL.md"
    done
}

# Create the sync scripts once
create_sync_scripts() {
    cat > "$TEST_DIR/sync-to-local.sh" << 'EOF'
#!/bin/bash
set -e
SKILLS_DIR="$1"
REPO_DIR="$2"
for skill in git-workflow pr-create pr-review; do
    if [ -d "$REPO_DIR/$skill" ]; then
        mkdir -p "$SKILLS_DIR/$skill"
        cp "$REPO_DIR/$skill/SKILL.md" "$SKILLS_DIR/$skill/"
    fi
done
EOF
    chmod +x "$TEST_DIR/sync-to-local.sh"
    
    cat > "$TEST_DIR/sync-from-local.sh" << 'EOF'
#!/bin/bash
set -e
SKILLS_DIR="$1"
REPO_DIR="$2"
for skill in git-workflow pr-create pr-review; do
    if [ -d "$SKILLS_DIR/$skill" ]; then
        mkdir -p "$REPO_DIR/$skill"
        cp "$SKILLS_DIR/$skill/SKILL.md" "$REPO_DIR/$skill/"
    fi
done
EOF
    chmod +x "$TEST_DIR/sync-from-local.sh"
}

pass() {
    echo -e "${GREEN}PASS${NC}: $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
    echo -e "${RED}FAIL${NC}: $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

assert_file_exists() {
    if [ -f "$1" ]; then
        pass "$2"
    else
        fail "$2"
    fi
}

assert_file_contains() {
    if grep -q "$2" "$1" 2>/dev/null; then
        pass "$3"
    else
        fail "$3"
    fi
}

test_sync_to_local() {
    echo -e "\n${YELLOW}=== Test: sync-to-local.sh ===${NC}"
    "$TEST_DIR/sync-to-local.sh" "$MOCK_SKILLS_DIR" "$MOCK_REPO_DIR"
    
    assert_file_exists "$MOCK_SKILLS_DIR/git-workflow/SKILL.md" "git-workflow copied"
    assert_file_exists "$MOCK_SKILLS_DIR/pr-create/SKILL.md" "pr-create copied"
    assert_file_exists "$MOCK_SKILLS_DIR/pr-review/SKILL.md" "pr-review copied"
    assert_file_contains "$MOCK_SKILLS_DIR/git-workflow/SKILL.md" "repo version" "Content from repo"
}

test_sync_from_local() {
    echo -e "\n${YELLOW}=== Test: sync-from-local.sh ===${NC}"
    
    echo "# git-workflow skill - modified local" > "$MOCK_SKILLS_DIR/git-workflow/SKILL.md"
    "$TEST_DIR/sync-from-local.sh" "$MOCK_SKILLS_DIR" "$MOCK_REPO_DIR"
    
    assert_file_contains "$MOCK_REPO_DIR/git-workflow/SKILL.md" "modified local" "Local changes synced to repo"
}

test_missing_directories() {
    echo -e "\n${YELLOW}=== Test: Missing directories ===${NC}"
    rm -rf "$MOCK_SKILLS_DIR/pr-create"
    "$TEST_DIR/sync-to-local.sh" "$MOCK_SKILLS_DIR" "$MOCK_REPO_DIR"
    assert_file_exists "$MOCK_SKILLS_DIR/pr-create/SKILL.md" "Missing directory created"
}

main() {
    echo -e "${YELLOW}Running sync tests...${NC}"
    
    setup
    create_sync_scripts
    
    test_sync_to_local
    test_sync_from_local
    test_missing_directories
    
    echo -e "\n${YELLOW}=== Test Summary ===${NC}"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    
    cleanup
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "\n${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}Some tests failed!${NC}"
        exit 1
    fi
}

main "$@"
