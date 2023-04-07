# Available

Available includes CLI tools designed to ease writing scripts for administration tasks on macOS. These CLI tools are wrapped within an application shell in order to provide a reliable installation path.

In most cases, the included tools would be used in scripts run via an MDM such as Jamf Pro.

## User Availability CLI Tool

Often one may need to interact with a user when running a management script. As many management tasks are critical for the security and stability of macOS, these dialogs can be pretty important.  Of course, it's *also* possible that the user is already doing something equally important.  Or slightly less important, but still not worth interrupting such as that pesky sales presentation on stage in front of 50,000 convention attendees.

That's where `available-cli` comes in.  This tool can check several different items to determine if it is a wise time to interrupt the user.  Best of all, you can decide what level of deference you want to give to the user based on the flags used.

| Flag | Description |
| --- | --- |
| `--camera` | Camera Active? |
| `--presenting` | 'No Sleep' Display Assertation? |
| `--zoom` | Zoom Meeting Active? |
| `--webex` | WebEx Meeting Active? |
| `--gotomeeting` | GotoMeeting Meeting Active? |
| `--teams` | Teams Meeting Active? |
| `--focus` | Focus Mode Active? | 
| `--power` | On Battery Power? |
| `--filevault` | FileVault Encrypting? |
| `--metered` | Is 'Low Data Mode' Connection? |
| `--all` | Includes all flags above |

Additionally, the *Work* focus can be excluded from the `--focus` check with the additional flag `--nowork`.  

### Usage

Depending on whether you would like some feedback, or simply a boolean result, usage may vary. Output can take three forms:

| Flag | Description |
| --- | --- |
| `--quiet` | No output; return code 1 means 'unavailable'. |
| `--verbose` | Status of all specified conditions is shown. |
| _no flag_ | Simple output for only the first failed condition. |

Here is an example of Bash usage, with a standard installation:

    binAvailable="/Applications/Available.app/Contents/Resources/available-cli"
    if state=$($binAvailable --camera --metered --presenting); then
      echo "User Unavaiable: '${state}'.  Exiting..."
      exit 1
    fi

## Script Output CLI Tool

While many management scripts can have fairly plain output, it can be useful for troubleshooting purposes to standarize output. The addition of color and context can also be helpful when testing scripts or running them directly from the CLI.

Using `output-cli`, script output can be easily colorized and standardized across all your management scripts. When used with a terminal that supports ANSI color, `output-cli` uses contextual colors based on the given flags.  When run via a method that has no color support, only plain text is used.

This tool can also provide consistent indentation, allowing for sectioned output.

### Context Flags

| Flag | Text Color |
| --- | --- |
| `--success` | Green |
| `--info` | Cyan |
| `--msg` | Magenta |
| `--error` | Red |
| `--warning` | Yellow |
| `--default` | No Color |

### Function Flags

| Flag | Output Style |
| --- | --- |
| `--notify` | Message, in cyan, followed by spacers.  Typically used before an activity. |
| `--badge` | Your short message inside uncolored brackets, such as [DONE].  Typically used an activity.  See example below.
| `--line` | Message with line feed. |
| `--inline` | Message without line feed. |
| `--section` | Message in magenta.  All subsequent messages will be indented. |
| `--endsection` | No message, but ends previously set section. |

### Verbosity Flags

By setting the environment variable `OUTPUT_QUIET=1` or `OUTPUT_VERBOSE=1` prior to using `output-cli`, you  can emit messages for different verbosity levels.

| Flag | Output Style |
| --- | --- |
| `--quiet` | Message will display even if `OUTPUT_QUIET=1` |
| `--verbose` | Message will display only if `OUTPUT_VERBOSE=2` | 
| `--very-verbose` | Message will display only if `OUTPUT_VERBOSE=3` | 
| _no flag_ | Message will display if not `OUTPUT_QUIET=1` |

### Example Usage

#### Notify / Badge
The most frequent use case is in combination with some sort of test. The example below gives an example using `--notify` and `--badge` to provide feedback on the result of a test. 

    binOutput="/Applications/Available.app/Contents/Resources/output-cli"
    $binOutput --notify "Checking Firefox Install"
    if [ -d "/Applications/Firefox.app ]; then 
      $binOutput --success --badge "FOUND"
    else
      $binOutput --error --badge "NOT FOUND"
      exit 1
    fi
    
Which would show the following output:

> Checking Firefox Install................................................. [FOUND]

#### Different Verbosity Levels

An example of providing different levels of messages is below:

    binOutput="/Applications/Available.app/Contents/Resources/output-cli"
    $binOutput --notify "Checking Something"
    out=$(/usr/bin/somebinary 2>&1);
    if echo "$out"; grep -q "error"; then
      $binOutput --error --badge "ERROR"
      echo ""
      # Show the error only if OUTPUT_VERBOSE=2
      $binOutput --error --verbose "$out"
      exit 1
    else
      $binOutput --success --badge "SUCCESS"
    fi

If used with `OUTPUT_VERBOSE=2` before the snippet above, and assuming _somebinary_ fails, the output would be:

> Checking Something....................................................... [ERROR]
> 
> ERROR MESSAGE FROM somebinary DISPLAYED HERE

If used without setting `OUTPUT_VERBOSE` only the notify and badge would be shown.





