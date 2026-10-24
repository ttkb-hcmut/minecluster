import argparse, socket

def description(): return\
  "TBA"

def arguments():
  parser = argparse.ArgumentParser(
    description=description(),
    formatter_class=argparse.RawDescriptionHelpFormatter,
  )
  parser.add_argument(
    "--hkind", type=str,
    help="Harbor kind"
  )
  parser.add_argument(
    "--sport", type=str,
    help="Server Port number"
  )
  parser.add_argument(
    "--gport", type=str,
    help="Gui Port number"
  )

  def parse_args(parse_args):
    args = parse_args()
    if args.hkind == "coco":
      args.socketkind = socket.AF_INET
      args.sport = ("localhost", int(args.sport))
      args.gport = ("localhost", int(args.gport))
    elif args.hkind == "agott":
      args.socketkind = socket.AF_UNIX
      args.sport = args.sport
      args.gport = args.gport
    else:
      raise TypeError(f"unknown {args.hkind=}")
    return args

  x = parser.parse_args
  parser.parse_args = lambda: parse_args(x)
  return parser
