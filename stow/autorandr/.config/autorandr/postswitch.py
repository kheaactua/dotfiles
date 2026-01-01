#!/usr/bin/env python3

"""
Autorandr postswitch script for i3wm
Manages workspace placement and Polybar configuration across multiple monitors
"""

import json
import os
import subprocess
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Dict, Optional
from enum import Enum
import logging
from datetime import datetime


# Setup logging
LOG_FILE = Path("/tmp/i3_autorandr_debug.log")
logging.basicConfig(
    level=logging.INFO,
    format="%(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE, mode="a"),
    ],
)
logger = logging.getLogger(__name__)


class PolybarTheme(str, Enum):
    """Available Polybar themes from adi1090x/polybar-themes"""
    BLOCKS = "blocks"
    COLORBLOCKS = "colorblocks"
    CUTS = "cuts"
    DOCKY = "docky"
    FOREST = "forest"
    GRAYBLOCKS = "grayblocks"
    HACK = "hack"
    MATERIAL = "material"
    SHADES = "shades"
    SHAPES = "shapes"


@dataclass
class Monitor:
    """Represents a connected monitor configuration"""

    device: str  # e.g., "DP-1-2"
    resolution: str  # e.g., "5120x1440"
    position: str  # e.g., "2560+768"
    is_primary: bool = False
    workspaces: List[int] = field(default_factory=list)
    polybar: Optional[PolybarTheme] = None  # None = no polybar, PolybarTheme.BLOCKS = specific theme

    @property
    def width(self) -> int:
        return int(self.resolution.split("x")[0])

    @property
    def height(self) -> int:
        return int(self.resolution.split("x")[1])


