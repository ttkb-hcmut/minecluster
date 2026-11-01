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

  def parse_args(args):
    if args.hkind == "coco":
      args.socketkind, args.sport, args.gport = \
        socket.AF_INET, ("localhost", int(args.sport)), ("localhost", int(args.gport))
    elif args.hkind == "agott":
      args.socketkind, args.sport, args.gport = \
        socket.AF_UNIX, args.sport, args.gport
    else:
      raise TypeError(f"unknown {args.hkind=}")
    return args

  _parse = parser.parse_args
  parser.parse_args = lambda: parse_args(_parse())
  return parser
