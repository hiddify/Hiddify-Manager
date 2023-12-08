import unittest
import sys
import os
TEST_DIR = os.path.abspath(os.path.dirname(__file__))
sys.path.append(os.path.join(TEST_DIR, '../../common/'))

from commander import is_valid_url, is_domain_valid, is_valid_slug  # nopep8


class TestCommanderValidators(unittest.TestCase):
    def __init__(self, methodName: str = "runTest") -> None:
        super().__init__(methodName)

        self.injections_commands = []
        with open(os.path.join(TEST_DIR, 'os_injection_commands.txt'), 'r') as f:
            self.injections_commands = f.read().splitlines()

    def test_is_valid_url(self):
        # valid urls
        self.assertEqual(is_valid_url('https://hiddify.com'), True)
        self.assertEqual(is_valid_url('http://www.hiddify.org'), True)
        self.assertEqual(is_valid_url('https://www.hiddify-panel.co'), True)
        self.assertEqual(is_valid_url('https://www.my.hiddify.com/'), True)

        # invalid urls
        for i in self.injections_commands:
            invalid_url = 'hiddify.com' + i
            self.assertEqual(is_valid_url(invalid_url), False)

    def test_is_valid_slug(self):
        # valid slugs
        self.assertEqual(is_valid_slug('523bxgip43'), True)
        self.assertEqual(is_valid_slug('2fpaweqvg3h'), True)
        self.assertEqual(is_valid_slug('9x1iaf2zpt8qsx'), True)
        self.assertEqual(is_valid_slug('mz5q9tpks2vr'), True)

        # invalid slugs
        for i in self.injections_commands:
            invalid_slug = '523bxgip43' + i
            self.assertEqual(is_valid_slug(invalid_slug), False)

    def test_is_valid_domain(self):
        # valid domains
        self.assertEqual(is_domain_valid('hiddify.com'), True)
        self.assertEqual(is_domain_valid('www.hiddify.org'), True)
        self.assertEqual(is_domain_valid('www.hiddify-panel.co'), True)
        self.assertEqual(is_domain_valid('www.my.hiddify.com'), True)

        # invalid domains
        for i in self.injections_commands:
            invalid_domain = 'hiddify.com' + i
            self.assertEqual(is_domain_valid(invalid_domain), False)


if __name__ == '__main__':
    unittest.main()
