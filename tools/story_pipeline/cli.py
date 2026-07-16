from __future__ import annotations

import argparse
import json
from pathlib import Path

from .core import (
    PipelineError,
    build_runtime_json,
    check_ir,
    diff_ir_runtime,
    load_json,
    parse_markdown,
    preflight_package,
    render_review,
    story_status_report,
    write_json,
)


def _catalogs(root: Path) -> dict:
    paths = {
        "states": "content/states/state_registry.json",
        "npcs": "content/npcs/npcs.json",
        "locations": "content/locations/locations.json",
        "items": "content/items/items.json",
        "combats": "content/combats/combats.json",
        "presentation": "content/presentation_tags.json",
    }
    return {name: load_json(root / relative) for name, relative in paths.items()}


def _governance(root: Path) -> tuple[dict | None, dict | None]:
    chapter_path = root / "docs/story/chapter_mapping_nv7.json"
    foreshadowing_path = root / "docs/story/foreshadowing_registry.json"
    chapter = load_json(chapter_path) if chapter_path.is_file() else None
    foreshadowing = load_json(foreshadowing_path) if foreshadowing_path.is_file() else None
    return chapter, foreshadowing


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description="离线剧情内容生产管线")
    commands = result.add_subparsers(dest="command", required=True)
    parse = commands.add_parser("parse", help="Markdown转Story IR")
    parse.add_argument("source", type=Path)
    parse.add_argument("output", type=Path)
    check = commands.add_parser("check", help="静态检查Story IR")
    check.add_argument("ir", type=Path)
    check.add_argument("--project-root", type=Path)
    build = commands.add_parser("build", help="批准后的Story IR转运行JSON")
    build.add_argument("ir", type=Path)
    build.add_argument("approval", type=Path)
    build.add_argument("output", type=Path)
    build.add_argument("--project-root", type=Path)
    review = commands.add_parser("review", help="运行JSON生成人工审阅稿")
    review.add_argument("runtime", type=Path)
    review.add_argument("output", type=Path)
    diff = commands.add_parser("diff", help="检查正典IR与运行JSON差异")
    diff.add_argument("ir", type=Path)
    diff.add_argument("runtime", type=Path)
    diff.add_argument("output", type=Path)
    preflight = commands.add_parser("preflight", help="只读预检剧情压缩包")
    preflight.add_argument("package", type=Path)
    preflight.add_argument("output", type=Path)
    preflight.add_argument("--project-root", type=Path)
    report = commands.add_parser("report", help="输出单任务接入状态")
    report.add_argument("story_id")
    report.add_argument("--script-status", default="SOURCE_ONLY")
    scan = commands.add_parser("scan", help="扫描并检查COMPLETE_SCRIPT Markdown")
    scan.add_argument("source_root", type=Path)
    scan.add_argument("--project-root", type=Path, required=True)
    return result


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    try:
        if args.command == "parse":
            write_json(args.output, parse_markdown(args.source))
        elif args.command == "check":
            ir = load_json(args.ir)
            chapter, foreshadowing = _governance(args.project_root) if args.project_root else (None, None)
            errors = check_ir(ir, _catalogs(args.project_root) if args.project_root else None,
                              chapter_mapping=chapter, foreshadowing_registry=foreshadowing)
            print(json.dumps({"ok": not errors, "errors": errors}, ensure_ascii=False, indent=2))
            return 1 if errors else 0
        elif args.command == "build":
            catalogs = _catalogs(args.project_root) if args.project_root else None
            chapter, foreshadowing = _governance(args.project_root) if args.project_root else (None, None)
            write_json(
                args.output,
                build_runtime_json(
                    load_json(args.ir), load_json(args.approval), catalogs,
                    chapter_mapping=chapter, foreshadowing_registry=foreshadowing,
                ),
            )
        elif args.command == "review":
            document = load_json(args.runtime)
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(render_review(document), encoding="utf-8")
        elif args.command == "diff":
            report = diff_ir_runtime(load_json(args.ir), load_json(args.runtime))
            write_json(args.output, report)
            return 0 if report["match"] else 1
        elif args.command == "preflight":
            catalogs = _catalogs(args.project_root) if args.project_root else None
            chapter, foreshadowing = _governance(args.project_root) if args.project_root else (None, None)
            result = preflight_package(args.package, catalogs, chapter, foreshadowing)
            write_json(args.output, result)
            return 0 if result["release_ready"] else 1
        elif args.command == "report":
            print(json.dumps(story_status_report(args.story_id, script_status=args.script_status), ensure_ascii=False, indent=2))
        elif args.command == "scan":
            sources = sorted(args.source_root.rglob("*.md")) if args.source_root.is_dir() else []
            sources = [path for path in sources if path.name.casefold() != "readme.md"]
            catalogs = _catalogs(args.project_root)
            chapter, foreshadowing = _governance(args.project_root)
            reports = []
            failed = False
            checked_count = 0
            for source in sources:
                try:
                    ir = parse_markdown(source)
                    content_status = str(ir.get("quest", {}).get("content_status", "")).casefold()
                    if content_status not in {"complete_script", "data_ready"}:
                        reports.append({
                            "source": source.as_posix(),
                            "story_id": ir.get("quest", {}).get("quest_id"),
                            "status": "DRAFT",
                            "ok": True,
                            "skipped": "not COMPLETE_SCRIPT",
                            "errors": [],
                        })
                        continue
                    checked_count += 1
                    errors = check_ir(ir, catalogs, chapter_mapping=chapter, foreshadowing_registry=foreshadowing)
                    failed = failed or bool(errors)
                    report = story_status_report(
                        str(ir.get("quest", {}).get("quest_id", "")),
                        script_status="COMPLETE_SCRIPT", parsed=not errors,
                        references_ok=not errors, ownership_ok=not errors,
                    )
                    report.update({"source": source.as_posix(), "ok": not errors, "errors": errors})
                    reports.append(report)
                except PipelineError as exc:
                    failed = True
                    reports.append({"source": source.as_posix(), "ok": False, "errors": [{"code": exc.code, "message": exc.message}]})
            region_path = args.project_root / "docs/story/scripts/nv7/region_manifest.json"
            if region_path.is_file():
                reported_ids = {report.get("story_id") for report in reports}
                for entry in load_json(region_path).get("tasks", []):
                    story_id = entry.get("task_id")
                    if story_id not in reported_ids:
                        reports.append(story_status_report(story_id, script_status=entry.get("status", "SOURCE_ONLY")))
            print(json.dumps({"ok": not failed, "complete_script_count": checked_count, "reports": reports}, ensure_ascii=False, indent=2))
            return 1 if failed else 0
        return 0
    except PipelineError as exc:
        print(json.dumps({"ok": False, "code": exc.code, "message": exc.message}, ensure_ascii=False))
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
