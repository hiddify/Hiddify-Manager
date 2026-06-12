import os
import pytest
from unittest.mock import patch, MagicMock
from hiddify_manager.installer import install_module

@patch('hiddify_manager.installer.log')
def test_install_module_disabled(mock_log):
    install_module('dummy', enable=False)
    mock_log.info.assert_called_with("Skipping module dummy (disabled)")

@patch('hiddify_manager.installer.importlib.import_module')
@patch('hiddify_manager.installer.log')
def test_install_module_python_impl(mock_log, mock_import):
    mock_module = MagicMock()
    mock_module.install = MagicMock()
    mock_import.return_value = mock_module
    
    install_module('dummy')
    
    mock_import.assert_called_once_with('hiddify_manager.modules.dummy')
    mock_module.install.assert_called_once()

@patch('hiddify_manager.installer.os.path.exists')
@patch('hiddify_manager.installer._module_dir')
@patch('hiddify_manager.installer.log')
def test_install_module_missing_dir(mock_log, mock_module_dir, mock_exists):
    mock_module_dir.return_value = "/mock/dir/dummy"
    mock_exists.return_value = False
    
    with patch('hiddify_manager.installer.importlib.import_module', side_effect=ImportError):
        install_module('dummy')
    
    mock_exists.assert_called_once_with("/mock/dir/dummy")
    mock_log.error.assert_called_with("Module directory does not exist: /mock/dir/dummy")

@patch('hiddify_manager.installer.run_cmd')
@patch('hiddify_manager.installer.os.path.exists')
@patch('hiddify_manager.installer._module_dir')
@patch('hiddify_manager.installer.log')
def test_install_module_bash_fallback(mock_log, mock_module_dir, mock_exists, mock_run_cmd):
    mock_module_dir.return_value = "/mock/dir/dummy"
    
    # Return True for directory existence and the bash scripts
    def exists_side_effect(path):
        return path in [
            "/mock/dir/dummy",
            "/mock/dir/dummy/install.sh",
            "/mock/dir/dummy/run.sh"
        ]
    mock_exists.side_effect = exists_side_effect
    
    with patch('hiddify_manager.installer.importlib.import_module', side_effect=ImportError):
        install_module('dummy')
    
    assert mock_run_cmd.call_count == 2
    mock_run_cmd.assert_any_call(["bash", "install.sh"], cwd="/mock/dir/dummy")
    mock_run_cmd.assert_any_call(["bash", "run.sh"], cwd="/mock/dir/dummy")
