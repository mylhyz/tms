import os
import sys
import shutil
import argparse
import subprocess

TEMPLATE_REPO_URL = "https://gitlab.com/viper-repo/viper-templates.git"
TEMPLATE_REPO_DIR = "templates"


def exec_command(cmd, cwd):
    proc = subprocess.Popen(
        cmd.split(" "),
        cwd=cwd,
        shell=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    out, err = proc.communicate()
    if err:
        print(err)
    else:
        print(out.decode().strip())


def get_project_dir():
    return os.path.dirname(os.path.abspath(__file__))


def get_template_repo_dir():
    return os.path.join(get_project_dir(), TEMPLATE_REPO_DIR)


def clone_template_repo():
    cmd = "git clone {} {}".format(TEMPLATE_REPO_URL, get_template_repo_dir())
    exec_command(cmd, cwd=os.getcwd())


def update_template_repo():
    cmd = "git pull --rebase"
    exec_command(cmd, cwd=get_template_repo_dir())


def get_template_list():
    for _, dirs, _ in os.walk(get_template_repo_dir()):
        for dir in dirs:
            if dir.startswith("."):
                dirs.remove(dir)
        return dirs


def clone_template(dir, working):
    print("[TMS] 开始克隆模板")
    shutil.copytree(dir, working, dirs_exist_ok=True)
    print("[TMS] 克隆模板完成")


def init(args):
    template_name = None
    if args.t is None:
        print("[TMS] 未使用 -t 指定项目模板")
        sys.exit(1)
    else:
        template_name = args.t
        print("[TMS] 选择了 {} 模板".format(template_name))
    working_dir = None
    if args.project_dir is None:
        working_dir = os.getcwd()
        print("[TMS] 未指定 project_dir => {}".format(working_dir))
    else:
        working_dir = args.project_dir
        print("[TMS] 指定 project_dir => {}".format(working_dir))
    if working_dir is None or not os.path.exists(working_dir):
        print("[TMS] {} 不存在".format(working_dir))
        return
    # 选择模板
    template_dir = os.path.join(get_template_repo_dir(), template_name)
    # 拷贝模板到指定目录下
    clone_template(template_dir, working_dir)


def upgrade(args):
    # 检查文件夹是否存在
    template_dir = get_template_repo_dir()
    if not os.path.exists(template_dir):
        print("开始克隆模板仓库")
        clone_template_repo()
    # 拉取更新
    update_template_repo()


def show(args):
    dirs = get_template_list()
    for dir in dirs:
        print(dir)


def main():
    # 创建解析器
    parser = argparse.ArgumentParser(prog="tms", description="模板管理系统 - TMS")

    # 添加参数
    subparsers = parser.add_subparsers(help="可用的子命令")
    parser_init = subparsers.add_parser("init", help="初始化项目")
    parser_init.add_argument(
        "project_dir", type=str, nargs="?", default=None, help="项目路径（可选）"
    )
    parser_init.add_argument("-t", type=str, nargs="?", help="选择模板")
    parser_init.set_defaults(func=init)
    parser_upgrade = subparsers.add_parser("upgrade", help="更新模板")
    parser_upgrade.set_defaults(func=upgrade)
    parser_show = subparsers.add_parser("show", help="显示可用模板")
    parser_show.set_defaults(func=show)

    # 解析参数
    args = parser.parse_args()
    if hasattr(args, "func"):
        args.func(args)


if __name__ == "__main__":
    main()