# Static config for all the displays on the supported hosts
# Each key is <hostname>-<no. of displays>
DISPLAY_CONFIGS: Dict[str, List[Monitor]] = {
    "khea-2": [  # Home setup
        Monitor(
            device="DisplayPort-2",
            resolution="2560x1080",
            position="0+0",
            is_primary=True,
            workspaces=[2, 4, 9],
            polybar=PolybarTheme.BLOCKS,  # Can specify theme per monitor!
        ),
        Monitor(
            device="DisplayPort-1",
            resolution="5120x1440",
            position="2560+0",
            is_primary=True,
            workspaces=[1, 5, 6, 7, 8, 10],
            polybar=PolybarTheme.SHAPES,  # Or use same theme on both
        ),
    ],
    "UGC14VW7PZ3-3": [  # Work setup
        Monitor(
            device="DP-0",
            resolution="1920x1200",
            position="0+0",
            is_primary=True,
            workspaces=[1, 8],
            polybar=None,
        ),
        Monitor(
            device="DP-2.8",
            resolution="1920x1200",
            position="1920+0",
            is_primary=False,
            workspaces=[2, 4, 5, 6, 7, 9, 10],
            polybar=PolybarTheme.BLOCKS,
        ),
        Monitor(
            device="DP-2.1",
            resolution="1200x1920",
            position="3840+0",
            is_primary=False,
            workspaces=[3, 11, 12],
            polybar=None,
        ),
    ],
    "UGC147YVDS3-3": [  # Laptop with 2 external monitors
        Monitor(
            device="DP-1-1",
            resolution="2560x1080",
            position="0+1128",
            is_primary=False,
            workspaces=[1, 8],
            polybar=PolybarTheme.FOREST,
        ),
        Monitor(
            device="DP-1-2",
            resolution="5120x1440",
            position="2560+768",
            is_primary=True,
            workspaces=[2, 4, 5, 6, 7, 10],
            polybar=PolybarTheme.SHAPES,  # Or use same theme on both
        ),
        Monitor(
            device="eDP-1",
            resolution="1366x768",
            position="3469+0",
            is_primary=False,
            workspaces=[3, 9, 11, 12],
            polybar=None,  # No bar on laptop screen
        ),
    ],
    "UGC147YVDS3-1": [  # Laptop only
        Monitor(
            device="eDP-1",
            resolution="1366x768",
            position="0+0",
            is_primary=True,
            workspaces=[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
            polybar=PolybarTheme.BLOCKS,
        ),
    ],
}


class DisplayManager:
    """Manages display detection and workspace arrangement"""

    def __init__(self):
        self._monitors: Optional[List[Monitor]] = None
        self.hostname = self._get_hostname()

    def _get_hostname(self) -> str:
        return subprocess.check_output(["hostname"], text=True).strip()

    def _run_cmd(
        self, cmd: List[str], check: bool = True
    ) -> subprocess.CompletedProcess:
        """Run a command and return the result"""
        return subprocess.run(cmd, capture_output=True, text=True, check=check)

    def detect_connected_monitors(self) -> List[str]:
        """Parse xrandr output to get list of connected monitor device names"""
        result = self._run_cmd(["xrandr", "--query"])
        connected = []

        for line in result.stdout.splitlines():
            if " connected" in line:
                parts = line.split()
                output = parts[0]
                connected.append(output)

        logger.info(f"--- {datetime.now()} ---")
        logger.info(
            f"Detected {len(connected)} connected monitor(s): {', '.join(connected)}"
        )

        return connected

    @property
    def monitors(self) -> List[Monitor]:
        """Return configured monitors based on hostname and number of displays"""
        if self._monitors is None:
            connected = self.detect_connected_monitors()
            key = f"{self.hostname}-{len(connected)}"

            if key in DISPLAY_CONFIGS:
                self._monitors = DISPLAY_CONFIGS[key]
                logger.info(f"Loaded static config for '{key}'")
                for m in self._monitors:
                    logger.info(
                        f"  {m.device}: {m.resolution}+{m.position} "
                        + f"(primary={m.is_primary}, workspaces={m.workspaces}, polybar={m.polybar})"
                    )
            else:
                logger.error(f"No static display config found for key '{key}'")
                logger.error(f"Available configs: {list(DISPLAY_CONFIGS.keys())}")
                self._monitors = []

        return self._monitors

    def get_i3_workspaces(self) -> List[int]:
        """Get list of existing i3 workspace numbers"""
        result = self._run_cmd(["i3-msg", "-t", "get_workspaces"])
        workspaces = json.loads(result.stdout)
        return [ws["num"] for ws in workspaces if ws["num"] is not None]

    def move_workspace_to_output(self, workspace_num: int, output: str):
        """Move an i3 workspace to a specific output"""
        workspaces = self.get_i3_workspaces()

        if workspace_num not in workspaces:
            logger.info(f"Workspace {workspace_num} does not exist, skipping move.")
            return

        cmd = [
            "i3-msg",
            f"[workspace={workspace_num}]",
            "move",
            "workspace",
            "to",
            "output",
            output,
        ]
        result = self._run_cmd(cmd, check=False)
        logger.info(
            f"Moved workspace {workspace_num} to {output}: {result.stdout.strip()}"
        )

    def arrange_workspaces(self):
        """Arrange i3 workspaces across monitors based on static configuration"""
        for monitor in self.monitors:
            if monitor.workspaces:
                logger.info(
                    f"Assigning {len(monitor.workspaces)} workspace(s) to {monitor.device}: {monitor.workspaces}"
                )
                for ws_num in monitor.workspaces:
                    self.move_workspace_to_output(ws_num, monitor.device)


class PolybarManager:
    """Manages Polybar configuration and launching"""

    def __init__(self, display_manager: DisplayManager):
        self.display_manager = display_manager
        self.polybar_config_dir = Path.home() / ".config" / "polybar"

    def get_polybar_monitors(self) -> List[Monitor]:
        """Get all monitors that should display Polybar"""
        monitors = self.display_manager.monitors
        polybar_monitors = [m for m in monitors if m.polybar]

        if not polybar_monitors:
            logger.warning("No monitors configured for Polybar")
            # Fallback: use primary monitor
            for monitor in monitors:
                if monitor.is_primary:
                    logger.info(
                        f"Polybar: No polybar config set, falling back to primary ({monitor.device})"
                    )
                    return [monitor]
            # Last resort: first monitor
            if monitors:
                logger.info(
                    f"Polybar: No polybar config set, falling back to first monitor ({monitors[0].device})"
                )
                return [monitors[0]]
            return []

        logger.info(
            f"Polybar: Configured for {len(polybar_monitors)} monitor(s): {[m.device for m in polybar_monitors]}"
        )
        return polybar_monitors

    def get_theme_config(self, monitor: Monitor) -> Optional[Path]:
        """
        Get the polybar config file for a specific monitor.
        Priority:
        1. Monitor's polybar field (theme name)
        2. Environment variable POLYBAR_THEME
        3. current-theme symlink
        4. Default config.ini
        """
        # Use monitor-specific theme if set
        if monitor.polybar:
            # Get the actual string value from the enum
            theme_name = monitor.polybar.value if isinstance(monitor.polybar, PolybarTheme) else str(monitor.polybar)
            theme_config = self.polybar_config_dir / theme_name / "config.ini"
            if theme_config.exists():
                logger.info(f"Polybar: Using monitor-specific theme '{theme_name}' for {monitor.device}")
                return theme_config
            else:
                logger.warning(f"Polybar: Monitor theme '{theme_name}' not found for {monitor.device}, falling back")

        # Check for environment variable override
        theme_override = os.environ.get("POLYBAR_THEME")
        if theme_override:
            theme_config = self.polybar_config_dir / theme_override / "config.ini"
            if theme_config.exists():
                logger.info(f"Polybar: Using theme from POLYBAR_THEME env: {theme_override}")
                return theme_config
            else:
                logger.warning(f"Polybar: POLYBAR_THEME '{theme_override}' not found, using default")

        # Check for symlink to current theme
        current_theme_link = self.polybar_config_dir / "current-theme"
        if current_theme_link.exists():
            logger.info(f"Polybar: Using theme from current-theme symlink for {monitor.device}")
            return current_theme_link

        # Default to main config.ini
        default_config = self.polybar_config_dir / "config.ini"
        if default_config.exists():
            logger.info(f"Polybar: Using default config.ini for {monitor.device}")
            return default_config

        logger.error(f"Polybar: No config file found for {monitor.device}!")
        return None

    def launch_polybar(self):
        """Launch Polybar on all configured monitors with per-monitor theme support"""
        polybar_monitors = self.get_polybar_monitors()

        if not polybar_monitors:
            logger.error("No monitors selected for Polybar, aborting")
            return

        # Kill existing Polybar instances
        subprocess.run(["killall", "polybar"], check=False)

        # Launch Polybar on each configured monitor
        for monitor in polybar_monitors:
            # Get theme config for this specific monitor
            config_file = self.get_theme_config(monitor)
            if not config_file:
                logger.error(f"No polybar config available for {monitor.device}, skipping")
                continue

            log_file = Path(f"/tmp/polybar_{monitor.device}.log")
            env = os.environ.copy()
            env["MONITOR"] = monitor.device

            with open(log_file, "a") as f:
                subprocess.Popen(
                    ["polybar", "-c", str(config_file), "main"],
                    env=env,
                    stdout=f,
                    stderr=subprocess.STDOUT,
                )

            theme_name = monitor.polybar if isinstance(monitor.polybar, str) else "default"
            logger.info(f"Polybar: Launched '{theme_name}' on {monitor.device} (log: {log_file})")

        logger.info(
            f"Polybar: Successfully launched {len(polybar_monitors)} instance(s)"
        )


class BackgroundManager:
    """Manages desktop background/wallpaper"""

    @staticmethod
    def set_random_background():
        """Set a random background using feh"""
        backgrounds_dir = Path.home() / "Desktop" / "Backgrounds"

        if not backgrounds_dir.exists():
            logger.info("Backgrounds directory not found, skipping")
            return

        # Check if feh is available
        if subprocess.run(["which", "feh"], capture_output=True).returncode != 0:
            logger.info("feh not found, skipping background change")
            return

        # Get list of image files
        image_files = list(backgrounds_dir.glob("*"))
        if not image_files:
            logger.info("No images found in backgrounds directory")
            return

        subprocess.run(
            ["feh", "--randomize", "--bg-fill"] + [str(f) for f in image_files],
            check=False,
        )
        logger.info("Background updated with feh")


def main():
    """Main postswitch logic"""
    # Give xrandr and i3wm a moment to settle
    time.sleep(0.5)

    # Initialize managers
    display_mgr = DisplayManager()

    # Access monitors to trigger detection and config loading
    if not display_mgr.monitors:
        logger.error("No monitor configuration available, aborting")
        sys.exit(1)

    # Arrange workspaces
    display_mgr.arrange_workspaces()

    # Set background
    BackgroundManager.set_random_background()

    # Configure and launch Polybar
    polybar_mgr = PolybarManager(display_mgr)
    polybar_mgr.launch_polybar()

    logger.info("Postswitch completed successfully")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logger.exception(f"Postswitch failed with error: {e}")
        sys.exit(1)
