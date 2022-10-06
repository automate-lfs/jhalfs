import argparse
import logging
import io
import os
import sys

from pkg_resources import get_distribution
from jhalfs.parser import JHalfsLFSParser


PKGDIR = os.path.dirname(__file__)
TOPDIR = os.path.dirname(PKGDIR)

with open('{}/git-version'.format(PKGDIR), 'r') as f:
    detail = f.read()

__version__ = '''
Version: {version}
{detail}'''.format(version=get_distribution('jhalfs').version,
                   detail=detail)


class JHalfsException(Exception):
    """A simple exception that doesn't output a stack trace."""

    def __init__(self, message, return_code=1):
        super().__init__(message)
        logging.error('%s', message)
        sys.exit(return_code)


class JHalfsStdio(list):
    """A class for temporarily capturing a std fd, like stdout.
       May be used as a context manager.

        Args:
            fd (string): The name of the std fd.
    """

    def __init__(self, fd):
        self._fd = fd
        super().__init__()

    def __enter__(self):
        self._stdfd = getattr(sys, self._fd)
        self._io = io.StringIO()
        setattr(sys, self._fd, self._io)
        return self

    def __exit__(self, *args):
        self.extend(self._io.getvalue().splitlines())
        del self._io
        setattr(sys, self._fd, self._stdfd)


class JHalfs(object):
    def __init__(self, reconf=False, log=logging):
        """The JHalfs class.

            Args:
                log: The logging module. Allows dependency injection of a
                     mocked object for testing purposes.
        """

    def run(self):
        parser = JHalfsLFSParser(
            "/var/cache/golfs/lfs/index.xml",
            "/var/cache/golfs/lfs/stylesheets/lfs-xsl/profile.xsl")
        parser.run()
        # subprocess.run([self._legacy_cmd, 'run'],
        #              cwd=self.statedir, env=os.environ)


def _new(args):
    print("Got to the new func")


def _version(args):
    print(__version__)
    sys.exit(0)


def main(args=sys.argv[1:], log=logging):
    mainparser = argparse.ArgumentParser(
        description='Automate the building of Linux From Scratch')
    mainparser.add_argument(
        '-v', '--verbose', help='set verbose output',
        action='store_true')
    mainparser.set_defaults(function=_new)

    subparsers = mainparser.add_subparsers()
    parser_new = subparsers.add_parser(
        'new', parents=[mainparser], add_help=False, help='new help'
    )
    parser_new.set_defaults(function=_new)

    parser_version = subparsers.add_parser(
        'version', add_help=False, help='print version and exit'
    )
    parser_version.set_defaults(function=_version)

    parser = mainparser.parse_args(args)

    loglevel = logging.INFO
    if parser.verbose:
        loglevel = logging.DEBUG

    log.basicConfig(
        level=loglevel,
        format='%(asctime)s %(levelname)-6s %(message)s')

    parser.function(args)
