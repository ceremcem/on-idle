> Based on: https://unix.stackexchange.com/a/122816/65781

# Usage 

Run `command` if computer is idle for 5 seconds:

```
on-idle.sh 0:0:5 command [arguments...]
```

When the idle duration ended, `command` process is killed. 

# Example 

```
on-idle.sh 0:10:0 notify-send "Computer was idle for last 10 minutes."
```

# Dependencies

1. Install development headers:

      sudo apt-get install libxss-dev

2. Compile `getIdle`: 

      make
