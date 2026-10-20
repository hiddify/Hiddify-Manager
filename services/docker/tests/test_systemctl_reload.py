"""Run with python3 -m unittest discover -s services/docker/tests."""
import importlib.util
from importlib.machinery import SourceFileLoader
from pathlib import Path
import unittest
from unittest.mock import Mock, patch

path = Path(__file__).resolve().parents[1] / "systemctl"
loader = SourceFileLoader("docker_systemctl", str(path))
spec = importlib.util.spec_from_loader(loader.name, loader)
module = importlib.util.module_from_spec(spec)
loader.exec_module(module)


class TryReloadTests(unittest.TestCase):
    def test_alias_dispatch_and_exit_status(self):
        for command in ("try-reload-or-restart", "reload-or-try-restart"):
            for ok in (True, False):
                manager = Mock(error=0)
                manager.reload_or_try_restart_modules.return_value = ok
                with self.subTest(command=command, ok=ok), patch.object(module, "systemctl", manager, create=True):
                    self.assertEqual(module.run(command, "example.service"), 0 if ok else 1)
                    manager.reload_or_try_restart_modules.assert_called_once_with("example.service")

    def test_inactive_service_is_untouched_even_with_exec_reload(self):
        for reload in ([], ["/bin/true"]):
            manager, conf = Mock(), Mock()
            manager.is_active_from.return_value = False
            conf.getlist.return_value = reload
            self.assertTrue(module.Systemctl.do_reload_or_try_restart_unit_from(manager, conf))
            manager.do_reload_unit_from.assert_not_called()
            manager.do_restart_unit_from.assert_not_called()

    def test_active_service_and_failure_propagation(self):
        for reload in ([], ["/bin/true"]):
            for ok in (True, False):
                manager, conf = Mock(), Mock()
                manager.is_active_from.return_value = True
                conf.getlist.return_value = reload
                operation = manager.do_reload_unit_from if reload else manager.do_restart_unit_from
                operation.return_value = ok
                self.assertIs(module.Systemctl.do_reload_or_try_restart_unit_from(manager, conf), ok)
                operation.assert_called_once_with(conf)


if __name__ == "__main__":
    unittest.main()
