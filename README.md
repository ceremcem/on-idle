> Based on: https://unix.stackexchange.com/a/122816/65781

# Usage 

Run `command` if computer is idle for 5 seconds:

```
on-idle.sh 5 command [arguments...]
```

When the idle duration ended, `command` process is killed. 

# Example 

```
on-idle.sh 3 notify-send "Computer was idle for last 3 seconds."
```
