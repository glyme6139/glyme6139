import os
import random
import sys
import subprocess
import ctypes
import time


KEYS_TO_PRESS = "alt+tab"   # Do alt tab 
# KEYS_TO_PRESS = " "       # Just type a space
# KEYS_TO_PRESS = "enter"   # Just type a space

LOGOFF = False              # If true, will logoff instead of using the KEYS_TO_PRESS

MIN_TIME = 20               # Minimum time before new action
MAX_TIME = 50               # Maximum time before new action


try:
    import keyboard
except: 
    os.system("py -m pip install keyboard")
    import keyboard

def is_hidden():
    """
    Check if the program is currently running in a hidden console window.

    Explanation:
    - The Windows API function GetConsoleWindow() returns a handle (HWND) for the current
      console window. If the process does not have an attached console window, it returns 0.
    - Therefore, if the handle is 0, we consider that the program is running in a hidden mode.
    """
    hwnd = ctypes.windll.kernel32.GetConsoleWindow()
    return hwnd == 0

def require_hidden():
    """
    Ensure that the script is running in a hidden mode.
    
    If the program is not running in a hidden window, this function re-launches the 
    current script with the CREATE_NO_WINDOW flag to hide the console window, then exits
    the original process.
    """
    if is_hidden():
        # Already hidden; continue running the rest of your program.
        return

    # Command to re-launch the Python script:
    #   sys.executable: The path to the current Python interpreter.
    #   sys.argv: The list of command-line arguments passed to the script.
    command = [sys.executable] + sys.argv

    # The flag CREATE_NO_WINDOW prevents a console window from appearing for the new process.
    creationflags = subprocess.CREATE_NO_WINDOW

    # Re-run the script in a hidden window. Note:
    # - close_fds=True ensures file descriptors are closed in the child process,
    #   helping avoid issues with open files.
    subprocess.Popen(command, creationflags=creationflags, close_fds=True)

    # Exit the current process to avoid running both instances.
    sys.exit()


def press_release(keys) :
    keyboard.press(keys)
    time.sleep(0.2)
    keyboard.release(keys)

# Example usage
if __name__ == "__main__":
    require_hidden()

    while True:
        if LOGOFF :
            ctypes.windll.user32.LockWorkStation()
        else :
            press_release(KEYS_TO_PRESS)
        time.sleep(random.randint(MIN_TIME,MAX_TIME))