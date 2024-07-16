import sys
import argparse


def init(args):
    if args.project_dir is None:
        print("[INIT]未指定 project_dir")
    else:
        print("[INIT]指定 project_dir => {}".format(args.project_dir))


def upgrade(args):
    if args.project_dir is None:
        print("[UPGRADE]未指定 project_dir")
    else:
        print("[UPGRADE]指定 project_dir => {}".format(args.project_dir))


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
    parser_upgrade = subparsers.add_parser("upgrade", help="升级项目模板")
    parser_upgrade.add_argument(
        "project_dir", type=str, nargs="?", default=None, help="项目路径（可选）"
    )
    parser_upgrade.set_defaults(func=upgrade)

    # 解析参数
    args = parser.parse_args()
    if hasattr(args, "func"):
        args.func(args)


if __name__ == "__main__":
    main()
