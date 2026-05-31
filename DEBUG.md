# Build and Deploy Artifact DEBUG.md

## Failure hypotheses

1. The process remained tied to the interactive shell session.
When running `./main` or `./main &` directly via SSH, the process becomes a child of that terminal; when the SSH session is closed, the shell sends a SIGHUP (Signal Hang Up) signal that automatically kills all its child processes.

2. Missing environment variables outside the shell
The binary might be depending on an environment variable that is only loaded interactively in the user's profile during SSH, so when trying to run it unattended or with `nohup`, it crashes shortly after because it cannot find that configuration.

## Hypothesis verification

1. I connect via SSH, start the program by running `nohup ./main &` (which ignores the SIGHUP signal), close the session, log back in, and run `curl localhost:4444`. If it responds, the problem was definitely the dependency on the shell session.
2. I check the system logs or the error output by running `cat nohup.out` or `grep main /var/log/syslog` right after the app dies, to see if it threw any "variable not found" or permission errors.

## Solution

The cleanest and most robust solution, without resorting to Docker or rewriting everything, is to use **systemd**. We create a unit file at `/etc/systemd/system/myapp.service` with the instruction `ExecStart=/home/laborant/main`, and then we run `sudo systemctl enable --now myapp` so the operating system launches it in the background as a daemon.

## The underlying lesson

The main difference is that a process that "exists right now" is ephemeral and vulnerable because it depends on the lifecycle of the user terminal that launched it, whereas a "supervised process" is managed directly by the operating system, which guarantees that it runs in the background, starts on boot, and restarts automatically if it fails.