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



# Deployment to aws ec2

1. Security Group is blocking port 4444, a hang instead of "connection refused" is almost always a firewall silently dropping packets. Fix: add an inbound TCP/4444 rule to the Security Group.

Verification:
```bash
nc -zv <public-ip> 4444
```

2. app is listening on localhost only. If the app binds to `127.0.0.1` instead of `0.0.0.0`, external traffic never reaches it.

Verification:
```bash
ss -tlnp | grep 4444
```
## Solution
Add an inbound TCP/4444 rule from `0.0.0.0/0` in the Security Group.

## The underlying lesson
A **dropped** packet gets no response and the connection hangs forever.
A packet hitting a **closed port** gets a TCP RST back — immediate "connection refused".