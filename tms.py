import os
import argparse
import subprocess

TEMPLATE_REPO_URL = "https://gitlab.com/viper-repo/viper-templates.git"
TEMPLATE_DIR = "templates"


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


def get_template_dir():
    return os.path.join(get_project_dir(), TEMPLATE_DIR)


def clone_template():
    cmd = "git clone {} {}".format(TEMPLATE_REPO_URL, get_template_dir())
    exec_command(cmd, cwd=os.getcwd())


def update_template():
    cmd = "git pull --rebase"
    exec_command(cmd, cwd=get_template_dir())


def init(args):
    if args.project_dir is None:
        print("[INIT]未指定 project_dir")
    else:
        print("[INIT]指定 project_dir => {}".format(args.project_dir))


def upgrade(args):
    # 检查文件夹是否存在
    template_dir = get_template_dir()
    if not os.path.exists(template_dir):
        print("开始克隆模板仓库")
        clone_template()
    # 拉取更新
    update_template()


def main():
    # 创建解析器
    parser = argparse.ArgumentParser(prog="tms", description="模板管理系统 - TMS")

    # 添加参数
    subparsers = parser.add_subparsers(help="可用的子命令")
    parser_init = subparsers.add_parser("init", help="初始化项目")
    parser_init.add_argument(
        "project_dir", type=str, nargs="?", default=None, help="项目路径（可选）"
    )
    parser_init.set_defaults(func=init)
    parser_upgrade = subparsers.add_parser("upgrade", help="更新模板")
    parser_upgrade.set_defaults(func=upgrade)

    # 解析参数
    args = parser.parse_args()
    if hasattr(args, "func"):
        args.func(args)


if __name__ == "__main__":
    main()
