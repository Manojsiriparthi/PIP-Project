"""Smoke tests for CLI help output."""

import subprocess
import sys


SCRIPTS = [
    "scripts/ec2_inventory.py",
    "scripts/rds_inventory.py",
    "scripts/vpc_inventory.py",
    "scripts/resource_discovery.py",
    "scripts/cost_analysis.py",
    "scripts/security_group_audit.py",
    "scripts/ami_cleanup.py",
    "scripts/snapshot_manager.py",
]


def test_all_scripts_have_help():
    for script in SCRIPTS:
        result = subprocess.run(
            [sys.executable, script, "--help"],
            capture_output=True,
            text=True,
            check=False,
        )
        assert result.returncode == 0
        assert "usage:" in result.stdout.lower()
