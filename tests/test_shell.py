import subprocess
import pytest
from unittest.mock import patch, MagicMock
from hiddify_manager.utils.shell import run_cmd

def test_run_cmd_success():
    with patch('subprocess.run') as mock_run:
        mock_result = MagicMock()
        mock_result.returncode = 0
        mock_run.return_value = mock_result
        
        result = run_cmd(["echo", "hello"])
        
        mock_run.assert_called_once_with(
            ["echo", "hello"],
            check=True,
            shell=False,
            capture_output=False,
            text=True,
            cwd=None,
            input=None,
            env=None,
            stdout=None,
        )
        assert result == mock_result

def test_run_cmd_failure_check_true():
    with patch('subprocess.run') as mock_run:
        mock_run.side_effect = subprocess.CalledProcessError(1, ["ls", "/nonexistent"])
        
        with pytest.raises(subprocess.CalledProcessError):
            run_cmd(["ls", "/nonexistent"], check=True)

def test_run_cmd_failure_check_false():
    with patch('subprocess.run') as mock_run:
        error = subprocess.CalledProcessError(1, ["ls", "/nonexistent"])
        mock_run.side_effect = error
        
        result = run_cmd(["ls", "/nonexistent"], check=False)
        assert result == error

def test_run_cmd_capture_output():
    with patch('subprocess.run') as mock_run:
        mock_result = MagicMock()
        mock_result.stdout = "hello\n"
        mock_run.return_value = mock_result
        
        result = run_cmd(["echo", "hello"], capture_output=True)
        
        mock_run.assert_called_once_with(
            ["echo", "hello"],
            check=True,
            shell=False,
            capture_output=True,
            text=True,
            cwd=None,
            input=None,
            env=None,
            stdout=None,
        )
        assert result.stdout == "hello\n"


def test_run_cmd_quiet_suppresses_log_line():
    """quiet=True should NOT emit the 'Running command:' log line."""
    with patch('subprocess.run') as mock_run, \
         patch('hiddify_manager.utils.shell.log') as mock_log:
        mock_run.return_value = MagicMock(returncode=0)
        run_cmd(["echo", "hi"], quiet=True)
    # log.info shouldn't have been invoked at all.
    mock_log.info.assert_not_called()


def test_run_cmd_default_logs_command():
    """Without quiet=, the 'Running command:' line stays — default behaviour."""
    with patch('subprocess.run') as mock_run, \
         patch('hiddify_manager.utils.shell.log') as mock_log:
        mock_run.return_value = MagicMock(returncode=0)
        run_cmd(["echo", "hi"])
    mock_log.info.assert_called_once()
    assert "Running command" in mock_log.info.call_args.args[0]
