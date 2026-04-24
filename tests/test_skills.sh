#!/bin/bash
# Test suite for skill files

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNED=0

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

pass() {
    echo -e "${GREEN}PASS${NC}: $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
    echo -e "${RED}FAIL${NC}: $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

warn() {
    echo -e "${YELLOW}WARN${NC}: $1"
    TESTS_WARNED=$((TESTS_WARNED + 1))
}

# Find all skill directories (directories with SKILL.md)
# Excludes: tests, .github, and db9 (external skill not maintained in this repo)
find_skills() {
    find "$REPO_DIR" -mindepth 2 -maxdepth 2 -name "SKILL.md" | grep -v "/tests/" | grep -v "/.github/" | grep -v "/db9/" | sort
}

test_skill_files_exist() {
    echo -e "\n${YELLOW}=== Test: SKILL.md files exist ===${NC}"
    while IFS= read -r skill_file; do
        skill_dir=$(dirname "$skill_file")
        skill=$(basename "$skill_dir")
        assert_file_exists "$skill_file" "$skill/SKILL.md exists"
    done < <(find_skills)
}

test_yaml_frontmatter() {
    echo -e "\n${YELLOW}=== Test: YAML frontmatter ===${NC}"
    while IFS= read -r skill_file; do
        skill_dir=$(dirname "$skill_file")
        skill=$(basename "$skill_dir")

        # Check frontmatter exists
        if head -1 "$skill_file" | grep -q '^---$'; then
            pass "$skill: has YAML frontmatter opener"
        else
            fail "$skill: missing YAML frontmatter opener"
            continue
        fi

        # Extract frontmatter
        frontmatter=$(sed -n '/^---$/,/^---$/p' "$skill_file" | sed '1d;$d')

        # Check required fields
        if echo "$frontmatter" | grep -q '^name:'; then
            pass "$skill: has 'name' field"
        else
            fail "$skill: missing 'name' field"
        fi

        if echo "$frontmatter" | grep -q '^description:'; then
            pass "$skill: has 'description' field"
        else
            fail "$skill: missing 'description' field"
        fi

        # Check name matches directory (kebab-case consistency)
        name_value=$(echo "$frontmatter" | grep '^name:' | sed 's/^name: *//')
        if [ "$name_value" = "$skill" ]; then
            pass "$skill: name matches directory"
        else
            warn "$skill: name '$name_value' does not match directory '$skill'"
        fi
    done < <(find_skills)
}

test_markdown_style() {
    echo -e "\n${YELLOW}=== Test: Markdown style ===${NC}"
    while IFS= read -r skill_file; do
        skill_dir=$(dirname "$skill_file")
        skill=$(basename "$skill_dir")

        # Check ATX-style headers (# Header)
        if grep -qE '^#{1,6} ' "$skill_file"; then
            pass "$skill: uses ATX-style headers"
        else
            fail "$skill: no ATX-style headers found"
        fi

        # Check fenced code blocks have language spec (warn, don't fail)
        local code_blocks_total=0
        local code_blocks_missing_lang=0
        while IFS= read -r line; do
            code_blocks_total=$((code_blocks_total + 1))
            if echo "$line" | grep -qE '^```$'; then
                code_blocks_missing_lang=$((code_blocks_missing_lang + 1))
            fi
        done < <(grep '^```' "$skill_file")

        if [ "$code_blocks_missing_lang" -eq 0 ]; then
            pass "$skill: all fenced code blocks specify language"
        else
            warn "$skill: $code_blocks_missing_lang/$code_blocks_total fenced code blocks missing language"
        fi

        # Check unordered lists use - (warn for non-repo skills)
        if grep -qE '^[*+] ' "$skill_file"; then
            warn "$skill: uses * or + for unordered lists (should use -)"
        else
            pass "$skill: unordered lists use -"
        fi

        # Check line count (AGENTS.md recommends ~500 lines)
        local line_count
        line_count=$(wc -l < "$skill_file")
        if [ "$line_count" -gt 500 ]; then
            warn "$skill: $line_count lines (recommend keeping under 500)"
        else
            pass "$skill: $line_count lines (within 500 limit)"
        fi
    done < <(find_skills)
}

test_no_secrets() {
    echo -e "\n${YELLOW}=== Test: No secrets in skills ===${NC}"
    # Pattern to detect potential secrets
    local secret_patterns="api_key|apikey|token|password|secret|private_key"
    while IFS= read -r skill_file; do
        skill_dir=$(dirname "$skill_file")
        skill=$(basename "$skill_dir")

        # Extract frontmatter to check for external skills
        local frontmatter
        frontmatter=$(sed -n '/^---$/,/^---$/p' "$skill_file" | sed '1d;$d')
        local is_external=0
        if echo "$frontmatter" | grep -q '^homepage:'; then
            is_external=1
        fi

        local actual_secrets=0
        while IFS= read -r line; do
            # Skip lines that are clearly example placeholders
            if echo "$line" | grep -iqE '(YOUR_|example|placeholder|mock|test|dummy|fake)'; then
                continue
            fi
            # Skip lines with well-known example tokens or CLI patterns
            if echo "$line" | grep -qE '(gh auth token|\$TOKEN|\$(gh auth token)|Authorization: token \$)'; then
                continue
            fi
            # Skip descriptive text about secrets/security
            if echo "$line" | grep -iqE '(sensitive data|security|cleanup of|private_key file|public key)'; then
                continue
            fi
            # Skip proxy URLs with user:pass pattern (common in examples)
            if echo "$line" | grep -qE '(http\.proxy|proxy\.example)'; then
                continue
            fi
            # Skip CLI commands and documentation about token management
            if echo "$line" | grep -iqE '(db9 token|token show|token create|token list|token revoke|Bearer token|anonymous_secret|id_token)'; then
                continue
            fi
            # Skip markdown list items that are security warnings/documentation
            if echo "$line" | grep -qE '^[[:space:]]*[-*][[:space:]]+.*(token|secret|password)' ; then
                continue
            fi
            actual_secrets=$((actual_secrets + 1))
        done < <(grep -inE "$secret_patterns" "$skill_file")

        if [ "$actual_secrets" -gt 0 ]; then
            if [ "$is_external" -eq 1 ]; then
                warn "$skill: may contain secrets ($actual_secrets suspicious lines) — external skill, manual review recommended"
            else
                fail "$skill: may contain secrets ($actual_secrets suspicious lines)"
            fi
        else
            pass "$skill: no secrets detected"
        fi
    done < <(find_skills)
}

test_readme_references() {
    echo -e "\n${YELLOW}=== Test: README references ===${NC}"
    if [ -f "$REPO_DIR/README.md" ]; then
        while IFS= read -r skill_file; do
            skill_dir=$(dirname "$skill_file")
            skill=$(basename "$skill_dir")

            if grep -q "$skill" "$REPO_DIR/README.md"; then
                pass "$skill: referenced in README.md"
            else
                warn "$skill: not referenced in README.md"
            fi
        done < <(find_skills)
    else
        fail "README.md not found"
    fi
}

test_scripts_executable() {
    echo -e "\n${YELLOW}=== Test: Scripts are executable ===${NC}"
    for script in sync-to-local.sh sync-from-local.sh tests/test_sync.sh tests/test_skills.sh; do
        if [ -x "$REPO_DIR/$script" ]; then
            pass "$script is executable"
        else
            fail "$script is not executable"
        fi
    done
}

test_skill_scripts_syntax() {
    echo -e "\n${YELLOW}=== Test: Skill script syntax ===${NC}"
    local tmp_script
    tmp_script=$(mktemp)
    trap 'rm -f "$tmp_script"' RETURN

    while IFS= read -r skill_file; do
        skill_dir=$(dirname "$skill_file")
        skill=$(basename "$skill_dir")

        local blocks_checked=0
        local blocks_failed=0

        # Extract bash/sh/shell code blocks and validate syntax
        local in_block=0
        local block_lang=""
        local block_content=""

        while IFS= read -r line; do
            if echo "$line" | grep -qE '^```(bash|sh|shell|zsh)?$'; then
                if [ "$in_block" -eq 0 ]; then
                    in_block=1
                    block_lang=$(echo "$line" | sed 's/^```//')
                    block_content=""
                else
                    in_block=0
                    if [ -n "$block_content" ]; then
                        blocks_checked=$((blocks_checked + 1))
                        echo "$block_content" > "$tmp_script"
                        if ! bash -n "$tmp_script" 2>/dev/null; then
                            blocks_failed=$((blocks_failed + 1))
                        fi
                    fi
                    block_lang=""
                    block_content=""
                fi
            elif [ "$in_block" -eq 1 ]; then
                # Skip lines that are clearly not bash (mermaid, d2, json in -d flags, etc.)
                if echo "$line" | grep -qE '^```(mermaid|d2|json|yaml|toml|js|ts|py|go|rust)'; then
                    in_block=0
                    block_lang=""
                    block_content=""
                    continue
                fi
                block_content="${block_content}${line}"$'\n'
            fi
        done < "$skill_file"

        if [ "$blocks_checked" -eq 0 ]; then
            pass "$skill: no shell blocks to validate"
        elif [ "$blocks_failed" -eq 0 ]; then
            pass "$skill: $blocks_checked shell blocks have valid syntax"
        else
            warn "$skill: $blocks_failed/$blocks_checked shell blocks have possible syntax issues (may be intentional examples)"
        fi
    done < <(find_skills)
}

assert_file_exists() {
    if [ -f "$1" ]; then
        pass "$2"
    else
        fail "$2"
    fi
}

main() {
    echo -e "${YELLOW}Running skill tests...${NC}"

    test_skill_files_exist
    test_yaml_frontmatter
    test_markdown_style
    test_no_secrets
    test_readme_references
    test_scripts_executable
    test_skill_scripts_syntax

    echo -e "\n${YELLOW}=== Test Summary ===${NC}"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    if [ $TESTS_WARNED -gt 0 ]; then
        echo -e "Warnings: ${YELLOW}$TESTS_WARNED${NC}"
    fi

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "\n${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}Some tests failed!${NC}"
        exit 1
    fi
}

main "$@"
