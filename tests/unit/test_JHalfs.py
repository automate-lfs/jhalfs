"""Unit tests for the Runner Class"""
# import logging
import unittest

# from unittest.mock import Mock

import jhalfs


EXPECTED_CONFIG = {'CONFIG_TEST': '1', 'CONFIG_BLAH': 'more'}


class JHalfsTest(unittest.TestCase):
    """Tests for the jhalfs.JHalfs Class"""

    def setUp(self):
        """Before each test is run, set up some initial state."""

    def tearDown(self):
        """Clean up the state after each test."""

    def test_main_help(self):
        """Execute the main function with the help flag."""
        with self.assertRaises(SystemExit):
            jhalfs.main(args=['-h'])

    # def test_main_without_verbose(self):
    #     """Execute the main function without the verbose flag."""
    #     log = Mock(logging)
    #     jhalfs.main(args=[], log=log)
    #     log.basicConfig.assert_called_with(
    #         format='%(asctime)s %(levelname)-6s %(message)s',
    #         level=logging.INFO)

    # def test_main_verbose(self):
    #     """Execute the main function with the verbose flag."""
    #     log = Mock(logging)
    #     jhalfs.main(args=['-v'], log=log)
    #     log.basicConfig.assert_called_with(
    #         format='%(asctime)s %(levelname)-6s %(message)s',
    #         level=logging.DEBUG)

    def test_main_version(self):
        """Supplying the version argument will simply print a version and
           exit."""
        # noinspection PyTypeChecker
        with self.assertRaises(SystemExit):
            jhalfs.main(args=['-V'])
