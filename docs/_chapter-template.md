# Chapter NN: Title

> **Command tags:** `[Pi]` = SSH session on the robot, `[PC]` = normal PC terminal,
> `[PC-container]` = inside the Docker container on the PC.

## Goal

One or two sentences: what will work at the end of this chapter that did not work before?

## ROS concepts in this chapter

| Concept | What it is here | How to see it yourself |
|---------|-----------------|------------------------|
| e.g. Topic | `/scan` carries lidar data | `ros2 topic info /scan` |
| e.g. Publisher | the lidar driver node | `ros2 topic info /scan -v` |

Plain-language explanation (3 to 6 sentences) of the idea for someone who has never used ROS.

## Before you start

- [ ] Previous chapter's checklist is done
- [ ] Robot is powered and the battery is charged
- [ ] You know which machine each command runs on

## Steps

### Step N.1: Short imperative title

What this step does and why, in one or two sentences.

```bash
# [Pi]
command here
```

**You should see:** the expected output, or a description of it.

**If you do not:** jump to [When it broke](#when-it-broke) or the troubleshooting index.

## Checklist

- [ ] First thing that must be true
- [ ] Second thing that must be true
- [ ] You can explain, in your own words, what the concept above did in this chapter

## When it broke

*Leave this section out if nothing went wrong. If something did, keep the wrong turns.*

| | |
|---|---|
| **Symptom** | What you saw, with the exact error text or a screenshot |
| **What I thought it was** | The first hypothesis, even if it was wrong |
| **How I tested it** | The command or experiment |
| **What it really was** | The real cause, and how I know |
| **Fix** | The commands that fixed it |
| **Lesson** | What to check first next time |

## Recap

Three bullets: what you did, which ROS idea it showed, what comes next.

## Try it yourself (optional)

One small exercise that reinforces the concept, for example: "Run `ros2 topic hz /odom` and
compare it with `/scan`. Why are the rates different?"
