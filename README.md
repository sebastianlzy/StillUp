# StillUp

StillUp is a macOS menu bar app that keeps your Mac awake while it’s idle.
Open StillUp and click the coffee cup in the menu bar. Choose **Keep Mac Awake**
for an untimed session, or choose **1 Hour**, **2 Hours**, or **5 Hours** to
restore normal idle sleep automatically when the timer ends.

The cup fills in while StillUp is active. Hover over it to see the time remaining,
or open the menu to see when the session ends. Picking another duration starts
a fresh timer. Choose **Allow Sleep** or quit StillUp to end the session early.

Your display can still turn off. Closing a MacBook lid or choosing **Sleep**
from the Apple menu still follows normal macOS behavior.

## Build and run

Use macOS 13 or later with Apple’s Command Line Tools installed. From this directory:

```sh
./build.sh
open StillUp.app
```
