#!/usr/bin/env bash

mkdir -p memory prompts logs

CONTEXT_FILE="prompts/context_snapshot.md"

{
  echo "# Hermes Coding Room Context Snapshot"
  echo ""
  echo "## CLAUDE.md"
  if [ -f CLAUDE.md ]; then
    cat CLAUDE.md
  else
    echo "CLAUDE.md 없음"
  fi

  echo ""
  echo "## Project State"
  if [ -f memory/project_state.md ]; then
    cat memory/project_state.md
  else
    echo "memory/project_state.md 없음"
  fi

  echo ""
  echo "## Latest Run"
  if [ -f memory/latest_run.md ]; then
    cat memory/latest_run.md
  else
    echo "memory/latest_run.md 없음"
  fi

  echo ""
  echo "## Recent Task History"
  if [ -f memory/task_history.md ]; then
    tail -80 memory/task_history.md
  else
    echo "memory/task_history.md 없음"
  fi
} > "$CONTEXT_FILE"

echo "$CONTEXT_FILE"
