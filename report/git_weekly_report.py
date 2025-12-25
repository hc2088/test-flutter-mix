import subprocess
import os

# === 配置区 ===
REPO_PATH = "/Users/huchu/Documents/nook_client"  # 修改为你的 Git 仓库路径
# REPO_PATH = "/Users/huchu/Documents/dingheApp"  
SINCE = "2025-12-08"
UNTIL = "2025-12-12"
AUTHOR = "huchu"
OUTPUT_FILE = "weekly_report.md"

# 可选：目录到模块的映射
MODULE_MAP = {
   
}
# ==============

def run_git_command(cmd):
    return subprocess.check_output(cmd, cwd=REPO_PATH, universal_newlines=True)

def get_git_logs(since, until, author):
    cmd = [
        "git", "log",
        "--since=" + since,
        "--until=" + until,
        "--author=" + author,
        "--pretty=format:%h|%ad|%s",
        "--date=short"
    ]
    logs = run_git_command(cmd).splitlines()
    return logs

def get_commit_stat(commit_hash):
    cmd = ["git", "show", "--stat", "--oneline", commit_hash]
    return run_git_command(cmd)

def summarize_commit(commit_hash, message, diff_stat):
    """简单一句话总结"""
    files_changed = []
    for line in diff_stat.splitlines():
        if "|" in line:
            file_name = line.split("|")[0].strip()
            files_changed.append(file_name)
    if not files_changed:
        return message
    file_summary = ", ".join(files_changed[:3])
    if len(files_changed) > 3:
        file_summary += " 等文件"
    return "修改了 {}，提交内容: {}".format(file_summary, message)

def generate_report(logs):
    """详细 Markdown 报告，每条提交"""
    report_lines = ["# 本周工作总结（详细提交）\n"]
    for log in logs:
        parts = log.split("|", 2)
        if len(parts) < 3:
            continue
        commit_hash, date, message = parts
        diff_stat = get_commit_stat(commit_hash)
        diff_summary = "\n".join(
            [line for line in diff_stat.splitlines() if "|" in line or "changed" in line]
        )
        nl_summary = summarize_commit(commit_hash, message, diff_stat)

        report_lines.append("## {} - {}\n".format(date, message))
        report_lines.append("**总结:** {}".format(nl_summary))
        report_lines.append("```")
        report_lines.append(diff_summary.strip() if diff_summary else "无文件修改")
        report_lines.append("```\n")
    return "\n".join(report_lines)

def generate_consolidated_report(logs):
    """
    按模块整理修改内容，生成整合周报
    """
    module_changes = {}

    for log in logs:
        parts = log.split("|", 2)
        if len(parts) < 3:
            continue
        commit_hash, date, message = parts
        diff_stat = get_commit_stat(commit_hash)

        for line in diff_stat.splitlines():
            if "|" not in line:
                continue
            file_path = line.split("|")[0].strip()
            # 获取模块名
            module_name = None
            for key, value in MODULE_MAP.items():
                if file_path.startswith(key):
                    module_name = value
                    break
            if not module_name:
                module_name = file_path.split("/")[0]  # 默认一级目录名
            if module_name not in module_changes:
                module_changes[module_name] = []
            module_changes[module_name].append(message)

    # 生成自然语言总结
    summary_lines = ["# 本周整体工作内容总结\n"]
    for module, messages in module_changes.items():
        # 去重提交信息
        unique_msgs = list(dict.fromkeys(messages))
        summary_lines.append(f"- {module}: " + "；".join(unique_msgs))
    return "\n".join(summary_lines)


if __name__ == "__main__":
    logs = get_git_logs(SINCE, UNTIL, AUTHOR)

    if not logs:
        print("⚠️ 在指定时间范围内没有找到提交")
    else:
        # 详细报告
        detailed_report = generate_report(logs)
        with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
            f.write(detailed_report)

        # 整合总结
        consolidated_summary = generate_consolidated_report(logs)
        summary_file = "weekly_report_summary.md"
        with open(summary_file, "w", encoding="utf-8") as f:
            f.write(consolidated_summary)

        print("✅ 详细周报已生成: {}".format(os.path.abspath(OUTPUT_FILE)))
        print("✅ 整合周报已生成: {}".format(os.path.abspath(summary_file)))
